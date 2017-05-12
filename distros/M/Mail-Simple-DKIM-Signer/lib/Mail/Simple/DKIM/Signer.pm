package Mail::Simple::DKIM::Signer;

use strict;
use warnings;
use Digest::SHA qw/sha1/;
use MIME::Base64;
use Crypt::OpenSSL::RSA;
our $VERSION = '0.01';


sub new {

    my $class = shift;
    my $options = shift;
    my $self = {};
    
    my $private_key = $options->{key};
    $self->{headers} = $options->{headers};
    
    my $rsa_priv = new_private_key Crypt::OpenSSL::RSA($private_key);
    
    $self->{rsa} = $rsa_priv;
    
    $self->{BodyCanonicalization} = 'simplebody';
    $self->{HeadersCanonicalization} = 'simpleheader';
    
  
    $self->{d} = $options->{domain};
    
    $self->{s} = $options->{selector} || 'dkim';
    
    $self->{c} = $options->{c} || 'simple/simple';
    
    $self->{l} = $options->{l} || '0';
    
    ###get each methods
    my @methods = split(/\//, $self->{c});
    
    $self->{HeadersC} = $methods[0] || 'simple';
    $self->{BodyC} = $methods[1] || 'simple';
    
    $self->{a} = $options->{a} || 'rsa-sha1';
    $self->{q} = $options->{q} || 'dns/txt';
    
    $self->{i} = $options->{i};  
    
    return bless($self, $class);
}



sub sign {
    
    my ($self,$headers,$body) =@_;
    
    ####convert body with simple Canonicalization
    #$body = $self->SimpleBodyCanonicalization($body);
    
    $body = $self->SimpleBodyCanonicalization($body);
    
    ##get body length
    my $body_length = length($body);
    
    ####generate body ahsh key (bh)
    my $bh = pack("H*", $body);
    $bh = encode_base64(sha1($body));
    
    ###remove unwanted spaces from body hash
    $bh =~ tr/\015\012 \t//d  if defined $bh;
    
  
    ####start genrating signature of headers  
    
    ##first run Canonicalization
    $headers = SimpleHeaderCanonicalization($headers);

    ##add headers to array
    my @headers = split(/\r\n/, $headers);
    my @str;
    my @headers_to_be_signed;
    
    ##loop throug headers      
    foreach my $header (@headers){
        
        ###remove embty leading and ending lines
        $header = $self->trim($header);
        
        ##exlude headers with x- and dkim- part
        push @headers_to_be_signed,$header if $header !~/^X-|^Dkim-/i;
        #push @to_be_signed,$header;
        
        ##get name part of headers
        $header =~ m/(.*?): (.*?)/;
        push @str,$1 if $1 !~/^X-|^Dkim-/i;
        
    }

    ###join header values we want to sign this will go to the h= tag
    my $str = join(":",@str);

    ##getting i= tag
    my $i_part = '';
    my $l_part = '';
    
    if ($self->{i}){
        $i_part = " i=".$self->{i}.";";
    }
    
    if ($self->{l}){
        $l_part = " l=$body_length;";
    }
    
    ###create dkim string
    my $dkim="v=1; a=$self->{a}; q=$self->{q};$l_part s=$self->{s};\r\n".
    "\tc=$self->{c};\r\n".
    "\th=$str;\r\n".
    "\td=$self->{d};$i_part\r\n".
    "\tbh=$bh;\r\n".
    "\tb=";
    
  
    ##push dkim string to the headers_to_be_signed array
    push (@headers_to_be_signed,"DKIM-Signature: ".$dkim);

    ##get headers to be signed as string
    my $headers_to_be_signed = join("\r\n",@headers_to_be_signed);
  
   
    ##generate signature
    my $signature = $self->{rsa}->sign($headers_to_be_signed);
  
 
    ##encode segnature
    my $b = encode_base64($signature);
  
    ##remove unwanted new lines
    $b =~ tr/\015\012 \t//d  if defined $b;
  
    ###add signature to the dkim string
    $dkim = $dkim.$b;

    #return $dkim;
    return {
        string => "DKIM-Signature: ".$dkim,
        value => $dkim,
        key => "DKIM-Signature"
    };
  
  
}




sub SimpleBodyCanonicalization {
  
    my ($self,$body) = @_;
  
    ##convert \r\n to \n just in case if this came from windows
    $body =~s /\r\n/\n/g;

    $body =~s /\n/\r\n/g;
    
    #$body = length($body);
    my $bodylength = length($body);  
    
    ###remove embty lines from the end of the message body    
    
    while (substr($body,$bodylength-4,4) =~ m/\r\n\r\n/){
        $body = substr($body,0,length($body)-2);
    }
    
    return $body;
    
}



sub SimpleHeaderCanonicalization {
    
    my $header =shift;
    
    ##convert \r\n to \n just in case if this came from windows
    $header =~s /\r\n/\n/g;
    $header =~s /\n/\r\n/g;
    
    ###nothing else to do with headers as this is what simple header Canonicalization
    ##documents say

    return $header;
    
}



sub trim($) {
    
    my ($self,$string) = @_;
    
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    
    return $string;
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Simple::DKIM::Signer - Simple DKIM Signer

=head1 SYNOPSIS
    
    

    
    use Mail::Simple::DKIM::Signer;
    
    my $dkim = Mail::Simple::DKIM::Signer->new({
        
        key => $private_key, #private key string
        domain => 'example.com',
        selector => 'dkim',
        c => 'simple/simple', ###simple/simple is the only supported Canonicalization
        a => 'rsa-sha1', ##rsa-sha1 is the only supported method
        i => '@example.com',
        l => '1', ##include body length in signature
        
    });
    
    ##create message with MIME::Lite
    
    use MIME::Lite;
    ### Create a new single-part message, to send a GIF file:
        $msg = MIME::Lite->new(
        From    => 'me@myhost.com',
        To      => 'you@yourhost.com',
        Subject => 'Message Subject',
        Type    => 'TEXT',
        Data => 'bla bla bla...'
    );
    
    
    ##create dkim signature for this message
    my $signature = $dkim->sign($msg->header_as_string,$msg->body_as_string);
    
    ##add dkim header to the message message
    $msg->{Header}->[0] = [ $signature->{key}, $signature->{value} ];
    
    ##send your message
    $msg->send();
    
    
=head1 DESCRIPTION

THIS IS AN Experimental dkim simple signer
it only supports simple/simple Canonicalization and rsa-sha1 encoding

For more advanced signing methods please use Mail::DKIM



=head1 SEE ALSO

MIME::Lite

=head1 AUTHOR

Mahmoud A. Mehyar, E<lt>mamod.mehyar@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mahmoud A. Mehyar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
