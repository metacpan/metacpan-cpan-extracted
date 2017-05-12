use 5.10.0;
use strict;
use warnings;

package Map::Metro::Cmd::Available;

# ABSTRACT: Display installed maps
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use MooseX::App::Command;
extends 'Map::Metro::Cmd';

command_short_description 'Display installed maps';

sub run {
    my $self = shift;

    my $map = Map::Metro->new;

    say "The following maps are available:\n";
    say join "\n" => map { s{^Map::Metro::Plugin::Map::}{ }; $_ } grep { !/::Lines$/ } grep { !/^Map::Metro::Plugin::Map$/ } $map->available_maps;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Cmd::Available - Display installed maps

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
