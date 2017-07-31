package HTML::FormHandler::Field::PosInteger;
# ABSTRACT: positive integer field
$HTML::FormHandler::Field::PosInteger::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Integer';

our $class_messages = {
    'integer_positive' => 'Value must be a positive integer',
};

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
            check   => sub { $_[0] >= 0 },
            message => sub {
                my ( $value, $field ) = @_;
                return $field->get_message('integer_positive');
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

HTML::FormHandler::Field::PosInteger - positive integer field

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

Tests that the input is an integer and has a positive value.

Customize error message 'integer_positive'.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
