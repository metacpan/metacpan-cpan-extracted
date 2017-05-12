use Test::More tests => 35;

use Env::Modify 'system', 'source';
use strict;
use warnings;
use Cwd;
no warnings 'io';
no warnings 'once';

# not every system has /bin/true
my $bin_true = "'$^X' -e 'exit 0'";

open SOURCE,'>','my_export.sh';
print SOURCE "export foo=bar\n";
print SOURCE "baz=quux\n";
print SOURCE "abc=123\n";
print SOURCE "export baz abc\n";
close SOURCE;

for my $sh (qw(sh bash dash zsh ksh)) {
    local %ENV = ();
    local $Env::Modify::SHELL = $sh;
    my $cwd = Cwd::getcwd;
  SKIP: {
      my $c0 = eval { system("$bin_true") };
      if ($@) {
          if($@ =~ /error opening pipe/) {
              skip "shell $sh not available for testing", 5;
          }
      }
      ok($c0 == 0, "/bin/true returns true in $sh");
      no warnings 'uninitialized';
      ok($ENV{foo} eq '' && $ENV{baz} eq '' && $ENV{'abc'} eq '',
         "initial $sh environment is clean");
      my $c1 = eval { source("$cwd/my_export.sh"); }; # $cwd necessary for dash
      if ($@) {
          diag $@;
          ok(0, "source() return true status in $sh");
          skip "source() did not return true in $sh", 2;
      }
      ok($c1 == 0, "source() returned true status in $sh");
      ok($ENV{foo} eq 'bar', "export in $sh source successful");
      ok($ENV{baz} eq 'quux' && $ENV{abc} eq '123',
         "late export in $sh source successful");
    }
}
unlink "my_export.sh";


# I think Shell-GetEnv 0.09 still has a bug reading the exit code from csh.
# Skip csh tests if that bug isn't patched.
my $skip_csh;
{
    local $Env::Modify::SHELL = 'csh';
    my $c0 = eval { system("$bin_true") };
    if ($@) {
        diag "Think csh status is broken in Shell-GetEnv $Shell::GetEnv::VERSION: $@";
        $skip_csh = "can't retrieve csh status in Shell-GetEnv $Shell::GetEnv::VERSION";
        chomp($skip_csh);
    }
}

open SOURCE,'>','my_setenv.sh';
print SOURCE "setenv foo bar\n";
print SOURCE "setenv baz quux\n";
print SOURCE "setenv abc 123\n";
close SOURCE;

for my $sh (qw(csh tcsh)) {
    local %ENV = ();
    local $Env::Modify::SHELL = $sh;
  SKIP: {
      if ($sh eq 'csh' && $skip_csh) {
          skip "$skip_csh. Skipping csh", 5;
      }
      # this can fail on csh that require you to say "setenv foo $status"
      # instead of "setenv foo $?". Fix needed in Shell::GetEnv
      my $c0 = eval { system("$bin_true") };
      if ($@ && $@ =~ /error opening pipe/) {
          skip "shell $sh not available for testing", 5;
      }
      ok($c0 == 0, "/bin/true returns true in $sh");
      no warnings 'uninitialized';
      ok($ENV{foo} eq '' && $ENV{baz} eq '' && $ENV{'abc'} eq '',
         'initial environment is clean');
      my $c1 = eval { source("my_setenv.sh") };
      if ($@) {
          diag $@;
          ok(0, "source() return true status in $sh");
          skip "source() did not return true in $sh", 2;
      }
      ok($c1 == 0, "source() returned true status in $sh");
      ok($ENV{foo} eq 'bar', "export in $sh source successful");
      ok($ENV{baz} eq 'quux' && $ENV{abc} eq '123',
         "late export in $sh source successful");
    }
}
unlink "my_setenv.sh";
