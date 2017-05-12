# Iperntiy::API::Request
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id$
# Last modified: [ 2011-01-13 12:32:58 ]

### Module definitions {{{
package Ipernity::API::Request;
use strict;
use warnings;
use HTTP::Request;
use URI;

our @ISA = qw(Ipernity::API HTTP::Request);
our $VERSION = '0.09';
# }}}

### Module constructor {{{
sub new
{

	### Define class and object and read arguments
	my ( $class, %args ) = @_;
	my $self = new HTTP::Request;

	## Initalize placeholder for API signature
	$self->{ 'api_sig' } = {};

	### Some static definitions
	$self->method( 'POST' );
	$self->uri( 'http://api.ipernity.com/api/' );
	$self->header( 'User-Agent' => 'Ipernity::API v' . $Ipernity::API::VERSION );

	### Assign arguments to my object
	foreach my $key ( keys %args )
	{

		$self->{ 'args' }->{ $key } = $args{ $key };

	}
	
	### We need a method to call at least!
	warn 'Please provide at least a calling method' unless( defined( $self->{ 'args' }->{ 'method' } ) );

	### Reference object to class
	bless $self, $class;
	return $self;

}
# }}}

### Encode arguements and build a HTTP request // encode() {{{
sub encode
{
	### Get objects
	my $self = shift;

	### Build an URI object
	my $uri = URI->new( 'http:' );

	### Build an HTTP valid request URI
	delete( $self->{ 'args' }->{ 'method' } );
	$uri->query_form( $self->{ 'args' } );
	my $content = $uri->query;
	my $length = length( $content );

	### Add POST fields to HTTP header
	$self->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
	if( defined( $content ) )
	{

		$self->header( 'Content-Length' => $length );
		$self->content( $content );

	}

}
# }}}


1;
__END__
=head1 NAME

Ipernity::API::Request

=head1 SYNOPSIS

To be invoked via Ipernity::API

=head1 DESCRIPTION

To be done.

=head1 AUTHOR

Winfried Neessen, E<lt>doomy@dokuleser.org<gt>

=head1 REQUIRES

Perl 5, URI, HTTP::Request, XML::Simple, LWP::UserAgent, Digest::MD5

=head1 BUGS

Please report bugs in the CPAN bug tracker.

=head1 COPYRIGHT

Copyright (C) 2008 by Winfried Neessen. Published under the terms of the Artistic
License 2.0.

=cut
