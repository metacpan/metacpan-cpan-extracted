use 5.10.0;
use strict;
use warnings;

package Map::Metro::Cmd::AllRoutes;

# ABSTRACT: Display routes for all pairs of stations
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use MooseX::App::Command;
use Types::Standard qw/Str/;
extends 'Map::Metro::Cmd';

parameter cityname => (
    is => 'rw',
    isa => Str,
    documentation => 'The name of the city',
    required => 1,
);

command_short_description 'Display routes for *all* pairs of stations (slow)';

sub run {
    my $self = shift;
    my %hooks = (hooks => ['PrettyPrinter']);
    my $graph = $self->cityname !~ m{\.} ? Map::Metro->new($self->cityname, %hooks)->parse : Map::Metro::Shim->new($self->cityname, %hooks)->parse;
    my $all = $graph->all_pairs;

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Cmd::AllRoutes - Display routes for all pairs of stations

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
