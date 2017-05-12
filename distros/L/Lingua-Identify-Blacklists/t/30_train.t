#!/usr/bin/env perl
#-*-perl-*-

use utf8;
use Test::More;
use File::Compare;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Lingua::Identify::Blacklists ':all';

$Lingua::Identify::Blacklists::BLACKLISTDIR = "$Bin/blacklists";


my %files = ( bs => "$Bin/data/eval/dnevniavaz.ba.200.check",
	      hr => "$Bin/data/eval/vecernji.hr.200.check",
	      sr => "$Bin/data/eval/politika.rs.200.check" );

train( \%files );

my @langs = keys %files;

for my $s (0..$#langs){
    for my $t ($s+1..$#langs){
	is ( compare( "$Bin/data/blacklists/$langs[$s]-$langs[$t].txt", 
		      "$Bin/blacklists/$langs[$s]-$langs[$t].txt"), 
	     0, "$langs[$s]-$langs[$t] blacklist" );
    }
}


done_testing;
