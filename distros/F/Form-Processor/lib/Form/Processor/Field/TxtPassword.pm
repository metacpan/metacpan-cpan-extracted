package Form::Processor::Field::TxtPassword;
$Form::Processor::Field::TxtPassword::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::EnterPassword';
use File::ShareDir;
use Encode qw/ encode_utf8 is_utf8 /;
use Data::Password::Entropy;

use Rose::Object::MakeMethods::Generic (
    scalar => [
        min_bytes   => { interface => 'get_set_init' },
        min_entropy => { interface => 'get_set_init' },
    ],
);

sub init_min_bytes   { return 9 }
sub init_min_entropy { return 28 }    # Arbitrary!

# This is small because this is counting *characters*, not bytes.
sub init_min_length { return 4 }

my %bad_pw_lookup;
{
    my $pwd_list = File::ShareDir::dist_dir( 'Form-Processor' ) . '/passwords.txt';
    open my $fh, '<:utf8', $pwd_list or die "Failed to open file [$pwd_list]: $!";
    %bad_pw_lookup = map { chomp; $_ => 1 } <$fh>;    ## no critic
    close $fh;
}


sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $value = $self->input;


    # Check length of password in bytes.
    return $self->add_error( 'please enter a more secure password' )
        if length( is_utf8( $value ) ? encode_utf8( $value ) : $value ) < $self->min_bytes;


    return $self->add_error( 'please enter a more secure password' )
        if exists $bad_pw_lookup{$value};



    # This is totally arbitrary.  Plus, it can give away what what is considered
    # a "good" password, limiting the patterns to attempt.

    # See also Data::Password, but that excludes ANY dictionary word with in the phrase
    return $self->add_error( 'please enter a more secure password' )
        if password_entropy( $value ) < $self->min_entropy;
    return 1;


}



# ABSTRACT: Input a password


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::TxtPassword - Input a password

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Simple password field that accepts any string.

The only validation is a check if input matches any well-known passwords
found in the share file "passwords.txt" and that it is of minimum length.

See: L<https://github.com/danielmiessler/SecLists>.

=head1 ATTRIBUTES

=head2 min_bytes

Minimum size in bytes of the input string.  Bytes are used because we care
about entropy or than character length -- and 9 Chinese characters is a long phrase.

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
