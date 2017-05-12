package Graphics::Primitive::Paint;
use Moose;

__PACKAGE__->meta->make_immutable;

no Moose;
1;
=head1 NAME

Graphics::Primitive::Paint - A source for drawing on a path

=head1 DESCRIPTION

Graphics::Primitive::Paint is the base class for paints.  A paint is a pattern
suitable for use with a L<Fill|Graphics::Primitive::Operation::Fill> op.

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

You can redistribute and/or modify this code under the same terms as Perl
itself.
