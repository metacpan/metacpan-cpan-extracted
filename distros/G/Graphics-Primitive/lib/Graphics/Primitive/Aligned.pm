package Graphics::Primitive::Aligned;
use Moose::Role;

use Moose::Util::TypeConstraints;

enum 'Graphics::Primitive::Alignment::Horizontals' => [qw(center left right)];
enum 'Graphics::Primitive::Alignment::Verticals' => [qw(bottom center top)];

has 'horizontal_alignment' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Alignment::Horizontals',
);
has 'vertical_alignment' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Alignment::Verticals',
);

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Aligned - Role for components that care about alignment.

=head1 SYNOPSIS

Some components (or things that use components) require a bit more information
than origin and width/height.  The alignment role allows a component to
specify it's horizontal and vertical alignment.

    package My::Component;
    
    extends 'Graphics::Primitive::Component';
    
    with 'Graphics::Primitive::Aligned';
    
    1;

=head1 METHODS

=head2 horizontal_alignment

Horizontal alignment value.  Valid values are 'center', 'left' and 'right'.

=head2 vertical_alignment

Vertical alignment value.  Valid values are 'bottom', 'center' and 'top'.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 SEE ALSO

perl(1)

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.