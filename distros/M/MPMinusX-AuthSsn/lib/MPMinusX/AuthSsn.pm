package MPMinusX::AuthSsn; # $Id: AuthSsn.pm 2 2013-08-07 09:50:14Z minus $
use strict;

=head1 NAME

MPMinusX::AuthSsn - MPMinus AAA via Apache::Session and DBD::SQLite

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use MPMinusX::AuthSsn;

    # AuthSsn session
    my $ssn;
    
    ... see description ...

    sub hCleanup {
        ...
        undef $ssn;
        ...
    }

=head1 ABSTRACT

MPMinusX::AuthSsn - MPMinus AAA via Apache::Session and DBD::SQLite

=head1 DESCRIPTION

Methods of using

=head2 METHOD #1. MPMINUS HANDLERS LEVEL (RECOMENDED)

    sub hInit {
        ...
        my $usid = $usr{usid} || $q->cookie('usid') || '';
        $ssn = new MPMinusX::AuthSsn( $m, $usid );
        ...
    }
    sub hResponse {
        ...
        my $access = $ssn->access( sub {
                my $self = shift;
                return $self->status(0, 'FORBIDDEN') if $self->get('login') eq 'admin';
            } );
        if ($access) {
            # Auhorized!
            $h{login} = $ssn->get('login');
        }
        $template->cast_if("authorized", $access);
        ....
    }

=head2 METHOD #2. MPMINUS TRANSACTION LEVEL

    sub default_access {
        my $usid = $usr{usid} || $q->cookie('usid') || '';
        $ssn = new MPMinusX::AuthSsn( $m, $usid );
        return $ssn->access();
    }
    sub default_deny {
        my $m = shift;
        my $r = $m->r;
        $r->headers_out->set(Location => "/auth.mpm");
        return Apache2::Const::REDIRECT;
    }
    sub default_form {
        ...
        $h{login} = $ssn->get('login');
        ...
    }

=head1 METHODS

=over 8

=item B<new>

    my $authssn = new MPMinusX::AuthSsn( $m, $sid, $expires );

Returns object

=item B<authen>

    $ssn->authen( $callback, ...arguments... );

AAA Authentication.

The method returns status operation: 1 - successfully; 0 - not successfully

=item B<authz>

    $ssn->authz( $callback, ...arguments... );

AAA Authorization.

The method returns status operation: 1 - successfully; 0 - not successfully

=item B<access>

    $ssn->access( $callback, ...arguments... );

AAA Accounting (AAA Access).

The method returns status operation: 1 - successfully; 0 - not successfully

=item B<get>

    $ssn->get( $key );

Returns session value by $key

=item B<set>

    $ssn->set( $key, $value );

Sets session value by $key

=item B<delete>

    $ssn->delete();

Delete the session

=item B<sid, usid>

    $ssn->sid();

Returns current usid value

=item B<expires>

    $ssn->expires();

Returns current expires value

=item B<status>

    $ssn->status();
    $ssn->status( $newstatus, $reason );

Returns status of a previously executed operation. If you specify $reason, there will push installation $newstatus

=item B<reason>

    $ssn->reason();

Returns reason of a previously executed operation.

Now supported following values: DEFAULT, OK, UNAUTHORIZED, ERROR, SERVER_ERROR, NEW, TIMEOUT, LOGIN_INCORRECT, 
PASSWORD_INCORRECT, DECLINED, AUTH_REQUIRED, FORBIDDEN.

For translating this values to regular form please use method reason_translate like that

=item B<init>

    $ssn->init( $usid, $needcreate );

Internal method. Please do not use it

Method returns status operation: 1 - successfully; 0 - not successfully

=item B<toexpire>

    $ssn->toexpire( $time );

Returns expiration interval relative to ctime() form.

If used with no arguments, returns the expiration interval if it was ever set. 
If no expiration was ever set, returns undef. 

All the time values should be given in the form of seconds. 
Following keywords are also supported for your convenience:

    +-----------+---------------+
    |   alias   |   meaning     |
    +-----------+---------------+
    |     s     |   Second      |
    |     m     |   Minute      |
    |     h     |   Hour        |
    |     d     |   Day         |
    |     w     |   Week        |
    |     M     |   Month       |
    |     y     |   Year        |
    +-----------+---------------+

Examples:

    $ssn->toexpire("2h"); # expires in two hours
    $ssn->toexpire(3600); # expires in one hour

Note: all the expiration times are relative to session's last access time, not to its creation time. 
To expire a session immediately, call delete() method.

=back

=head1 CONFIGURATION

Sample in file conf/auth.conf:

    <Auth>
        expires +3m
        #sidkey usid
        #tplkey authorized
        #tplpfx auth
        #file   /document_root/db/session.db
    </Auth>

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<MPMinus>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<MPMinus>, L<CTK>, L<Apache::Session>, L<DBD::SQLite>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use Apache::Session::Flex;
use CTK::Util qw/ :API :FORMAT :DATE /;
use CTK::ConfGenUtil;
use CTK::DBI;

