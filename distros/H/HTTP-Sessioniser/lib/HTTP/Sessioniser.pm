package HTTP::Sessioniser;

use 5.008008;
use strict;
use warnings;

# We don't actually use this, but if it isn't installed
# then HTTP::Response will silently not ungzip data
# Using it here will error if it is installed
use IO::Compress::Gzip;		

# Be sure to use version 0.05 of HTTP::Parser with the two patches submitted
# to the public CPAN bug tracker. 
use HTTP::Parser 0.05;
use Net::LibNIDS 0.02;
use Carp;

use AutoLoader qw(AUTOLOAD);

our $VERSION = '0.05';

=head1 NAME

HTTP::Sessioniser - Rebuild HTTP sessions from pcap streams

=head1 SYNOPSIS

  use HTTP::Sessioniser;

  # This will be called once per HTTP request/response pair
  sub my_callback {
    my ($request, $response, $info) = @_;

    # $request is HTTP::Request
    # $response is HTTP::Response
  }

  my $s = HTTP::Sessioniser->new();
  $s->parse_file('/path/to/file.pcap', \&my_callback);

=head1 DESCRIPTION

This module extracts HTTP sessions from pcap files with the help of Net::LibNIDS.

It will piece HTTP data back together and return a pair of HTTP::Request and 
HTTP::Response which correspond to one HTTP 'session'.

HTTP CONNECT sessions are dealt with specially: the first request/response pair will
be returned as normal, subsequent requests will be skipped (as they do not contain
HTTP requests or responses, only SSL data).

=head2 EXPORT

None by default.

=head2 Methods

=head3 new

  my $s = HTTP::Sessioniser->new();

Creates a new object.

=cut

sub new {
	my ($class, %args) = @_;

	my $self = bless({}, $class);

	# Store statistics about the number of files parsed, requests found, failed
	# requests.  Useful if the same instance of this is used to parse multiple files.
	$self->{statistics} = {};
	$self->{statistics}{open_connections} = 0;
	$self->{statistics}{total_connections} = 0;

	@{$self->{portlist}} = qw(80 443 8080 3128);

	return $self;
}

=head3 parse_file

  $s->parse_file('/path/to/file.pcap', \&callback);

Parses a pcap file using libnids, rebuilding pairs of HTTP::Request and HTTP::Response.  These will be passed to the callback function along with a hash of information about the current connection.

=cut

sub parse_file {
	my ($self, $filename, $callback) = @_;

	# Reset the current connections table
	$self->{connections} = {};

	# Set this so we have them inside the callback
	$self->{current_filename} = $filename;
	$self->{callback} = $callback;

	Net::LibNIDS::param::set_filename($filename);

	# Set a pcap filter, see the manpage for tcpdump for more information.  The manpage for
	# libnids explains why the 'or (..)' is required.
	my $bpf_ports = join(" or ", map { "port $_" } @{$self->{portlist}});
	Net::LibNIDS::param::set_pcap_filter($bpf_ports . ' or (ip[6:2] & 0x1fff != 0)');

	if (!Net::LibNIDS::init()) {
		warn "Uh oh, libnids failed to initialise!\n";
		warn "Check you have successfully built and installed the module first.\n";
		return;
	}

	# Set the callback function and run libnids
	my $data_callback = sub { $self->process_data(@_); };
	Net::LibNIDS::tcp_callback($data_callback);

	# libnids resets state for each new file, so reset counter
	$self->{statistics}{open_connections} = 0;
	Net::LibNIDS::run();

	# TODO: At the end, go through and return all requests that had no responses?
}

sub clear_statistics {
	my ($self) = @_;
	undef $self->{statistics};
	$self->{statistics} = {};
}

=head3 ports

  $s->ports( [ 80, 443, 8080, 3128 ] );
  my @p = $s->ports;

Set or return and array of ports we expect to see HTTP transmission on.  The default set of ports is 80, 443, 8080 and 3128.  

If you are looking for HTTP on other ports (e.g. proxying or application servers) then use this to set the filter appropriately.

=cut

