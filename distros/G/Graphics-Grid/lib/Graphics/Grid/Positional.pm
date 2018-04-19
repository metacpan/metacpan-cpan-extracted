package Graphics::Grid::Positional;

# ABSTRACT: Role for supporting (x, y) position in Graphics::Grid

use Graphics::Grid::Role;

our $VERSION = '0.0001'; # VERSION

use Types::Standard qw(InstanceOf);
use Graphics::Grid::Types qw(:all);

use Graphics::Grid::Unit;


has [qw(x y)] => (
    is      => 'ro',
    isa     => UnitLike,
    coerce  => 1,
    default => sub { Graphics::Grid::Unit->new(0.5) },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Positional - Role for supporting (x, y) position in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This role describes something that has position defined by (x, y).

=head1 ATTRIBUTES

=head2 x

A Grahpics::Grid::Unit object specifying x-location.

Default to C<unit(0.5, "npc")>.

=head2 y

A Grahpics::Grid::Unit object specifying y-location.

Default to C<unit(0.5, "npc")>.

The reference point is the left-bottom of parent viewport.

=head1 SEE ALSO

L<Graphics::Grid>

L<Graphics::Grid::Unit>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
