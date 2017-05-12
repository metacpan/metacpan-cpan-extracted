# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Linux-Shadow.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 16;
BEGIN { use_ok('Linux::Shadow', qw(SHADOW getspnam getspent setspent endspent getpwnam getpwuid getpwent)) };


my $fail = 0;
foreach my $constname (qw(
	SHADOW)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Linux::Shadow macro $constname/) {
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

ok defined &getspnam;
ok defined &getspent;
ok defined &setspent;
ok defined &endspent;

SKIP: {
  skip('Shadow functions require access to the shadow file', 10) if (! -r SHADOW); 

  $fail = 0;
  my @shadow = getspnam('root');
  if (!@shadow) {
    $fail = 1;
  } elsif ($#shadow != 8) {
    $fail = 1;
  } elsif ($shadow[0] ne 'root') {
    $fail = 0;
  }
  ok( $fail == 0 , 'getspnam root' );

  @shadow = getspnam('rootybogus');
  if (@shadow) {
    $fail = 1;
  }
  ok( $fail == 0, 'getspnam rootybogus' );

  my $name;
  @shadow = getspent();
  if (!@shadow) {
    $fail = 1;
  } elsif ($#shadow != 8) {
    $fail = 1;
  }
  $name = $shadow[0];
  @shadow = getspent();
  if (!@shadow) {
    $fail = 1;
  } elsif ($#shadow != 8) {
    $fail = 1;
  } elsif ($shadow[0] eq $name) {
    $fail = 1;
  }
  ok( $fail == 0, 'getspent' );

  my $i = 2;
  while (@shadow = getspent()) {
    $i++;
  }
  if (open my $fh, '<', SHADOW) {
    my @sfile = <$fh>;
    close $fh;
    if ($i != scalar(@sfile)) {
      $fail = 1;
    }
  } else {
    $fail = 2;
  }
  ok( $fail == 0, ($fail == 1) ? 'getspent entry count mismatch' : "getspent couldn't open ".SHADOW );

  @shadow = getspent();
  if (@shadow) {
    $fail = 1;
  }
  ok( $fail == 0, 'getspent end of list' );

  setspent();
  @shadow = getspent();
  if (!@shadow) {
    $fail = 1;
  } elsif ($#shadow != 8) {
    $fail = 1;
  } elsif ($shadow[0] ne $name) {
    $fail = 1;
  }
  ok( $fail == 0, 'setspent' );

  endspent();
  @shadow = getspent();
  if (!@shadow) {
    $fail = 1;
  } elsif ($#shadow != 8) {
    $fail = 1;
  } elsif ($shadow[0] ne $name) {
    $fail = 1;
  }
  ok( $fail == 0, 'endspent' );

  my @pwent = getpwnam('root');
  if (!@pwent) {
     $fail = 1;
  } elsif ($#pwent != 9) {
     $fail = 1;
  }
  ok( $fail == 0, 'getpwnam overload' );

  @pwent = getpwuid(0);
  if (!@pwent) {
     $fail = 1;
  } elsif ($#pwent != 9) {
     $fail = 1;
  }
  ok( $fail == 0, 'getpwuid overload' );

  @pwent = getpwent();
  if (!@pwent) {
     $fail = 1;
  } elsif ($#pwent != 9) {
     $fail = 1;
  }
  ok( $fail == 0, 'getpwent overload' );

}
