package Echo::StreamServer::Account;

use 5.008008;
use strict;
use warnings;

use Echo::StreamServer::Settings;

our $VERSION = '0.01';

sub new {
	# TODO: Add auth-type: Basic vs. OAUth2
	my ($package, $appkey, $secret) = @_;
	my %hash;

	# Choose the account parameters, or the default account in Settings.
	if ($appkey) {
		%hash = ( 'appkey' => $appkey, 'secret' => $secret);
	}
	else {
		%hash = ( 'appkey' => $ECHO_API_KEY, 'secret' => $ECHO_API_SECRET );
	}

	my $obj = bless \%hash => $package;
	return $obj;
}

sub name {
	my $self = shift;
	return "(StreamServer Account: appkey=" . $self->{'appkey'} . ")";
}

1;
__END__

=head1 NAME

Echo::StreamServer::Account - Client Account

=head1 SYNOPSIS

  use Echo::StreamServer::Account;
  use Echo::StreamServer::Client;

  my $acct = new Echo::StreamServer::Account($appkey, $secret);
  my $client = new Echo::StreamServer::Client($acct);

=head1 DESCRIPTION

The Echo::StreamServer::Account contains hidden API Key and hidden Secret.
Every Echo client API requires an account to access StreamServer. 

The ($appkey, $secret) parameters are optional. Echo::StreamServer::Settings loads
the default account otherwise.

=head1 SEE ALSO

Echo::StreamServer::Items
Echo::StreamServer::Feeds
Echo::StreamServer::Users
Echo::StreamServer::KVS

=head1 AUTHOR

Andrew Droffner, E<lt>adroffne@advance.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Droffner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
