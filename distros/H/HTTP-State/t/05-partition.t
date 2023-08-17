use strict;
use warnings;
use feature "say";
##################################
# use Log::ger::Output "Screen"; #
# use Log::OK {                  #
#   lvl=>"info",                 #
#   opt=>"verbose"               #
# };                             #
# use Data::Dumper;              #
##################################
use Test::More;
use HTTP::State;
use HTTP::State::Cookie qw<:encode :constants>;

my $jar=HTTP::State->new();

# Store cookies 
#

my $third_party_url='http://test.com.au/some/path';

my @partition_key=(
  undef,          
  "http://test.com.au",
  "http://testa.com.au",
  "http://testb.com.au",
);

my @cookies;
my $i=0;

for(@partition_key){
  my $c=cookie_struct ("name$i"=>$_, expires=>(time +10), partitioned=>1);
  push @cookies,  $c;
  $i++;
  $jar->store_cookies( $third_party_url, $_, undef, $c);
}

#say STDERR join "\n", $jar->dump_cookies;
my @dump=$jar->dump_cookies;

ok @dump==@partition_key, "Correct count";

$i=0;
for my $key (@partition_key){
  #say Dumper 
  my @list=$jar->get_cookies($third_party_url,  $key, undef);
  unless($key){
    ok @list == 1, "No parition key used";

  }
  else {
    ok @list== 2, "Default jar and partitions";
    ok $list[1][COOKIE_NAME] eq $cookies[$i][COOKIE_NAME], "Expected name";
  }
  $i++;
}

my $jar2=HTTP::State->new();
$jar2->load_cookies(@dump);
my $j2=join "\n", $jar2->dump_cookies;
my $j1=join "\n", $jar->dump_cookies;
ok $j2 eq $j1, "Dump and load";


done_testing;
