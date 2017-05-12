##@file
# SAML Metadata object for Lemonldap::NG

##@class
# SAML Metadata object for Lemonldap::NG
package Lemonldap::NG::Common::Conf::SAML::Metadata;

use strict;
use utf8;
use warnings;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use Data::Dumper;
use HTML::Template;
use MIME::Base64;
use XML::Simple;
use Safe;
use Encode;

our $VERSION = '1.9.1';

## @cmethod Lemonldap::NG::Common::Conf::SAML::Metadata new(hashRef args)
# Class constructor.
# @param args hash reference
# @return Lemonldap::NG::Common::Conf::SAML::Metadata object
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    if ( ref( $_[0] ) ) {
        %$self = %{ $_[0] };
    }
    elsif ( (@_) && $#_ % 2 == 1 ) {
        %$self = @_;
    }
    return $self;
}

## @method public boolean initiliazeFromConf(string s)
# Initialize this object from configuration string.
# @param $s Configuration string.
# @return boolean
sub initializeFromConf {
    my $self   = shift;
    my $string = shift;

    $string =~ s/&#39;/'/g;
    my $data = eval $string;

    return $self->initializeFromConfHash($data);
}

## @method public boolean initiliazeFromConfHash(hash h)
# Initialize this object from configuration hash element.
# @param $h Configuration hash element.
# @return boolean
sub initializeFromConfHash {
    my $self = shift;
    my $hash = shift;

    return 0 unless $hash;

    foreach my $k ( keys %$hash ) {
        $self->{$k} = $hash->{$k};
    }

    return 1;
}

## @method public boolean initializeFromFile(string file)
# Initialize this object from XML file.
# @param $file Filename
# @return boolean
sub initializeFromFile {
    my $self = shift;
    my $file = shift;
    my $xml  = $self->_loadFile($file);
    if ( !$xml ) {
        return 0;
    }
    return $self->initializeFromXML($xml);
}

## @method public boolean initializeFromXML(string string)
# Initialize this object from configuration XML string.
# @param $string Configuration XML string.
# @return boolean
sub initializeFromXML {
    my $self   = shift;
    my $string = shift;

    # Remove spaces
    $string =~ s/[\n\r\s]+/ /g;
    $string =~ s/> </></g;

    # New XML::Simple object
    my $xs = XML::Simple->new( ForceContent => 1, ForceArray => 1 );
    my $data = $xs->XMLin($string);

    # Store data in Metadata object
    if ($data) {
        foreach my $k ( keys %{$data} ) {
            $self->{$k} = $data->{$k};
        }
        return 1;
    }
    return 0;

}

