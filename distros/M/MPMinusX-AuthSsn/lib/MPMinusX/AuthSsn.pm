package MPMinusX::AuthSsn; # $Id: AuthSsn.pm 5 2019-05-28 10:59:30Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinusX::AuthSsn - MPMinus AAA via Apache::Session and DBD::SQLite

=head1 VERSION

Version 1.01

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
        #file   /document_root/session.db
        #dsn    dbi:SQLite:dbname=/document_root/session.db
    </Auth>

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<MPMinus>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MPMinus>, L<CTK>, L<Apache::Session>, L<DBD::SQLite>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut


use vars qw/ $VERSION /;
$VERSION = '1.01';

use Carp;
use Apache::Session::Flex;
use File::Spec;

use CTK::Util qw/ :API :FORMAT :DATE /;
use CTK::ConfGenUtil;
use CTK::DBI;

use constant {
        CONFKEY         => 'auth',
        SIDKEY          => 'usid',
        TPLKEY          => 'authorized',
        TPLPFX          => '',
        SESSION_DIR     => 'sessions',
        SESSION_FILE    => 'sessions.db',
        SESSION_DSN_MSK => 'dbi:SQLite:dbname=%s',
        SESSION_EXPIRES => '+1h', # 3600sec as default

        # Statuses translating map
        STAT => {
            DEFAULT             => "Status not defined",
            OK                  => "OK",
            UNAUTHORIZED        => "Unauthorized",
            ERROR               => "Session not exists or session creation error has occurred",
            SERVER_ERROR        => "Server error",
            NEW                 => "Created",
            TIMEOUT             => "The session has expired",
            LOGIN_INCORRECT     => "Login incorrect",
            PASSWORD_INCORRECT  => "Password incorrect",
            DECLINED            => "Account not found",
            AUTH_REQUIRED       => "Auth required",
            FORBIDDEN           => "Forbidden",
        },
    };

sub new {
    my $class   = shift;
    my $m       = shift;
    my $usid    = shift || undef; # USID User Session IDentifier
    my $expires = shift || undef;
    croak("The method call not in the MPMinus context") unless ref($m) =~ /MPMinus/;

    my $authconf    = hash($m->conf(CONFKEY));
    my $s_sidkey    = value($authconf, 'sidkey') || SIDKEY;
    my $s_tplkey    = value($authconf, 'tplkey') || TPLKEY;
    my $s_tplpfx    = value($authconf, 'tplpfx') || TPLPFX;
    my $s_dir       = value($authconf, 'dir') || File::Spec->catdir($m->conf('document_root'), SESSION_DIR);
    my $s_file      = value($authconf, 'file') || File::Spec->catfile($s_dir, SESSION_FILE);
    my $dsn         = value($authconf, 'dsn') || sprintf(SESSION_DSN_MSK, $s_file);
    my $s_expires   = value($authconf, 'expires') || SESSION_EXPIRES;
    $expires ||= $s_expires;

    # Create
    my $self = bless {
        session     => {},
        transtable  => STAT,
        status      => 0, # No tied
        reason      => "UNAUTHORIZED",
        dir         => $s_dir,
        file        => $s_file,
        expires     => $class->toexpire($expires),
        $s_sidkey   => undef,
        sidkey      => $s_sidkey,
        tplkey      => $s_tplkey,
        tplpfx      => $s_tplpfx,
        dsn         => $dsn,
        prepared    => 0,
    }, $class;

    # Initialize as "read mode"
    $self->init($usid, 0) if $usid;

    return $self;
}
sub init {
    my $self = shift;
    my $usid = shift || undef; # USID User Session IDentifier
    my $create = shift || 0; # 1 - create session; 0 - read session

    my %session;
    my $ssndata = $self->{session} && ref($self->{session}) eq 'HASH' ? $self->{session} : {};
    my $reason;

    # Paths
    my $dsn  = $self->{dsn};
    my $sfile = $self->{file};

    # Prepare database
    if ($sfile) { # My custom file
        $self->{prepared} = 1 if (-e $sfile) && (-s _); # file and file is not empty
    }

    unless ($self->{prepared}) {
        my $sqlc = new CTK::DBI(-dsn  => $dsn);
        $sqlc->execute('CREATE TABLE IF NOT EXISTS sessions ( id CHAR(32) NOT NULL PRIMARY KEY, a_session TEXT NOT NULL )');
        $sqlc->disconnect;
        $self->{prepared} = 1;
    }

    # Apache::Session options
    my $opts = {
        Store       => 'MySQL',
        Lock        => 'Null',
        Generate    => 'MD5',
        Serialize   => 'Base64',
        DataSource  => $dsn,
    };

    # Tie!
    my $retstat = $self->status;
    eval { tie %session, 'Apache::Session::Flex', $usid, $opts; };
    if ($@) {
        $reason = 'ERROR'; # Init error
    } else {
        if ($usid) {
            $reason = 'OK'; # Not init request
        } else {
            $reason = 'NEW'; # Init request
        }
        # USID
        $self->{$self->{sidkey}} = $session{_session_id};

        # Add data to created session
        if ($create) {
            $session{time_create} = time(); # Create time
            $session{time_access} = time(); # Access time
            $session{expires}     = $self->{expires}; # Time for current session
            $session{$_} = $ssndata->{$_} foreach (keys %$ssndata);
        }
        $self->{session} = \%session;
        $retstat = 1; # Ok
    }

    return $self->status($retstat, $reason);
}

sub authen { # AAA-authen
    #
    # Possible responses:
    #   LOGIN_INCORRECT / PASSWORD_INCORRECT / AUTH_REQUIRED / DECLINED / FORBIDDEN / OK
    #

    my $self = shift;
    my $callback = shift;

    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self, @_);
    }

    return $self->status(1, 'OK');
}
sub authz {  # AAA-authz
    #
    # Possible responses:
    #   FORBIDDEN / OK
    #

    my $self = shift;
    my $callback = shift;

    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self, @_);
    }

    # Авторизация прошла успешно. Можно создавать сессию
    return 0 unless $self->init(undef, 1);
    return 1;
}
sub access { # AAA-access
    my $self = shift;
    my $callback = shift;
    return $self->status(0, $self->reason) unless $self->status;

    # Проверка expires и обновление данных последнего доступа.
    my $expires = $self->expires;
    my $lastaccess = $self->get('time_access') || 0;
    my $newaccess = time();
    my $accessto = (($newaccess - $lastaccess) > $expires); # true - timeout
    if ($accessto) {
        $self->delete(); # Expired
        return $self->status(0, 'TIMEOUT');
    }

    # !!! callback here !!!
    if ($callback && ref($callback) eq 'CODE') {
        return 0 unless $callback->($self, @_);
    }

    # Ok
    $self->set('time_access', $newaccess);

    return $self->status(1, 'OK'); # Access granted
}

sub sid {
    my $self = shift;
    return $self->{$self->{sidkey}} || undef;
}
sub usid { goto &sid }
sub expires {
    my $self = shift;
    my $expires = $self->{session}->{expires} ? $self->{session}->{expires} : $self->{expires};
    return $expires || 0;
}
sub status {
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
    my $self = shift;
    return $self->{reason};
}
sub get {
    my $self = shift;
    my $key = shift || return;
    return $self->{session}->{$key} || undef;
}
sub set {
    my $self = shift;
    my $key = shift || return 0;
    my $value = shift;
    return $self->{session}->{$key} = $value;
}
sub delete {
    my $self = shift;
    tied(%{$self->{session}})->delete() if $self->{status};
    return $self->status(0, 'UNAUTHORIZED');
}
sub reason_translate {
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
