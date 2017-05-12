package Farly::Director;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Any qw($log);

our $VERSION = '0.26';

sub new {
    my $class = shift;

    my $self = {
        FILE    => undef,
        BUILDER => undef,
    };
    bless( $self, $class );

    
    $log->info("$self NEW ");
    return $self;
}

sub set_file {
    my ( $self, $file ) = @_;

    $file->isa('IO::File')
      or confess "an IO::File object is required";

    $self->{FILE} = $file;
    
    $log->info( "$self set FILE = " . $self->{FILE} );
}

sub file {
    return $_[0]->{FILE};
}

sub set_builder {
    my ( $self, $builder ) = @_;

    $builder->isa('Farly::Builder')
      or confess " A Farly::Builder object is required ";

    $self->{BUILDER} = $builder;

    
    $log->info( "$self set BUILDER = " . $self->{BUILDER} );
}

sub builder {
    return $_[0]->{BUILDER};
}

sub run {
    my ($self) = @_;

    $self->builder()->set_file( $self->file() );
    $self->builder()->run();
    return $self->builder()->result();
}

1;
__END__

=head1 NAME

Farly::Director - Manages Builder creation and configuration

=head1 DESCRIPTION

Farly::Director sets up the vendor specific Farly::Builder. It accepts a
firewall configuration IO::File object and returns an 
Farly::Object::List<Farly::Object> firewall device model when
finished.

Farly::Director is used by the Farly factory class only.

=head1 COPYRIGHT AND LICENCE

Farly::Director
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
