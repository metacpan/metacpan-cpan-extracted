package MPMinus::Debug::System; # $Id: System.pm 173 2013-07-12 11:16:43Z minus $
use strict;

=head1 NAME

MPMinus::Debug::System - Debug functions

=head1 VERSION

Version 1.13

=head1 SYNOPSIS

    use MPMinus::Debug::System;

=head1 DESCRIPTION

Debug functions. See C<Kernel.pm> of yuor project

=head1 FUNCTIONS

=over 8

=item B<typeglobs_info>

    my %info = typeglobs_info( $namespace );

Returns list of defined typeglobs by $namespace

=item B<callstack_info>

    my %info = callstack_info();

Returns Call stack

=item B<isa_info>

    my %info = isa_info( $namespace );

Returns ISA contents by $namespace

=item B<env_info>

    my %info = env_info();

Returns %ENV contents

=item B<config_info>

    my %info = config_info( $m->get('conf') );

Returns configuration dump

=item B<metadata_info>

    my %info = metadata_info( catfile($m->conf('document_root'), 'META.yml') );

Returns data from META.yml file of project

=item B<controllers_info>

    my %info = controllers_info( $m->disp() );

Returns controllers information from dispatcher records

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

use vars qw($VERSION);
$VERSION = 1.13;

use base qw /Exporter/;
our @EXPORT = qw/
        typeglobs_info
        callstack_info
        isa_info
        env_info
        config_info
        metadata_info
        controllers_info
    /;

use Data::Dumper;
use YAML;
use Try::Tiny;

sub typeglobs_info {
    my $f = shift || 'main';
    no strict "refs";  
    my %outh;
      
    foreach (sort keys %{"$f\:\:"}) {
        my $k = $_;
        $k =~ s/</&lt;/;
        $k =~ s/>/&gt;/;
        my $v = ${"$f\:\:"}{$_};
        $v =~ s/</&lt;/;
        $v =~ s/>/&gt;/;
        $outh{$k} = $v if /^\w/;
    }
    
    return %outh
}
sub callstack_info {
    my %outh;
    my $j = 0;
    my @args;
    
    while (@args = caller($j++)) {
        $outh{'#'.$j} = join("\n",map {$_ = defined($_) ? $_ : ''} @args[0..3]);
    }

    return %outh
}
sub isa_info {
    my $package = shift || 'main';
    my %outh;
    my $j = 0;
    no strict 'refs';
    foreach (@{"$package\:\:ISA"}) {
        $outh{'#'.(++$j)} = $_;
    }
    return %outh;
}
sub env_info {
    my %outh;
    my $val;
    foreach my $var (sort(keys(%ENV))) {
        $val = $ENV{$var};
        $val =~ s|\n|\\n|g;
        $val =~ s|"|\\"|g;
        $outh{$var} = $val;
    }
    return %outh;
}
sub config_info {
    my $lconf = shift || return ();
    my %outh;
    
    my %conf = %{$lconf};
    foreach my $k (keys %conf) {
        my $v = $conf{$k};
        
        if (defined($v) && ref($v) eq "ARRAY") {
            $outh{$k} = "[ " . (join ", ", @{$v}) . " ]";
        } else {
            $outh{$k} = defined($v) ? $v : '';
        }
    }
    return %outh;
}
sub metadata_info {
    my $metaf = shift || '';
    my $meta = {Error => ""};
    if (-e $metaf) {
        try { $meta = YAML::LoadFile($metaf) } catch {$meta->{Error} = $_};
        unless ($meta->{Error}) {
            $meta = {Error => "Can't load file \"$metaf\""} unless $meta->{x_mpminus};
        }
    } else {
        $meta = {Error => "File \"$metaf\" not exists"};
    }
    return %$meta;
}
sub controllers_info {
    my $dispo = shift;
    my $records = $dispo->{records};
    my %ret;
    foreach my $k (grep {$_ ne 'default'} keys %$records) {
        my $rec = $dispo->get($k);
        my $ctp = $rec->{type};
        if ($ctp eq 'location') {
            if ($k eq '/') {
                $ret{'location:root'} = $k;
            } else {
                $ret{'location:'.$k} = $k;
            }
        } else {
            my $params = $rec->{params};
            my $paramsv = $params->{$ctp} ? $params->{$ctp} : 'undefined';
            my $v = $paramsv && ref($paramsv) eq 'ARRAY' ? $paramsv->[0] : $paramsv;
            $ret{lc($ctp.':'.$k)} = ref($v) ? "/$k" : $v;
        }
    }
    return %ret;
}
1;
