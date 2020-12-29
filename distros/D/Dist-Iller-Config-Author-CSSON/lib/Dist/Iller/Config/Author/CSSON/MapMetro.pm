use 5.14.0;
use strict;
use warnings;

package Dist::Iller::Config::Author::CSSON::MapMetro;

# ABSTRACT: Dist::Iller config for Map::Metro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0328';

use Moose;
extends 'Dist::Iller::Config::Author::CSSON';
use Types::Path::Tiny qw/Path/;
use Types::Standard qw/Str/;
use namespace::autoclean;

has '+filepath' => (
    default => 'author-csson-mapmetro.yaml',
);
has '+main_module' => (
    default => 'Dist::Iller::Config::Author::CSSON',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Config::Author::CSSON::MapMetro - Dist::Iller config for Map::Metro

=head1 VERSION

Version 0.0328, released 2020-12-28.



=head1 SYNOPSIS

    # in iller.yaml
    +config: Author::CSSON::MapMetro

=head1 DESCRIPTION

Dist::Iller::Config::Author::Csson::MapMetro is a L<Dist::Iller> configuration. The plugin list is in C<share/author-csson-mapmetro.yaml>.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller-Config-Author-CSSON>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller-Config-Author-CSSON>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
