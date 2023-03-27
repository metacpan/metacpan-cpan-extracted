# Benchmark inserting a new element into the correct position in an existing
# sorted list
#
use strict;
use warnings;
use feature ":all";
use Data::Dumper;
use List::Insertion {type=>"numeric", duplicate=>"left", accessor=>'->{value}'};
use Benchmark qw<cmpthese>;
use List::BinarySearch::PP;# qw<binsearch_pos>;
use List::BinarySearch::XS;
use constant DEBUG=>undef;

my @data=map {{value=>rand(10)}} 1..$ARGV[0]//10;

cmpthese DEBUG ? 1 : -1, {
  # An example of sorting data all at once. Assumes all data is available
  #####################################################
  # perl_once=>sub {                                  #
  #   my @sort=@data;                                 #
  #   @sort=sort {$a->{value} <=> $b->{value}} @sort; #
  #   if(DEBUG){                                      #
  #     say "perl_once";                              #
  #     say Dumper @sort                              #
  #   }                                               #
  # },                                                #
  #####################################################

  # Sorting and building array with new data using built in sort.
  perl_sort_update=>sub {
    my @sort;
    for(@data){
      push @sort, $_;
      @sort=sort {$a->{value} <=> $b->{value}} @sort;
    }
    if(DEBUG){
      say "perl";
      say Dumper @sort
    }
  },

  # Sorting and building array with new data using List::Insertion
  L_I_update=>sub {
    my @sort;
    my $pos;
    for(@data){

      if(@sort){
        $pos=search_numeric_left $_->{value}, \@sort;
        splice @sort, $pos, 0 , $_;
      }
      else{
        push(@sort, $_)
      }

    }
    if(DEBUG){
      say "L_I";
      say Dumper @sort
    }
  },
  L_BS_PP_update=>sub {
    my @sort;
    my $pos;
    for(@data){

      if(@sort){
        #$pos=List::BinarySearch::PP::binsearch_pos {$a <=> $b} $_, @sort;
        $pos=List::BinarySearch::PP::binsearch_pos {$a->{value} <=> $b->{value}} $_, @sort;
        splice @sort, $pos, 0 , $_;
      }
      else{
        push(@sort, $_)
      }

    }
    if(DEBUG){
      say "L_BS_PP";
      say Dumper @sort
    }
  },
  L_BS_XS_update=>sub {
    my @sort;
    my $pos;
    for(@data){

      if(@sort){
        #$pos=List::BinarySearch::XS::binsearch_pos {$a <=> $b} $_, @sort;
        $pos=List::BinarySearch::XS::binsearch_pos {$a->{value} <=> $b->{value}} $_, @sort;
        splice @sort, $pos, 0 , $_;
      }
      else{
        push(@sort, $_)
      }

    }
    if(DEBUG){
      say "L_BS_XS";
      say Dumper @sort
    }
  }
}
;





