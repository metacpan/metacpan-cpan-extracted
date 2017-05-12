package MiniTest;
use strict;
use warnings;

my $done;
my $tests = 0;
my $failed = 0;

END {
  die "done_testing not seen!"
    if !$done;
  $? ||= $failed;
}

sub is ($$;$) {
  my ($got, $want, $message) = @_;

  $_ = defined $_ ? qq{'$_'} : 'undef'
    for $got, $want;

  ok ($got eq $want, $message) or do {
    s/\n/\n# /g
      for $got, $want;
    print STDERR "#   Failed test" . ($message ? " '$message'" : '') . "\n";
    print STDERR "#          got: $got\n";
    print STDERR "#     expected: $want\n";
    return !!0;
  };
}

sub ok ($;$) {
  my ($ok, $message) = @_;
  $tests++;
  if (!$ok) {
    print 'not ';
    $failed++;
  }
  print "ok $tests";
  print " - $message"
    if defined $message && length $message;
  print "\n";
  return $ok;
}

sub done_testing (;$) {
  if (@_) {
    die "tests done ($tests) doesn't match tests planned ($_[0])"
      if $tests != $_[0];
  }
  $done = 1;
  print "1..$tests\n";
}

sub import {
  my $target = caller;
  no strict 'refs';
  *{"${target}::$_"} = \&$_
    for qw(is ok done_testing);
}

1;
