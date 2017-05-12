package Geo::Address::Mail::Standardizer::USPS::AMS;

use Moose;

=head1 NAME

Geo::Address::Mail::Standardizer::USPS::AMS - address standardization using the United States Postal Service Address Matching System

=head1 SYNOPSIS

 my $ms   = new Geo::Address::Mail::Standardizer::USPS::AMS;
 my $addr = new Geo::Address::Mail::US;
 my $res  = $ms->standardize($addr);

 $addr = $res->standardized_address
     or die 'unable to standardize address: ' . $res->error;

=head1 AMS PATHS

by default, the USPS::AMS standardizer assumes AMS paths are
configured as follows:

 datadir: /usr/share/uspsams
 statedir: /var/lib/uspsams

 AMS: datadir/comm
 DPV: datadir/dpv
 ELOT: datadir/elot
 LACSLink: datadir/lacslink
 SUITELink: datadir/suitelink
 Z4CXLOG.DAT: statedir/Z4CXLOG.DAT

you may change datadir or statedir via those attributes, but
the other paths are computed and are immutable.

=cut

use Geo::Address::Mail::Standardizer::USPS::AMS::Results;

with 'Geo::Address::Mail::Standardizer';

our $VERSION = '0.03';

require XSLoader;

XSLoader::load('Geo::Address::Mail::Standardizer::USPS::AMS', $VERSION);

has datadir		=> (is => 'rw', isa => 'Str', default => '/usr/share/uspsams');
has statedir	=> (is => 'rw', isa => 'Str', default => '/var/lib/uspsams');

=head1 METHODS

=head2 new

the Geo::Address::Mail::Standardizer::USPS::AMS constructor
accepts two arguments:

=over 4

=item datadir (default: /usr/share/uspsams)

the path to the USPS AMS shared data directory.  this
directory typically contains all of the database files
provided with AMS.

=item statedir (defaults to /var/lib/uspsams)

the path to the USPS AMS state directory.  this directory
is expected to contain the Z4CXLOG.DAT date/time file that
is written to by AMS.  i have no idea what its purpose is;
AMS won't initialize without it though.

=back

=cut

sub BUILD
{
	my $self = shift;

	$self->init;
}

=head2 init

initializes the AMS database.  called during construction
by the BUILD method.

=head2 standardize($address)

attempt to standardize an address.  the standardize method
accepts a hashref or a Geo::Address::Mail::US object.  a
results object will be returned.  see the documentation for
Geo::Address::Mail::Standardizer::USPS::AMS::Results for
details on the results object.

=cut

sub standardize
{
	my $self = shift;
	my $addr = shift;

	if (blessed $addr and $addr->isa('Geo::Address::Mail::US')) {
		$addr =
		{
			street		=> uc $addr->street,
			firm		=> uc '',
			secondary	=> uc $addr->street2,
			city		=> uc $addr->city,
			state		=> uc $addr->state,
			zip			=> uc $addr->postal_code
		};
	} else {
		$addr = { map { $_ => uc $addr->{$_} } keys %$addr };
	}

	die 'Address must be a hashref or a Geo::Address::Mail::US'
		if ref $addr ne 'HASH';

	my $res = $self->_standardize($addr);

	return new Geo::Address::Mail::Standardizer::USPS::AMS::Results $res;
}

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010 Mike Eldridge

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
