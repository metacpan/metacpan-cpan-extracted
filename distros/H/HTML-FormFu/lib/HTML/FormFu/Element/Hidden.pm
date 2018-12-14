use strict;

package HTML::FormFu::Element::Hidden;
$HTML::FormFu::Element::Hidden::VERSION = '2.07';
# ABSTRACT: Hidden form field

use Moose;

extends 'HTML::FormFu::Element';

with 'HTML::FormFu::Role::Element::Input';

after BUILD => sub {
    my $self = shift;

    $self->field_type('hidden');
    $self->container_tag(undef);

    $self->layout( [ 'field', ] );

    return;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Element::Hidden - Hidden form field

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    my $e = $form->element( Hidden => 'foo' );

=head1 DESCRIPTION

Hidden form field.

=head1 METHODS

=head1 SEE ALSO

Is a sub-class of, and inherits methods from
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
