package MPMinus::Store::DBI; # $Id$
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Store::DBI - Simple database interface based on CTK::DBI

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use MPMinus::Store::DBI;

    # MySQL connect
    my $mysql = new MPMinus::Store::DBI (
        -dsn        => 'DBI:mysql:database=TEST;host=192.168.1.1',
        -user       => 'login',
        -pass       => 'password',
        -connect_to => 5,
        -request_to => 60
        -attr       => {
                mysql_enable_utf8 => 1,
                RaiseError => 0,
                PrintError => 0,
            },
    ); # See CTK::DBI

    # MySQL connect (old style, without DSN)
    my $mysql = new MPMinus::Store::DBI (
        -m          => $m, # OPTIONAL
        -driver     => 'mysql', # Driver name. See DBI module
            # Available drivers:
            #  CSV, DBM, ExampleP, File, Gofer, ODBC, Oracle,
            #  Pg, Proxy, SQLite, Sponge, mysql
        -host       => '192.168.1.1',
        -port       => '3306', # default
        -database   => 'TEST',
        -user       => 'login',
        -pass       => 'password',
        -attr       => {
                mysql_enable_utf8 => 1,
                RaiseError => 0,
                PrintError => 0,
            },
    );

    my $dbh = $mysql->connect;

    my $pingstat = $mysql->ping if $mysql;

    $mysql->reconnect() unless $pingstat;

    # Table select (as array)
    my @result = $mysql->table($sql, @inargs);

    # Table select (as hash)
    my %result = $mysql->tableh($key, $sql, @inargs); # $key - primary index field name

    # Record (as array)
    my @result = $mysql->record($sql, @inargs);

    # Record (as hash)
    my %result = $mysql->recordh($sql, @inargs);

    # Fiels (as scalar)
    my $result = $mysql->field($sql, @inargs);

    # SQL/PL-SQL
    my $sth = $mysql->execute($sql, @inargs);
    ...
    $sth->finish;

=head1 DESCRIPTION

Simple database interface based on CTK::DBI

=head2 DEBUG

You can set $MPMinus::Store::DBI::DEBUG_FORCE = 1 to enable forced debugging

=head1 METHODS

=over 8

=item B<new>

    my $mysql = new MPMinus::Store::DBI (
        -m          => $m, # OPTIONAL
        -driver     => 'mysql', # Driver name. See DBI module
            # Available drivers:
            #  CSV, DBM, ExampleP, File, Gofer, ODBC, Oracle,
            #  Pg, Proxy, SQLite, Sponge, mysql
        -host       => '192.168.1.1',
        -port       => '3306', # default
        -database   => 'TEST',
        -user       => 'login',
        -pass       => 'password',
        -attr       => {
                mysql_enable_utf8 => 1,
                RaiseError => 0,
                PrintError => 0,
            },
    );

Returns MPMinus::Store::DBI object. See also L<CTK::DBI>

=item B<ping>

    my $status = $mysql->ping();

Returns connection's life status

=item B<reconnect>

    $mysql->reconnect unless $mysql->ping();

=item B<err, errstr, state>

    my $err = $mysql->err;
    my $errstr = $mysql->errstr;
    my $state = $mysql->state;

Methods returns DBI values: err, errstr and state.

See L<DBI/"METHODS_COMMON_TO_ALL_HANDLES">

=back

=head1 EXAMPLES

=over 8

=item B<Handler example>

    package MPM::Foo::Handlers;
    use strict;

    use MPMinus::Store::DBI;

    sub handler {
        my $r = shift;
        my $m = MPMinus->m;

        ...

        # MySQL connect
        $m->set_node(
            mysql => new MPMinus::Store::DBI (
                -dsn    => 'DBI:mysql:database=NAME;host=HOST',
                -user   => 'USER',
                -pass   => 'PASSWORD',
                -attr   => {
                    mysql_enable_utf8 => 1,
                    RaiseError => 0,
                    PrintError => 0,
                    HandleError => sub { $m->log_error(shift || '') },
                },
            )
        ) unless $m->mysql;

        ...

    }

    package MPM::Foo::Test;
    use strict;

    sub response {
        my $m = shift;

        my @data = $m->mysql->table('select * from table');

        ...

        return Apache2::Const::OK;
    }

