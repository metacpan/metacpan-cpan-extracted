package Graphics::Grid::Dimensional;

# ABSTRACT: Role for supporting width and height in Graphics::Grid

use Graphics::Grid::Role;

our $VERSION = '0.0001'; # VERSION

use Types::Standard qw(InstanceOf);
use Graphics::Grid::Types qw(:all);

use Graphics::Grid::Unit;


has [qw(width height)] => (
    is      => 'ro',
    isa     => UnitLike,
    coerce  => 1,
    default => sub { Graphics::Grid::Unit->new(1); },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Dimensional - Role for supporting width and height in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This role describes something that has width and height.

=head1 ATTRIBUTES

=head2 width

A Grahpics::Grid::Unit object specifying width.

Default to C<unit(1, "npc")>.

=head2 height

Similar to the C<width> attribute except that it is for height. 

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
