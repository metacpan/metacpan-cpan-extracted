#########################################################################################
# Package        HiPi::Huawei::HiLink
# Description  : HiLink HTTP API Class
# Copyright    : Copyright (c) 2019 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Huawei::HiLink;
use strict;
use warnings;
use LWP::UserAgent;
use Try::Tiny;
use XML::LibXML;
use Encode ();

use parent qw( HiPi::Class );

my @_package_accessors = qw(
    debug
    manual_cookie
    request_token
    timeout
);

__PACKAGE__->create_accessors( @_package_accessors );

our $VERSION ='0.81';

my $arrayelements = {
    'Messages' => 'Message',
    'Profiles' => 'Profile',
};


sub new {
    my( $class, %params ) = @_;
    $params{'timeout'} //= 30;
    my $self = $class->SUPER::new( %params );
    return $self;
};

sub _get_request_headers {
    my( $self ) = @_;
    my $headers = {
        'Accept'            => '*/*',
        'User-Agent'        => 'HiPi_Agent',
        'Content-Type'      => 'text/html; charset=UTF-8',
    };
    
    if( $self->manual_cookie ) {
        $headers->{'Cookie'} =  $self->manual_cookie;
    }
    
    if( $self->request_token ) {
        # we need to prefix with a colon or Perl modules will transform
        # underscores to dashes.(Took a while to figure out)
        $headers->{':__RequestVerificationToken'} =  $self->request_token;
    }
    
    return $headers;
}

sub _decode_xml {
    my($self, $xml) = @_;
    my $parser = XML::LibXML->new();
    my $dom = $parser->load_xml( string => $xml );
    my $ref = $self->_xml_node_to_hash( $dom );
    $ref = $self->_normalise_response_ref($ref);
    $ref = $ref->{'response'} || $ref->{'error'} || $ref->{'config'}; 
    if(ref($ref)) {
        return $ref;
    } elsif($ref && $ref eq 'OK') {
        return { success => 'OK'};
    } else {
        return { code => 106 };
    }
}

sub _xml_node_to_hash {
    my ($self, $node) = @_;
    my $ref = {};
    my $text = '';
    my $elementcount = 0;
    my @attributes = $node->attributes;
    
    for ( @attributes ) {
        next unless defined($_);
        my $aname = $_->localName;
        $ref->{$aname} = $_->value;
    }

    for my $child ($node->childNodes) {
        if( $child->isa('XML::LibXML::Element') ){
            $elementcount ++;
            my $childname = $child->localName;
            $ref->{$childname} = [] unless exists($ref->{$childname});
            my $subref = $self->_xml_node_to_hash($child);
            push @{ $ref->{$childname} }, $subref;
        } elsif( $child->isa('XML::LibXML::Text') ) {
            $text .= $child->textContent();
        }
    }

    $ref->{value} = $text if( defined($text) && !$elementcount );
    return $ref;
}

sub _normalise_response_ref {
    my ( $self, $input ) = @_;
    my $output = {};
    if(ref($input) eq 'HASH') {
        my @hkeys = keys %$input;
        for my $hkey ( @hkeys ) {
            if(exists($arrayelements->{$hkey})) {
                my $innerkey = $arrayelements->{$hkey};
                $output->{$hkey} = [];
                for my $inneritem ( @{ $input->{$hkey}->[0]->{$innerkey} } ) {
                    my $member = $self->_normalise_response_ref( $inneritem );
                    push @{ $output->{$hkey} }, $member;
                }
            } else {
                $output->{$hkey} = $self->_normalise_response_ref( $input->{$hkey} );
            }
        }
    } elsif(ref($input) eq 'ARRAY') {
        if(scalar(@$input) == 0) {
            $output = [];
        } elsif( scalar(@$input) == 1 ) {
            if(exists($input->[0]->{'value'})) {
                $output = $input->[0]->{'value'};
            } else {
                $output = $self->_normalise_response_ref($input->[0]);
            }
        } else {
            $output = [];
            for my $item ( @$input ) {
                if(exists($item->{'value'})) {
                    push @$output,  $item->{'value'};
                } else {
                    push @$output,  $self->_normalise_response_ref($item);
                }
            }
        }
        
    } else {
        $output = $input;
    }
    return $output;
}

sub set_security {
    my($self, $sessid, $tokid) = @_;
    $self->manual_cookie( $sessid );
    $self->request_token( $tokid );
    return 1;
}

sub clear_security {
    my ($self) = @_;
    $self->manual_cookie( undef );
    $self->request_token( undef );
    return 1;
}

sub get {
    my ( $self, $url ) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->timeout($self->timeout);
    my $headers = $self->_get_request_headers;
    my $retref = { 'code' => 400 };
    
    try {
        
        my $resp = $ua->get( $url, %$headers );
        
        if( $self->debug ) {
            print qq(--------------START REQUEST--------------------\n);
            print qq(REQUEST URL : $url\n);
            print qq(REQUEST HEADERS\n);
            print $resp->request->headers->as_string;
            print qq(\nRESPONSE\n\n);
            print $resp->as_string;
            print qq(---------------END REQUEST---------------------\n\n);
        }
        
        if($resp->is_success) {
            my $ref = $self->_decode_xml( $resp->content );
            if( my $setcookie = $resp->header('Set-Cookie') ) {
                chomp $setcookie;
                $self->manual_cookie( $setcookie );
            }
            if( my $reqtoken = $resp->header('__RequestVerificationToken') ) {
                chomp $reqtoken;
                $self->request_token( $reqtoken );
            }
            $retref = $ref;
        } else {
            $retref->{code} = $resp->code;
            $retref->{message} = $resp->status_line
        }
    } catch {
        $retref->{message} = '' . $_;
    };
    
    return $retref;
}

sub post {
    my($self, $url, $xml) = @_;
    
    my $ua = LWP::UserAgent->new();
    $ua->timeout($self->timeout);
    
    my $headers = $self->_get_request_headers;
    
    my $retref = { code => 400 };

    try {
        
        my $octets = Encode::encode('UTF-8', $xml );
        
        my $resp = $ua->post( $url, %$headers, 'Content' => $octets );
        
        if( $self->debug ) {
            print qq(--------------START REQUEST--------------------\n);
            print qq(REQUEST URL : $url\n);
            print qq(REQUEST HEADERS\n);
            print $resp->request->headers->as_string;
            print qq(REQUEST BODY\n);
            print qq($octets\n);
            print qq(\nRESPONSE\n\n);
            print $resp->as_string;
            print qq(---------------END REQUEST---------------------\n\n);
        }
        
        if($resp->is_success) {
            my $ref = $self->_decode_xml( $resp->content );
            if( my $setcookie = $resp->header('Set-Cookie') ) {
                chomp $setcookie;
                $self->manual_cookie( $setcookie );
            }
            if( my $reqtoken = $resp->header('__RequestVerificationToken') ) {
                chomp $reqtoken;
                $self->request_token( $reqtoken );
            }
            $retref = $ref;
        } else {
            $retref->{code} = $resp->code;
            $retref->{message} = $resp->status_line
        }
    } catch {
        $retref->{message} = '' . $_;
    };
    
    return $retref;
}

1;
__END__