package Graphics::Primitive::Driver::TextLayout;
use Moose::Role;

requires 'slice';

has 'component' => (
    is => 'rw',
    isa => 'Graphics::Primitive::TextBox',
    required => 1,
    weak_ref => 1
);
has 'height' => (
    is => 'rw',
    isa => 'Num',
    default => sub { -1 }
);
has 'width' => (
    is => 'rw',
    isa => 'Num',
    lazy => 1,
    default => sub { my ($self) = @_; $self->component->width }
);

no Moose;
1;
__END__;
=head1 NAME

Graphics::Primitive::Driver::TextLayout - TextLayout role

=head1 DESCRIPTION

Graphics::Primitive::Driver::TextLayout is a role for Driver text layout
engines.

=head1 SYNOPSIS

    package MyLayout;
    use Moose;

    with 'Graphics::Primitive::Driver::TextLayout';

    ...

=head1 METHODS

=over 4

=item I<component>

Set/Get the component from which to draw layout information.

=item I<height>

Set/Get this layout's height

=item I<slice>

Implemented by role consumer. Given an offset and an optional size, returns a
TextBox containing lines from this layout that come as close to C<$size>
without exceeding it.  This method is provided to allow incremental rendering
of text.  For example, if you have a series of containers 80 units high, you
might write code like this:

  for(my $i = 0; $i < 3; $i++) {
      $textbox = $layout->slice($i * 80, 80);
      # render the text
  }

=item I<width>

Set/Get this layout's width.  Defaults to the width of the component supplied.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
