package Echo::StreamServer::Client;

use 5.008008;
use strict;
use warnings;

use Echo::StreamServer::Account;

our $VERSION = '0.01';

sub new {
	my ($package, $account) = @_;
	my %hash;

	# Choose the $account parameter, or the default account in Settings.
	my $acct;
	if ($account) {
		$acct = $account;
	}
	else {
		# Default Account:
		$acct = new Echo::StreamServer::Account();
	}

	%hash = ( 'account' => $acct );
	my $obj = bless \%hash => $package;
	return $obj;
}

1;
__END__

=head1 NAME

Echo::StreamServer::Client - Base Client Class

=head1 SYNOPSIS

  use Echo::StreamServer::Account;
  use Echo::StreamServer::Client;

  my $acct = new Echo::StreamServer::Account($appkey, $secret);
  my $client = new Echo::StreamServer::Client($acct);

=head1 DESCRIPTION

The Echo::StreamServer::Client is a base class that requires an Echo::StreamServer::Account.
All the Echo APIs derive from this class such as the Items API & KVS API.

The Echo::StreamServer::Account parameter is optional. Echo::StreamServer::Settings loads
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
