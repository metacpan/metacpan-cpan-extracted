package Form::Processor::Field::Phone;
$Form::Processor::Field::Phone::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';



# ABSTRACT: input a telephone number



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Phone - input a telephone number

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a placeholder field that does not override any methods
and is just a subclass of the Text field.

This origianlly had valiation to test the phone number length and pattern,
but it became clear that phone numbers vary too much to be validated in
this way -- and it breaks the rule that you should only validate what
needs validation.

You may wish to replace this class if you really need a specific phone number
format.

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
