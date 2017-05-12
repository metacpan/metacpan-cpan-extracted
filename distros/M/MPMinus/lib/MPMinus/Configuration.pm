package MPMinus::Configuration; # $Id: Configuration.pm 151 2013-05-29 14:31:19Z minus $
use strict;

=head1 NAME

MPMinus::Configuration - Configuration of MPMinus

=head1 VERSION

Version 1.33

=head1 SYNOPSIS

    package MPM::foo::Handlers;
    use strict;

    sub handler {
        my $r = shift;
        my $m = MPMinus->m;
        $m->conf_init($r, __PACKAGE__);
        
        ...
        
        my $project = $m->conf('project');
        
        ...    
    }

=head1 DESCRIPTION

The module works with the configuration data of the resource on the platform mod_perl.
The configuration data are relevant at the global level, and they are the same for all 
users at once!

=head1 METHODS

=over 8

=item B<conf_init>

    $m->conf_init( $r, $pkg );

=item B<conf, get_conf, config, get_config>

    my $value = $m->conf( 'key' );

=item B<set_conf, set_config>

    $m->set_conf( 'key', $value );

=back

=head1 HISTORY

=over 8

=item B<1.00 / 27.02.2008>

Init version on base mod_main 1.00.0002

=item B<1.10 / 01.04.2008>

Module is merged into the global module level

=item B<1.20 / 19.04.2010>

Added new type (DSN) support: Oracle

=item B<1.30 / 08.01.2012>

Added server_port variable

=item B<1.31 / Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=item B<1.32 / Wed May  8 12:25:30 2013 MSK>

Added locked_keys parameter

=back

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

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

use CTK::Util qw/ :BASE /; # Утилитарий
use MPMinus::MainTools; # Модуль для двух функций getHiTime и getSID
use Config::General;
use Try::Tiny;

use vars qw($VERSION);
$VERSION = 1.33;

