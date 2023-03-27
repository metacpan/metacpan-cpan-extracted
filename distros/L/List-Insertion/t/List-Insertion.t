use strict;
use warnings;

use feature ":all";

use Test::More;
BEGIN { use_ok('List::Insertion') };

use List::Insertion "make_search";
use List::Insertion {type=>"string"};
use List::Insertion {type=>"numeric", duplicate=>[qw<left right>]};
use List::Insertion {type=>"numeric", duplicate=>[qw<left right>], prefix=>"mysearch"};
use List::Insertion {type=>"numeric", duplicate=>[qw<left right>], prefix=>"hashsearch", accessor=>"->{key}"};
use List::Insertion {type=>"numeric", duplicate=>[qw<left right>], prefix=>"arraysearch", accessor=>"->[0]"};

my $ok;
$ok=eval {
    \&search_string_left;
};

ok $ok, "imported ok";

$ok=eval {
    \&search_numeric_left;
};

ok $ok, "imported ok";

$ok=eval {
    \&search_numeric_right;
};

ok $ok, "imported ok";

$ok=eval {
    \&mysearch_numeric_left;
};

ok $ok, "imported ok";

$ok=eval {
    \&mysearch_numeric_right;
};

ok $ok, "imported ok";

$ok=eval {
    \&keysearch_numeric_left;
};

ok $ok, "imported ok";

$ok=eval {
    \&keysearch_numeric_right;
};

ok $ok, "imported ok";


{

  my  @data=(
    {key=>1},
    {key=>2},
    {key=>3}
  );

  my $pos=hashsearch_numeric_right 2, \@data;
 #say STDERR "POS IS $pos";
  ok $pos ==2, "accessor execution";


}
{

  my  @data=(
    [1],
    [2],
    [3]
  );

  my $pos=arraysearch_numeric_right 2, \@data;
  ok $pos == 2, "accessor execution";

}

my $sub=make_search {type=>"nv", duplicate=>"left", accessor=>""};

ok defined($sub), "Sub created";



my @input=(1,2,3,4,5,6);

#say STDERR  $sub->(3, \@input);
#say STDERR  $sub->(3, \@input);


use List::Insertion {
      type=>[qw<string numeric>],
      duplicate=>[qw"left right"],
      #accessor=>"->{my_field}",
      prefix=>"bin"
    };

#say STDERR "Symbol is:".\&binsearch_string_left;
#say STDERR bin_string_left 2, \@input;
#say STDERR bin_numeric_left 2, \@input;



{
  # Test duplicates
  my @input=(10,20,30,30, 40,50);
  my $left=make_search {type=>"nv", duplicate=>"left", accessor=>""};
  my $right=make_search {type=>"nv", duplicate=>"right", accessor=>""};

  my $key=30;
  my $index=bin_numeric_left $key, \@input;
  ok $index==2;

  $index=bin_numeric_right $key, \@input;
  ok $index==4;


  $key=33;
  $index=bin_numeric_left $key, \@input;
  ok $index==4;

  $index=bin_numeric_right $key, \@input;
  ok $index==4;

  $key=29;
  $index=bin_numeric_left $key, \@input;
  ok $index==2;

  $index=bin_numeric_right $key, \@input;
  ok $index==2;
}

done_testing;
