use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::Which::Cached 'which';
use File::Which();


ok( ! eval { which() }, 'which with no arg');



for my $bogus ( qw/bogusthingthatdoesnotexist anotherboguscliething 
   morestuffgoesherethis isnotareadl_cliwhichexutlb/ ){
   ok( ! which($bogus),"dont have bogus which '$bogus'");
}



my $i=0;
# inspect machine for what we can test for having
my @have = qw/ping dir bogus ls whoami traceroute astroboy thundercats/;
my %have;

for my $e ( @have ){   
   #warn("$e\n");
   File::Which::which($e) and $have{$e}++;
   $i++;
   $i > 100 and die("bad iter");
}


for my $thing (keys %have){
   my $huh;
   ok( $huh = which($thing),"have which '$thing' - $huh");
   
}
