sub ports {
	my ($self, @ports) = @_;

	if (@ports) {
		$self->{portlist} = qw();

		foreach my $p (@ports) {
			push(@{$self->{portlist}}, $p) if $p =~ /\d+/ and ($p >= 0 or $p <= 65535);
		}

		# TODO: If our portlist is empty here, should we reset it?
	}
	return @{$self->{portlist}};
}

=head3 add_port

  $s->add_port(8000);

Add one port to the filter list.

=cut
sub add_port {
	my ($self, $tcpport) = @_;
	return 0 if $tcpport !~ /^\d+$/;
	return 0 if $tcpport < 0 or $tcpport > 65535;

	push(@{$self->{portlist}}, $tcpport);
	return $tcpport;
}

# The libnids callback
sub process_data {
	my ($self, $args) = @_;
	my $key = $args->client_ip . ":" . $args->client_port . "-" . $args->server_ip . ":" . $args->server_port;

	# If we want to stop processing a certain connection, we need
	# to skip any new events for it.  Turning libnids collect_off
	# doesn't work, it will send NIDS_JUST_EST for new packets.
	if (defined $self->{connections}{$key}{ignored}) {
		return;
	}

	if($args->state != Net::LibNIDS::NIDS_JUST_EST() && !defined $self->{connections}{$key}{request_obj}) {
		#print "ERROR: not just established and no object in $key\n";
		print "status was: " . $args->state . "\n";
		exit 1;
	}

	# Collect from any new connections
	if($args->state == Net::LibNIDS::NIDS_JUST_EST()) {
		$self->{statistics}{total_connections}++;
		$self->{statistics}{open_connections}++;

      		$args->server->collect_on();
      		$args->client->collect_on();

		# Create a request and response object
		$self->{connections}{$key}{request_obj} = HTTP::Parser->new(request => 1);
		$self->{connections}{$key}{response_obj} = HTTP::Parser->new(response => 1);

#		print STDERR "New connection: $key (" . $statistics{open_connections} . " open)\n";

	} elsif ($args->state == Net::LibNIDS::NIDS_CLOSE()) {

		# If this flag has been set, there was a successful response with
		# no content length header.  We can assume that the connection close
		# marks the end-of-data, so pass it back now
		if ($self->{connections}{$key}->{no_content_length}) {
#			print STDERR "DEBUG: No content length header, connection closed, assuming finished\n";
			$self->do_callback($key, $args);
		}
#		print "CLOSED CONNECTION EVENT FOR $key IS CALLING cleanup\n";
		$self->cleanup($key);
		return;

	} elsif (
          $args->state == Net::LibNIDS::NIDS_RESET() ||
          $args->state == Net::LibNIDS::NIDS_TIMED_OUT() ||
	      $args->state == Net::LibNIDS::NIDS_EXITING()
     ) {
		#print "EXIT/RESET CONNECTION EVENT FOR $key IS CALLING cleanup " . $args->state . "\n";
		$self->cleanup($key);
		return;

	} elsif ($args->state == Net::LibNIDS::NIDS_DATA()) {

		# Data toward the server
		if ($args->server->count_new) {
			#print "DEBUG: Parsing data client->server\n";
			my $data = substr($args->server->data, 0, $args->server->count_new);

			# We should not receive new data for a new request if one is already complete.
			# But HTTP pipelining is allowed, which might get us here.  So error.
			# TODO: Check HTTP::Parser when we hit this, or possibly implement pipelining
			if (defined $self->{connections}{$key}{request_complete}) {
				#print "ERROR: Got more client->server data when we we expecting server->client in $key\n";
				$self->stop_collecting($args, $key);
				return;
			}

			if (!defined $self->{connections}{$key}{request_time}) {
				$self->{connections}{$key}{request_time} = $args->lastpacket_sec;
				$self->{connections}{$key}{request_time_usec} = $args->lastpacket_usec;
			}

			my $status;
			eval {
				$status = $self->{connections}{$key}{request_obj}->add($data);
			};

			if ($@) {
				chomp $@;
				#print "ERROR: $key HTTP::Parser died for some reason ($@), data was:\n";
				$self->stop_collecting($args, $key);
				return;
			}

			# Once we have enough data, mark the request as complete
			if ($status == 0) {
				if ($self->{connections}{$key}{request_obj}->object->method eq 'CONNECT') {
					# Set a flag for the rest of this connection so it is not parsed
					$self->stop_collecting($args, $key);
					return;
				}
				$self->{connections}{$key}{request_complete} = 1;
#				print "DEBUG: We have a complete request now, data was $data\n";
			} else {
				#print "added to $key request:\n$data\nwhich got status $status\n";
			}

			return;
		}

		# Data toward the client
		if ($args->client->count_new) {
			my $data = substr($args->client->data, 0, $args->client->count_new);

			# Data from the server->client before we expected it.  Possibly HTTP pipelining, which
			# isn't yet supported.
			if (!defined $self->{connections}{$key}{request_complete}) {
				$self->stop_collecting($args, $key);
				return;
			}

			# Set the time from the first packet of the response
			if (!defined $self->{connections}{$key}{response_time}) {
				$self->{connections}{$key}{response_time} = $args->lastpacket_sec;
				$self->{connections}{$key}{response_time_usec} = $args->lastpacket_usec;
			}

			# HTTP::Parser uses die(), so catch that here
			my $status;
			eval {
				$status = $self->{connections}{$key}{response_obj}->add($data);
			};

			if ($@) {
				chomp $@;
#				print "ERROR: HTTP::Parser died for some reason in $key: $@\n";
				$self->stop_collecting($args, $key);
				return;
			}

			# Missing content-length header
			if ($status == -3) {
				# Set a flag to show that the response had no content-length header,
				# then assume at the end of this connection that we need to process it
				$self->{connections}{$key}{no_content_length} = 1;
			}

			# No more data needed
			if ($status == 0) {
				$self->do_callback($key, $args);

			}
			
			return;
		}
	}
}

