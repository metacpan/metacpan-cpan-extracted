###############################################################################
# Purpose : Load resources using LWP
# Author  : John Alden
# Created : Aug 2006
###############################################################################

package Email::MIME::CreateHTML::Resolver::LWP;

use strict;
use Carp;
use MIME::Types;
use LWP::UserAgent;

our $VERSION = '1.042';

sub new {
	my ($class, $options) = @_;
	$options ||= {};

	my $ua = LWP::UserAgent->new(agent => __PACKAGE__);
	$ua->env_proxy;

	# Stop us getting cached resources when they have been updated on the server
	$ua->default_header( 'Cache-Control' => 'no-cache' );
	$ua->default_header( 'Pragma' => 'no-cache' );

	my $self = {
		%$options,
		'UA' => $ua,
	};
	return bless($self, $class);
}

#Resource loader using LWP
sub get_resource {
	my ($self, $src) = @_;
	my $base = $self->{base};

	#Resolve URIs relative to optional base URI
	my $uri;
	if(defined $base) {
		require URI::WithBase;
		$uri = URI::WithBase->new_abs( $src, $base );
	} else {
		$uri = new URI($src);	
	}

	#Fetch resource from URI using LWP
	my $response = $self->{UA}->get($uri->as_string);
	croak( "Could not fetch ".$uri->as_string." : ".$response->status_line ) unless ($response->is_success);
	my $content = $response->content;
	DUMP("HTTP response", $response);

	#Filename
	my $path = $uri->path;
	my ($volume,$directories,$filename) = File::Spec->splitpath( $path );

	#Deduce MIME type and transfer encoding
	my ($mimetype, $encoding);
	if(defined $filename && length($filename)) {
		TRACE("Using file extension to deduce MIME type and transfer encoding");
		($mimetype, $encoding) = MIME::Types::by_suffix($filename);
	} else {
		$filename = 'index';
	}

	#If we have a content-type header we can make a more informed guess at MIME type
	if ($response->header('content-type')) {
		$mimetype = $response->header('content-type');
		TRACE("Content Type header: $mimetype");
		$mimetype = $1 if($mimetype =~ /(\S+);\s*charset=(.*)$/); #strip down to just a MIME type
	}
	
	#If all else fails then some conservative and general-purpose defaults are:
	$mimetype ||= 'application/octet-stream';
	$encoding ||= 'base64';
	
	#Return values expected from a resource callback
	return ($content, $filename, $mimetype, $encoding);		
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Email::MIME::CreateHTML::Resolver::LWP - uses LWP as a resource resolver

=head1 SYNOPSIS

	my $o = new Email::MIME::CreateHTML::Resolver::LWP(\%args)
	my ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=head1 DESCRIPTION

This is used by Email::MIME::CreateHTML to load resources.

=head1 METHODS

=over 4

=item $o = new Email::MIME::CreateHTML::Resolver::LWP(\%args)

%args can contain:

=over 4

=item base

Base URI to resolve URIs passed to get_resource.

=back

=item ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=back

=head1 AUTHOR

Tony Hennessy, Simon Flack and John Alden with additional contributions by
Ricardo Signes <rjbs@cpan.org> and Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT

(c) BBC 2005,2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut