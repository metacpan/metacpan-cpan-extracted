package Ham::Reference::Callook;

# --------------------------------------------------------------------------
# Ham::Reference::Callook - An interface to the Callook.info Database Service
#
# Copyright (c) 2010-2011 Brad McConahay N8QQ.
# Cincinnati, Ohio USA
# --------------------------------------------------------------------------

use strict;
use warnings;
use XML::Simple;
use LWP::UserAgent;
use vars qw($VERSION);

our $VERSION = '0.02';

my $callook_url = "http://callook.info/";
my $site_name = 'Callook.info';
my $default_timeout = 10;
my $default_type = 'xml';

sub new
{
	my $class = shift;
	my %args = @_;
	my $self = {};
	bless $self, $class;
	$self->_clear_errors;
	$self->_set_agent;
	$self->timeout($args{timeout});
	$self->type($args{type});
	return($self);
}

sub listing
{
	my $self = shift;
	my $callsign = shift;
	$self->_clear_errors;
	$callsign =~ tr/a-z/A-Z/;
	$self->{_callsign} = $callsign;
	my $url = "$callook_url/$self->{_callsign}/$self->{_type}";
	if ($self->{_type} eq 'text')
	{
		$self->{_data} = $self->_get_http($url);
	}
	elsif ($self->{_type} eq 'xml')
	{
		$self->{_data} = $self->_get_xml($url);
	}
	else # unknown type
	{
		$self->{is_error} = 1;
		$self->{error_message} = "Unknown type: $self->{_type}";
		$self->{_data} = undef;
	}
	return $self->{_data};
}

sub timeout
{
	my $self = shift;
	my $timeout = shift || $default_timeout;
	$self->{_timeout} = $timeout;
}

sub type
{
	my $self = shift;
	my $type = shift || $default_type;
	$self->{_type} = $type;
}

sub is_error { my $self = shift; $self->{is_error} }
sub error_message { my $self = shift; $self->{error_message} }


# -----------------------
#	PRIVATE
# -----------------------

sub _set_agent
{
	my $self = shift;
	$self->{_agent} = "Perl-Module-Ham-Reference-Callook-$VERSION";
}

sub _get_xml
{
	my $self = shift;
	my $url = shift;
	my $content = $self->_get_http($url);
	return undef if $self->{is_error};
	chomp $content;
	$content =~ s/(\r|\n)//g;
	my $xs = XML::Simple->new( SuppressEmpty => 0 );
	my $data = $xs->XMLin($content);
	return $data;
}

sub _get_http
{
	my $self = shift;
	my $url = shift;
	$self->_clear_errors;
	my $ua = LWP::UserAgent->new( timeout=>$self->{_timeout} );
	$ua->agent( $self->{_agent} );
	my $request = HTTP::Request->new('GET', $url);
	my $response = $ua->request($request);
	if (!$response->is_success) {
		$self->{is_error} = 1;
		$self->{error_message} = "Could not contact $site_name - ".HTTP::Status::status_message($response->code);
		return undef;
	}
	return $response->content;
}

sub _clear_errors
{
	my $self = shift;
	$self->{is_error} = 0;
	$self->{error_message} = '';
}


1;
__END__

=head1 NAME

Ham::Reference::Callook - An object oriented front end for the Callook.info callsign API

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 use Ham::Reference::Callook;
 my $callook = Ham::Reference::Callook->new;

 # get the listing data for a callsign
 my $listing = $callook->listing('N8QQ');

 # print some info
 print "Name: $listing->{name}\n";

 # examine the entire hashref of callsign data
 use Data::Dumper;
 print Dumper($listing);

 # get data for another callsign in text format and print the block of text
 $callook->type('text');
 print $callook->listing('W8IRC');


=head1 DESCRIPTION

The C<Ham::Reference::Callook> module provides an easy object oriented front end to access Amateur Radio
callsign data made available from the Callook.info web site.

To help ensure foward compatibility with the data from the FCC provided by Callook.info, this module does
not attempt to manage or filter individual data elements of a callsign.  You will need to inspect the hash
reference keys to see which elements are available for any given callsign, as demonstrated in the synopsis.

=head1 CONSTRUCTOR

=head2 new()

 Usage    : my $callook = Ham::Reference::Callook->new;
 Function : creates a new Ham::Reference::Callook object
 Returns  : a Ham::Reference::Callook object
 Args     : a hash:

            key       required?   value
            -------   ---------   -----
            timeout   no          an integer of seconds to wait for
                                   the timeout of the xml site
                                   default = 10
            type      no          possible values are xml or text
                                   'xml' will cause the listing to be
                                   returned as a hash reference whose
                                   structure matches the XML returned
                                   from the Callook.info API.
                                   'text' will cause the listing to be
                                   returned as a single complete block
                                   of text in a scalar reference.
                                   default = xml

=head1 METHODS

=head2 listing()

 Usage    : $hashref = $callook->listing($callsign) - OR - $scalar = $callook->listing($callsign}
 Function : retrieves data for the standard listing of a callsign from Callook.info
 Returns  : a hash reference if type is 'xml' (the default), or a scalar if type is 'text'
 Args     : a scalar (the callsign)

=head2 type()

 Usage    : $callook->type($type}
 Function : sets the type of structure to retrieve when using the listing() method to get data 
 Returns  : n/a
 Args     : a scalar ('xml' or 'text')
 Notes    : 'xml' will cause the listing to be returned as a hash reference with a structure that
              matches the XML returned from the Callook.info API.
            'text' will cause the listing to be returned as a single complete block of text in a
              scalar reference.
            defaults to 'xml'

=head2 timeout()

 Usage    : $callook->timeout($seconds);
 Function : sets the number of seconds to wait on the API server before timing out
 Returns  : n/a
 Args     : an integer

=head2 is_error()

 Usage    : if ( $callook->is_error )
 Function : test for an error if one was returned from the call to the API site
 Returns  : a true value if there has been an error
 Args     : n/a

=head2 error_message()

 Usage    : $err_msg = $callook->error_message;
 Function : if there was an error message when trying to call the API site, this is it
 Returns  : a string (the error message)
 Args     : n/a

=head1 DEPENDENCIES

=over 4

=item * L<XML::Simple>

=item * L<LWP::UserAgent>

=item * An Internet connection

=back

=head1 TODO

=over 4

=item * Add ARRL section info.

=item * Improve this documentation.

=back

=head1 ACKNOWLEDGEMENTS

This module accesses data from the Callook.info site provided by Joshua Dick, W1JDD.  See http://callook.info

=head1 SEE ALSO

For more information about the data provided by Callook.info, see the API reference at http://callook.info/api_reference.php

=head1 AUTHOR

Brad McConahay N8QQ, C<< <brad at n8qq.com> >>

=head1 COPYRIGHT AND LICENSE

C<Ham::Reference::Callook> is Copyright (C) 2010 Brad McConahay N8QQ.

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.