## @method public string serviceToXML
# Return all SAML parameters in well formated XML format, corresponding to
# SAML 2 description.
# @return string
sub serviceToXML {
    my ( $self, $file, $conf ) = @_;

    my $template = HTML::Template->new(
        filename          => "$file",
        die_on_bad_params => 0,
        cache             => 0,
    );

    # Automatic parameters
    my @param_auto = qw(
      samlEntityID
      samlOrganizationName
      samlOrganizationDisplayName
      samlOrganizationURL
    );

    foreach (@param_auto) {
        $template->param( $_, $self->getValue( $_, $conf ) );
    }

    # Boolean parameters
    my @param_boolean = qw(
      samlSPSSODescriptorAuthnRequestsSigned
      samlSPSSODescriptorWantAssertionsSigned
      samlIDPSSODescriptorWantAuthnRequestsSigned
    );

    foreach (@param_boolean) {
        $template->param( $_, $self->getValue( $_, $conf ) ? 'true' : 'false' );
    }

    # Format public keys
    my @param_keys = qw(
      samlServicePublicKeySig
      samlServicePublicKeyEnc
    );

    foreach (@param_keys) {
        my $str = '';
        my $val = $self->getValue( $_, $conf );

        # A default value for samlServicePublicKeyEnc parameter
        if ( $_ =~ /samlServicePublicKeyEnc/ ) {
            unless ( $val && length $val gt 0 ) {
                $val = $conf->{samlServicePublicKeySig};
            }
        }

        # Generate XML
        if ( defined $val && length $val gt 0 ) {

            # Public Key ?
            if ( $val =~ /^-----BEGIN PUBLIC KEY-----/
                and my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($val) )
            {
                my @params = $rsa_pub->get_key_parameters();
                my $mod    = encode_base64( $params[0]->to_bin() );
                my $exp    = encode_base64( $params[1]->to_bin() );
                $str =
                    '<ds:KeyValue>' . "\n\t"
                  . '<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">'
                  . "\n\t\t"
                  . '<Modulus>'
                  . $mod
                  . '</Modulus>'
                  . "\n\t\t"
                  . '<Exponent>'
                  . $exp
                  . '</Exponent>' . "\n\t"
                  . '</RSAKeyValue>' . "\n"
                  . '</ds:KeyValue>';
            }

            # Certificate ?
            if ( $val =~ /^-----BEGIN CERTIFICATE-----/
                and my $certificate =
                Crypt::OpenSSL::X509->new_from_string($val) )
            {
                $certificate = $certificate->as_string();
                $certificate =~ s/^-----BEGIN CERTIFICATE-----\n?//g;
                $certificate =~ s/\n?-----END CERTIFICATE-----$//g;
                $str =
                    '<ds:X509Data>' . "\n\t"
                  . '<ds:X509Certificate>' . "\n\t"
                  . $certificate
                  . '</ds:X509Certificate>' . "\n"
                  . '</ds:X509Data>';
            }
        }
        $template->param( $_, $str );
    }

    # Rebuilded parameters for SAML services
    # A samlService value is formated like the following:
    # "binding;location;responseLocation"
    # The last value, responseLocation, is optional.
    my @param_service = qw(
      samlSPSSODescriptorSingleLogoutServiceHTTPRedirect
      samlSPSSODescriptorSingleLogoutServiceHTTPPost
      samlSPSSODescriptorSingleLogoutServiceSOAP
      samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect
      samlIDPSSODescriptorSingleSignOnServiceHTTPPost
      samlIDPSSODescriptorSingleSignOnServiceHTTPArtifact
      samlIDPSSODescriptorSingleSignOnServiceSOAP
      samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect
      samlIDPSSODescriptorSingleLogoutServiceHTTPPost
      samlIDPSSODescriptorSingleLogoutServiceSOAP
      samlAttributeAuthorityDescriptorAttributeServiceSOAP
    );

    foreach (@param_service) {
        my @_tab = split( /;/, $self->getValue( $_, $conf ) );
        $template->param( $_ . 'Binding',          $_tab[0] );
        $template->param( $_ . 'Location',         $_tab[1] );
        $template->param( $_ . 'ResponseLocation', $_tab[2] );
    }

    # Rebuilded parameters for SAML assertions
    # A samlAssertion value is formated like the following:
    # "default;index;binding;location"
    my @param_assertion = qw(
      samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact
      samlSPSSODescriptorAssertionConsumerServiceHTTPPost
      samlSPSSODescriptorArtifactResolutionServiceArtifact
      samlIDPSSODescriptorArtifactResolutionServiceArtifact
    );

    foreach (@param_assertion) {
        my @_tab = split( /;/, $self->getValue( $_, $conf ) );
        $template->param( $_ . 'Default', $_tab[0] ? 'true' : 'false' );
        $template->param( $_ . 'Index',   $_tab[1] );
        $template->param( $_ . 'Binding', $_tab[2] );
        $template->param( $_ . 'Location', $_tab[3] );
    }

    # Return the XML metadata.
    return $template->output;
}

## @method public string toXML
# Return this object in XML format.
# @return string
sub toXML {
    my $self = shift;

    # Use XML::Simple to Dump Perl Hash in XML format
    my $xs = XML::Simple->new( RootName => "md:EntityDescriptor" );

    # Force xmlns:md key
    $self->{"xmlns:md"} = "urn:oasis:names:tc:SAML:2.0:metadata"
      unless defined $self->{"xmlns:md"};

    # Serialize XML
    my $xml = $xs->XMLout($self);

    # Force UTF-8 encoding
    my $xml_utf8 = encode( "utf8", $xml );

    # XML schema requires Exponent after Modulus in KeyInfo
    $xml_utf8 =~
s#<Exponent>(.+)</Exponent>\s*<Modulus>(.+)</Modulus>#<Modulus>$2</Modulus>\n<Exponent>$1</Exponent>#mg;

    return $xml_utf8;
}

