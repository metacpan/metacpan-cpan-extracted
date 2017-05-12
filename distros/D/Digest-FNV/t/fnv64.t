# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Digest-FNV.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 10;
use lib ( @INC, '../lib', '../blib/arch/auto/Digest/FNV' );
BEGIN { use_ok('Digest::FNV') };


my $fail = 0;
foreach my $constname (qw(
	FNV0_32_INIT FNV1A_64_LOWER FNV1A_64_UPPER FNV1_32A_INIT FNV1_32_INIT
	FNV1_64_LOWER FNV1_64_UPPER)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Digest::FNV macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %test64 = (
    'http://www.google.com/' => {'upper' => 2325532018, 'lower' => 1179644077},
    'Digest::FNV' => {'upper' => 3420530631, 'lower' => 3779597753},
    'abc123' => {'upper' => 613701733, 'lower' => 979917445},
    'pgsql://10.0.1.33:5432/postgres' => { 'upper' => 139274100, 'lower' => 3481306936}
);

my %test64a = (
    'http://www.google.com/' => {'upper' => 152110607, 'lower' => 1634959329},
    'Digest::FNV' => {'upper' => 3275304004, 'lower' => 421288737},
    'abc123' => {'upper' => 1657578049, 'lower' => 789249893},
    'pgsql://10.0.1.33:5432/postgres' => { 'upper' => 3211852046, 'lower' => 247944710}
);

foreach my $key (keys %test64) {
    my $fnv64 = Digest::FNV::fnv64($key);

    ok (
        $fnv64->{upper} == $test64{$key}{'upper'} &&
        $fnv64->{lower} == $test64{$key}{'lower'},
        'fnv64: '.$key
    );
}

foreach my $key (keys %test64a) {
    my $fnv64a = Digest::FNV::fnv64a($key);

    ok (
        $fnv64a->{upper} == $test64a{$key}{'upper'} &&
        $fnv64a->{lower} == $test64a{$key}{'lower'},
        'fnv64a: '.$key
    );
}
