use 5.10.0;
use strict;
use warnings;

package Map::Metro::Shim;

# ABSTRACT: Easily load a map file
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/ArrayRef/;
use Types::Path::Tiny qw/AbsFile/;
use Map::Metro::Graph;

has filepath => (
    is => 'rw',
    isa => AbsFile,
    required => 1,
    coerce => 1,
);
has hooks => (
    is => 'ro',
    isa => ArrayRef,
    traits => ['Array'],
    default => sub { [] },
    handles => {
        all_hooks => 'elements',
    }
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my @args = @_;

    return $class->$orig(@args) if scalar @args == 2;
    return $class->$orig(filepath => shift @args) if scalar @args == 1;

    my %args;
    if(scalar @args % 2 != 0) {
        my $filepath = shift @args;
        %args = @args;
        $args{'filepath'} = $filepath;
    }
    else {
        %args = @args;
    }
    if(exists $args{'hooks'} && !ArrayRef->check($args{'hooks'})) {
        $args{'hooks'} = [$args{'hooks'}];
    }

    return $class->$orig(%args);
};

sub parse {
    my $self = shift;
    my %args = @_;
    my $override_line_change_weight = exists $args{'override_line_change_weight'} ? $args{'override_line_change_weight'} : 0;

    return Map::Metro::Graph->new(filepath => $self->filepath,
                                  wanted_hook_plugins => [$self->all_hooks],
                                  defined $override_line_change_weight ? (override_line_change_weight => $override_line_change_weight) : (),
                           )->parse;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Shim - Easily load a map file

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SYNOPSIS

    use Map::Metro::Shim;

    my $graph = Map::Metro::Shim->new('../path/to/mapfile.txt')->parse;

=head1 DESCRIPTION

If you want to test a map file without creating a module, use this class instead of L<Map::Metro> and pass the path to the map file.

=head2 Methods

=head3 new($filepath)

B<C<$filepath>>

The path to the map file.

Apart from that this module works just like L<Map::Metro>.

=head1 SEE ALSO

L<Map::Metro>

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
