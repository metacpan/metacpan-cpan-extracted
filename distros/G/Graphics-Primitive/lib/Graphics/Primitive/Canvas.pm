package Graphics::Primitive::Canvas;
use Moose;
use MooseX::Storage;

extends 'Graphics::Primitive::Component';

with 'MooseX::Clone';
with Storage (format => 'JSON', io => 'File');

use Graphics::Primitive::Path;

has path => (
    isa => 'Graphics::Primitive::Path',
    is  => 'rw',
    default =>  sub { Graphics::Primitive::Path->new },
    handles => [
        'arc', 'close_path', 'current_point', 'curve_to', 'line_to',
        'move_to', 'rectangle', 'rel_curve_to', 'rel_line_to', 'rel_move_to'
    ]
);

has paths => (
    traits => [qw(Array Clone)],
    isa => 'ArrayRef',
    is  => 'rw',
    default =>  sub { [] },
    handles => {
        add_path => 'push',
        path_count => 'count',
        get_path => 'get',
    }
);

has saved_paths => (
    traits => [qw(Array Copy)],
    isa => 'ArrayRef',
    is  => 'rw',
    default =>  sub { [] },
    handles => {
        push_path => 'push',
        pop_path => 'pop',
        saved_path_count => 'count',
    }
);

sub do {
    my ($self, $op) = @_;

    $self->add_path({ op => $op, path => $self->path->clone });
    # Don't replace the current path if we are preserving.
    unless($op->preserve) {
        $self->path(Graphics::Primitive::Path->new);
    }
}

sub save {
    my ($self) = @_;

    $self->push_path($self->path->clone);
}

sub restore {
    my ($self) = @_;

    return if($self->saved_path_count < 1);

    $self->path($self->pop_path);
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Canvas - Component composed of paths

=head1 DESCRIPTION

Graphics::Primitive::Canvas is a component for drawing arbitrary things.  It
holds L<Paths|Graphics::Primitive::Path> and
L<Operations|Graphics::Primitive::Operation>.

=head1 SYNOPSIS

  use Graphics::Primitive::Canvas;

  my $canvas = Graphics::Primitive::Canvas->new;
  $canvas->move_to($point); # or just $x, $y
  $canvas->do($op);

=head1 DESCRIPTION

The Canvas is a container for multiple L<Paths|Graphics::Primitive::Path>.
It has a I<path> that is the operative path for all path-related
methods.  You can treat the Canvas as if it was a path, calling methods
like I<line_to> or I<move_to>.

When you are ready to perform an operation on the path, call the I<do> method
with the operation you want to call as an argument.  Drawing a line and
stroking it would look like:

  $canvas->move_to(0, 0);
  $canvas->line_to(10, 10);
  my $op = Graphics::Primitive::Operation::Stroke->new;
  $stroke->brush->color(
      Graphics::Color::RGB->new(red => 0, blue => 1, green => 1)
  );
  $canvas->do($op);

When you instantiate a Canvas a newly instantiated path resides in
I<path>.  After you call I<do> that current path is moved to the I<paths>
list and new path is placed in I<current_path>.  If you want to keep the path
around you can call I<save> before I<do> then call I<restore> to put a saved
copy of the path back into I<path>.

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Canvas

=back

=head2 Instance Methods

=over 4

=item I<do>

Given an operation, pushes the current path onto the path stack.

  FIXME: Example

=item I<path>

The current path this canvas is using.

=item I<path_count>

Count of paths in I<paths>.

=item I<paths>

Arrayref of hashrefs representing paths combined with their operations:
  
  [
    {
        path => $path,
        op   => $op
    },
  ]

=item I<restore>

Replace the current path by popping the top path from the saved path list.

=item I<save>

Copy the current path and push it onto the stack of saved paths.

=item I<saved_paths>

List of saved paths.  Add to the list with I<save> and pop from it using
I<restore>.

=item I<saved_path_count>

Count of paths saved in I<saved_paths>.

=back

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

You can redistribute and/or modify this code under the same terms as Perl
itself.
