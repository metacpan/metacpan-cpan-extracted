package EBook::Ishmael::EBook::CBZ;
use 5.016;
our $VERSION = '1.01';
use strict;
use warnings;

use parent 'EBook::Ishmael::EBook::CB';

use EBook::Ishmael::Unzip;

my $MAGIC = pack "C*", 0x50, 0x4b, 0x03, 0x04;

sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	return 0 unless $file =~ /\.cbz$/;

	read $fh, my $mag, length $MAGIC;

	return $mag eq $MAGIC;

}

sub extract {

	my $self = shift;
	my $out  = shift;

	unzip($self->{Source}, $out);

	return 1;

}

sub format { 'CBZ' }

1;
