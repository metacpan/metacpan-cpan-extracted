#!perl -w

use strict;
use Test::More tests => 4;
use Config;
#use File::Spec;

my $make = $Config{make};

chdir 'example' or die "chdir 'example' failed: $!";

#open *STDOUT, '>', File::Spec->devnull;

sub cmd{
	my $cmd = join ' ', @_;
	system(@_) == 0 or die "Cannot call system command: $?";
	pass $cmd;
}

cmd $^X, '-Mblib', 'Makefile.PL';
cmd $make;
cmd $make, 'test';

END{
	cmd $make, 'clean';
}
