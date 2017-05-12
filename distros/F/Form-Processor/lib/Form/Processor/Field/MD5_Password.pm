package Form::Processor::Field::MD5_Password;
$Form::Processor::Field::MD5_Password::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Password';
use Digest::MD5 'md5_hex';
use Encode;




sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input;


    return $self->add_error( 'Passwords must include one or more digits' )
        unless $input =~ /\d/;

    return 1;
}

sub input_to_value {
    my $field = shift;

    # Failing test
    #$field->value( md5_hex(  $field->input  ) );

    $field->value( md5_hex( Encode::encode_utf8( $field->input ) ) );

    return;
}


# ABSTRACT: convert passwords to MD5 hashes






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::MD5_Password - convert passwords to MD5 hashes

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Validation requires one or more digits.  Value returned is the MD5 hash
of the input value.

Useful for storing hashed passwords.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "password".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Password".

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
