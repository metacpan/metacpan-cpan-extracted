#  Copyright (c) 2008-2009 Manni Heumann. All rights reserved.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#   Date: 2009-11-06
#   Revision: 43
#

package Google::SAML::Request;

=head1 NAME

Google::SAML::Request - Create or parse Google's SAML requests

=head1 VERSION

You are currently reading the documentation for version 0.05

=head1 DESCRIPTION

Google::SAML::Request will parse (and, for the sake of completeness, create)
SAML requests as used by Google. B<Please note> that Google::SAML::Request is by
no means a full implementation of the SAML 2.0 standard. But if you want to
talk to Google to authenticate users, you should be fine.

In fact, if you want to talk to Google about SSO, just use
L<Google::SAML::Response|Google::SAML::Response>
and you should be fine.

=head1 SYNOPSIS

Create a new request object by taking the request ouf of the CGI environment:

 use Google::SAML::Request;
 my $req = Google::SAML::Request->new_from_cgi();
 if ( $req->ProviderName() eq 'google.com'
    && $req->AssertionConsumerServiceURL() eq 'https://www.google.com/hosted/psosamldemo.net/acs' ) {

    processRequest();
 }
 else {
     print "go talk to someone else\n";
 }

Or use a request string that you get from somewhere else (but make sure that it is no longer
URI-escaped):

 use Google::SAML::Request;
 my $req = Google::SAML::Request->new_from_string( $request_string );
 if ( $req->ProviderName() eq 'google.com'
    && $req->AssertionConsumerServiceURL() eq 'https://www.google.com/hosted/psosamldemo.net/acs' ) {

    processRequest();
 }
 else {
     print "go talk to someone else\n";
 }

Or, finally, create a request from scratch and send that to somebody else:

 use Google::SAML::Request;
 my $req = Google::SAML::Request->new(
            {
                ProviderName => 'me.but.invalid',
                AssertionConsumerServiceURL => 'http://send.your.users.here.invalid/script',
            }
           );




=head1 PREREQUISITES

You will need the following modules installed:

=over

=item * L<MIME::Base64|MIME::Base64>

=item * L<Compress::Zlib|Compress::Zlib>

=item * L<Date::Format|Date::Format>

=item * L<XML::Simple|XML::Simple>

=item * L<URI::Escape|URI::Escape>

=item * L<CGI|CGI> (if you are going to use the 'new_from_cgi' constructor)

=back

=head1 METHODS

=cut

use strict;
use warnings;

use MIME::Base64;
use Compress::Zlib;
use Date::Format;
use Carp;
use XML::Simple;
use URI::Escape;


our $VERSION = '0.05';


=head2 new

Create a new Google::SAML::Request object from scratch.

You have to provide the needed parameters here. Some parameters
are optional and defaults are used if they are not supplied.

The parameters need to be passed in in a hash reference as
key value pairs.

=head3 Required parameters

=over

=item * ProviderName

Your name, e.g. 'google.com'

=item * AssertionConsumerServiceURL

The URL the user used to contact you. E.g. 'https://www.google.com/hosted/psosamldemo.net/acs'

=back

=head3 Optional parameters

=over

=item * IssueInstant

The time stamp for the Request. Default is I<now>.

=item * ID

If you need to create the ID yourself, use this option. Otherwise the ID is
generated from the current time and a pseudo-random number.

=back

=cut

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = {
        ProviderName
            => '',
        AssertionConsumerServiceURL
            => '',
        IssueInstant
            => time2str( "%Y-%m-%dT%XZ", time, 'UTC' ),
        ID
            => undef,
    };

    bless $self, $class;

    foreach my $required ( qw/ ProviderName AssertionConsumerServiceURL / ) {
        confess "You need to provide the $required parameter to Googe::SAML::Request::new()"
            unless exists $args->{ $required };
        $self->{ $required } = $args->{ $required };
    }

    foreach my $optional ( qw/ IssueInstant ID / ) {
        $self->{ $optional } = $args->{ $optional }
            if exists $args->{ $optional };
    }

    unless ( defined $self->{ ID } ) {
        $self->{ ID } = $self->_generate_id();
    }

    $self->{request} = {
          'ID'                          => $self->{ID},
          'Version'                     => '2.0',
          'xmlns:samlp'                 => 'urn:oasis:names:tc:SAML:2.0:protocol',
          'IssueInstant'                => $self->{IssueInstant},
          'ProviderName'                => $self->{ProviderName},
          'ProtocolBinding'             => 'urn:oasis:names.tc:SAML:2.0:bindings:HTTP-Redirect',
          'AssertionConsumerServiceURL' => $self->{AssertionConsumerServiceURL},
    };

    return $self;
}




=head2 new_from_cgi

Create a new Google::SAML::Request object by fishing it out of the CGI
environment.

