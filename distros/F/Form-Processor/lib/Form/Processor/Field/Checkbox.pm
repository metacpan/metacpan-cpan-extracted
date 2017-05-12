package Form::Processor::Field::Checkbox;
$Form::Processor::Field::Checkbox::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Boolean';


sub init_widget { return 'checkbox' }

sub input_to_value {
    my $field = shift;

    return $field->value( $field->input ? 1 : 0 );
}

sub value {
    my $field = shift;
    return $field->SUPER::value( @_ ) if @_;
    my $v = $field->SUPER::value;
    return defined $v ? $v : 0;
}


# ABSTRACT: A boolean checkbox field type


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Checkbox - A boolean checkbox field type

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field is very similar to the Boolean field with the exception
that only true or false can be returned.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "checkbox".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

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
