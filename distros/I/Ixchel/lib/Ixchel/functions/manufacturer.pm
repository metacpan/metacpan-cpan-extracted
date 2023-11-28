package Ixchel::functions::manufacturer;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(manufacturer);

=head1 NAME

Ixchel::functions::manufacturer - Returns the manufacturer of the system found via dmidecode.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::manufacturer;

    print 'Manufacturer: '.manufacturer."\n";

=head1 Functions

=head2 manufacturer

Fetches system-manufacturer via dmidecode.

If not ran as root, this will return blank.

=cut

sub manufacturer {
	my $output = `dmidecode --string=system-manufacturer 2> /dev/null`;
	chomp($output);

	return $output;
}

1;