use constant {
        CONFKEY         => 'auth',
        SIDKEY          => 'usid',
        TPLKEY          => 'authorized',
        TPLPFX          => '',
        SESSION_DIR     => 'sessions', # not used
        SESSION_FILE    => 'sessions.db',
        SESSION_EXPIRES => '+1h', # 3600sec as default
        
        # Определяем таблицу перевода состояний
        STAT => {
            DEFAULT             => to_utf8('Статус неопределен'),
            OK                  => to_utf8('Операция прошла успешно'),
            UNAUTHORIZED        => to_utf8('Вы неавторизированы'),
            ERROR               => to_utf8('Сессия несуществует или возникла ошибка создания сессии'),
            SERVER_ERROR        => to_utf8('Ошибка сервера'),
            NEW                 => to_utf8('Сесиия создана успешно'),
            TIMEOUT             => to_utf8('Период жизни сессии истек'),
            LOGIN_INCORRECT     => to_utf8('Неправильный логин'),
            PASSWORD_INCORRECT  => to_utf8('Неправильный пароль'),
            DECLINED            => to_utf8('Такой учетной записи нет'),
            AUTH_REQUIRED       => to_utf8('Неверно введен пароль'),
            FORBIDDEN           => to_utf8('Доступ запрещен'),
        },
    };

sub new {
    # Конструктор: создаем или используем ранее созданную сессиию
    my $class   = shift;
    my $m       = shift;
    my $usid    = shift || undef; # USID User Session IDentifier
    my $expires = shift || undef; # Дефолтное Количество секунд которое может существовать сессия
    croak("The method call not in the MPMinus context") unless ref($m) =~ /MPMinus/;

    my $authconf    = hash($m->conf(CONFKEY));
    my $s_sidkey    = value($authconf, 'sidkey') || SIDKEY;
    my $s_tplkey    = value($authconf, 'tplkey') || TPLKEY;
    my $s_tplpfx    = value($authconf, 'tplpfx') || TPLPFX;
    my $s_dir       = value($authconf, 'dir') || catdir($m->conf('document_root'),$m->conf('dir_db'),SESSION_DIR);
    my $s_file      = value($authconf, 'file') || catfile($m->conf('document_root'),$m->conf('dir_db'),SESSION_FILE);
    my $s_expires   = value($authconf, 'expires') || SESSION_EXPIRES;
    $expires ||= $s_expires;
    #$m->log_error("Expires in OUT: ".$class->toexpire($expires));

    # Создаем пустой объект
    my $self = bless {
        session     => {},
        transtable  => STAT,
        status      => 0, # Связки не произошло
        reason      => "UNAUTHORIZED",
        dir         => $s_dir,
        file        => $s_file,
        expires     => $class->toexpire($expires), # сессия с момента последнего доступа к ней!
        $s_sidkey   => undef,
        sidkey      => $s_sidkey,
        tplkey      => $s_tplkey,
        tplpfx      => $s_tplpfx,
    }, $class;
    
    # Секция инициализации как использование
    $self->init($usid, 0) if $usid; # Используем существующую сессию (НЕ создаем, создание ТОЛЬКО при авторизации)
    
    return $self;
}
sub init {
    # Непосредственно инициализатор сессии
    my $self = shift;
    my $usid = shift || undef; # USID User Session IDentifier
    my $create = shift || 0; # 1 - создать сессию; 0 - не создавать сессию, а просто свзять и все
    
    #
    # Выполняет задачу валидации и создания сессии.
    # Если пользователь ввел данные но они неверные, то возвращается ошибка со статусом ERROR
    # Если пользователь вошел впервые то для него создается сессия со статусом NEW
    # Если пользователь уже не первый раз посещает страницы с сессией то используется сессиия со статусом OK
    #
    
    my %session;
    my $ssndata = $self->{session} && ref($self->{session}) eq 'HASH' ? $self->{session} : {};
    my $reason;

    # Пути
    my $sdir  = $self->{dir}; #use File::Path; mkpath( $sdir, {verbose => 0} ) unless -e $sdir;
    my $sfile = $self->{file};
    
    # Создание пустой базы если ее нет или она пуста
    my $dsn = "dbi:SQLite:dbname=$sfile";
    unless ($sfile && (-e $sfile) && !(-z _)) {
        my $sqlc = new CTK::DBI( -dsn  => $dsn);
        $sqlc->execute('CREATE TABLE IF NOT EXISTS sessions ( id CHAR(32) NOT NULL PRIMARY KEY, a_session TEXT NOT NULL )');
        $sqlc->disconnect;
    }
    
    # Опции для Apache::Session
    my $opts = {
        Store       => 'MySQL',
        Lock        => 'Null',
        Generate    => 'MD5',
        Serialize   => 'Base64',
        DataSource  => $dsn,
    };

    # Создаем новый галстук
    my $retstat = $self->status;
    eval { tie %session, 'Apache::Session::Flex', $usid, $opts; };
    if ($@) {
        $reason = 'ERROR'; # Ошибки при инициализации объекта
    } else {
        if ($usid) {
            $reason = 'OK'; # Непервый удачный заход
        } else {
            $reason = 'NEW'; # Первый заход!
        }
        # Определяем созданный USID
        $self->{$self->{sidkey}} = $session{_session_id};
        
        # Добавляем данные в только-что созданную сессию (т.к. $create == 1)
        if ($create) {
            $session{time_create} = time(); # Время создания
            $session{time_access} = time(); # Время доступа
            $session{expires}     = $self->{expires}; # Время кастомизированное для данной сессии
            $session{$_} = $ssndata->{$_} foreach (keys %$ssndata);
        }
        $self->{session} = \%session;
        $retstat = 1; # Связка произошла удачно
    }

    return $self->status($retstat, $reason);
}

