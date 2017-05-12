use 5.10.0;
use strict;
use warnings;

package Map::Metro::Cmd::Route;

# ABSTRACT: Search in a map
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use MooseX::App::Command;
extends 'Map::Metro::Cmd';
use Types::Standard qw/Str/;
use Try::Tiny;
use Safe::Isa qw/$_call_if_object/;

parameter cityname => (
    is => 'rw',
    isa => Str,
    documentation => 'The name of the city you want to search in',
    required => 1,
);
parameter origin => (
    is => 'rw',
    isa => Str,
    documentation => 'Start station',
    required => 1,
);
parameter destination => (
    is => 'rw',
    isa => Str,
    documentation => 'Final station',
    required => 1,
);

command_short_description 'Search in a map';

sub run {
    my $self = shift;

    my %hooks = (hooks => ['PrettyPrinter']);
    my $graph = $self->cityname !~ m{\.} ? Map::Metro->new($self->cityname, %hooks)->parse : Map::Metro::Shim->new($self->cityname, %hooks)->parse;

    try {
        $graph->routing_for($self->origin,  $self->destination);
    }
    catch {
        my $error = $_;
        say sprintf q{Try search by station id. Run '%s stations %s' to see station ids.}, $0, $self->cityname;
        die($_->$_call_if_object('desc') || $_);
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Cmd::Route - Search in a map

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