=item B<Handler example with reconnection>

    package MPM::Foo::Handlers;
    use strict;

    use MPMinus::Store::DBI;

    sub handler {
        my $r = shift;
        my $m = MPMinus->m;

        ...

        # MySQL connect/reconnect
        if ($m->mysql) {
            $m->mysql->reconnect unless $m->mysql->ping;
        } else {
            # eval 'sub CTK::DBI::_error {1}'; # For supressing CTK::DBI errors
            $m->set_node(
                mysql => new MPMinus::Store::DBI (
                    -dsn    => 'DBI:mysql:database=NAME;host=HOST',
                    -user   => 'USER',
                    -pass   => 'PASSWORD',
                    -attr   => {
                        mysql_enable_utf8 => 1,
                        RaiseError => 0,
                        PrintError => 0,
                        HandleError => sub { $m->log_error(shift || '') },
                    },
                )
            );
        }

        ...

    }

    package MPM::Foo::Test;
    use strict;

    sub response {
        my $m = shift;

        my @data = $m->mysql->table('select * from table');

        ...

        return Apache2::Const::OK;
    }

=item B<Simple example>

    use MPMinus::Store::DBI;

    $MPMinus::Store::DBI::DEBUG_FORCE = 1;
    my $dbi = new MPMinus::Store::DBI (
            -driver   => 'mysql',
            -name     => 'mylocaldb',
            -user     => 'user',
            -password => 'password'
      );
    ...
    my @table = $dbi->table("select * from tablename where date = ?", "01.01.2000");

=item B<Sponge example>

    use MPMinus::Store::DBI;
    use Data::Dumper;

    $MPMinus::Store::DBI::DEBUG_FORCE = 1;
    my $o = new MPMinus::Store::DBI(
        -driver => 'Sponge',
        -attr   => { RaiseError => 1 },
    );
    my $dbh = $o->connect();
    my $sth = $dbh->prepare("select * from table", {
        rows => [
            [qw/foo bar baz/],
            [qw/qux quux corge/],
            [qw/grault garply waldo/],
        ],
        NAME => [qw/h1 h2 h3/],
    });

    $sth->execute();
    my $result = $sth->fetchall_arrayref;
    $sth->finish;
    print Dumper($result);

=back

=head1 HISTORY

=over 8

=item B<1.00 / Mon Apr 29 11:04:52 2013 MSK>

Init version

=back

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>, L<DBI>, L<CTK::DBI>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<DBI>, L<CTK::DBI>, L<Apache::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION $DEBUG_FORCE);
$VERSION = 1.01;

use constant {
        ATTR_NAMES => [
            ['M', 'GLOBAL', 'GLOB', 'MPMINUS', 'MPM'],                                                  # 0
            ['DSN','STRING','STR'],                                                                     # 1
            ['HOST','HOSTNAME','SERVER','SERVERNAME','ADDRESS','ADDR','SERVERADDR'],                    # 2
            ['DB','BD','DBNAME','DATABASE','NAME','DATABASENAME'],                                      # 3
            ['PORT',],                                                                                  # 4
            ['USER','USERNAME','LOGIN'],                                                                # 5
            ['PASSWORD','PASS'],                                                                        # 6
            ['DRIVER','DRIVERNAME'],                                                                    # 7
            ['TIMEOUT_CONNECT','CONNECT_TIMEOUT','CNT_TIMEOUT','TIMEOUT_CNT','TO_CONNECT','CONNECT_TO'],# 8
            ['TIMEOUT_REQUEST','REQUEST_TIMEOUT','REQ_TIMEOUT','TIMEOUT_REQ','TO_REQUEST','REQUEST_TO'],# 9
            ['ATTRIBUTES','ATTR','ATTRHASH','PARAMS'],                                                  # 10
        ],
    };

use DBI;
use CTK::Util qw/ :API /;
use MPMinus::Log;

use base qw/CTK::DBI/;

