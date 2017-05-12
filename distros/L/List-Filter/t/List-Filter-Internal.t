# Test file created outside of h2xs framework.
# Run this like so: `perl List-Filter-Internal.t'
#   doom@kzsu.stanford.edu     2007/05/07 09:48:03

use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;
use Env qw( HOME );

use Test::More;
BEGIN { plan tests => 14 };
use FindBin qw($Bin);
use lib ("$Bin/../../..");

BEGIN {
  use_ok( 'List::Filter::Internal' );
}

ok(1, "Traditional: If we made it this far, we're ok.");

my $default_stash = "/tmp/nada.yaml";
my $lfi = List::Filter::Internal->new( { default_stash => $default_stash } );
my $testname = "Testing qualify_storage given";

{#3
  my $testcase = "empty args";
  my $args = {};
  my $storage = $lfi->qualify_storage( $args->{ storage } );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/nada.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
}

{#4
  my $testcase = "args with storage defined as undef";
  my $args = { storage => undef };
  my $storage = $lfi->qualify_storage( $args->{ storage } );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/nada.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
}

{#5
  my $testcase = "args with storage defined as string";
  my $args = { storage => "/tmp/nonesuch.yaml" };
  my $storage = $lfi->qualify_storage( $args->{ storage } );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/nonesuch.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
}

{#6
  my $testcase = "args with storage defined as aref containing string";
  my $args = { storage => ["/tmp/nonesuch.yaml"] };
  my $storage = $lfi->qualify_storage( $args->{ storage } );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/nonesuch.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
}

{#7
  my $testcase = "args with storage defined as HREF";
  my $args = { storage =>
               {
                'type' => 'MEM'
               } };
  my $storage = $lfi->qualify_storage( $args->{ storage } );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
                       {
                        'type' => 'MEM'
                       }
                      ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
}

{#8
  my $testcase = "an aref inside an aref should error out";
  # This is to cover a pass on error that I've seen happen:
  #    storage => [ $storage ],
  my $storage_input = [ "/tmp/blah.yaml" ] ;
  eval {
    my $storage = $lfi->qualify_storage( [ $storage_input ] );
    ($DEBUG) && print STDERR Dumper($storage), "\n";
  };
  if ($@) {
    my $err_mess = $@;
    like( $err_mess, qr{ The \s+ storage \s+ parameter \s+ should \s+ not \s+ be \s+ an \s+ aref \s+ inside \s+ an \s+ aref }x,
          "$testname: $testcase");
  } else {
    fail( "$testname: $testcase" );
  }
}


# New series of tests

{#9
  my $testname = "Testing define_yaml_default: ";
  my $testcase = "args with storage defined as undef";
  my $lfi = List::Filter::Internal->new();
  my $old_home = $HOME;
  $HOME = "/tmp/home/popeye";
  my $filename = $lfi->define_yaml_default( 'anchor' );
  my $expected = "/tmp/home/popeye/.list-filter/anchors.yaml";

  is( $filename, $expected, "$testname $testcase" );
  $HOME = $old_home;
}

{#10
  my $testname = "Testing qualify_storage_from_namespace";
  my $testcase = "";
  my $lfi = List::Filter::Internal->new();

  my $args = {};
  my $old_home = $HOME;
  $HOME = "/tmp/home/popeye";
  my $storage = $lfi->qualify_storage_from_namespace(
                          $args->{ storage },
                          'spinach',
                                                    );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/home/popeye/.list-filter/spinachs.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
  $HOME = $old_home;
}

# Once again, testing various argument settings
# as with the first series of tests.

$testname = "Testing qualify_storage_from_namespace:";

{#11
  my $testcase = "deref an empty args href, \$args->{ storage }";
  my $args = {};
  my $old_home = $HOME;
  $HOME = "/tmp/home/rhett";
  my $storage = $lfi->qualify_storage_from_namespace(
                        $args->{ storage },
                        'pimpernel',
                       );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/home/rhett/.list-filter/pimpernels.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
  $HOME = $old_home;
}

{#12
  my $testcase = "storage defined as undef";
  my $args = { storage => undef };
  my $old_home = $HOME;
  $HOME = "/tmp/home/rhett";
  my $storage = $lfi->qualify_storage_from_namespace(
                        $args->{ storage },
                        'pimpernel',
                       );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/home/rhett/.list-filter/pimpernels.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
  $HOME = $old_home;
}

{#13
  my $testcase = "storage defined as string";
  my $args = { storage => "/tmp/home/rhett/.list-filter/gone_daddies.yaml" };
  my $old_home = $HOME;
  $HOME = "/tmp/home/rhett";
  my $storage = $lfi->qualify_storage_from_namespace(
                        $args->{ storage },
                        'pimpernel',
                       );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/home/rhett/.list-filter/gone_daddies.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
  $HOME = $old_home;
}

{#15
  my $testcase = "storage defined as aref containing string";
  my $args = { storage => ["/tmp/home/rhett/.list-filter/gone_daddies.yaml"] };
  my $old_home = $HOME;
  $HOME = "/tmp/home/rhett";
  my $storage = $lfi->qualify_storage_from_namespace(
                        $args->{ storage },
                        'pimpernel',
                       );
  ($DEBUG) && print STDERR Dumper($storage), "\n";
  my $expected_aref = [
          '/tmp/home/rhett/.list-filter/gone_daddies.yaml'
        ];
  is_deeply( $storage, $expected_aref, "$testname $testcase" );
  $HOME = $old_home;
}


