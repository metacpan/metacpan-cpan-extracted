package Mail::Decency::ContentFilter::DKIM;

use Moose;
extends qw/
    Mail::Decency::ContentFilter::Core
/;
with qw/
    Mail::Decency::ContentFilter::Core::Spam
/;

use version 0.74; our $VERSION = qv( "v0.1.6" );

use mro 'c3';

use Mail::Decency::ContentFilter::Core::Constants;
use Mail::DKIM::Signer;
use Mail::DKIM::Verifier;
use Data::Dumper;

=head1 NAME

Mail::Decency::ContentFilter::DKIM

=head1 DESCRIPTION

This module can be used for signing OR verifying mails. DONT USE BOTH IN THE SAME INSTANCE!!

=head1 CONFIG FOR SIGN

    ---
    
    disable: 0
    #max_size: 0
    #timeout: 30
    
    enable_sign: 1
    
    # the default key. can be used only or as fallback
    sign_key: /etc/decency/dkim/default.key
    
    # a directory where the keys per (sender) domain are. 
    #   /etc/dkim/some-domain.co.uk.key
    #   /etc/dkim/other-domain.com.key
    sign_key_dir: /etc/decency/dkim/domains
    
    # the algorithmus and method .. change if you know what you are doing
    #sign_algo: rsa-sha1
    #sign_method: relaxed


=head1 CONFIG FOR VERIFY

    ---
    DKIM:
        enable_verify: 1
        
        # signature present and fitting
        #weight_pass: 50
        
        # signature present, but incorrect
        #weight_fail: -100
        
        # signature malformed .. cannot be processed
        #weight_invalid: -50
        
        # some temporary error occured. Probably nothing bad
        #weight_temperror: -10
        
        # no key whats-o-ever found in mail, cannot verify
        #weight_none: 0

=head1 CLASS ATTRIBUTES

=cut


# signing
has enable_sign    => ( is => 'rw', isa => 'Bool', default => 0 );
has sign_key       => ( is => 'rw', isa => 'Str', predicate => 'has_sign_key' );
has sign_key_dir   => ( is => 'rw', isa => 'Str', predicate => 'has_sign_key_dir' );
has sign_algo      => ( is => 'rw', isa => 'Str', default => 'rsa-sha1' );
has sign_method    => ( is => 'rw', isa => 'Str', default => 'relaxed' );

# verification
has enable_verify    => ( is => 'rw', isa => 'Bool', default => 0 );
has weight_pass      => ( is => 'rw', isa => 'Int', default => 15 );
has weight_fail      => ( is => 'rw', isa => 'Int', default => -50 );
has weight_invalid   => ( is => 'rw', isa => 'Int', default => -25 );
has weight_temperror => ( is => 'rw', isa => 'Int', default => 0 );
has weight_none      => ( is => 'rw', isa => 'Int', default => 0 );


=head1 METHODS


=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    # init base, assure we get mime encoded
    $self->next::method();
    
    # wheter signing is enabled
    if ( $self->config->{ enable_sign } ) {
        $self->enable_sign( 1 );
        
        # having sign key
        if ( $self->config->{ sign_key } ) {
            die "Sign key '". $self->config->{ sign_key }. "' does not exist or not readable\n"
                unless -f $self->config->{ sign_key };
            $self->sign_key( $self->config->{ sign_key } )
        }
        
        # having sign key dir (domain.tld.key)
        if ( $self->config->{ sign_key_dir } ) {
            die "Sign key dir '". $self->config->{ sign_key_dir }. "' is not a directory or not readable\n"
                unless -d $self->config->{ sign_key_dir };
            $self->sign_key( $self->config->{ sign_key_dir } )
        }
        
        # at least one
        die "Require 'sign_key' and/or 'sign_key_dir'\n"
            unless $self->has_sign_key && $self->has_sign_key_dir;
        
        # update other args
        foreach my $attr( qw/ sign_algo sign_method / ) {
            $self->$attr( $self->config->{ $attr } )
                if defined $self->config->{ $attr };
        }
        
    }
    
    # enable verify
    if ( $self->config->{ enable_verify } ) {
        $self->enable_verify( 1 );
        
        # get weightings
        foreach my $weight( qw/ weight_pass weight_fail weight_invalid weight_temperror weight_none / ) {
            $self->$weight( $self->config->{ $weight } )
                if defined $self->config->{ $weight };
        }
    }
    
    die "DKIM: Enable one of enable_sign or enable_verify. Never both, never none.!\n"
        if $self->enable_sign && $self->enable_verify || ( ! $self->enable_sign && ! $self->enable_verify );
    
}


=head2 handle

Default handling for any content filter is getting info about the to be filterd file

=cut


sub handle {
    my ( $self ) = @_;
    
    # verify mail
    if ( $self->enable_verify ) {
        
        # open file for read
        open my $fh, '<', $self->file
            or die "Cannot open file '". $self->file. "' for DKIM read\n";
        
        # init verifier and load file
        my $verifier = Mail::DKIM::Verifier->new;
        #$verifier->load( $fh );
        while( <$fh> ) {
            chomp;
            s/\015\012?$//;
            $verifier->PRINT( "$_\015\012" );
        }
        
        # close verifier and file
        close $fh;
        $verifier->CLOSE;
        
        # get result
        my $res = $verifier->result;
        
        # handle result, if found
        if ( $res && ( my $meth = $self->can( "weight_$res" ) ) ) {
            $self->logger->debug2( "Got result '$res'" );
            return $self->add_spam_score( $self->$meth, [ "Result: ". $verifier->result_detail ] );
        }
        else {
            $self->logger->error( "Unknown DKIM result '$res'" );
        }
    }
    
    # sign mail
    else {
        # determine domain
        my ( $prefix, $domain ) = split( /@/, $self->from, 2 );
        
        # determine key file (having dir, trye "domain.tld.key" there, then fallback to normal)
        my $key_file = $self->has_sign_key_dir && -f $self->sign_key_dir . "/${domain}.key"
            ? $self->sign_key_dir . "/${domain}.key"
            : $self->sign_key
        ;
        
        # found key file
        if ( $key_file ) {
            $self->logger->debug0( "Sign mail from '". $self->from. "' to '". $self->to. "' with '$key_file'" );
            
            # create new signer
            my $signer = Mail::DKIM::Signer->new(
                Algorithm => $self->sign_algo,
                Method    => $self->sign_method,
                Domain    => $domain,
                KeyFile   => $key_file
            );
            
            # open file and load into signer
            open my $fh, '<', $self->file;
            $signer->load( $fh );
            
            # close both
            close $fh;
            $signer->CLOSE;
            
            # update header in mime
            my $mime = $self->mime;
            $mime->head->replace( 'DKIM-Signature' => $signer->signature->as_string );
            $self->write_mime;
        }
    }
    
    return ;
}



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
