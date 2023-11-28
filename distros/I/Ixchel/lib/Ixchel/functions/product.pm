package Ixchel::functions::product;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(product);

=head1 NAME

Ixchel::functions::product - Returns the product name of the system found via dmidecode.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::product;

    print 'Product: '.product."\n";

=head1 Functions

=head2 product

Fetches system-product-name via dmidecode.

If not ran as root, this will return blank.

=cut

sub product {
	my $output = `dmidecode --string=system-product-name 2> /dev/null`;
	chomp($output);

	return $output;
}

1;
