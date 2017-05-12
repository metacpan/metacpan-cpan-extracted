# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-Personality.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Linux::Personality') };
use Linux::Personality qw/ personality PER_LINUX32 /;

my $fail = 0;
foreach my $constname (qw(
	ADDR_COMPAT_LAYOUT ADDR_LIMIT_32BIT ADDR_LIMIT_3GB ADDR_NO_RANDOMIZE
	MMAP_PAGE_ZERO PER_BSD PER_HPUX PER_IRIX32 PER_IRIX64 PER_IRIXN32
	PER_ISCR4 PER_LINUX PER_LINUX32 PER_LINUX32_3GB PER_LINUX_32BIT
	PER_MASK PER_OSF4 PER_OSR5 PER_RISCOS PER_SCOSVR3 PER_SOLARIS PER_SUNOS
	PER_SVR3 PER_SVR4 PER_UW7 PER_WYSEV386 PER_XENIX READ_IMPLIES_EXEC
	SHORT_INODE STICKY_TIMEOUTS WHOLE_SECONDS)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Linux::Personality macro $constname/) {
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

my $uname = `uname -m`;
chomp $uname;
SKIP: {
        skip "need x86_64 architecture", 1 unless $uname eq "x86_64";
        &Linux::Personality::personality(0x0008);
        my $per_uname = `uname -m`;
        chomp $per_uname;
        like($per_uname, qr/i[36]86/, "personality set to linux32");
}

personality(PER_LINUX32);
ok(1, "survived personality set");
