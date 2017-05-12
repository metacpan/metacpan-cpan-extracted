package Form::Processor::Field::OneToTen;
$Form::Processor::Field::OneToTen::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::IntRange';



# ABSTRACT: Field::Processor Field



sub init_widget      {'radio'}
sub init_range_start {1}
sub init_range_end   {10}






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::OneToTen - Field::Processor Field

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

DEPRECATED

Value constrained to integers 1 to 10.
For use in surveys using ten radio selects.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "radio".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "IntRange".

=head1 DESCRIPTION

=head1 NAME

Form::Processor::Field::OneToTen- DEPRECATED Example custom field

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
