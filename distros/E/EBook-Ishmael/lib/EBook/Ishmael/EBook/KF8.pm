package EBook::Ishmael::EBook::KF8;
use 5.016;
our $VERSION = '1.04';
use strict;
use warnings;

use parent 'EBook::Ishmael::EBook::Mobi';

my $TYPE    = 'BOOK';
my $CREATOR = 'MOBI';

sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	return 0 unless -s $file >= 68;

	seek $fh, 32, 0;
	read $fh, my ($null), 1;

	unless ($null eq "\0") {
		return 0;
	}

	seek $fh, 60, 0;
	read $fh, my ($type),    4;
	read $fh, my ($creator), 4;

	return 0 unless $type eq $TYPE && $creator eq $CREATOR;

	seek $fh, 78, 0;
	read $fh, my ($off), 4;
	$off = unpack "N", $off;
	seek $fh, $off + 36, 0;
	read $fh, my ($ver), 4;
	$ver = unpack "N", $ver;

	return $ver == 8;

}

1;
