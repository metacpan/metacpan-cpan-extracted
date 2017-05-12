package MPMinus; # $Id: MPMinus.pm 224 2017-04-04 10:27:41Z minus $
use strict;

=head1 NAME

MPMinus - mod_perl2 Web Application Framework

=head1 VERSION

Version 1.20

=head1 SYNOPSIS

    use MPMinus;

=head1 ABSTRACT

MPMinus - mod_perl2 Web Application Framework

=head1 DESCRIPTION

See C<README> file first and L<MPMinus::Manual>

=head1 METHODS

=over 8

=item B<conf, config, get_conf, get_config>

    my $project = $m->conf('project');

Getting configuration value by name

=item B<disp, dispatcher>

    my $disp = $m->disp;

Returns all Dispatcher records

=item B<drec, drecord, record>

    my $d = $m->drec;

Returns current Dispatcher record. See L<MPMinus::Dispatcher>

=item B<get, get_node>

    my $r = get('r');

Getting node by name

=item B<m, glob>

    # Used in the dependent packages
    my $m = MPMinus->m;

    # Used in the Apache handlers
    my $m = shift;    

Returns main MPMinus object

=item B<mysql, oracle, multistore>

    my $mysql = $m->mysql;
    my $oracle = $m->oracle;
    my $mso = $m->multistore;

Getting mysql (L<MPMinus::Store::MySQL>), oracle (L<MPMinus::Store::Oracle>) or multistore
(L<MPMinus::Store::MultiStore>) objects

=item B<namespace>

    my $namespace = $m->namespace;

Return current name space

=item B<r, req>

    my $r = $m->r;

Returns Apache2::RequestRec object. See L<Apache2::RequestRec>

=item B<set, set_node>

Setting node by name

For example (in handler of MPM::foo::Handlers module):

    # Set r as Apache2::RequestRec object
    $m->set( r => $r );
    
    # Set mysql as MPMinus::Store::MySQL object
    $m->set( mysql => new MPMinus::Store::MySQL(
            -m => $m,
            -attributes => {mysql_enable_utf8 => 1
        })
    ) unless $m->mysql;

    # Set disp as MPMinus::Dispatcher object
    $m->set(
        disp => new MPMinus::Dispatcher($m->conf('project'),$m->namespace)
    ) unless $m->disp;

    # Initialising dispatcher record
    my $record = $m->disp->get(-uri=>$m->conf('request_uri'));
    $m->set(drec => $record);

=item B<set_conf, set_config>

    $m->set_conf("LOCALHOST", $m->conf('http_host') =~ /localhost|workstation/ ? 1 : 0); 

Setting configuration value

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>, L<Apache2>, L<TemplateM>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>, L<CTK::Util>, L<TemplateM>

=head1 THANKS

Thanks to Dmitry Klimov for technical translating C<http://fla-master.com>.

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@serzik.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

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

use vars qw/ $VERSION $PATCH_20141100055 /;
$VERSION = "1.20";
$PATCH_20141100055 = 0;

use base qw/
        MPMinus::Configuration
        MPMinus::Transaction
        MPMinus::Util
        MPMinus::Debug::Info
    /;

use Apache2::ServerUtil;
use Apache2::Connection;
    
use Carp; # qw/carp croak cluck confess/
# carp    -- просто пишем
# croak   -- просто пишем и убиваем
# cluck   -- пишем но с подробностями
# confess -- пишем с подробностями и убиваем

our @ISA;

