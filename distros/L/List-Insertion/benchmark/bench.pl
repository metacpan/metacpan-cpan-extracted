# General binary search benchmarking
#
use Benchmark qw<cmpthese>;
use Data::Dumper;

use List::BinarySearch::PP;
use List::BinarySearch::XS;
use List::Insertion {type=>"numeric", duplicate=>"left", accessor=>'->{value}'};

use constant DEBUG=>undef;
# test
my $max=10;
my $size=$ARGV[0]//10000;
my @list=sort {$a->{value} <=> $b->{value} } map {{value=>rand($max)}} 1..$size;
my @keys=map rand($max), 1..10;


use feature ":all";


cmpthese DEBUG ? 1 : -1, {
  "L::BS::PP"=>sub {

    my @res=map List::BinarySearch::PP::binsearch_pos(sub {$a->{value} <=> $b->{value}}, {value=>$_}, @list), @keys;
    if(DEBUG){
      say "L::BS::PP";
      say Dumper @res;
    }
  },
  "L::BS::XS"=>sub {

  my @res=map List::BinarySearch::XS::binsearch_pos(sub {$a->{value} <=> $b->{value}}, {value=>$_}, @list), @keys;
    if(DEBUG){
      say "L::BS::XS";
      say Dumper @res;
    }
  }, 
  "L::I"=>sub {
    my @res=map search_numeric_left($_, \@list), @keys;
    if(DEBUG){
      say "L::I";
      say Dumper @res;
    }

  }
};


