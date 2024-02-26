use strict;
use warnings;
use Dispatch::Fu;
use Test::More tests => 3;

my $INPUT = [qw/1 2 3 4 5/];

my ($val0, $val1, $val2) = dispatch {
    my $input_ref = shift;                                          # <~ input reference
    return ( scalar @$input_ref > 5 )                               # <~ return a string that must be
     ? q{case5}                                                     #    defined below using the 'on'
     : sprintf qq{case%d}, scalar @$input_ref;                      #    keyword, this i
} $INPUT,                                                           # <~ input reference, SCALAR passed to dispatch BLOCK
  on case0 => sub { my $INPUT = shift; return qq{case 0}},          # <~ if dispatch returns 'case0', run this CODE
  on case1 => sub { my $INPUT = shift; return qq{case 1}},          # <~ if dispatch returns 'case1', run this CODE
  on case2 => sub { my $INPUT = shift; return qq{case 2}},          #    ...   ...   ...   ...   ...   ...   ...
  on case3 => sub { my $INPUT = shift; return qq{case 3}},          # ...   ...   ...   ...   ...   ...   ...   ...
  on case4 => sub { my $INPUT = shift; return qq{case 4}},          #    ...   ...   ...   ...   ...   ...   ...
  on case5 => sub { my $INPUT = shift; return qw/val0 val1 val2/ }; # <~ if dispatch returns a LIST


is $val0, q{val0}, q{multi return val0 worked as expected};
is $val1, q{val1}, q{multi return val1 worked as expected};
is $val2, q{val2}, q{multi return val2 worked as expected};
