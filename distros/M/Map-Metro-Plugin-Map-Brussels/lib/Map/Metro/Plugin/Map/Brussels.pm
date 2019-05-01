use 5.14.0;
use strict;
use warnings;

package Map::Metro::Plugin::Map::Brussels;

# ABSTRACT: Map::Metro map for Brussels
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1002';

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-brussels.metro',
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

=encoding UTF-8

=head1 NAME

Map::Metro::Plugin::Map::Brussels - Map::Metro map for Brussels



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.16+-blue.svg" alt="Requires Perl 5.16+" />
<a href="https://travis-ci.org/Csson/p5-Map-Metro-Brussels"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Brussels.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Map-Metro-Plugin-Map-Brussels-0.1002"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Map-Metro-Plugin-Map-Brussels/0.1002" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Map-Metro-Plugin-Map-Brussels%200.1002"><img src="http://badgedepot.code301.com/badge/cpantesters/Map-Metro-Plugin-Map-Brussels/0.1002" alt="CPAN Testers result" /></a>
</p>

=end html

=head1 VERSION

Version 0.1002, released 2019-04-30.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Brussels')->parse;

Or:

    map-metro.pl route Brussels "Gare de l'Ouest" 'Centraal Station'

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

This map L<contains|Map::Metro::Plugin::Map::Brussels::Lines>:

=over 4

=item *

The four metro lines I<L1>, I<L2>, I<L5> and I<L6> [L<wikipedia|https://en.wikipedia.org/wiki/Brussels_Metro>]

=item *

The I<T3> tram line, but only between I<Gare du Nord/Noordstation> and I<Albert> [L<wikipedia|https://en.wikipedia.org/wiki/Brussels_tram_route_3>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Brussels/master/static/images/brussels.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Brussels/master/static/images/brussels.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Brussels>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Brussels>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
