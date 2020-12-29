use 5.10.0;
use strict;
use warnings;

package Dist::Zilla::MintingProfile::DistIller::Basic;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: A basic minting profile for Dist::Iller
our $VERSION = '0.1409';

use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::DistIller::Basic - A basic minting profile for Dist::Iller

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
