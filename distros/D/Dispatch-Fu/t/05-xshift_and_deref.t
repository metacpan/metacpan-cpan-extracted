use strict;
use warnings;
use Dispatch::Fu;
use Test::More tests => 6;

my $INPUT = [qw/1 2 3 4 5/];

my ($val0, $val1, $val2) = dispatch {
    my @input_arr = xshift_and_deref @_;                            # <~ NOTE: derefs $_[0] into @input_arr
    return ( scalar @input_arr > 5 )                                # <~ return a string that must be
     ? q{case5}                                                     #    defined below using the 'on' keyword
     : sprintf qq{case%d}, scalar @input_arr;
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

$INPUT = { 1 => q{foo}, 2 => q{bar}, 3 => q{baz}, 4 => q{herp}, 5 => q{derp} };

($val0, $val1, $val2) = dispatch {
    my %input_hash = xshift_and_deref @_;                           # <~ NOTE: derefs $_[0] into %input_hash
    return ( scalar keys %input_hash > 5 )                          # <~ return a string that must be
     ? q{case5}                                                     #    defined below using the 'on' keyword
     : sprintf qq{case%d}, scalar keys %input_hash;
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