# We have a complete HTTP transaction, return it to the user
sub do_callback {
	my ($self, $key, $nids_obj) = @_;

	my $request = $self->{connections}{$key}{request_obj}->object;
	my $response = $self->{connections}{$key}{response_obj}->object;

	# BUG: Shouldn't ever get this!
	if (!defined $request || !defined $response) {
		print "DEBUG: request or response is not defined in $key\n";
		exit 1;
	}

	my $info = { 
		'request_time' => $self->{connections}{$key}{request_time},
		'request_time_usec' => $self->{connections}{$key}{request_time_usec},
		'response_time' => $self->{connections}{$key}{response_time},
		'response_time_usec' => $self->{connections}{$key}{response_time_usec},
		'filename' => $self->{current_filename},
	    'client_ip' => $nids_obj->client_ip,
	    'server_ip' => $nids_obj->server_ip
	};

	$self->{callback}($request, $response, $info);

	# Reset state variables so that we can handle multiple HTTP
	# requests per TCP connection
	undef $self->{connections}{$key}{request_obj};
	undef $self->{connections}{$key}{response_obj};
	$self->{connections}{$key}{request_obj} = HTTP::Parser->new(request => 1);
	$self->{connections}{$key}{response_obj} = HTTP::Parser->new(response => 1);
	undef $self->{connections}{$key}{request_complete};
	undef $self->{connections}{$key}{request_time};
	undef $self->{connections}{$key}{response_time};

	return;
}

# Stop collecting on a connection for some reason
sub stop_collecting {
  my ($self, $args, $key) = @_;

  # TODO: Can we save the stream out as a pcap if it fails processing?

  # We could set libnids collect_off here, but it will just generate
  # NIDS_JUST_EST events for future packets.  So we don't bother.
  $self->cleanup($key);
  $self->{connections}{$key}{ignored} = 1;

  return;
}

# A connection has finished, cleanup any associated data
sub cleanup {
  my ($self, $key) = @_;

  delete $self->{connections}{$key};
  $self->{statistics}{open_connections}--;
}

=head1 BUGS

This module does not support HTTP pipelining.  It could be added if I find data which requires it.

=head1 SEE ALSO

HTTP::Parser - used to parse data into HTTP::Request or HTTP::Response objects

=head1 AUTHOR

David Cannings E<lt>david@edeca.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by David Cannings

=cut

1;
__END__

