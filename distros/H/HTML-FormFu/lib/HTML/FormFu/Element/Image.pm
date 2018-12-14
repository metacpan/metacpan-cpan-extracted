use strict;

package HTML::FormFu::Element::Image;
$HTML::FormFu::Element::Image::VERSION = '2.07';
# ABSTRACT: Image button form field

use Moose;

extends 'HTML::FormFu::Element::Button';

__PACKAGE__->mk_attr_accessors(qw( src width height ));

after BUILD => sub {
    my $self = shift;

    $self->field_type('image');

    if ( !defined $self->src ) {
        $self->src('');
    }

    return;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Element::Image - Image button form field

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    $e = $form->element( Image => 'foo' );

=head1 DESCRIPTION

Image button form field.

=head1 METHODS

=head1 SEE ALSO

Is a sub-class of, and inherits methods from
L<HTML::FormFu::Element::Button>,
L<HTML::FormFu::Role::Element::Input>,
L<HTML::FormFu::Role::Element::Field>,
L<HTML::FormFu::Element>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
