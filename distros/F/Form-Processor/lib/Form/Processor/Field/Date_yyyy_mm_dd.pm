package Form::Processor::Field::Date_yyyy_mm_dd;
$Form::Processor::Field::Date_yyyy_mm_dd::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::DateTime';




sub format_value {
    my $field = shift;

    return () unless defined $field->value;


    return ( $field->name, $field->value->strftime( '%F' ) );
}

# ABSTRACT: Expects datas in yyyy_mm_dd format



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Date_yyyy_mm_dd - Expects datas in yyyy_mm_dd format

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This inherits from the DateTime field and formats using the %F strftime
format.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "DateTime".

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
