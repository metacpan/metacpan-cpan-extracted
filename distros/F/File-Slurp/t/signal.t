#!/usr/local/bin/perl -w

use strict ;
use File::Slurp qw(read_file);

use Carp ;
use Test::More ;

BEGIN { 
	if( $^O =~ '32' ) {
		plan skip_all => 'skip signal test on windows';
		exit ;
	}

	plan tests => 1 ;
}

$SIG{CHLD} = sub {};

pipe(IN, OUT);

print "forking\n";
if (!fork) {
   sleep 1;
   exit;
} 
if (!fork) {
   sleep 2;
   print OUT "success";
   exit;
}
close OUT;
my $data = read_file(\*IN);
is ($data, "success", "handle EINTR failed");
