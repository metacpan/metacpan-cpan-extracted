use 5.16.0;

package Map::Metro::Plugin::Map::Athens;

our $VERSION = '0.1102'; # VERSION
# ABSTRACT: Map::Metro map for Athens

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-athens.metro',
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

Map::Metro::Plugin::Map::Athens - Map::Metro map for Athens



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.16+-brightgreen.svg" alt="Requires Perl 5.16+" /> <a href="https://travis-ci.org/Csson/p5-Map-Metro-Athens"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Athens.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-69.2%-red.svg" alt="coverage 69.2%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.16+](https://img.shields.io/badge/perl-5.16+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Map-Metro-Athens.svg?branch=master)](https://travis-ci.org/Csson/p5-Map-Metro-Athens) ![coverage 69.2%](https://img.shields.io/badge/coverage-69.2%-red.svg)

=end markdown

=head1 VERSION

Version 0.1102, released 2016-01-27.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Athens')->parse;

Or:

    $ map-metro.pl route Athens Marousi Panormou

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

As of 2015-01-02 it contains the three Metro lines and the two Proastiakos lines. See L<wikipedia|https://en.wikipedia.org/wiki/Athens_metro>.

Notes:

* Larissa Station (Athens Railway Station) is considered to be the same station on both M2 and P1.

* The Irakleio station on P2 is called 'Irakleio P' to separate it from the Irakleio station on M1.

See L<Map::Metro::Plugin::Map::Athens::Lines>.

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Athens/master/static/images/athens.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Athens/master/static/images/athens.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Athens>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Athens>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
