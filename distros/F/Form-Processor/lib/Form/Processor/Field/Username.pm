# ABSTRACT: ** Please provide abstract **

package Form::Processor::Field::Username;
$Form::Processor::Field::Username::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';



sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input || '';

    return $self->add_error( 'Usernames must not contain spaces' )
        if $input =~ /\s/;

    return $self->add_error( 'Usernames must be at least 4 characters long' )
        if length $input < 4;

    return 1;
}






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Username - ** Please provide abstract **

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Validate that the input does not contain any spaces and is at least
four characters long.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text".

=head1 NAME

Form::Processor::Field::Username

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
