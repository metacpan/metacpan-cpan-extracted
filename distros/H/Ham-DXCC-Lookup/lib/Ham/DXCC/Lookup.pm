package Ham::DXCC::Lookup;

use strict;
use warnings;

use Carp;
use Exporter 'import';
use FindBin qw($Bin);
use Params::Get;
use Params::Validate::Strict;

use Ham::DXCC::Lookup::DB::cty;

my $dbh;
our @prefixes;

our @EXPORT_OK = qw(lookup_dxcc);

=head1 NAME

Ham::DXCC::Lookup - Look up DXCC entity from amateur radio callsign

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Ham::DXCC::Lookup qw(lookup_dxcc);

    my $info = lookup_dxcc('G4ABC');
    print "DXCC: $info->{dxcc_name}\n";

=head1 DESCRIPTION

This module provides a simple lookup mechanism to return the DXCC entity from a given amateur radio callsign.

=head1 FUNCTIONS

=head2 lookup_dxcc($callsign)

Returns a hashref with C<dxcc> for the given callsign.

=head3 API Specification

=head4 input

  callsign:
    optional: 0
    position: 0
    matches: '^([A-Z0-9]{1,3})([0-9])([A-Z]{1,4})$'
    min: 3
    type: string

=head4 output

  type: hashref

=cut

sub lookup_dxcc
{
	if(!defined($dbh)) {
		my $db = "$Bin/../data";
		eval {
			$dbh = Ham::DXCC::Lookup::DB::cty->new({ directory => $db });
		};
		if(!defined($dbh)) {
			require Module::Locate;
			if(my $db2 = Module::Locate::locate(__PACKAGE__)) {
				require File::Basename;
				$db2 = File::Basename::dirname($db2) . "/../../../data";
				$dbh = Ham::DXCC::Lookup::DB::cty->new({ directory => $db2 });
				if(!defined($dbh)) {
					croak("No database found at $db or $db2");
				}
			} else {
				croak("No database found at $db2");
			}
		}
	}

        my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('callsign', \@_),
		schema => {
			callsign => {
				type => 'string',
				matches => qr/^([A-Z0-9]{1,3})([0-9])([A-Z]{1,4})$/,
				min => 3,
			}
		}
	}) or Carp::croak 'Usage: ', __PACKAGE__, '::lookup(callsign => $str)';

	if(my $callsign = $params->{callsign}) {
		if(my $rc = $dbh->fetchrow_hashref({ prefix => "=$callsign" })) {
			return $rc;
		}

		if(scalar(@prefixes) == 0) {
			@prefixes = $dbh->prefix();
		}

		for my $prefix (sort { length($b) <=> length($a) } @prefixes) {
			if(index($callsign, $prefix) == 0) {
				return $dbh->fetchrow_hashref({ prefix => $prefix });
			}
		}
		return {};
	}
	Carp::croak 'Usage: ', __PACKAGE__, '::lookup(callsign => $str)';
}

=head2 run

You can also run this module from the command line:

    perl lib/Ham/DXCC/Lookup.pm G4ABC

=cut

__PACKAGE__->run(@ARGV) unless caller();

sub run {
	require Data::Dumper;

	my $program = shift;

	foreach my $callsign(@_) {
		if(my $rc = lookup_dxcc($callsign)) {
			print Data::Dumper->new([$rc])->Dump();
		} else {
			die "$0: $1 not found";
		}
	}
}

1;

__END__

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

L<https://www.country-files.com/>

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
