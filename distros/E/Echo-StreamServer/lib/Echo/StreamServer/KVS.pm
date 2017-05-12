package Echo::StreamServer::KVS;

use 5.008008;
use strict;
use warnings;

use Echo::StreamServer::Client;
our @ISA = ( 'Echo::StreamServer::Client' );

use Echo::StreamServer::Core;
$Echo::StreamServer::Core::DEBUG=0;

# Serializer:
use Storable qw(nfreeze thaw);

our $VERSION = '0.02';

sub delete {
	my ($self, $key, $raise_not_found) = @_;

	my %params = (
		'key' => $key,
		'appkey' => $self->{'account'}->{'appkey'},
	);

	my $json_hash_ref;
	eval {
		$json_hash_ref = send_request($self->{'account'}, 'kvs/delete', \%params);
	};
	# Re-raise not_found StreamServer error.
	if ($@) {
		if ((not defined($raise_not_found)) and ($@ =~ m/\[not_found\]/)) {
			# not_found OK
		}
		else {
			die($@);
		}
	}
	return $json_hash_ref->{'result'};
}

sub get {
	my ($self, $key, $raise_not_found) = @_;

	my %params = (
		'key' => $key,
		'appkey' => $self->{'account'}->{'appkey'},
	);

	my $json_hash_ref;
	eval {
		$json_hash_ref = send_request($self->{'account'}, 'kvs/get', \%params);
	};
	# Re-raise not_found StreamServer error.
	if ($@) {
		if ((not defined($raise_not_found)) and ($@ =~ m/\[not_found\]/)) {
			# not_found OK
		}
		else {
			die($@);
		}
	}
	# Return value, when present (may be serialized).
	# De-serialize $value data-structure.
	my $value = thaw($json_hash_ref->{'value'});
	$value = ${ $value } if (ref($value) eq "SCALAR");
	return $value;
}

sub put {
	my ($self, $key, $value_ref, $public) = @_;

	# Serialize $value_ref data-structure.
	my %params = (
		'key' => $key,
		'value' => nfreeze($value_ref),
		'public' => ($public)? 'true': 'false',
	);

	my $json_hash_ref = send_request($self->{'account'}, 'kvs/put', \%params, 'post');

	# Return true on success.
	if (exists($json_hash_ref->{'result'}) and ($json_hash_ref->{'result'} eq 'success')) {
		return 1; # true
	}
	else {
		return 0; # false
	}
}

1;
__END__

=head1 NAME

Echo::StreamServer::KVS - Key-Value Store API

=head1 SYNOPSIS

  use Echo::StreamServer::Account;
  use Echo::StreamServer::KVS;

  my $acct = new Echo::StreamServer::Account($appkey, $secret);
  my $client = new Echo::StreamServer::KVS($acct);

  my %hash = ( 'a' => 'ok', 'b' => 1 ); 
  $client->put('sample', \%hash);
  my $sample_ref = $client->get('sample');
  $client->delete('sample');

  # Inspect KVS get reference to make PERL data.
  if (ref($sample_ref) eq "ARRAY") {
    @list = @{ $sample_ref };
  }

  if (ref($sample_ref) eq "HASH") {
    %hash = %{ $sample_ref };
  }

=head1 DESCRIPTION

The Key-Value Store API is Echo::StreamServer::KVS and requires an Echo::StreamServer::Account.

The store is a simple Key-Value database created to store the third-party widgets' arbitrary data elements permanently.
Keys are arbitrary strings. Values are never interpreted by Echo. Each data element has public flag indicating
if it is readable only by the owner or by everyone.

Each application key has its own independent store.

=head2 Client Methods

=over

=item C<delete>

Delete a data element by the C<$key>.

=item C<get>

Fetch a data element by the C<$key>.

=item C<put>

Save a data element to the store. The C<$public> flag indicates that it is readable by everyone.

=back

=head1 SEE ALSO

Echo::StreamServer::Account

=head1 AUTHOR

Andrew Droffner, E<lt>adroffne@advance.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Droffner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
