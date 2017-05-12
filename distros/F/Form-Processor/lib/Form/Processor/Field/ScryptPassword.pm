package Form::Processor::Field::ScryptPassword;
$Form::Processor::Field::ScryptPassword::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::TxtPassword';
use Crypt::ScryptKDF 0.009 qw/ scrypt_hash /;
use Encode;


sub input_to_value {
    my $field = shift;

    $field->value( scrypt_hash( Encode::encode_utf8( $field->input ) ) );

    return;
}


# ABSTRACT: convert passwords to scrypt hash.



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::ScryptPassword - convert passwords to scrypt hash.

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This class converts the input value to a script hash using L<Crypt::ScryptKDF>.
The class inherits from TxtPassword which enforces some length, common word, and
entropy checks.

Currently doesn't allow changing the script_hash parameters (as per L<Crypt::ScryptKDF>
documentation).

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
