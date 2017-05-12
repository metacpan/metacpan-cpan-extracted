package Form::Processor::Field::Integer;
$Form::Processor::Field::Integer::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';



sub init_size {10}

sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    # remove plus sign.
    my $value = $self->input;
    if ( $value =~ s/^\+// ) {
        $self->input( $value );
    }

    return $self->add_error( 'Value must be an integer' )
        unless $self->input =~ /^-?\d+$/;

    return 1;

}



# ABSTRACT: validate an integer value




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Integer - validate an integer value

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This accepts a positive or negative integer.  Negative integers may
be prefixed with a dash.

The intention of the Integer field is to be subclasses for specific uses.

By default a max of ten digits are accepted.  This is a change form previous
versions where it was limited to 8.  The change to 10 digits was to bring it in
line with a common usage with 32 bit numbers.

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
