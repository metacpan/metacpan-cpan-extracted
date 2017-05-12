package MPMinus::Store::MultiStore; # $Id: MultiStore.pm 143 2013-05-21 09:13:44Z minus $
use strict;

=head1 NAME

MPMinus::Store::MultiStore - Multistoring

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

    use MPMinus::Store::MultiStore;

    # Multistoring
    my $mso = new MPMinus::Store::MultiStore (
            -m   => $m, # OPTIONAL
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

Multistoring Database independent interface for MPMinus on MPMinus::Store::DBI based.

See L<MPMinus::Store::DBI>

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
                -m   => $m,
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

=item B<1.00 / 13.11.2010>

Init version

=item B<1.01 / 22.12.2010>

Added method for getting list of stores

=item B<1.02 / Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=back

=head1 SEE ALSO

L<MPMinus::Store::DBI>, L<CTK::DBI>, L<Apache::DBI>, L<DBI>

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

use vars qw($VERSION);
$VERSION = 1.04;

use MPMinus::Store::DBI;
use CTK::Util qw/ :API /;

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
        # Тут читаем данные конфигурации (на перспективу)
        # $s = ...
    }
    my @stores = keys %$s; # Принимаем значения всех соединений
    
    # пробегаемся по всем соединениям и устанавливаем их в общий массив
    my $ret = {};
    foreach my $store (@stores) {
        my $sc = $s->{$store};
        if ($sc && ref($sc) eq 'HASH') {
            $sc->{-m} = $m if $m;
            $ret->{$store} = new MPMinus::Store::DBI(%$sc);
        } else {
            $ret->{$store} = undef;
        }
    }
    
    return bless {
            m => $m,
            s => {%$s},
            stores => $ret,
        }, $class;
}
sub stores {
    # Возврат списка коннектов
    my $self = shift;
    my $stores = $self->{stores};
    return ($stores && ref($stores) eq 'HASH') ? keys(%$stores) : ();
}
sub get {
    # Возврат конкретного соединения
    my $self = shift;
    my $name = shift;
    if ($name && $self->{stores} && $self->{stores}->{$name}) {
        return $self->{stores}->{$name};
    } else {
        carp("Can't find store \"$name\"");
    }
    return undef;
}
sub store { goto &get };
sub set {
    # Установка конкретного соединения
    my $self = shift;
    my $name = shift;
    my $value = shift;
    carp("Key name undefined") && return undef unless $name;
    carp("Value incorrect or is't MPMinus::Store::DBI object") && return undef unless $value && ref($value) eq 'MPMinus::Store::DBI';
    
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
        carp("Can't find store \"$ss\"");
    }
    return undef;
}
sub DESTROY {
    my $self = shift;
    undef $self;
}

1;
