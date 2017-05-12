#!/usr/bin/perl
use Test::Simple 'no_plan';
use File::Which 'which';


for my $bin (qw(automake gcc)){
   
   ok( which($bin),"have $bin")
      or die("you must have $bin installed\n".notes());


}

sub notes {

my $msg = q{

automake

   yum -y install automake.noarch

gcc 

   yum -y install gcc-c++

};

   return $msg;
}
