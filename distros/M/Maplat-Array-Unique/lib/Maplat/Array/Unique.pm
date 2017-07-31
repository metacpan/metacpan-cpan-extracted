package Maplat::Array::Unique;

use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
our $VERSION = 2.7; # Based on Maplat version this was tested against
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(unique);

sub unique {
    my ($dataset) = @_;

    if(!defined($dataset)) {
        croak('array reference is not defined in unique()');
    }

    if(ref($dataset) ne 'ARRAY') {
        croak('dataset is not an array reference in unique()');
    }

    my %temp;

    foreach my $key (@{$dataset}) {
        $temp{$key} = 1;
    }
    @{$dataset} = sort keys %temp;
}

1;
__END__
=head1 NAME

Maplat::Array::Unique - make all Array elements unique

=head1 SYNOPSIS

  use Maplat::Array::Unique;

  my @myarray = qw[one two one three];

  unique(\@myarray);

  # @myarray now equals qw[one three two]

=head1 DESCRIPTION

Maplat::Array::Unique is a simple replacement function to make all array elements unique.

Warnings: This re-sorts array elements (changes order and therefore element index of all elements);

This module is designed for convenience and readable code rather than for
speed.

=head1 FUNCTIONS

This module currently exports its only function by default:

=head2 unique()

C<unique()> takes one array reference and replaces the array with one
that only holds all unique values.

=head1 SEE ALSO

L<List::Util>

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
