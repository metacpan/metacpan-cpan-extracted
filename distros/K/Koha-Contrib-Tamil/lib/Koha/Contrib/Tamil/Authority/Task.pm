package Koha::Contrib::Tamil::Authority::Task;
# ABSTRACT: Base class for managing authorities manipulations
$Koha::Contrib::Tamil::Authority::Task::VERSION = '0.055';
use Moose;

extends 'AnyEvent::Processor';

use 5.010;
use utf8;
use Carp;
use YAML qw( LoadFile );

has conf_authorities => ( is => 'rw', isa => 'ArrayRef' );

has conf_file => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my ($self, $file) = @_;
        unless ( -e $file ) {
            croak "File doesn't exist: " . $file;
        }
        my @authorities = LoadFile( $file ) or croak "Load conf auth impossible";
        $self->conf_authorities( \@authorities );
    }
);


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Authority::Task - Base class for managing authorities manipulations

=head1 VERSION

version 0.055

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
