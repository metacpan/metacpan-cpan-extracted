package Graphics::Primitive::Oriented;
use Moose::Role;

use Moose::Util::TypeConstraints;

enum 'Graphics::Primitive::Orientations' => [qw(vertical horizontal)];

has 'orientation' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Orientations',
);

sub is_vertical {
    my ($self) = @_;

    return 0 unless $self->orientation;

    return ($self->orientation eq 'vertical');
}

sub is_horizontal {
    my ($self) = @_;

    !$self->is_vertical;
}

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Oriented - Role for components that care about
orientation.

=head1 SYNOPSIS

Some components (or things that use components) require a bit more information
than origin and width/height.  The orientation role allows a component to
specify whether is vertically or horizontally oriented.

    package My::Component;
    
    extends 'Graphics::Primitive::Component';
    
    with 'Graphics::Primitive::Oriented';
    
    1;

=head1 METHODS

=over 

=item I<is_vertical>

Returns true if the component is vertically oriented.

=item I<is_horizontal>

Returns true if the component is not vertically oriented.

=item I<orientation>

The way a component is oriented. Values allowed are 'horizontal' or
'vertical'.


=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 SEE ALSO

perl(1)

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.