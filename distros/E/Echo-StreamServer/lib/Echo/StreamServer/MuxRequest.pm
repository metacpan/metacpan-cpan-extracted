package Echo::StreamServer::MuxRequest;

use 5.008008;
use strict;
use warnings;

use JSON;

our $VERSION = '0.01';

our @MUX_METHODS = ( 'search', 'count' );
our $MUX_MAX_REQUESTS = 100; # server-side limit

# ======================================================================
# JSON.pm calls TO_JSON() method on the blessed hash.
# This method returns a "plain" hash to render the document.
#
# NOTE: The convert_blessed flag must be set (false by default).
#	my $json = JSON->new->convert_blessed;
# ======================================================================
my $json = JSON->new->convert_blessed;

sub TO_JSON {
	my $self = shift;

	my %hash = %$self;
	return \%hash;
}

sub new {
	my ($package, $query, $api_method, $id) = @_;
	my %hash;

	unless (grep(m/^$api_method$/, @MUX_METHODS)) {
		die("MuxRequest Error: Invalid API method $api_method\n");
	}

	# Construct id code, when none is given.
	# TODO: time or sequence number?
	my $seq = 0;
	my $_id = "$api_method$seq";
	$_id = $id if (defined $id);

	%hash = (
		'method' => $api_method,
		'id' => $_id,
		'q' => $query,
	);

	my $obj = bless \%hash => $package;
	return $obj;
}

# Transform a MuxRequest objects list into a JSON document.
sub requests_json {
	my (@mux_requests_list) = @_;

	return $json->encode(\@mux_requests_list);
}

1;
__END__

=head1 NAME

Echo::StreamServer::MuxRequest - Items MUX API Utilities

=head1 SYNOPSIS

  use Echo::StreamServer::MuxRequest;
  use Echo::StreamServer::Items;

  # Create a MuxRequest objects list.
  my $count = new Echo::StreamServer::MuxRequest($eql_str, 'count');
  my $search = new Echo::StreamServer::MuxRequest($eql_str, 'search');
  my @mux_requests = ($count, $search);

  # Send @mux_requests to Echo.
  my $client = new Echo::StreamServer::Items();
  $client->mux(@mux_requests);

=head1 DESCRIPTION

The Items MUX API allows a single API call to C<multiplex> several requests.
The multiplexed requests are executed concurrently and independently by the Echo server.

The Echo::StreamServer::MuxRequest class builds one C<multiplexed> request.
This package provides utilities to the Items API, Echo::StreamServer::Items, method mux().

=head1 SEE ALSO

Echo::StreamServer::Items

=head1 AUTHOR

Andrew Droffner, E<lt>adroffne@advance.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Droffner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
