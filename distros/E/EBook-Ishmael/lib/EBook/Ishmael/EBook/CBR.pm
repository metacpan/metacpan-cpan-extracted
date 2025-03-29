package EBook::Ishmael::EBook::CBR;
use 5.016;
our $VERSION = '1.04';
use strict;
use warnings;

use parent 'EBook::Ishmael::EBook::CB';

use File::Which;

# TODO: Create new CBR test file that uses older RAR version, so that tests
# on systems with older unrar's can pass.

my $MAGIC = pack "C*", 0x52, 0x61, 0x72, 0x21, 0x1a, 0x07;

my $UNRAR = which('unrar') // which('UnRAR');

our $CAN_TEST = defined $UNRAR;

sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	return 0 unless $file =~ /\.cbr$/;

	read $fh, my $mag, length $MAGIC;

	return $mag eq $MAGIC;

}

sub _unrar {

	my $rar = shift;
	my $out = shift;

	unless (defined $UNRAR) {
		die "Cannot unrar $rar; unrar not installed\n";
	}

	qx/$UNRAR x '$rar' '$out'/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$UNRAR' on $rar\n";
	}

	return 1;

}

sub extract {

	my $self = shift;
	my $out  = shift;

	_unrar($self->{Source}, $out);

	return 1;

}

sub format { 'CBR' }

1;
