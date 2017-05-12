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

my %test32 = (
    'http://www.google.com/' => 1088293357,
    'Digest::FNV' => 2884831097,
    'abc123' => 3613024805,
    'pgsql://10.0.1.33:5432/postgres' => 1222035128
);

my %test32a = (
    'http://www.google.com/' => 912201313,
    'Digest::FNV' => 3166764897,
    'abc123' => 951228933,
    'pgsql://10.0.1.33:5432/postgres' => 713413542
);

# Test fnv() && fnv32
foreach my $key (keys %test32) {
    my $fnv = Digest::FNV::fnv($key);
    my $fnv32 = Digest::FNV::fnv32($key);
    ok (
        $fnv == $fnv32 &&
        $fnv == $test32{$key},
        'fnv/fnv32: '.$key
    );
}

# Test fnv32a()
foreach my $key (keys %test32) {
    my $fnv32a = Digest::FNV::fnv32a($key);
    ok (
        $fnv32a == $test32a{$key},
        'fnv32a: '.$key
    );
}
