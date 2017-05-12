package Form::Processor::Field::Readonly;
$Form::Processor::Field::Readonly::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';



sub init_readonly { return 1 };    # for html rendering

sub init_noupdate { return 1 }



# ABSTRACT: Field that can be read but not updated






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Readonly - Field that can be read but not updated

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field is used to display but not update data from the database/model.

This readonly field has the "readonly" and "noupdate" flags set.
The "readonly" flag is a hint to render the HTML as a readonly field.
The "noupdate" flag tells L<Form::Processor> to not update the database
with this data.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text/readonly".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text".

=item

This field is a display only field

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
