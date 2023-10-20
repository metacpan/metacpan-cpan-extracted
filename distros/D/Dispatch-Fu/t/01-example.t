use strict;
use warnings;
use Dispatch::Fu; # 'dispatch', 'cases', 'xdefault', and 'on' are exported by default, just for show here
use Test::More tests => 1;

my $INPUT = [qw/1 2 3 4 5/];

my $results = dispatch {                       # <~ start of 'dispatch' construct
    my $input_ref = shift;                     # <~ input reference
    return ( scalar @$input_ref > 5 )          # <~ return a string that must be
     ? q{case5}                                #    defined below using the 'on'
     : sprintf qq{case%d}, scalar @$input_ref; #    keyword, this i
} $INPUT,                                      # <~ input reference, SCALAR passed to dispatch BLOCK
  on case0 => sub { my $INPUT = shift; return qq{case 0}},    # <~ if dispatch returns 'case0', run this CODE
  on case1 => sub { my $INPUT = shift; return qq{case 1}},    # <~ if dispatch returns 'case1', run this CODE
  on case2 => sub { my $INPUT = shift; return qq{case 2}},    #    ...   ...   ...   ...   ...   ...   ...
  on case3 => sub { my $INPUT = shift; return qq{case 3}},    # ...   ...   ...   ...   ...   ...   ...   ...
  on case4 => sub { my $INPUT = shift; return qq{case 4}},    #    ...   ...   ...   ...   ...   ...   ...
  on case5 => sub { my $INPUT = shift; return qq{case 5}};    # <~ if dispatch returns 'case5', run this CODE

is $results, q{case 5}, q{POD example works};
