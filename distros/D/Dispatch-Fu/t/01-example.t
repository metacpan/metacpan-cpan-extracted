use Dispatch::Fu;    # exports 'dispatch' and 'on', which are needed

use Test::More tests => 1;

my $input_ref = [qw/1 2 3 4 5/];

my $bucket = dispatch {

    # here, give a reference $H of any kind,
    # you compute a static string that is added
    # via the 'on' keyword; result will be
    # 'bucket' + some number in in 0-5

    my $baz = shift;

    # what gets returned here should be a static string
    # that is used as a key in the "on" entries below.
    return ( scalar @$baz > 5 )
      ? q{bucket5}
      : sprintf qq{bucket%d}, scalar @$baz;
}
$input_ref,
  on bucket0 => sub {
    note qq{bucket 0};
    0;
  },
  on bucket1 => sub {
    note qq{bucket 1};
    1;
  },
  on bucket2 => sub {
    note qq{bucket 2};
    2;
  },
  on bucket3 => sub {
    note qq{bucket 3};
    3;
  },
  on bucket4 => sub {
    note qq{bucket 4};
    4;
  },
  on bucket5 => sub {
    note qq{bucket 5};
    5;
  };

is $bucket, 5, q{POD example works};