sub import {
    my $class = shift;
    my $callerp = caller(0);
    if ($callerp =~ /^(.+)\:\:Handlers$/) {
        my $pnamespace = $1;
        push @ISA, $pnamespace unless grep {$_ eq $pnamespace} @ISA; 
        $class->new($callerp);
    }
    
    # Patch: http://osdir.com/ml/modperl.perl.apache.org/2014-11/msg00055.html
    unless ($PATCH_20141100055) {
        my $sver = _get_server_version();
        if ($sver && ($sver >= 2.04) && !Apache2::Connection->can('remote_ip')) { # Apache 2.4.x or larger
            eval 'sub Apache2::Connection::remote_ip { return $_[0]->client_ip }';
        }
        $PATCH_20141100055 = 1;
    }
}
sub new {
    my $class = shift;
    my $caller = shift;
    
    # Получаем название пакета
    my $pnamespace = _search_pnamespace($caller || caller(0));
    no strict 'refs';
    
    my $self = bless {
        namespace     => $pnamespace,
    }, $class;
    
    # Присваиваем подструктуре новый объект
    ${"${pnamespace}::glob"} = $self;
    
    return ${"${pnamespace}::glob"};
}
sub m {
    # Возвращает указатель на объект
    my $self = shift;
    my $caller = shift || caller(0);
    my $pnamespace = _search_pnamespace($caller);
    no strict 'refs';
    return ${"$pnamespace\:\:glob"};
}
sub glob { goto &m };
sub r {
    # Получение объекта (ноды) запроса
    my $self = shift;
    return undef unless $self->{r};
    return $self->{r};
}
sub req { goto &r };
sub drec {
    # Получение строки записи диспетчера
    my $self = shift;
    return undef unless $self->{drec};
    return $self->{drec};
}
sub drecord { goto &drec };
sub record { goto &drec };
sub set_node {
    # Добавить ноду к глобальному массиву
    my $self = shift;
    my $node = shift;
    my $data = shift;
    $self->{$node} = $data;
}
sub set { goto &set_node };
sub get_node {
    # Прочитать ноду из глобального массива
    my $self = shift;
    my $node = shift;
    return $self->{$node};
}
sub get { goto &get_node };
sub mysql {
    # вернуть объект бд MySQL
    my $self = shift;
    return undef unless $self->{mysql};
    return $self->{mysql};
}
sub oracle {
    # вернуть объект бд Oracle
    my $self = shift;
    return undef unless $self->{oracle};
    return $self->{oracle};
}
sub multistore {
    # вернуть объект MultiStore
    my $self = shift;
    return undef unless $self->{multistore};
    return $self->{multistore};
}
sub disp {
    # вернуть объект диспетчера disp
    my $self = shift;
    return undef unless $self->{disp};
    return $self->{disp};
}
sub dispatcher { goto &disp };
sub namespace {
    my $self = shift;
    return $self->{namespace};
}
sub _search_pnamespace {
    my $clr = shift;
    my ($pn) = grep {$clr =~ /$_/ } @ISA;
    croak("Missing 'use MPMinus' in module $clr\:\:Handlers") unless $pn;
    return $pn;
}
sub _get_server_version {
    return 0 unless $ENV{MOD_PERL};
    my $sver = Apache2::ServerUtil::get_server_banner() || '';
    $sver =~ s/^.+?\///;
    if ($sver =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/) {
        return $1 + ($2/100) + ($3/10000);
    } elsif ($sver =~ /([0-9]+)\.([0-9]+)/) {
        return $1 + ($2/100);
    } elsif ($sver =~ /([0-9]+)/) {
        return $1;
    }
    return 0
}
sub AUTOLOAD {
    # Это своего рода интерфейс ко всем свойствам через объектную модель
    # если такого свойства не окажится, то значит ругаемся карпом !!
    my $self = shift;
    our $AUTOLOAD;
    my $AL = $AUTOLOAD;
    my $ss = undef;
    $ss = $1 if $AL=~/\:\:([^\:]+)$/;
    if ($ss && $self->{$ss}) {
        return $self->{$ss};
    } else {
        carp("Can't find MPMinus node \"$ss\"");
    }
    return undef;
}
sub DESTROY {
    my $self = shift;
    return 1 unless $self && ref($self);
    my $oo = $self->oracle;
    my $mo = $self->mysql;
    my $msoo = $self->multistore;
    undef $oo;
    undef $mo;
    undef $msoo;
    return 1;
}

1;
