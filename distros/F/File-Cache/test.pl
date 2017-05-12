#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print. (It may become useful if
# the test is moved to ./t subdirectory.) Remember that all the tests
# except the first are done twice--once with Storable, and once with
# Data::Dumper. The $TEST_SET_SIZE is the number of unique tests, not
# counting the trivial first test. @PERSISTENCE_MECHANISMS is an array
# containing all the supported persistence mechanisms

use vars qw($TEST_SET_SIZE @PERSISTENCE_MECHANISMS);

BEGIN
{
  $| = 1;
  $TEST_SET_SIZE = 25;
  @PERSISTENCE_MECHANISMS = qw(Data::Dumper Storable);

  # The test set is repeated once for each implementation, plus the
  # first test
  my $last_test_to_print =
    (($TEST_SET_SIZE) * ($#PERSISTENCE_MECHANISMS + 1)) + 1;

  print "1..$last_test_to_print\n";
}

END {print "not ok 1\n" unless $loaded;}

use File::Cache qw($sSUCCESS $sFAILURE);


$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;

my $sTEST_CACHE_KEY = "/tmp/TSTC";
my $sTEST_NAMESPACE = "TestCache";
my $sMAX_SIZE = 1000;
my $sTEST_USERNAME = "web";
my $sTEST_CACHE_DEPTH = 3;

# Run all remaining tests for each implementation
my $test_set_number = 0;

foreach my $implementation (@PERSISTENCE_MECHANISMS)
{
  $test_set_number++;
  my $test_set_start = $TEST_SET_SIZE * ($test_set_number - 1) + 2;
  my $test_set_end = $TEST_SET_SIZE * $test_set_number + 1;

  # Only do the tests if the persistence mechanism module is present
  if (eval "require $implementation")
  {
    do_tests($implementation, $test_set_start);
  }
  else
  {
    skip_tests($test_set_start, $test_set_end);
  }
}

sub skip_tests
{
  my ($start,$end) = @_;

  for (my $i = $start; $i <= $end;$i++)
  {
    print "ok $i # skip\n";
  }
}


sub do_tests
{
  my ($implementation,$test_number_start) = @_;

  print "--> Testing $implementation implementation\n";

  # Test creation of a cache object

  my $test = $test_number_start;

  my $cache1 = new File::Cache( { cache_key => $sTEST_CACHE_KEY,
                                  namespace => $sTEST_NAMESPACE,
                                  max_size => $sMAX_SIZE,
                                  auto_remove_stale => 0,
                                  username => $sTEST_USERNAME,
                                  filemode => 0770,
                                  implementation => $implementation,
                                  cache_depth => $sTEST_CACHE_DEPTH } );

  if ($cache1)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the setting of a scalar in the cache

  $test++;

  my $seed_value = "Hello World";

  my $key = 'key1';

  my $status = $cache1->set($key, $seed_value);

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }

  # Test the getting of a scalar from the cache

  $test++;

  my $val1_retrieved = $cache1->get($key);

  if ($val1_retrieved eq $seed_value)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the setting of a blessed object from the cache

  $test++;

  my $key2 = 'key2';

  $status = $cache1->set($key2, $cache1);

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }

  # Test the getting of a blessed object from the cache

  $test++;

  my $cache1_retrieved = $cache1->get($key2);

  $val1_retrieved = $cache1_retrieved->get($key);

  if ($val1_retrieved eq $seed_value)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the getting of the scalar from a subprocess

  $test++;

  my $pid = fork( );

  if ( not defined $pid )
  {
    die( "Error forking\n" );
  }
  elsif ( $pid == 0 )
  {
    test_subprocess_get( $sTEST_CACHE_KEY,
                         $sTEST_NAMESPACE,
                         $sTEST_USERNAME,
                         $sTEST_CACHE_DEPTH,
                         $implementation,
                         $key,
                         $seed_value,
                         $test );

    exit( 1 );
  }
  else
  {
    sleep( 1 );
  }


  # Test checking the memory consumption of the cache

  $test++;

  my $size = File::Cache::SIZE($sTEST_CACHE_KEY);

  if ($size > 0)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test clearing the cache's namespace

  $test++;

  $status = $cache1->clear();

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the max_size limit
  # Intentionally add more data to the cache than fits in max_size

  $test++;

  my $string = 'abcdefghij';

  my $start_size = $cache1->size();

  $cache1->set('initial_value', $string);

  my $end_size = $cache1->size();

  my $string_size = $end_size - $start_size;

  my $cache_item = 0;

  # This should take the cache to nearly the edge

  while (($cache1->size() + $string_size) < $sMAX_SIZE)
  {
    $cache1->set("item:$cache_item", $string);
    $cache_item++;
  }

  # This should put it over the top

  $cache1->set("item:$cache_item", $string);

  if ($cache1->size > $sMAX_SIZE)
  {
    print "not ok $test\n";
  }
  else
  {
    print "ok $test\n";
  }



  # Test the getting of a scalar after the clearing of a cache

  $test++;

  my $val2_retrieved = $cache1->get($key);

  if ($val2_retrieved)
  {
    print "not ok $test\n";
  }
  else
  {
    print "ok $test\n";
  }


  # Test the setting of a scalar in the cache with a immediate timeout

  $test++;

  $status = $cache1->set($key, $seed_value, 0);

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the getting of a scalar from the cache that should have timed
  # out immediately

  $test++;

  my $val3_retrieved = $cache1->get($key);

  if ($val3_retrieved)
  {
    print "not ok $test\n";
  }
  else
  {
    print "ok $test\n";
  }


  # Test the getting of the expired scalar using get_stale

  $test++;

  my $val3_stale_retrieved = $cache1->get_stale($key);

  if ($val3_stale_retrieved)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the setting of a scalar in the cache with a timeout in the
  # near future

  $test++;

  $status = $cache1->set($key, $seed_value, 2);

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the getting of a scalar from the cache that should not have
  # timed out yet (unless the system is *really* slow)

  $test++;

  my $val4_retrieved = $cache1->get($key);

  if ($val4_retrieved eq $seed_value)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the getting of a scalar from the cache that should have timed out

  $test++;

  sleep(3);

  my $val5_retrieved = $cache1->get($key);

  if ($val5_retrieved)
  {
    print "not ok $test\n";
  }
  else
  {
    print "ok $test\n";
  }


  # Test purging the cache's namespace

  $test++;

  $status = $cache1->purge();

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test getting the creation time of the cache entry

  $test++;

  my $timed_key = 'timed key';

  my $creation_time = time();

  my $expires_in = 1000;

  $cache1->set($timed_key, $seed_value, $expires_in);


  # Delay a bit

  sleep(2);


  # Let's expect no more than 1 second delay between the creation of
  # the cache entry and our saving of the time.

  my $cached_creation_time = $cache1->get_creation_time($timed_key);

  my $creation_time_delta = $creation_time - $cached_creation_time;

  if ($creation_time_delta <= 1)
  {
    $status = 1;
  }
  else
  {
    $status = 0;
  }

  if ($status)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test getting the expiration time of the cache entry

  $test++;

  my $expected_expiration_time =
    $cache1->get_creation_time($timed_key) + $expires_in;

  my $actual_expiration_time = $cache1->get_expiration_time($timed_key);

  $status = $expected_expiration_time == $actual_expiration_time;

  if ($status)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }



  # Test PURGING of a cache object

  $test++;

  $status = File::Cache::PURGE($sTEST_CACHE_KEY);

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the removal of a cached file

  $test++;

  $status = $sSUCCESS;

  my $remove_key = "foo";

  my $remove_value = "bar";

  $cache1->set($remove_key, $remove_value);

  $cache1->get($remove_key) eq $remove_value or
    $status = $sFAILURE;

  $cache1->remove($remove_key) or
    $status = $sFAILURE;

  if (defined $cache1->get($remove_key))
  {
    $status = $sFAILURE;
  }


  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test CLEARING of a cache object

  $test++;

  $status = File::Cache::CLEAR($sTEST_CACHE_KEY);

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test directories not created unless needed

  $test++;

  File::Cache::CLEAR($sTEST_CACHE_KEY);

  if (-e $sTEST_CACHE_KEY)
  {
    print "not ok $test\n";
  }

  $cache1 = new File::Cache( { cache_key => $sTEST_CACHE_KEY,
                               implementation => $implementation,
                               namespace => $sTEST_NAMESPACE } );

  opendir(DIR, $sTEST_CACHE_KEY) or
    croak("Couldn't open directory $sTEST_CACHE_KEY: $!");

  my @dirents = readdir(DIR);

  closedir DIR;

  my @files = grep { $_ !~ /^(\.|\.\.|.description)$/ } @dirents;

  if (!@files)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }

  File::Cache::CLEAR($sTEST_CACHE_KEY);


  # Test the setting of a binary scalar in the cache

  $test++;

  $cache1 = new File::Cache( { cache_key => $sTEST_CACHE_KEY,
                               implementation => $implementation,
                               namespace => $sTEST_NAMESPACE } );

  # Make a string of all possible ASCII characters
  $seed_value = '';

  for (my $i = 0; $i < 256 ; $i++)
  {
    $seed_value .= chr($i);
  }

  my $binary_key = 'key1';

  $status = $cache1->set($binary_key, $seed_value);

  if ($status == $sSUCCESS)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }


  # Test the getting of a binary scalar from the cache

  $test++;

  my $val6_retrieved = $cache1->get($binary_key);

  if ($val6_retrieved eq $seed_value)
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }

  File::Cache::CLEAR($sTEST_CACHE_KEY);
}


sub test_subprocess_get
{
  my ( $cache_key, $namespace, $username, $cache_depth, $implementation,
       $key, $expected_value, $test ) = @_;

  $cache_key or
    die( 'cache_key required' );

  $namespace or
    die( 'namespace required' );

  $username or
    die( 'username required' );

  $cache_depth or
    die( 'cache_depth required' );

  $implementation or
    die( 'implementation required' );

  $key or
    die( 'key required' );

  $expected_value or
    die( 'expected_value required' );

  $test or
    die( 'test required' );

  my $cache = new File::Cache( { cache_key => $cache_key,
                                 namespace => $namespace,
                                 username => $username,
                                 implementation => $implementation,
                                 cache_depth => $cache_depth } ) or
                                   die("Couldn't create cache");

  my $value = $cache->get($key) or
    die( "Couldn't get object at $key" );

  if ( $value eq $expected_value )
  {
    print "ok $test\n";
  }
  else
  {
    print "not ok $test\n";
  }
}

1;


