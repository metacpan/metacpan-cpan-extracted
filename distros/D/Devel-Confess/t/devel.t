use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 2;
use lib 't/lib';
use Capture
  capture_as_debugger => ['-d:Confess'],
  capture_with_debugger => ['-d', '-MDevel::Confess'],
;
use Cwd qw(cwd);

my $code = <<'END_CODE';
BEGIN { print STDERR "started\n" }
package A;

sub f {
#line 1 test-block.pl
    die  "Beware!";
}

sub g {
#line 2 test-block.pl
    f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE

my $expected = <<"END_OUTPUT";
Beware! at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT

{
  my $out = capture_as_debugger $code;
  $out =~ s/\A.*?^started\s+//ms;
  is $out, $expected, 'Devel::Confess usable as a debugger';
}

{
  local %ENV = %ENV;
  delete $ENV{$_} for grep /^PERL5?DB/, keys %ENV;
  delete $ENV{LOGDIR};
  $ENV{HOME} = cwd;
  $ENV{PERLDB_OPTS} = 'NonStop noTTY dieLevel=1';
  my $out = capture_with_debugger $code;
  $out =~ s/\A.*?^started\s+//ms;
  like $out, qr/^\Q$expected/, 'Devel::Confess usable with the debugger';
}
