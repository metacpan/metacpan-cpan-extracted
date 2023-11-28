package Ixchel::functions::serial;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(serial_num);

=head1 NAME

Ixchel::functions::serial - Returns either system serial or baseboard serial found via dmidecode.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::serial;

    print 'Serial: '.serial_num."\n";

=head1 Functions

=head2 serial_num

Fetches either system-product-name or baseboard-serial-number via dmidecode.

First system-serial-number is tried and if that matches /To be/, then
baseboard-serial-number is used.

If not ran as root, this will return blank.

=cut

sub serial_num {
	my $output = `dmidecode --string=system-serial-number 2> /dev/null`;
	if ( $output =~ /To be/ ) {
		$output = `dmidecode --string=baseboard-serial-number 2> /dev/null`;
	}

	chomp($output);

	return $output;
}

1;
