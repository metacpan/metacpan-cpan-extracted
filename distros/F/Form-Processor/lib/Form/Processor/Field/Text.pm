package Form::Processor::Field::Text;
$Form::Processor::Field::Text::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field';



use Rose::Object::MakeMethods::Generic (
    scalar => [
        min_length => { interface => 'get_set_init' },
        size       => { interface => 'get_set_init' },
    ],
);

sub init_size       { return 2500 }    # new in .20 as a sanity check
sub init_min_length { return 0 }



sub init_widget { return 'text' }

sub validate {
    my $field = shift;

    return unless $field->SUPER::validate;

    my $value = $field->input;


    if ( my $size = $field->size ) {

        my $value = $field->input;

        return $field->add_error( 'Please limit to [quant,_1,character]. You submitted [_2]', $size, length $value )
            if length $value > $size;

    }

    # Check for min length
    if ( my $size = $field->min_length ) {

        return $field->add_error( 'Input must be at least [quant,_1,character]. You submitted [_2]', $size, length $value )
            if length $value < $size;

    }

    return 1;

}

# ABSTRACT: A simple text entry field




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Text - A simple text entry field

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a simple text entry field.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

=head1 METHODS

=head2 size [integer]

This integer value, if non-zero, defines the max size in characters of the input field.

The recommendation is to not use "Text" fields directly but to create
a subclass for each type of input (e.g. Name) that inherits from this
class and sets additional validation, including size.

As of L<Form::Processor> version .20 (0.04 for this class) the default has
changed from zero to 2500.

=head2 min_length [integer]

This integer value, if non-zero, defines the minimum number of characters that must 
be entered.

Default to zero characters.

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
