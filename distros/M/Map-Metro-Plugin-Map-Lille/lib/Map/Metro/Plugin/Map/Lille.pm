use 5.14.0;

package Map::Metro::Plugin::Map::Lille;

our $VERSION = '0.1002'; # VERSION
# ABSTRACT: Map::Metro map for Lille

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-lille.metro',
);
sub map_version {
    return $VERSION;
}
sub map_package {
    return __PACKAGE__;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Map::Metro::Plugin::Map::Lille - Map::Metro map for Lille



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.16+-brightgreen.svg" alt="Requires Perl 5.16+" /> <a href="https://travis-ci.org/Csson/p5-Map-Metro-Lille"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Lille.svg?branch=master" alt="Travis status" /></a></p>

=end HTML


=begin markdown

![Requires Perl 5.16+](https://img.shields.io/badge/perl-5.16+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Map-Metro-Lille.svg?branch=master)](https://travis-ci.org/Csson/p5-Map-Metro-Lille)

=end markdown

=head1 VERSION

Version 0.1002, released 2015-05-09.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Lille')->parse;

Or

	$ map-metro.pl route Lille "Gambetta" "Lille Grand Palais"

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

L<Map::Metro::Plugin::Map::Lille::Lines>

This map includes:

=over 4

=item *

The two metro lines [L<wikipedia|https://en.wikipedia.org/wiki/Lille_Metro>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Lille/master/static/images/lille.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Lille/master/static/images/lille.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Lille>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Lille>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