sub authen { # AAA-authen
    #
    # Аутентификация. Проверка - правильно ли введены логин и пароль
    #
    # Может принимать значения:
    #   LOGIN_INCORRECT / PASSWORD_INCORRECT / AUTH_REQUIRED / DECLINED / FORBIDDEN / OK
    #
    
    my $self = shift;
    my $callback = shift;

    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self,@_);
    }
    
    return $self->status(1, 'OK');
}
sub authz {  # AAA-authz
    #
    # Авторизация. Проверка ролей и бан-листов уровня БД
    #
    # Может принимать значения:
    #   FORBIDDEN / OK
    #
    
    my $self = shift;
    my $callback = shift;

    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self,@_);
    }    
    
    # Авторизация прошла успешно. Можно создавать сессию
    return 0 unless $self->init(undef,1);
    return 1;
}
sub access { # AAA-access
    #
    # Проверка данных сессии на предмет разрешения доступа к расширенному функционалу
    # Бан-листы и прочее
    #

    my $self = shift;
    my $callback = shift;
    
    # Проверка - а есть ли ошибки при инициализации ??
    return $self->status(0, $self->reason) unless $self->status;

    # Проверка expires и обновление данных последнего доступа.
    my $expires = $self->expires;
    my $lastaccess = $self->get('time_access') || 0;
    my $newaccess = time();
    my $accessto = (($newaccess - $lastaccess) > $expires); # true - timeout
    if ($accessto) {
        $self->delete(); # Удаляем если время истекло
        return $self->status(0, 'TIMEOUT');
    }
    
    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self,@_);
    }
    
    # Все проверки прошли успешно. обновляем время
    $self->set('time_access', $newaccess); # Время доступа
    
    return $self->status(1, 'OK'); # Доступ разрешен!
}

sub sid {
    # Получение USID
    my $self = shift;
    return $self->{$self->{sidkey}} || undef;
}
sub usid { goto &sid }
sub expires {
    # Получение expires
    my $self = shift;
    my $expires = $self->{session}->{expires} ? $self->{session}->{expires} : $self->{expires};
    return $expires || 0;
}
sub status {
    # Получение/установка статуса и причины или установка если задана причина
    my $self = shift;
    my $ns   = shift || 0;
    my $nr   = shift || '';
    if ($nr) {
        $self->{status} = $ns;
        $self->{reason} = $nr;
    }
    return $self->{status};
}
sub reason {
    # Получение описания статуса
    my $self = shift;
    return $self->{reason};
}
sub get {
    # Получение указанного ключа из сессии
    my $self = shift;
    my $key = shift || return;
    return $self->{session}->{$key} || undef;
}
sub set {
    # Запись указанного ключа в сессию
    my $self = shift;
    my $key = shift || return 0;
    my $value = shift;
    return $self->{session}->{$key} = $value;
}
sub delete {
    # Удаление сессии
    my $self = shift;
    tied(%{$self->{session}})->delete() if $self->{status}; # Удаляем если есть что
    return $self->status(0, 'UNAUTHORIZED');
}
sub reason_translate {
    # Перевод описания reason на русский язык с с расшифровкой
    my $self = shift;
    my $reason = shift || $self->reason() || 'DEFAULT';

    return $self->{transtable}->{DEFAULT} unless
        grep {$_ eq 'DEFAULT'} keys %{$self->{transtable}};
        
    return $self->{transtable}->{$reason};
}
sub toexpire {
    my $self = shift;
    my $str = shift || 0;

    return 0 unless defined $str;
    return $1 if $str =~ m/^[-+]?(\d+)$/;

    my %_map = (
        s       => 1,
        m       => 60,
        h       => 3600,
        d       => 86400,
        w       => 604800,
        M       => 2592000,
        y       => 31536000
    );

    my ($koef, $d) = $str =~ m/^([+-]?\d+)([smhdwMy])$/;
    unless ( defined($koef) && defined($d) ) {
        croak "toexpire(): couldn't parse '$str' into \$koef and \$d parts. Possible invalid syntax";
    }
    return $koef * $_map{ $d };
}
sub DESTROY {
    my $self = shift;
    undef $self;
}

1;
