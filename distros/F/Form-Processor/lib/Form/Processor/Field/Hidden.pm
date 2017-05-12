package Form::Processor::Field::Hidden;
$Form::Processor::Field::Hidden::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';



sub init_widget {'hidden'}


# ABSTRACT: a text field as a hidden widget



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Hidden - a text field as a hidden widget

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This simply inherits from the Text field and sets the widget type as
"hidden".

This should probably be deprecated because it's probalby better to simply
use a text field and set its widget type to "hidden".

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "hidden".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: Text

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
