#TODO: add env()-method and remove $Konstrukt::Handler->{ENV}
#TODO: move $Konstrukt::Handler->{abs_filename} and $Konstrukt::Handler->{filename} to this object
#FEATURE: cookie handling? currently done through $Konstrukt::Handler->{cookies} and CGI::Cookie->new();
#FEATURE: add network address of the requesting host (although its in the ENV?)

=head1 NAME

Konstrukt::Request - Class for everything related to the page request

=head1 SYNOPSIS
	
	#set/get request method
	$Konstrukt::Request->method('GET');
	my $m = $Konstrukt::Request->method();
	
	#set/get requested uri
	$Konstrukt::Request->uri('/foo');
	my $u = $Konstrukt::Request->uri();
	
	#set/get header
	$Konstrukt::Request->header('Content-Type' => 'text/html');
	my $c = $Konstrukt::Request->header('Content-Type');
	
	#all heades as hash ref
	my $h = $Konstrukt::Response->headers();
	
=head1 DESCRIPTION

This object will provide access to the request, which is currently processed.
Usually you will only retrieve data from the request, but you may also set it.

To set response parameters you should use L<Konstrukt::Response>.

It's similar to L<HTTP::Request> but without some methods, that are not needed here.

=cut

package Konstrukt::Request;

use strict;
use warnings;

=head1 METHODS

=head2 new

B<Parameters>:

To initialize the request object you can specify these optional keys:

	my $r = Konstrukt::Request->new(
		uri     => '/foo',
		method  => 'GET',
		headers => {
			Accept => 'text/html'
		}
	);

=cut
sub new {
	my ($class, %init) = @_;
	
	my $self = bless { uri => $init{uri}, method => $init{method} }, $class;
	
	#add (normalized) header fields
	foreach my $field (keys %{$init{headers}}) {
		$self->header($field, $init{headers}->{$field}) if defined $init{headers}->{$field};
	}
	
	return $self;
}

=head2 uri

Returns the current URI. If the URI parameter is defined, the current URI will
be overwritten.

B<Parameters>: 

=over

=item * $uri - Optional: When defined, this URI will replace the current URI

=back

=cut
sub uri {
	my ($self, $uri) = @_;
	
	$self->{uri} = $uri if defined $uri;
	return $self->{uri};
}
#= /uri

=head2 method

Returns the current method. If the method parameter is defined, the current method will
be overwritten.

B<Parameters>: 

=over

=item * $method - Optional: When defined, this method will replace the current method

=back

=cut
sub method {
	my ($self, $method) = @_;
	
	$self->{method} = $method if defined $method;
	return $self->{method};
}
#= /method

=head2 header

Returns the value of the requested header field or undef, if no such header field
exists. If the value parameter is defined, the current value for the specified
header field will be overwritten.

B<Parameters>: 

=over

=item * $field - The header field

=item * $value - Optional: When defined, this value will replace the current
value for the specified header field

=back

=cut
sub header {
	my ($self, $field, $value) = @_;
	
	#normalize field
	$field =~ tr/_/-/;
	$field = lc $field;
	$field =~ s/\b(\w)/\u$1/g;
	
	$self->{headers}->{$field} = $value if defined $value;
	return exists $self->{headers}->{$field} ? $self->{headers}->{$field} : undef;
}
#= /header

=head2 headers

Returns a hash reference containing all set header fields and the appropriate
values.

=cut
sub headers {
	my ($self) = @_;
	return $self->{headers};
}
#= /headers

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Response>, L<Konstrukt::Handler>

=cut
