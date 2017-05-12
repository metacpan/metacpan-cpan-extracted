use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();


use Lingua::Names 'is_name';

for my $string (qw/leo james lUCy beth alicia Carla natalie alice marge brigitte/){
   ok( is_name($string), "is_name() $string");
}

for my $string (qw/44 j4l mpothapp juli-an/){
   ok( !is_name($string), "is_name() (not) $string") or warn("  Was $string");
}


my $count_f = scalar @Lingua::Names::NAMES_FEMALE;
my $count_m = scalar @Lingua::Names::NAMES_MALE;

printf STDERR "\nTotal female names: %s\nMale names: %s\nTotal: %s\n", $count_f, $count_m, ($count_f + $count_m);








sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


