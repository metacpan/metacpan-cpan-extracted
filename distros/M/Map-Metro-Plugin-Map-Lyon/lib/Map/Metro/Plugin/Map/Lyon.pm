use v5.14;

package Map::Metro::Plugin::Map::Lyon;

our $VERSION = '1.001'; # VERSION
# ABSTRACT: Map::Metro map for Lyon

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-lyon.metro',
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

Map::Metro::Plugin::Map::Lyon - Map::Metro map for Lyon

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Lyon')->parse;

Or

    $ map-metro.pl route Lyon 1 4

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

L<Map::Metro::Plugin::Map::Lyon::Lines>

This map includes the four metro lines from the
L<Lyon metro|https://en.wikipedia.org/wiki/Lyon_Metro>.

=over 4

=item *

L<Line A|https://en.wikipedia.org/wiki/Lyon_Metro_Line_A>

=item *

L<Line B|https://en.wikipedia.org/wiki/Lyon_Metro_Line_B>

=item *

L<Line C|https://en.wikipedia.org/wiki/Lyon_Metro_Line_C>

=item *

L<Line D|https://en.wikipedia.org/wiki/Lyon_Metro_Line_D>

=back

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Philippe Bruhat (BooK).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