sub new {
    my $class = shift;
    my @in = read_attributes(ATTR_NAMES,@_);

    my $m       = $in[0]; # Optional
    my $dsn     = $in[1] || '';
    my $host    = $in[2] || '';
    my $db      = $in[3] || '';
    my $port    = $in[4] || '';
    my $user    = $in[5] // '';
    my $pass    = $in[6] // '';
    my $driver  = $in[7] || '';
    my $toc     = $in[8] || 0;
    my $tor     = $in[9] || 0;
    my $attr    = $in[10] || undef;

    my $pkg = scalar(caller(0));
    my $logger = new MPMinus::Log( sprintf("[%s] ", $pkg) );

    unless ($dsn) {
        my @adrivers = DBI->available_drivers();
        if (grep {$driver eq $_} @adrivers) {
            if ($driver =~ /mysql/i) {
                $dsn = "DBI:mysql:database=$db".($host?";host=$host":'').($port?";port=$port":'');
            } elsif ($driver =~ /Oracle/i) {
                if ($host) {
                    $dsn = "DBI:Oracle:host=$host".($db?";service_name=$db":'').($port?";port=$port":'');
                } else {
                    $dsn = "DBI:Oracle:".($db?"$db":'').($port?";port=$port":'');
                }
            } else {
                # dbi:DriverName:database=database_name;host=hostname;port=port
                $dsn = "DBI:".$driver.":"
                    .($db?"database=$db":'')
                    .($host?";host=$host":'')
                    .($port?";port=$port":'');
            }
        } else {
            $logger->log_crit("Driver \"$driver\" not availebled. Available drivers: ",join(", ",@adrivers));
        }
    }
    my %args = (
            -dsn  => $dsn,
            -user => $user,
            -pass => $pass,
            -timeout_connect => $toc,
            -timeout_request => $tor,
            -attr => $attr,
        );

    if ($dsn) {
        my $obj = $class->SUPER::new(%args);
        $obj = bless({}, $class) unless $obj && ref($obj) eq __PACKAGE__;
        $obj->{m} = $m;
        $obj->{logger} = $logger;
        return $obj unless $obj->{dbh};
        $logger->log_debug(sprintf("--- CONNECT {%s} AS %s ---", $dsn, ref($obj))) if $DEBUG_FORCE;
        return $obj if $obj;
    } else {
        return bless({
                m       => $m,
                logger  => $logger,
            }, $class);
    }
    return undef;
}
sub ping {
    my $self = shift;
    return 0 unless $self && ref($self) eq __PACKAGE__;
    return 0 unless $self->{dsn};
    return 0 unless $self->{dbh};
    return 0 unless $self->{dbh}->can('ping');
    return $self->{dbh}->ping();
}
sub reconnect {
    my $self = shift;

    my $logger = $self->{logger};
    my $dsn = $self->{dsn};

    # See CTK::DBI::DBI_CONNECT
    $self->{dbh} = CTK::DBI::DBI_CONNECT(
            $dsn,
            $self->{user},
            $self->{password},
            $self->{attr},
            $self->{connect_to},
        );
    if ($self->{dbh}) {
        $logger->log_debug(sprintf("--- RECONNECT {%s} AS %s ---", $dsn, ref($self))) if $DEBUG_FORCE;
        return 1;
    }
    return undef;
}
sub err {
    my $self = shift;
    return $self->{dbh}->err if $self->{dbh} && $self->{dbh}->can('err');
    return defined $DBI::err ? $DBI::err : 0;
}
sub errstr {
    my $self = shift;
    return $self->{dbh}->errstr if $self->{dbh} && $self->{dbh}->can('errstr');
    return defined $DBI::errstr ? $DBI::errstr : '';
}
sub state {
    my $self = shift;
    return $self->{dbh}->state if $self->{dbh} && $self->{dbh}->can('state');
    return defined $DBI::state ? $DBI::state : '';
}
sub DESTROY {
    my $self = shift;
    my $dsn = '';
    $dsn = $self->{dsn} if $self->{dsn};
    my $logger = '';
    $logger = $self->{logger} if $self->{logger};
    if ($DEBUG_FORCE && $dsn && $self->{dbh}) {
        my $msg = sprintf("--- DISCONNECT (DESTROY) {%s} ---", $dsn);
        if($logger && ref($logger) eq 'MPMinus::Log') {
            $logger->log_debug($msg);
        } else {
            warn($msg."\n");
        }
    }
}

1;
