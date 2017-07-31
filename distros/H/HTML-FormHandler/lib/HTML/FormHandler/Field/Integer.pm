package HTML::FormHandler::Field::Integer;
# ABSTRACT: validate an integer value
$HTML::FormHandler::Field::Integer::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

has '+size' => ( default => 8 );
has '+html5_type_attr' => ( default => 'number' );

our $class_messages = {
    'integer_needed' => 'Value must be an integer',
};

sub get_class_messages {
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
                my $value = shift;
                $value =~ s/^\+//;
                return $value;
                }
        },
        {
            check => sub { $_[0] =~ /^-?[0-9]+$/ },
            message => sub {
                my ( $value, $field ) = @_;
                return $field->get_message('integer_needed');
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

HTML::FormHandler::Field::Integer - validate an integer value

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

This accepts a positive or negative integer.  Negative integers may
be prefixed with a dash.  By default a max of eight digits are accepted.
Widget type is 'text'.

If form has 'is_html5' flag active it will render <input type="number" ... />
instead of type="text"

The 'range_start' and 'range_end' attributes may be used to limit valid numbers.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
