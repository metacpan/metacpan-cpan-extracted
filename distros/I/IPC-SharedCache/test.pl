# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use IPC::SharedCache;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use IPC::SharedCache;

local($^W) = 1;

# test creation
my %cache;
tie %cache, 'IPC::SharedCache', 
  ipc_key => 'MYKI',
  load_callback => sub { return [time(), time(), time()] },
  validate_callback => sub { return 1; },
  debug => 0;
print "ok 2\n";

# test load
my $time_array = $cache{'some_key'};
die "not ok 3\n" unless defined($time_array);
die "not ok 3\n" unless ref($time_array) eq 'ARRAY';
print "ok 3\n";

# test delete/exists
delete($cache{'some_key'});
die "not ok 4\n" if exists($cache{'some_key'});
print "ok 4\n";

# test delete/exists
$time_array = $cache{'some_other_key'};
die "not ok 5\n" unless exists($cache{'some_other_key'});
print "ok 5\n";
delete($cache{'some_other_key'});

# test keys/each
my $a = $cache{'a'};
my $b = $cache{'b'};
my $c = $cache{'c'};
die "not ok 6\n" unless keys(%cache) == 3;
die "not ok 6\n" unless (keys(%cache))[0] eq 'a';
die "not ok 6\n" unless (keys(%cache))[1] eq 'b';
die "not ok 6\n" unless (keys(%cache))[2] eq 'c';
my @keys = keys(%cache);
for (my $x = 0; $x < 3; $x++) {
  die "not ok 6\n"
    unless ($keys[$x] eq scalar(each(%cache)));
}
delete($cache{'a'});
die "not ok 6\n" unless keys(%cache) == 2;
die "not ok 6\n" unless (keys(%cache))[0] eq 'b';
die "not ok 6\n" unless (keys(%cache))[1] eq 'c';
delete($cache{'b'});
die "not ok 6\n" unless keys(%cache) == 1;
die "not ok 6\n" unless (keys(%cache))[0] eq 'c';
delete($cache{'c'});
die "not ok 6\n" unless keys(%cache) == 0;
print "ok 6\n";

# clean up with remove
untie %cache;
IPC::SharedCache::remove('MYKI');

# test max_size
my %mcache;
tie %mcache, 'IPC::SharedCache', 
  ipc_key => 'MYKI',
  load_callback => sub { my $data = 'a' x 1024; return [ $data ]; },
  validate_callback => sub { return 1; },
  max_size => 4500,
  debug => 0;
print "ok 7\n";

# fill the cache
my $f = $mcache{'f'};
my $g = $mcache{'g'};
my $h = $mcache{'h'};
my $i = $mcache{'i'};
die "not ok 8\n" unless scalar(keys(%mcache)) == 4;
print "ok 8\n";

# this should make the cache delete 'f' by crossing max_size:
my $j = $mcache{'j'};
die "not ok 9\n" unless keys(%mcache) == 4;
die "not ok 9\n" unless (keys(%mcache))[0] eq 'g';
die "not ok 9\n" unless (keys(%mcache))[1] eq 'h';
die "not ok 9\n" unless (keys(%mcache))[2] eq 'i';
die "not ok 9\n" unless (keys(%mcache))[3] eq 'j';
print "ok 9\n";

# clean up
untie %mcache;
IPC::SharedCache::remove('MYKI');

#my %cache;
#tie %cache, 'IPC::SharedCache', 
#  ipc_key => 'MYKI',
#  load_callback => sub { die "blah" },
#  validate_callback => sub { return 1; },
#  max_size => 4500,
#  debug => 0;
#print "ok 10\n";
#
#my $z = $cache{'z'};
#
#{ 
#  print "ok 11\n";
#}
# IPC::SharedCache::remove('MYKI');
