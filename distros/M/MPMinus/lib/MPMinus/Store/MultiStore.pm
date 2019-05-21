package MPMinus::Store::MultiStore; # $Id: MultiStore.pm 273 2019-05-08 10:44:56Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Store::MultiStore - Multistoring MPMinus::Store::DBI interface

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    use MPMinus::Store::MultiStore;

    # Multistoring
    my $mso = new MPMinus::Store::MultiStore (
            -mso => {
                foo => {
                    -dsn    => 'DBI:mysql:database=TEST;host=192.168.1.1',
                    -user   => 'login',
                    -pass   => 'password',
                    -attr   => {
                        mysql_enable_utf8 => 1,
                        RaiseError => 0,
                        PrintError => 0,
                    },
                },
                bar => {
                    -dsn    => 'DBI:Oracle:SID',
                    -user   => 'login',
                    -pass   => 'password',
                    -attr   => {
                        RaiseError => 0,
                        PrintError => 0,
                    },
                },
            },
        );

    my @stores = $mso->stores; # foo, bar

    $mso->set(baz => new MPMinus::Store::DBI( {
                -dsn    => 'DBI:Oracle:BAZSID',
                -user   => 'login',
                -pass   => 'password',
                -attr   => {
                    RaiseError => 0,
                    PrintError => 0,
                },
            })
        );

    my @stores = $mso->stores; # foo, bar, baz

    my $foo = $mso->get('foo');
    my $foo = $mso->store('foo');
    my $foo = $mso->foo;

=head1 DESCRIPTION

Multistoring MPMinus::Store::DBI interface

See L<MPMinus::Store::DBI>

=head2 new

    my $mso = new MPMinus::Store::MultiStore (
            -mso => { ... },
        );

Returns MultiStore object

See also L<MPMinus::Store::DBI>

=head1 METHODS

=over 8

=item B<get, store>

    my $foo = $mso->get('foo');
    my $foo = $mso->store('foo');
    my $foo = $mso->foo;

Getting specified connection by name

=item B<set>

    $mso->set(baz => new MPMinus::Store::DBI( {
                -dsn    => 'DBI:Oracle:BAZSID',
                -user   => 'login',
                -pass   => 'password',
                -attr   => {
                    RaiseError => 0,
                    PrintError => 0,
                },
            })
        );

Setting specified connection by name and returns state of operation

=item B<stores>

    my @stores = $mso->stores; # foo, bar, baz

Returns current connections as list (array)

=back

=head1 EXAMPLE

    package MPM::foo::Handlers;
    use strict;

    use MPMinus::Store::MultiStore;
    use MPMinus::MainTools qw/ msoconf2args /;

    sub InitHandler {
        my $pkg = shift;
        my $m = shift;

        # MSO Database Nodes
        if ($m->multistore) {
            my $mso = $m->multistore;
            foreach ($mso->stores) {
                $mso->get($_)->reconnect unless $mso->get($_)->ping;
            }
        } else {
            $m->set( multistore => new MPMinus::Store::MultiStore (
                -mso => { msoconf2args($m->conf('store')) },
                )
            );
        }

        return __PACKAGE__->SUPER::InitHandler($m);
    }

    ...

    package MPM::foo::Test;
    use strict;

    sub response {
        my $m = shift;

        my $mso = $m->multistore;

        my $data = $mso->foo->errstr
            ? $mso->foo->errstr
            : $mso->foo->field('select sysdate() from dual');

        ...

        return Apache2::Const::OK;
    }

In conf/mso.conf file:

    <store foo>
        dsn   DBI:mysql:database=TEST;host=192.168.1.1
        user  login
        pass  password
        <Attr>
            mysql_enable_utf8 1
            RaiseError        0
            PrintError        0
        </Attr>
    </store>
    <store bar>
        dsn   DBI:Oracle:FOOSID
        user  login
        pass  password
        connect_to    10
        request_to    50
        <Attr>
            RaiseError        0
            PrintError        0
        </Attr>
    </store>
    <store baz>
        dsn   DBI:Oracle:BARSID
        user  login
        pass  password
        <Attr>
            RaiseError        0
            PrintError        0
        </Attr>
    </store>

=head1 HISTORY

=over 8

=item B<1.00 13.11.2010>

Init version

=item B<1.01 22.12.2010>

Added method for getting list of stores

=item B<1.02 Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=back

See C<CHANGES> file

=head1 DEPENDENCIES

L<MPMinus::Store::DBI>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MPMinus::Store::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = 1.05;

use MPMinus::Store::DBI;
use CTK::Util qw/ :API /;
use MPMinus::Log;

sub new {
    my $class = shift;
    my @in = read_attributes([
            ['M', 'GLOBAL', 'GLOB', 'MPMINUS', 'MPM'],
            ['CONFIG','MSCONFIG','MSO','CONF','DATA','MULTISTORE','STORES'],
        ],@_);
    my $m = $in[0];
    my $s = $in[1] || {};
    unless ($s && ref($s) eq 'HASH') {
        $s = {};
        # For future -- loading data configuration
        # $s = ...
    }
    my @stores = keys %$s; # Get all stores
    my $pkg = scalar(caller(0));
    my $logger = new MPMinus::Log( sprintf("[%s] ", $pkg) );

    my $ret = {};
    foreach my $store (@stores) {
        my $sc = $s->{$store};
        if ($sc && ref($sc) eq 'HASH') {
            $sc->{"-m"} = $m if $m;
            $ret->{$store} = new MPMinus::Store::DBI(%$sc);
        } else {
            $ret->{$store} = undef;
        }
    }

    return bless {
            m => $m,
            s => {%$s},
            logger => $logger,
            stores => $ret,
        }, $class;
}
sub stores { # List of stores
    my $self = shift;
    my $stores = $self->{stores};
    return ($stores && ref($stores) eq 'HASH') ? keys(%$stores) : ();
}
sub get { # Get story by name
    my $self = shift;
    my $name = shift;
    if ($name && $self->{stores} && $self->{stores}->{$name}) {
        return $self->{stores}->{$name};
    } else {
        $self->{logger}->log_error("Can't find store \"$name\"");
    }
    return undef;
}
sub store { goto &get };
sub set {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    $self->{logger}->log_error("Key name undefined") && return undef
        unless $name;
    $self->{logger}->log_error("Value incorrect or is't MPMinus::Store::DBI object") && return undef
        unless $value && ref($value) eq 'MPMinus::Store::DBI';
    $self->{stores}->{$name} = $value;
}
sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $AL = $AUTOLOAD;
    my $ss = undef;
    $ss = $1 if $AL=~/\:\:([^\:]+)$/;
    if ($ss && $self->{stores} && $self->{stores}->{$ss}) {
        return $self->{stores}->{$ss};
    } else {
        $self->{logger}->log_error(sprintf("Can't find store \"%s\"", $ss // ""));
    }
    return undef;
}
sub DESTROY {
    my $self = shift;
    undef $self;
}

1;
