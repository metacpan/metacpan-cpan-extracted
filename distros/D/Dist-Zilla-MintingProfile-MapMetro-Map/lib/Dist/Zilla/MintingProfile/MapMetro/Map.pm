use 5.14.0;

package Dist::Zilla::MintingProfile::MapMetro::Map;

our $VERSION = '0.1500'; # VERSION
# ABSTRACT: Mint a Map::Metro Map distribution

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::MintingProfile::MapMetro::Map - Mint a Map::Metro Map distribution

=head1 VERSION

Version 0.1500, released 2015-02-01.

=head1 SYNOPSIS

  $ dzil new -P MapMetro::Map  Map::Metro::Plugin::Map::[Cityname]

=head1 DESCRIPTION

Dist::Zilla::MintingProfile::MapMetro::Map is the easiest way to create a map distribution for L<Map::Metro>.

=head1 SEE ALSO

L<Map::Metro>

L<Map::Metro::Plugin::Map>

L<Task::MapMetro::Dev>

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-MintingProfile-MapMetro-Map>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-MintingProfile-MapMetro-Map>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
