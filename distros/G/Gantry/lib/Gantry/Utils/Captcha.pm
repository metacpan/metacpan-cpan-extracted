package Gantry::Utils::Captcha;
use strict;

use Gantry::Utils::Crypt;
use Data::Random qw(:all);

sub new {
    my ( $class, $secret, $images ) = @_;

    my $self = {};
    bless( $self, $class );

    die "secret encryption string required" if ! $secret;

    $self->{images}        = [];
    $self->{current_image} = '';
    $self->{crypt_obj}     = Gantry::Utils::Crypt->new( { secret => $secret } );
    
    foreach ( @{ $images } ) {
        $self->add( $_ );
    }

    # populate self with data from site
    return( $self );

} # end new

sub add {
    my( $self, $image ) = @_;

    foreach my $f ( qw/key image label/ ) {
        die "captcha $f required" if ! $image->{$f};
    }
    
    $image->{crypt_string} = $self->{crypt_obj}->encrypt( $image->{key} );
    
    push( @{ $self->{images} }, $image );
}

sub shuffle {
    my( $self ) = @_;
    
	my @rand = rand_set( set => $self->{images}, size => 1 );
    my $img_ct = scalar( @{ $self->{images} } ) || 0;
    
	for ( my $i=0; $i < $img_ct; $i++ ) {
    	$self->{current_image} = $i 
    	    if $rand[0]->{key} eq $self->{images}[$i]->{key};   
	}	
}

sub valid {
    my( $self, $crypt_string ) = @_;
    
    my( $cap_value, $cap_key ) = split( ':;:', $crypt_string );
    return 0 if ! $cap_value;
    
    my $decrypted = $self->{crypt_obj}->decrypt( $cap_key );
    
    return 1 if $decrypted eq $cap_value;
    return 0;
}

sub key {
    my( $self ) = @_;    
    return $self->{images}[$self->{current_image}]->{key};
}

sub base_url {
    my( $self ) = @_;    
    return $self->{images}[$self->{current_image}]->{base_url};
}

sub image {
    my( $self ) = @_;
    return $self->{images}[$self->{current_image}]->{image};
}
    
sub label {
    my( $self ) = @_;
    return $self->{images}[$self->{current_image}]->{label};    
}

sub alt_text {
    my( $self ) = @_;
    return $self->{images}[$self->{current_image}]->{alt_text};    
}

sub crypt_string {
    my( $self ) = @_;
    return $self->{images}[$self->{current_image}]->{crypt_string};    
}

sub gantry_form_options {
    my $self = shift;

    my @options;
    
    push( @options, { label => ' - select - ', value => 0 } );

    foreach my $i ( @{ $self->{images} } ) {
        push( @options, {
            label => $i->{label},
            value => $i->{key} . ":;:" . $self->crypt_string,            
        } );        
    }
    
    return \@options;
}

sub image_link {
    my( $self ) = @_;
    
    my @link;
    push( @link,
        q!<img src="!,
        $self->base_url,
        "/",
        $self->image,
        q!" alt="!,
        $self->alt_text,
        q!" class="captcha-image" />!,
    );
    
    return join( '', @link );    
}

# EOF
1;

__END__

=head1 NAME 

Gantry::Utils::Captcha - a way to mange captchas

=head1 SYNOPSIS

    my $captcha = Gantry::Utils::Captcha->new( 'h2xsg' ); 
    
    $captcha->add( { 
        base_url => $self->doc_rootp() . "/images",
        image    => 'captcha-image-1.jpg',  
        key      => 'chair', 
        label    => 'looks like a chair to me',
        alt_text => 'sometimes it feels reaally good to sit',                 
    } );

    $captcha->add( { 
        base_url  => $self->doc_rootp() . "/images",
        image     => 'captcha-image-2.jpg', 
        key       => 'yoda', 
        label     => 'hrm ... yoda you are',
        alt_text  => 'use the force, Luke',                
    } );

    $captcha->add( {
        base_url  => $self->doc_rootp() . "/images",
        image     => 'captcha-image-3.jpg', 
        key       => 'biking', 
        label     => 'biking is fun',
        alt_text  => 'two wheels and a seat',
    } );

    or 
    
    my $captcha = Gantry::Utils::Captcha->new( 
        'h2xs',
        [
            {
                base_url  => $self->doc_rootp() . "/images",
                image     => 'captcha-image-3.jpg', 
                key       => 'biking', 
                label     => 'biking is fun',
                alt_text  => 'two wheels and a seat',
            }        
        ]
    );

=head1 DESCRIPTION

This module is a utility to help with captchas.

=head1 METHODS 

=over 4

=item new( [secret encryption key] )

Standard constructor, call it first. 

Requires the following parameter

    secret       # this is your super secret encryption key

=item add( { ... } )

add a captcha item

Requires the following parameter

     image       # the image i.e. myimage.gif
     key         # the unique key for this captcha
     label       # the question that will appear in the select box

Optional

    alt_text     # the alt text for the image
    base_url     # a base url

=item shuffle

Shuffle the captchas and set one in the queue

=item valid( [captcha form param value] );

Tests to the captcha's encrypted string with the key and returns true of false

=item key

Return the captcha's key for the queued chaptcha

=item base_url

Returns the captcha's base url for the queued chaptcha

=item image

Returns the captcha's image for the queued chaptcha

=item label

Returns the captcha's label for the queued chaptcha

=item alt_text

Returns the captcha's alt_text for the queued chaptcha

=item crypt_string

Returns the captcha's crypt_string for the queued chaptcha

=item gantry_form_options

returns a reference to an array of form options that can be passed directly to
form.tt

=item image_link

Returns the captcha's image link

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
