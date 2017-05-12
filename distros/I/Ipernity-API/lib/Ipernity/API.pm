# Iperntiy::API
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id$
# Last modified: [ 2011-01-13 12:32:46 ]

### Module definitions {{{
package Ipernity::API;
use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5_hex);
use Ipernity::API::Request;
use LWP::UserAgent;
use XML::Simple;

our @ISA = qw(LWP::UserAgent);
our $VERSION = '0.10';
# }}}

### Module constructor / new() {{{
sub new
{

	### Define class and object
	my $class = shift;
	my $self = new LWP::UserAgent;

	### Read arguments
	my %args = @_;

	## Assign arguments to object
	foreach my $key ( keys %args )
	{

		$self->{ 'args' }->{ $key } = $args{ $key };

	}
	
	### For Ipernity we need an output format
	unless( defined( $self->{ 'args' }->{ 'outputformat' } ) )
	{

		$self->{ 'args' }->{ 'outputformat' } = 'xml';

	}

	### The API key is mandatory
	warn 'Please provide at least an API key' unless( defined( $self->{ 'args' }->{ 'api_key' } ) );

	### Reference object to class
	bless $self, $class;
	return $self;

}
# }}}

### Perform an API request / execute() {{{
sub execute
{

	### Get object and arguments
	my ( $self, %args ) = @_;

	### Assign them to my object
	foreach my $key ( keys %args )
	{

		$self->{ 'request' }->{ $key } = $args{ $key };

	};

	## Create a request object
	my $request = Ipernity::API::Request->new( %{ $self->{ 'request' } } );

	## Query the API object with the request
	$self->execute_request( $request );

}
# }}}

### Execute the API request and return a XML object / execute_hash() {{{
sub execute_hash
{

	### Get object and request
	my ( $self, %args ) = @_;

	## Initialize placeholer for old format setting
	my ( $oldformat );

	### For XML output we need to force the output format to be XML
	unless( lc( $self->{ 'args' }->{ 'outputformat' } ) eq 'xml' )
	{

		## Keep the old format type so we can restore it afterwards
		$oldformat = $self->{ 'args' }->{ 'outputformat' };

		## Set new output format
		$self->{ 'args' }->{ 'outputformat' } = 'xml';

	}

	### Execute the request and read response
	my $response = $self->execute( %args )->{ '_content' };

	### Generate a hashref out of the XML tree
	my $xml = new XML::Simple;
	my $xmlresult = $xml->XMLin(

		$response, 
		ForceContent => 1,
		ForceArray   => 1,

	);

	### Check the status of the request
	$self->CheckResponse( $xmlresult );

	## Restore old outputformat
	$self->{ 'args' }->{ 'outputformat' } = $oldformat if defined( $oldformat );

	### Return the XML hashref
	return $xmlresult;

}
# }}}

### Information placeholder for execute_xml / execute_xml() {{{
sub execute_xml
{

	## This function is deprecated
	return "execute_xml() has been renamed to execute_hash()";

}
# }}}

### Execute the API request / execute_request() {{{
sub execute_request
{

	### Get object and request
	my ( $self, $request ) = @_;

	## Generate a valid URI path
	$request->{ '_uri' }->path( $request->{ '_uri' }->path() . $request->{ 'args' }->{ 'method' } . '/' . $self->{ 'args' }->{ 'outputformat' } );

	### Add API key and secret to the request
	$request->{ 'args' }->{ 'api_key' } = $self->{ 'args' }->{ 'api_key' };
	$request->{ 'args' }->{ 'api_sig' } = $self->signargs( $request->{ 'args' } ) if( defined( $self->{ 'args' }->{ 'secret' } ) );

	### Encode the arguments and build a POST request
	$request->encode();
	
	### Call the API
	my $response = $self->request( $request );

	### Return the response
	return $response;

}
# }}}