## @method public string toConf ()
# Return this object in configuration string format.
# @return string
sub toConf {
    my $self   = shift;
    my $fields = $self->toHash();
    local $Data::Dumper::Indent  = 0;
    local $Data::Dumper::Varname = "data";
    my $data = Dumper($fields);
    $data =~ s/^\s*(.*?)\s*$/$1/;
    $data =~ s/'/&#39;/g;
    $data =~ s/^\$data[0-9]*\s*=\s*({?\s*.+\s*}?)/$1/g;
    return $data;
}

## @method public string toHash ()
# Return this object in configuration hash format.
# @return hashref
sub toHash {
    my $self   = shift;
    my $fields = ();
    foreach ( keys %$self ) {
        $fields->{$_} = $self->{$_};
    }
    return $fields;
}

## @method public hashref toStruct ()
# Return this object to be display into the Manager.
# NOT USED FOR THE MOMENT.
# @return hashref
sub toStruct {
    my $self   = shift;
    my $struct = ();
    foreach ( keys %$self ) {
        $struct->{$_} = $self->{$_};
    }
    return $self->_toStruct( '', $struct );
}

## @method private hashref _toStruct (string path, hashref node)
# Return a preformated structure to be stored into Manager structure.
# NOT USED FOR THE MOMENT.
# @param $path The path of the node.
# @param $node The current node into the hashref tree.
# @return hashref A structure to be inserted into Manager structure.
sub _toStruct {
    my $self = shift;
    my $path = shift;
    my $node = shift;
    if ( ref $node ) {
        my $struct = {
            _nodes => [],
            _help  => 'default'
        };
        my @nodes = ();
        my $tmpnode;
        if ( ref $node eq 'ARRAY' ) {

            # More than one value for the same key
            # Build a hash with indices
            my $i = 0;
            foreach (@$node) {
                $tmpnode->{$i} = $node->[$i];
            }
        }
        else {
            $tmpnode = $node;
        }
        foreach ( keys %$tmpnode ) {

            if ( $_ =~ /^xmlns/ ) {
                next;
            }
            my $key = $path . ' ' . $_;
            $key =~ s/^ +//g;
            my $data;

            $data = $self->_toStruct( $key, $tmpnode->{$_} );
            if ($data) {
                $struct->{$key} = $data;
                push @nodes, 'n:' . $key;
            }
            else {
                $struct->{$key} = 'text:/' . $_;
                push @nodes, $key;
            }
        }
        $struct->{_nodes} = \@nodes;
        return $struct;
    }
    return 0;
}

## @method public static boolean load(array files)
# Return an array of Metadata object.
# @param @files Array of filenames
# @return array of Metadata objects
sub load {
    my @files     = @_;
    my @metadatas = ();
    foreach (@files) {
        my $metadata = new Lemonldap::NG::Common::Conf::SAML::Metadata();
        if ( $metadata->initializeFromFile($_) ) {
            push @metadatas, $metadata;
        }
    }
    return @metadatas;
}

## @method private hashref _loadFile(string file)
# Load XML file as a XML string.
# @param $file Filename
# @return string
sub _loadFile {
    my $self = shift;
    my $file = shift;
    local $/ = undef;
    open FILE, $file
      or die "Couldn't open file: $!";
    my $string = <FILE>;
    close FILE;
    return $string;
}

#@method string getValue(string key, hashref conf)
# Get the value for a metadata configuration key
# Replace #PORTAL# macro
# @param key Configuration key
# @param conf Configuration hash ref
# @return value
sub getValue {
    my ( $self, $key, $conf ) = @_;

    # Get portal value
    my $portal = $conf->{portal} || "http://auth.example.com/";
    $portal =~ s/\/$//;

    # Try to get value for the given key in configuraiton
    my $value = $conf->{$key};
    return unless defined $value;

    # Replace #PORTAL# macro
    $value =~ s/#PORTAL#/$portal/g;

    # Return value
    return $value;
}

1;

