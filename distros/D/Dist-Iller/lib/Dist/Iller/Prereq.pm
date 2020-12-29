use 5.10.0;
use strict;
use warnings;

package Dist::Iller::Prereq;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Handle a prerequisite
our $VERSION = '0.1409';

use Dist::Iller::Elk;
use Types::Standard qw/Str Enum/;

has module => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has phase => (
    is => 'ro',
    isa => Enum[qw/build configure develop runtime test/],
    required => 1,
);
has relation => (
    is => 'ro',
    isa => Enum[qw/requires recommends suggests conflicts/],
    required => 1,
);
has version => (
    is => 'rw',
    isa => Str,
    default => '0',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Prereq - Handle a prerequisite

=head1 VERSION

Version 0.1409, released 2020-12-27.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
