use 5.14.0;

package Map::Metro::Plugin::Map::Barcelona;

# ABSTRACT: Map::Metro map for Barcelona
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1008';

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-barcelona.metro',
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

Map::Metro::Plugin::Map::Barcelona - Map::Metro map for Barcelona



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.16+-blue.svg" alt="Requires Perl 5.16+" />
<a href="https://travis-ci.org/Csson/p5-Map-Metro-Barcelona"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Barcelona.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Map-Metro-Plugin-Map-Barcelona-0.1008"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Map-Metro-Plugin-Map-Barcelona/0.1008" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Map-Metro-Plugin-Map-Barcelona%200.1008"><img src="http://badgedepot.code301.com/badge/cpantesters/Map-Metro-Plugin-Map-Barcelona/0.1008" alt="CPAN Testers result" /></a>
</p>

=end html

=head1 VERSION

Version 0.1008, released 2019-03-31.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Barcelona')->parse;

Or:

    $ map-metro.pl route Barcelona Paral·lel Tibidabo
    $ map-metro.pl route Barcelona Parallel Tibidabo

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 STATUS

This map L<contains|Map::Metro::Plugin::Map::Barcelona::Lines>:

=over 4

=item *

The eleven L-lines (L1 to L11) [L<wikipedia|https://en.wikipedia.org/wiki/Barcelona_Metro>]

=item *

The I<Tramvia Blau> [L<wikipedia|https://en.wikipedia.org/wiki/Tramvia_Blau>]

=item *

I<Funicular del Tibidabo> [L<wikipedia|https://en.wikipedia.org/wiki/Funicular_del_Tibidabo>]

=item *

I<Funicular de Montjuïc> [L<wikipedia|https://en.wikipedia.org/wiki/Funicular_de_Montju%C3%AFc>]

=back

=head2 Notes

* L9 and L10 ends at La Sagrera.

* I<Tramvia Blau> only includes the two end-points.

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Barcelona/master/static/images/barcelona.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Barcelona/master/static/images/barcelona.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Barcelona>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Barcelona>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