### Sign arguments for authenticated call // signargs() {{{
sub signargs
{

	### Get object
	my ( $self, $args ) = @_;

	## Initialize placeholer for signed arguments
	my ( $signed_args );

	### Sort arguments
	foreach my $key ( sort { $a cmp $b } keys %{ $args } )
	{

		## Read value if it is set
		my $val = $args->{ $key } ? $args->{ $key } : '';

		## Skip the 'method'
		next if $key eq 'method';

		## Add key/value pair to sign arguments string
		$signed_args .= $key . $val;

	}

	## Add method if present
	$signed_args .= $args->{ 'method' } if defined( $args->{ 'method' } );

	## Add secret to the end
	$signed_args .= $self->{ 'args' }->{ 'secret' };

	### Return as MD5 Hex hash of signed arguments
	return md5_hex( $signed_args );

}
# }}}

### Fetch a Frob for the AuthToken request / fetchfrob() {{{
sub fetchfrob
{

	### Get object and initalize frob
	my $self = shift;
	my $frob = {};

	### Create an API request
	my $response = $self->execute_hash(

		'method' => 'auth.getFrob',

	);

	### Return the frob
	return $response->{ 'auth' }->[0]->{ 'frob' }->[0]->{ 'content' };

}
# }}}

### Build an AuthToken request URL / authurl {{{
sub authurl
{
	### Get object and arguments
	my ( $self, %args ) = @_;

	### Initalize placeholder for signed args
	my ( $signed_args );

	## Add api_key to provided arguements
	$args{ 'api_key' } = $self->{ 'args' }->{ 'api_key' };

	### Lets put the permissions into the main hash
	foreach my $permkey ( %{ $args{ 'perms' } } )
	{

		$args{ $permkey } = $args{ 'perms' }->{ $permkey };

	}

	## Delete permissions from arguments
	delete( $args{ 'perms' } );

	### Sort arguments and add them to $api_sig
	foreach my $key ( sort { $a cmp $b } keys %args )
	{

		## Skip if no key is defined
		next unless( defined( $args{ $key } ) );

		## Skip the method argument
		next if $key eq 'method';

		## Read value
		my $val = $args{ $key } ? $args{ $key } : '';

		## Add value/key to signed arguments list
		$signed_args .= $key . $val;

	}

	## Add method to signed arguments list
	$signed_args .= $args{ 'method' } if defined( $args{ 'method' } );

	## Add secret to signed arguments
	$signed_args .= $self->{ 'args' }->{ 'secret' };

	### Create MD5 hash out of the signed args
	my $api_sig = md5_hex( $signed_args );

	### Decide wether Auth URL to use
	my $url = 'http://www.ipernity.com/apps/authorize';

	### Build AuthURL
	my $authurl = $url . '?api_key=' . $args{ 'api_key' };

	## Add frob if defined
	$authurl .= '&frob=' . $args{ 'frob' } if defined( $args{ 'frob' } );

	## Add permission if any
	foreach my $permission ( keys %args )
	{

		## Add permissions to AuthURL string
		$authurl .= '&' . $permission . '=' . $args{ $permission } if $permission =~ /^perm_/;

	}

	## Add API signature to AuthURL string
	$authurl .= '&api_sig=' . $api_sig;

	### Return the AuthURL
	return $authurl;

}
# }}}

### Fetch the AuthToken / authtoken {{{
sub authtoken
{

	### Get object and frob
	my ( $self, $frob ) = @_;

	### Create an API request
	my $response = $self->execute_hash(

		'method' => 'auth.getToken',
		'frob'	 => $frob,

	);

	### Let's safe the auth token and user information
	$self->{ 'auth' }->{ 'authtoken' } = $response->{ 'auth' }->[0]->{ 'token' }->[0]->{ 'content' };
	$self->{ 'auth' }->{ 'realname' }  = $response->{ 'auth' }->[0]->{ 'user' }->[0]->{ 'realname' };
	$self->{ 'auth' }->{ 'userid' }    = $response->{ 'auth' }->[0]->{ 'user' }->[0]->{ 'user_id' };
	$self->{ 'auth' }->{ 'username' }  = $response->{ 'auth' }->[0]->{ 'user' }->[0]->{ 'username' };

	### Return the AuthToken
	return $response->{ 'auth' }->[0]->{ 'token' }->[0]->{ 'content' };

}
# }}}

