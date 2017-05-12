use 5.14.0;

package Map::Metro::Plugin::Map::Oslo;

our $VERSION = '0.1104'; # VERSION
# ABSTRACT: Map::Metro map for Oslo

use Moose;

with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-oslo.metro',
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

Map::Metro::Plugin::Map::Oslo - Map::Metro map for Oslo



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.16+-brightgreen.svg" alt="Requires Perl 5.16+" /> <a href="https://travis-ci.org/Csson/p5-Map-Metro-Oslo"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Oslo.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-69.2%-red.svg" alt="coverage 69.2%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.16+](https://img.shields.io/badge/perl-5.16+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Map-Metro-Oslo.svg?branch=master)](https://travis-ci.org/Csson/p5-Map-Metro-Oslo) ![coverage 69.2%](https://img.shields.io/badge/coverage-69.2%-red.svg)

=end markdown

=head1 VERSION

Version 0.1104, released 2016-01-24.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Oslo')->parse;

Or:

	$ map-metro.pl route Oslo Veitvet Holmenkollen

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

This map L<contains|Map::Metro::Plugin::Map::Oslo::Lines>:

=over 4

=item *

All six metro lines [L<wikipedia|https://en.wikipedia.org/wiki/Oslo_metro>]

=back

=head2 Note

Line 1 terminates at Helsfyr.

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Oslo/master/static/images/oslo.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Oslo/master/static/images/oslo.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Oslo>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Oslo>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
