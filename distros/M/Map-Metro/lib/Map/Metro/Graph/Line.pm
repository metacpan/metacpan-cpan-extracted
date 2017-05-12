use 5.10.0;
use strict;
use warnings;

package Map::Metro::Graph::Line;

# ABSTRACT: Meta information about a line
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/Str Int/;
use Map::Metro::Exceptions;

has id => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has description => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has color => (
    is => 'rw',
    isa => Str,
    default => '#333333',
);
has width => (
    is => 'rw',
    isa => Int,
    default => 3,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if($args{'id'} =~ m{([^a-z0-9])}i)  {
        die lineid_contains_illegal_character line_id => $args{'id'}, illegal_character => $_;
    }
    $self->$orig(%args);
};

sub to_hash {
    my $self = shift;

    return {
        id => $self->id,
        name => $self->name,
        description => $self->description,
        color => $self->color,
        width => $self->width,
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Graph::Line - Meta information about a line

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 DESCRIPTION

Lines are currently only placeholders to identify the concept of a line. They don't have stations.

=head1 METHODS

=head2 id()

Returns the line id given in the parsed map file.

=head2 name()

Returns the line name given in the parsed map file.

=head2 description()

Returns the line description given in the parsed map file.

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
