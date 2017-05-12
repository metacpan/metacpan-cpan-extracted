#!/usr/bin/perl
use warnings;
use utf8;


=pod
  mfor [[  ] , [ ] ]  { code expression };
=cut
=pod
sub mfor(&@);
sub mfor(&@) {
  my $c_r = shift;
  my $arrs = shift;

  my $arr_lev = shift if ( @_ );
  $arr_lev ||= 0;

  print '    ' x $arr_lev , 'lev:' , $arr_lev;
  print ' size:' , scalar @$arrs , "\n";

  my $arr_size = scalar(@$arrs);
  
  if( $arr_size == $arr_lev  ) {
    my $cur_arr = $arrs->[ $arr_lev - 1 ] ;
    print "         last one\n";
    for my $i ( 0 .. scalar(@$cur_arr) -1 ) {
      $c_r->($i,$cur_arr->[$i]);
    }
  } 
  else {
    my $cur_arr = $arrs->[ $arr_lev++ ];
    my $idx = scalar(@$cur_arr);
    for my $i ( 0 .. $idx-1  ) {
    #  print $i,$cur_arr->[$i],"\n";
      mfor { &$c_r } $arrs,$arr_lev;
    }
  }
}
=cut

use strict;
use warnings;

use MFor;
use lib 'lib';
# $test = [ [qw/a s d f/] , [qw/1 2 3 4 5/] ];
# print scalar @$test;
my $g_idx = 0;
 mfor {
   my @args = @_;
   print "{CODE}" , $g_idx++ , ":" , join(',',@_) , "\n";

 }  [
       [ qw/a b c/ ],
       [ qw/x y z/ ],
       [ qw/1 2 3 4 5 6 7/ ],
   ];






__END__

