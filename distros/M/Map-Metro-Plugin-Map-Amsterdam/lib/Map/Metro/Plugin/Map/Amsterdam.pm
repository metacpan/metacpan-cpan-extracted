use 5.14.0;

package Map::Metro::Plugin::Map::Amsterdam;

# ABSTRACT: Map::Metro map for Amsterdam
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1103';

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-amsterdam.metro',
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

Map::Metro::Plugin::Map::Amsterdam - Map::Metro map for Amsterdam



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.16+-blue.svg" alt="Requires Perl 5.16+" />
<a href="https://travis-ci.org/Csson/p5-Map-Metro-Amsterdam"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Amsterdam.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Map-Metro-Plugin-Map-Amsterdam-0.1103"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Map-Metro-Plugin-Map-Amsterdam/0.1103" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Map-Metro-Plugin-Map-Amsterdam%200.1103"><img src="http://badgedepot.code301.com/badge/cpantesters/Map-Metro-Plugin-Map-Amsterdam/0.1103" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-69.2%-red.svg" alt="coverage 69.2%" />
</p>

=end html

=head1 VERSION

Version 0.1103, released 2019-11-30.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Amsterdam')->parse;

Or:

    $ map-metro.pl route Amsterdam Isolatorweg Gein

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

This map L<contains|Map::Metro::Plugin::Map::Amsterdam::Lines>:

=over 4

=item *

Lines 50, 51, 53 and 54 [L<wikipedia|https://en.wikipedia.org/wiki/Amsterdam_metro>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Amsterdam/master/static/images/amsterdam.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Amsterdam/master/static/images/amsterdam.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Amsterdam>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Amsterdam>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
