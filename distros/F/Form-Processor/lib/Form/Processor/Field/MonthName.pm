package Form::Processor::Field::MonthName;
$Form::Processor::Field::MonthName::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Select';



sub init_options {
    my $i      = 1;
    my @months = qw/
        January
        February
        March
        April
        May
        June
        July
        August
        September
        October
        November
        December
        /;
    return [
        map {
            { value => $i++, label => $_ }
            } @months
    ];
}


# ABSTRACT: Select list for month names




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::MonthName - Select list for month names

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Generates a list of English month names.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "select".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Select".

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