If you provide a hash-ref with the key 'param_name' you can determine
which cgi parameter to use. The default is 'SAMLRequest'.

=cut

sub new_from_cgi {
    my $class = shift;
    my $args  = shift;

    my $self ={};
    bless $self, $class;

    require CGI;
    my $cgi = CGI->new();

    my $param = ( exists $args->{param_name} ) ? $args->{param_name} : 'SAMLRequest';
    my $request = $cgi->param( $param );

    if ( ! $request ) {
        warn "could not get request from cgi environment through parameter '$param'.";
    }
    elsif ( $self->_decode_saml_msg( $request ) ) {
        return $self;
    }

    return;
}






=head2 new_from_string

Pass in a (uri_unescaped!) string that contains the request string. The string
will be base64-unencoded, inflated and parsed. You'll get back a fresh
Google::SAML::Response object if the string can be parsed.

=cut

sub new_from_string {
    my $class  = shift;
    my $string = shift;

    my $self = {};
    bless $self, $class;

    if ( $self->_decode_saml_msg( $string ) ) {
        return $self;
    }
    else {
        return;
    }
}



=head2 get_xml

Returns the XML representation of the request.

=cut

sub get_xml {
    my $self = shift;

    if ( exists $self->{request} ) {
        return
            XMLout( $self->{request},
                    KeyAttr  => [ keys %{$self->{request}} ],
                    RootName => 'samlp:AuthnRequest',
                    XMLDecl  => 1
            );
    }
    else {
        confess "The request object hasn't even been made yet";
    }
}


=head2 get_get_param

No, that's not a typo. This method will return the request in a form
suitable to be used as a GET parameter. In other words, this method
will take the XML representation, compress it, base64-encode the result
and, finally, URI-escape that.

=cut

sub get_get_param {
    my $self = shift;

    my $xml = $self->get_xml();

    my ( $d, $status ) = deflateInit( -WindowBits => -&MAX_WBITS() );

    if ( $status == Z_OK && $d ) {
        my ( $compressed, $status ) = $d->deflate( $xml );
        $compressed .= $d->flush();

        if ( $status == Z_OK && length( $compressed ) ) {
            my $encoded = encode_base64( $compressed, '' );
            my $escaped = uri_escape( $encoded );

            return $escaped;
        }
        else {
            warn "Could not compress xml";
        }
    }
    else {
        warn "Could not initialise deflation stream.";
    }

    return;
}





sub _generate_id {
    my $self = shift;

    my $id = '';

    my $time = time;
    foreach ( split //, $time ) {
        $id .= chr( $_ + 97 );
    }

    foreach ( 1 .. 30 ) {
        $id .= chr( int(rand( 26 )) + 97 );
    }

    return $id;
}




sub _decode_saml_msg {
    my $self = shift;
	my $msg  = shift;

	my $decoded  = decode_base64( $msg );
    my $inflated = undef;

    foreach my $wbits ( -&MAX_WBITS(), &MAX_WBITS() ) {
        $inflated = $self->_inflate( $decoded, $wbits );
        last if defined $inflated;
    }

    if ( defined $inflated ) {
        $self->{request} = XMLin( $inflated, ForceArray => 0 );
        foreach ( qw/ ProviderName AssertionConsumerServiceURL ID IssueInstant / ) {
            $self->{ $_ } = $self->{request}->{ $_ };
        }

        return 1;
    }
    else {
        warn "Could not inflate base64-decoded string.";
    }

	return;
}




sub _inflate {
    my $self       = shift;
    my $string     = shift;
    my $windowBits = shift;

    my ( $i, $status ) = inflateInit( -WindowBits => $windowBits );

	if ( $status == Z_OK ) {
		my $inflated;
		($inflated, $status) = $i->inflate( $string );

		if ( $status == Z_OK || $status == Z_STREAM_END ) {
		    return $inflated;
		}
	}
	else {
	    warn "No inflater!";
	}

	return;
}

=head3 Accessor methods (read-only)

All of the following accessor methods return the value of the
attribute with the same name

=head2 AssertionConsumerServiceURL

=head2 ID

=head2 IssueInstant

=head2 ProtocolBinding

=head2 ProviderName

=head2 Version

=cut

sub AssertionConsumerServiceURL { return shift->{AssertionConsumerServiceURL}; }
sub ID { return shift->{ID}; }
sub IssueInstant { return shift->{IssueInstant}; }
sub ProviderName { return shift->{ProviderName}; }

=head1 SOURCE CODE

This module has a repository on github. Pull requests are welcome.

  https://github.com/mannih/Google-SAML-Request/

=head1 AUTHOR

Manni Heumann (saml at lxxi dot org)


=head1 LICENSE

Copyright (c) 2008 Manni Heumann. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
