package Exobrain::Measurement::Geo::POI;

use 5.010;
use Moose;

# ABSTRACT: Geo Point Of Interest class
our $VERSION = '1.08'; # VERSION

with 'Exobrain::JSONify';

# Practically a stub class for now.

has id     => (is => 'ro', isa => 'Str', required => 1);
has name   => (is => 'ro', isa => 'Str', required => 1);
has lat    => (is => 'ro', isa => 'Num', required => 0);
has long   => (is => 'ro', isa => 'Num', required => 0);

# Source is (for example) Foursquare, Facebook, etc
# This may be filled by our containing class
has source => (is => 'rw', isa => 'Str', required => 0);

no Moose;

1;

__END__

=pod

=head1 NAME

Exobrain::Measurement::Geo::POI - Geo Point Of Interest class

=head1 VERSION

version 1.08

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