### Check the API status code and return an error if unsuccessfull // CheckResponse() {{{
sub CheckResponse
{
	### Get the object and XML hashref
	my ( $self, $xmlhash ) = @_;

	## Initialize placeholder for code and msg
	my ( $code, $msg );

	### Get the status;
	my $status = $xmlhash->{ 'status' };

	### We caught an error - let's die!
	if( lc( $status ) ne 'ok' )
	{
		
		## Get code and message of the error
		$code = $xmlhash->{ 'code' };
		$msg  = $xmlhash->{ 'message' };

		## Croak the error
		croak( 'An API call caught an unexpected error: ' . $msg . ' (Error Code: ' . $code . ')' );
	}

	### Otherwise everthing is fine
	return undef;

}
# }}}

1;
__END__

=head1 NAME

Ipernity::API - Perl interface to the Ipernity API

=head1 SYNOPSIS

	use Ipernity::API;
	
	my $api = Ipernity::API->new(

		'api_key'	=> '12345678901234567890123456789012',
		'secret'	=> '0123456789012345',
		'outputformat'	=> 'xml',

	);

	my $raw_response = $api->execute(

		'method'	=> 'test.hello',

	);

	my $hash = $api->execute_hash(

		'method'	=> 'test.hello',
		'auth_token'	=> '12345-123-1234567890',

	);
	
	my $frob = $api->fetchfrob();

	my $authurl = $api->authurl(

		'frob'		=> $frob,
		'perms'		=> {

			'perm_doc'	=> 'read',
			'perm_network'	=> 'write',
			'perm_blog'	=> 'delete',

		},

	);

	my $token = $api->authtoken( $frob );

	### After fetching the authtoken, all useful user information are
	### stored in the $api->{ 'auth' } section for later usage

	my $username  = $api->{ 'auth' }->{ 'username' };
	my $user_id   = $api->{ 'auth' }->{ 'userid' };
	my $realname  = $api->{ 'auth' }->{ 'realname' };
	my $authtoken = $api->{ 'auth' }->{ 'authtoken' };

=head1 DESCRIPTION

Ipernity::API is a full implementation of the Ipernity API interface. It uses
LWP::UserAgent to communicate with the API and returns the results in the 3
possible formats (provided by Ipernity): JSON, XML, SOAP, XML-RPC

=head1 METHODS

=over 4

=item B<new>( configuration arguments )

The constructor takes a single arguments with all needed configuration values.
B<api_key> and B<secret> are mandatory values. The B<outputformat> is optional and
will be set to XML if not defined.

=item B<fetchfrob>()

This method fetches a frob from Ipernity, which later can be used to generate and
authentication URL and an AuthToken

=item B<authurl>( config arguments )

Generates an authentication URL which can be provided to the user. This is needed
so that the user can confirm that he grants permissions to the script. This method
requires a B<frob> and a B<perms> parameter to be set.

=item B<authtoken>( frob )

Will fetch the AuthToken from Ipernity for later usage (for authenticated API calls).
This method requires a valid frob to be provided as argument.

=item B<execute>( ipernity parameters )

Calling this method will execute the provided method together with its options on
the Ipernity API. As result the method returns the raw answer from the API so that
the script can take care of parsing the output from Ipernity on its own

=item B<execute_hash>( ipernity parameters )

Works similar to B<execute>() but returns a hashref for easy access to the results
from Ipernity

=back

=head1 CAVEATS

Since version 0.07 the execute_hash() function always returns arrays, even
if the XML result would be only one. Please not that you might have to adjust
your code, in case you are upgradeing to v0.07 (which is highly recommended).

Starting with verseion 0.09 the new() constructor doesn't accept a hashref of
configuration parameters anymore, but will now require the single key/value
pairs provided to the constructor directly. If you are upgrading to 0.09 you
will have to adjust your code, so that will with work with newer setup.

=head1 DEVELOPMENT

The latest (development) version of Ipernity::API is always available via GIT
at: http://nop.li/ipernityapi

=head1 AUTHOR

Winfried Neessen, E<lt>doomy@dokuleser.org<gt>

=head1 REQUIRES

Perl 5, URI, HTTP::Request, XML::Simple, LWP::UserAgent, Digest::MD5

=head1 BUGS

Please report bugs in the CPAN bug tracker.

=head1 COPYRIGHT

Copyright (c) 2008-2010, Winfried Neessen <doomy@dokuleser.org>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the neessen.net nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