sub conf_init {
    # Инициализация. Запускается из главного хэндлера!!
    my $m = shift;
    croak("The method call is made ActionCheck not in the style of OOP") unless ref($m) =~ /MPMinus/;
    my $r   = shift;
    croak("Object Apache2::RequestRec not defined") unless ref($r) eq 'Apache2::RequestRec';
    my $pkg = shift || ''; # Пакет, который вызвал инициализацию
    croak("Package name missing!") unless $pkg && $pkg =~ /Handlers$/;
    
    # Устанавливаем главнный объект Apache2::RequestRec и зависимые пакеты
    $m->set(r => $r);
    my $s = $r->server; # сервер
    my $c = $r->connection; # Соединение 
    
    # Внутренний массив
    my %conf;

    ##########################################################################
    # !!! Параметры, устанавливаемые каждый перезапуск !!!
    ##########################################################################

    # Пакет должен возглавлять список
    my $i = $m->conf('package') ? ($m->conf('package')->[1] + 1) : 0;
    $i = 1 if $i > 65534; # На случай переполнения стека
    $conf{package} = [$pkg,$i]; # Полное имя пакета и количество инициализаций за дочку. 0 - первый раз
    
    # Доопределяем параметры
    $conf{sid}    = getSID(16,'m'); # ID Сессии (SID) - Для контроля сессии
    $conf{hitime} = getHiTime();

    #
    # Основные значения (НЕ РЕДАКТИРУЕМЫЕ)
    #
    my $prj = '';
    if ($pkg =~ /([^\:]+?)\:\:Handlers$/) {
        $prj = $1;
        $conf{project} = $prj;
        $conf{prefix} = lc($prj);
    } else {
        $conf{project} = '';
        $conf{prefix} = '';
    }
    $conf{preffix} = $conf{prefix}; # Для обратной совместимости потом удалить !! 

    #
    # Переменные "окружения" Apache
    #
    $conf{request_uri}    = $r->uri() || ""; # полученная GET строка
    $conf{request_method} = $r->method() || ""; # полученная метода
    $conf{remote_addr}    = $c->remote_ip || ""; # IP клиента
    $conf{remote_user}    = $r->user() || ""; # Имя пользователя 

    $conf{server_admin}   = $s->server_admin() || ""; # Адрес электронной почты
    $conf{server_name}    = $s->server_hostname() || ""; # Имя сервера (главного хоста)
    $conf{server_port}    = $s->port() || 80; # Порт сервера (главного хоста)
    # HTTP_HOST = SERVER_NAME:SERVER_PORT if SERVER_PORT <> {80|443}
    $conf{http_host}    = $r->hostname() || ""; # Имя хоста (виртуального хоста, обращения)
    if ($conf{server_port} != 80 and $conf{server_port} != 443 and $conf{server_name} eq $conf{http_host}) {
        $conf{http_host} = join ':', $conf{server_name}, $conf{server_port};
    }

    # АБСОЛЮТНЫЙ путь от корня сервера до корня сайта. Базовый путь для ресурса
    $conf{document_root} =  $r->document_root || '';
    # АБСОЛЮТНЫЙ путь от корня сервера до корня modperl. Базовый путь для modperl (от него отталкиваемся !!)
    $conf{modperl_root} = $r->dir_config('ModperlRoot') || $conf{document_root};

    # Список заблокированных ключей
    my @locked_keys = keys %conf;
    
    # Не производим действий в случае если инициализация вызывается не первый раз!
    # То что получилось закидываем в глобавльный объект
    if ($i > 0) {
        my %tconf = %{$m->get('conf')};
        foreach (keys %conf) { $tconf{$_} = $conf{$_} }
        $m->set(conf=>{%tconf});
        return 1
    }

    ##########################################################################
    # !!! Параметры, устанавливаемые только 1 раз на жизнь всех процессов !!!
    ##########################################################################
    my $modperl_root = $conf{modperl_root}; # Этот путь для всех умолчаний !!
    
    # Формируем имя конфигурационного файла. Например, foo.conf 
    $conf{fileconf} = $r->dir_config('FileConf') || catfile($modperl_root,$conf{prefix}.".conf");
    $conf{configloadstatus} = 0; # See _loadconfig
    
    #
    # Относительные пути к директориям (относительно document_root)
    #
    $conf{dir_conf}  = "conf";  # Директория к файлам конфигурации
    $conf{dir_logs}  = "log";   # Директория к логам относительно document_root
    $conf{dir_cache} = "cache"; # Директория к файлам кэша
    $conf{dir_db}    = "db";    # Директория к файловым данным
    $conf{dir_shtml} = "shtml"; # Директория к файлам шаблонов и файлов ssi
    
    #
    # Абсолютные пути к директориям относительно корня сервера (НЕ РЕДАКТИРУЕМЫЕ)
    #
    my $logdir = syslogdir();
    unless (-e $logdir) {
        $logdir = catdir($modperl_root, $conf{dir_logs});
        preparedir($logdir) unless -e $logdir;
    }
    $conf{logdir} = $logdir;
    $conf{confdir} = $r->dir_config('ConfDir') || catdir($modperl_root,$conf{dir_conf});

    #
    # Имена фалов (НЕ РЕДАКТИРУЕМЫЕ)
    #

    # Префиксные имена файлов
    my $fprefix = ($conf{prefix} ? ('mpminus-'.$conf{prefix}.'_') : 'mpminus-'); # Префикс имён
    $conf{file_error}   = $fprefix."error.log";   # Имя файла ошибок (log)
    $conf{file_debug}   = $fprefix."debug.log";   # Имя файла отладки (log)
    $conf{file_connect} = $fprefix."connect.log"; # Имя файла соединений с БД (log)
    $conf{file_mail}    = $fprefix."mail.log";    # Имя файла писем (log)
    $conf{file_mpminfo} = "mpminfo.shtml";        # Имя файла шаблона mpminfo (shtml)
    
    # Абсолютные пути (НЕ РЕДАКТИРУЕМЫЕ)
    $conf{errorlog} = catfile($logdir,$conf{file_error});
    $conf{debuglog} = catfile($logdir,$conf{file_debug});

    # Базовые URL
    my $urlsfx = '';
    my $urlpfx = 'http://';
    $urlsfx = ':'.$conf{server_port} if (1 
        and $conf{server_port} != 80
        and $conf{server_port} != 443
        and $conf{http_host}
        and $conf{http_host} !~ /\:\d+$/
       );
    $urlpfx = 'https://' if $conf{server_port} == 443;
    $conf{url}        = $urlpfx.$conf{http_host}.$urlsfx;
    $conf{urls}       = "https://".$conf{http_host}.$urlsfx;
    $conf{url_shtml}  = $conf{url}.'/'.$conf{dir_shtml};
    $conf{urls_shtml} = $conf{urls}.'/'.$conf{dir_shtml};

    #
    # Флаги (директивы с преффиксом и суффиксом _ )
    #
    $conf{_debug_}         = $r->dir_config('_debug_') || 0; # Флаг отладки
    $conf{_errorsendmail_} = $r->dir_config('_errorsendmail_') || 0; # Флаг отправки сообщения по почте при ошибках
    $conf{_sendmail_}      = $r->dir_config('_sendmail_') || 0; # Флаг отправки сообщения (для всех)
    $conf{_syslog_}        = $r->dir_config('_syslog_') || 0; # Флаг использования Apache для отработки функций log и debug
    push @locked_keys, qw/_debug_ _errorsendmail_ _sendmail_/; # блокируем!

    push @locked_keys, grep {/dir|file|log|url/} keys(%conf); # блокируем!
    push @locked_keys, qw/configloadstatus locked_keys/;
    $conf{locked_keys} = [sort(@locked_keys)];
    
    #
    # SMTP (почта)
    #
    $conf{smtp_host} = $r->dir_config('smtp_host') || '';
    $conf{smtp_user} = $r->dir_config('smtp_user') || '';
    $conf{smtp_password} = $r->dir_config('smtp_password') || '';

    #
    # База данных (любая)
    #
    for (qw/
            db_driver db_dsn db_host db_name db_port db_user db_password 
            db_timeout_connect db_timeout_request
           /
        ) {
            $conf{$_} = defined $r->dir_config($_) ? $r->dir_config($_) : '';
    }
    
    #
    # База данных MySQL
    #
    for (qw/ db_mysql_host db_mysql_name db_mysql_user db_mysql_password /) {
        $conf{$_} = defined $r->dir_config($_) ? $r->dir_config($_) : '';
    }

    #
    # База данных Oracle
    #
    for (qw/ db_oracle_host db_oracle_name db_oracle_user db_oracle_password /) {
        $conf{$_} = defined $r->dir_config($_) ? $r->dir_config($_) : '';
    }

    #
    # стандарты вывода и прочие параметры
    #
    $conf{content_type} = $r->dir_config('content_type') || ''; # Дефолтный Content-type

    # То что получилось закидываем в глобавльный объект, предварительно дозагрузив данные из внешеней конфигурации
    _loadconfig(\%conf, @locked_keys); # Чтение файла конфигурации
    $m->set(conf=>{%conf});
    return 1;
}
sub conf {
    # Прочитать указанный параметр конфигурации
    my $self = shift;
    my $key  = shift;
    return undef unless $self->{conf};
    return $self->{conf}->{$key};
}
sub get_conf { goto &conf };
sub config { goto &conf };
sub get_config { goto &conf };
sub set_conf {
    # Установить указанный параметр конфигурации
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    $self->{conf} = {} unless $self->{conf};
    $self->{conf}->{$key} = $val;
}
sub set_config { goto &set_conf };
sub _loadconfig {
    my $lconf = shift;
    my @lkeys = @_;
    return 0 unless $lconf && ref($lconf) eq 'HASH';
    return 0 unless $lconf->{fileconf} && -e $lconf->{fileconf};
    
    # Пытаемся прочитать конфигурационные данные
    my $cfg;
    try {
        $cfg = new Config::General( 
            -ConfigFile         => $lconf->{fileconf}, 
            -ConfigPath         => [$lconf->{modperl_root}, $lconf->{confdir}],
            -ApacheCompatible   => 1,
            -LowerCaseNames     => 1,
            -AutoTrue           => 1,
        );
    } catch {
        carp($_);
    };
    
    my %newconfig = $cfg->getall if $cfg && $cfg->can('getall');
    $lconf->{configfiles} = [];
    $lconf->{configfiles} = [$cfg->files] if $cfg && $cfg->can('files');
    
    # Записываем только разрешенные ключики
    foreach my $k (keys(%newconfig)) {
        $lconf->{$k} = $newconfig{$k} if 1 == 1
            && $k
            && !(grep {$_ eq $k} @lkeys) 
    }
    
    $lconf->{configloadstatus} = 1 if %newconfig;
    return 1;
}

1;

