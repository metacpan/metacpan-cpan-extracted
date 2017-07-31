package HTML::FormHandler::Field::Email;
# ABSTRACT: validates email using Email::Valid
$HTML::FormHandler::Field::Email::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';
use Email::Valid;

our $class_messages = {
    'email_format' => 'Email should be of the format [_1]',
};
has '+html5_type_attr' => ( default => 'email' );

has 'email_valid_params' => (
    is => 'rw',
    isa => 'HashRef',
);

has 'preserve_case' => (
    is => 'rw',
    isa => 'Bool',
);

sub get_class_messages  {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

apply(
    [
        {
            transform => sub {
                my ( $value, $field ) = @_;
                return $value
                    if $field->preserve_case;
                return lc( $value );
            }
        },
        {
            check => sub {
                my ( $value, $field ) = @_;
                my $checked = Email::Valid->address(
                    %{ $field->email_valid_params || {} },
                    -address => $value,
                );
                $field->value($checked)
                    if $checked;
            },
            message => sub {
                my ( $value, $field ) = @_;
                return [$field->get_message('email_format'), 'someuser@example.com'];
            },
        }
    ]
);


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Email - validates email using Email::Valid

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

Validates that the input looks like an email address using L<Email::Valid>.
Widget type is 'text'.

If form has 'is_html5' flag active it will render <input type="email" ... />
instead of type="text"

This field has an 'email_valid_params' attribute that accepts a hash
reference of extra values passed to L<Email::Valid/address> when
validating email addresses.

If you want to preserve the case of the email address, set the
'preserve_case' attribute.

=head1 DEPENDENCIES

L<Email::Valid>

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
