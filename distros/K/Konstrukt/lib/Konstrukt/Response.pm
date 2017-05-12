=head1 NAME

Konstrukt::Response - Class for everything related to the generated response

=head1 SYNOPSIS
	
	#set/get status code
	$Konstrukt::Response->status('200');
	my $s = $Konstrukt::Request->status();

	#set/get header
	$Konstrukt::Response->header('Content-Type' => 'text/html');
	my $c = $Konstrukt::Response->header('Content-Type');
	
	#all heades as hash ref
	my $h = $Konstrukt::Response->headers();
	
=head1 DESCRIPTION

This object will provide access to some response-related information for the
response, which is currently generated.

Usually you will only set data for the respons, but you may also read it.

To get the request data you should use L<Konstrukt::Request>.

It's similar to L<HTTP::Response> but without some methods, that are not needed here.

=cut

package Konstrukt::Response;

use strict;
use warnings;

=head1 METHODS

=head2 new

B<Parameters>:

To initialize the response object you can specify these optional keys:

	my $r = Konstrukt::Response->new(
		status  => '200',
		headers => {
			'Content-Type' => 'text/html'
		}
	);

=cut
sub new {
	my ($class, %init) = @_;
	
	my $self = bless { status => $init{status} }, $class;
	
	#add (normalized) header fields
	foreach my $field (keys %{$init{headers}}) {
		$self->header($field, $init{headers}->{$field}) if defined $init{headers}->{$field};
	}
	
	return $self;
}

=head2 status

Returns the current status code. If the status parameter is defined, the current
status code will be overwritten.

B<Parameters>: 

=over

=item * $status - Optional: When defined, this status code will replace the current
status code

=back

=cut
sub status {
	my ($self, $status) = @_;
	
	$self->{status} = $status if defined $status;
	return $self->{status};
}
#= /status

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

L<Konstrukt::Request>, L<Konstrukt::Handler>

=cut
