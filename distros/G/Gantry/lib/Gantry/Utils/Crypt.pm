package Gantry::Utils::Crypt;
use strict;

use Crypt::CBC;
use MIME::Base64;
use Digest::MD5 qw( md5_hex );

sub new {
    my ( $class, $opt ) = @_;

    my $self = { options => $opt };
    bless( $self, $class );

    my @errors;
    foreach( qw/secret/ ) {
        push( @errors, "$_ is not set properly" ) if ! $opt->{$_};
    }

    if ( scalar( @errors ) ) {
        die join( "\n", @errors );
    }
    
    # populate self with data from site
    return( $self );

} # end new

#-------------------------------------------------
# decrypt()
#-------------------------------------------------
sub decrypt { 
    my ( $self, $encrypted ) = @_;

    $encrypted ||= '';
    $self->set_error( undef );
    
    local $^W = 0;
    
    my $c;
    eval {
        $c = new Crypt::CBC ( {    
            'key'         => $self->{options}{secret},
            'cipher'      => 'Blowfish',
            'padding'     => 'null',
        } );
    };
    if ( $@ ) {
        my $error = (
            "Error building CBC object are your Crypt::CBC and"
            . " Crypt::Blowfish up to date?  Actual error: $@"
        );
        
        $self->set_error( $error );   
        die $error;
    }

    my $p_text = $c->decrypt( MIME::Base64::decode( $encrypted ) );
    
    $c->finish();
    
    my @decrypted_values = split( ':;:', $p_text );
    my $md5              = pop( @decrypted_values );
    my $omd5             = md5_hex( join( '', @decrypted_values ) ) || '';

    if ( $omd5 eq $md5 ) {
        if ( wantarray ) { 
            return @decrypted_values;
        }
        else {
            return join( ' ', @decrypted_values );            
        } 
    }
    else {
        $self->set_error( 'bad encryption' );
    }

} # END decrypt_cookie

#-------------------------------------------------
# encrypt
#-------------------------------------------------
sub encrypt {
    my ( $self, @to_encrypt ) = @_;

    local $^W = 0;    
    $self->set_error( undef );
    
    my $c;
    eval {
        $c = new Crypt::CBC( {    
            'key'         => $self->{options}{secret},
            'cipher'     => 'Blowfish',
            'padding'    => 'null',
        } );
    };
    if ( $@ ) {
        my $error = (
            "Error building CBC object are your Crypt::CBC and"
            . " Crypt::Blowfish up to date?  Actual error: $@"
        );

        $self->set_error( $error );
        die $error;
    }

    my $md5 = md5_hex( join( '', @to_encrypt ) );
    push ( @to_encrypt, $md5 );
    
    my $str      = join( ':;:', @to_encrypt );    
    my $encd     = $c->encrypt( $str );    
    my $c_text   = MIME::Base64::encode( $encd, '' );

    $c->finish();
 
    return( $c_text );
    
} # END encrypt

#-------------------------------------------------
# set_error()
#-------------------------------------------------
sub set_error {
    my $self = shift;
    $self->{__error__} = shift;

    return $self->{__error__};
}

#-------------------------------------------------
# get_error()
#-------------------------------------------------
sub get_error {
    my $self = shift;
    return $self->{__error__};
}

# EOF
1;

__END__

=head1 NAME 

Gantry::Utils::Crypt - an easy way to crypt and decrypt

=head1 SYNOPSIS

    use Gantry::Utils::Crypt;
    
    my $crypt_obj = Gantry::Utils::Crypt->new ( 
        { secret => 'my_secret_encryption_string' }
    );

    my $encrypted_string = $crypt->encrypt( 'red', 'blue', 'green' );
    my @decrypted_values = $crypt->decrypt( $encrypted_string );

=head1 DESCRIPTION

This module is a utillity to help with encryption and decryption.

=head1 METHODS 

=over 4

=item new

Standard constructor, call it first. 

Requires the following parameter

    secret       # this is your super secret encryption key

=item encrypt( 'value' [, ... ] )

encrypts and returns the encrypted string 

=item decrypt( 'string' )

decrypts and returns the values 

=back

=head1 SEE ALSO

Gantry(3)

=head1 LIMITATIONS 

This module depends on Gantry(3)

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-7, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
