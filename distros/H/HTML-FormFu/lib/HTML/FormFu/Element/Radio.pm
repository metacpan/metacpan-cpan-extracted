use strict;

package HTML::FormFu::Element::Radio;
$HTML::FormFu::Element::Radio::VERSION = '2.07';
# ABSTRACT: Radio form field

use Moose;

extends 'HTML::FormFu::Element::Checkbox';

use HTML::FormFu::Constants qw( $EMPTY_STR );

__PACKAGE__->mk_output_accessors(qw( default ));

after BUILD => sub {
    my $self = shift;

    $self->field_type('radio');

    return;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Element::Radio - Radio form field

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    my $element = $form->element( Radio => 'foo' );

=head1 DESCRIPTION

Radio form field.

=head1 SEE ALSO

Is a sub-class of, and inherits methods from
L<HTML::FormFu::Element::Checkbox>,
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
