package Form::Processor::Field::USPhone;
$Form::Processor::Field::USPhone::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';


sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input;

    $input =~ s/\D//g;

    return $self->add_error( 'Phone Number must be 10 digits, including area code' )
        unless length $input == 10;

    return 1;
}


# ABSTRACT: Validate that the input looks like a US phone number






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::USPhone - Validate that the input looks like a US phone number

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This removes any non-digits and then tests that there are ten digits.

This is probably not that useful as valid phone numbers may not need to contain
ten digits -- and that additional input data may be important.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text".

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
