package Echo::StreamServer::Feeds;

use 5.008008;
use strict;
use warnings;

use Echo::StreamServer::Client;
our @ISA = ( 'Echo::StreamServer::Client' );

use Echo::StreamServer::Core;
$Echo::StreamServer::Core::DEBUG=0;

use Data::Dumper;
our $DEBUG=0;

our $VERSION = '0.01';

sub list {
	my ($self) = @_;

	my $feeds_xml = send_request($self->{'account'}, 'feeds/list', {}, 0, 'xml');

        # Return feeds XML document.
        return $feeds_xml;
}

sub register {
	my ($self, $url, $interval) = @_;

	my %params = (
		'url' => $url,
		'interval' => (defined $interval)? $interval: 0, # seconds
	);

	my $json_hash_ref = send_request($self->{'account'}, 'feeds/register', \%params);

        # Return true on success.
        if (exists($json_hash_ref->{'result'}) and ($json_hash_ref->{'result'} eq 'success')) {
                return 1; # true
        }
        else {
                return 0; # false
        }
}

sub unregister {
	my ($self, $url) = @_;

	my %params = (
		'url' => $url,
	);

	my $json_hash_ref = send_request($self->{'account'}, 'feeds/unregister', \%params);

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

Echo::StreamServer::Feeds - Feeds API

=head1 SYNOPSIS

  use Echo::StreamServer::Account;
  use Echo::StreamServer::Feeds;

  my $acct = new Echo::StreamServer::Account($appkey, $secret);
  my $client = new Echo::StreamServer::Feeds($acct);

  my $result = $client->register("http://www.example.com");
  my $feeds_xml = $client->list();
  my $result = $client->unregister("http://www.example.com");

=head1 DESCRIPTION

The Feeds API is Echo::StreamServer::Feeds and requires an Echo::StreamServer::Account.

Echo Platform allows you to register Activity Stream feeds in the system.
Registered URLs will be aggressively polled by the Platform looking for new data
and the data will be submitted into the Echo database.

=head2 Client Methods

=over

=item C<list>

Fetch the list of registered feeds for the Echo::StreamServer::Account.

=item C<register>

Register a new Activity Stream feed URL to update every C<$interval> seconds.

=item C<unregister>

Remove a certain URL form the list of Activity Stream feeds registered earlier.

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
