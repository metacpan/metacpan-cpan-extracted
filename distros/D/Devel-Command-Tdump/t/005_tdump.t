use Test::More tests=>53;
use Devel::Command::Tdump;

tie *OUT, 'Capture';
open OUT, "dummy - not actually opened";
$contents = tied *OUT;

# We have to "export" this filehandle if we want it to be seen.
*DB::OUT = \*main::OUT;

# Test cases.
my %cases_of = (
  case_1 => { comment => "empty history",
              hist => [],
              count => 1,
              output => ["use Test::More tests=>0;\n"],
              message => qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
            },
  case_2 => { comment => "no valid tests",
               hist => [
                        '?',
                        'definitely not a test',
                        'bogus(1)',
                        'zorch'
               ],
              count => 1,
              output => ["use Test::More tests=>0;\n"],
              message => qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
            },
  case_3 => { comment => "one test, no setups",
              hist => ['?',
                       '$x="this is setup"',
                       '$y="no comment to trap it"',
                       'is(1,1)',
                       'c'],
              count => 2,
              output => [qq(use Test::More tests=>1;\n),
                         qq(is(1,1);\n) ],
              message => qq[Recording tests for this session in t/check.output ... done (1 test).\n],
            },
  case_4 => { comment => "two tests, no setup",
              hist => [
               '?',
               '$x="this is setup"',
               '$y="no comment to trap it"',
               'is(1,1)',
               'c',
               'isnt(2,1)',
              ],
              count => 3,
              output => [
                     qq(use Test::More tests=>2;\n),
                     qq(is(1,1);\n),
                     qq(isnt(2,1);\n)
              ],
              message => qq[Recording tests for this session in t/check.output ... done (2 tests).\n],
            },
  case_5 => { comment => "no tests, setup with one comment",
              hist => ['?',
                       '$x="this is not trapped"',
                       '$y="this has a comment to trap it"',
                       '# $y should be captured here',
                       'c',
              ],
              count => 3,
              output => [qq(use Test::More tests=>0;\n),
                         q(# $y should be captured here)."\n",
                         q($y="this has a comment to trap it";)."\n" 
              ],
              message => qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
            },
  case_6 => { comment => "multi-comment trapping",
              hist => [
               '?',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'c',
              ],
              count => 4,
              output => [
                     qq(use Test::More tests=>0;\n),
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n"
              ],
              message => qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
            },
  case_7 => { comment => "one test before, setup with two comments",
              hist => [
                '?',
               '$x="this is not trapped"',
               'is(1,1)',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'c',
              ],
              count => 5,
              output => [
                qq(use Test::More tests=>1;\n),
                qq[is(1,1);\n],
                q(# $y should be captured here)."\n",
                q(# this comment comes second)."\n",
                q($y="this has a comment to trap it";)."\n",
              ],
              message => qq[Recording tests for this session in t/check.output ... done (1 test).\n],
            },
  case_8 => { comment => "one test after, setup with two comments",
              hist => [
               '?',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'is(1,1)',
               'c',
              ],
              count => 5,
              output => [
                     qq(use Test::More tests=>1;\n),
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n",
                     qq[is(1,1);\n]
              ],
              message => qq[Recording tests for this session in t/check.output ... done (1 test).\n],
            },
  case_9 => { comment => "one test before and one after, setup with two comments",
              hist => [
               '?',
               'is(0,0)',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'is(1,1)',
               'c',
              ],
              count => 6,
              output => [
                     qq(use Test::More tests=>2;\n),
                     qq[is(0,0);\n],
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n",
                     qq[is(1,1);\n]
              ],
              message => qq[Recording tests for this session in t/check.output ... done (2 tests).\n],
            },
);

sub erase {
  close OUT;
  @DB::hist = ();
  unlink "t/check.output" or die "Can't unlink check.output: $!\n"
    if -e "t/check.output";
  open OUT, "reopen for capture";
}

sub slurp {
  my $file = (shift || "t/check.output");
  open SLURP, $file  or die "Can't read check.output: $!\n";
  my @file = <SLURP>;
  close SLURP;
  @file;
}

# Clean up to start out.
erase;

# tdump() expects @DB::hist to be around; we'l define it and fill it up
# with various possibilities.

# Test 0: Can't touch this.
SKIP:{
  skip "Can't do unwritable file test as root", 2 unless $> != 0;
  open(JUNK,">t/nowrite.file");
  close JUNK;
  chmod 0000, "t/nowrite.file";
  Devel::Command::Tdump::command("tdump t/nowrite.file");
  ok($$contents, "got a message");
  like($$contents, qr/can't write history:/, "expected error");
  chmod 0700, "t/nowrite.file";
  unlink "t/nowrite.file";
erase;
}

foreach my $case (keys %cases_of) {
   @DB::hist = @{$cases_of{$case}->{hist}};
   Devel::Command::Tdump::command("tdump t/check.output");
   @lines = slurp();
   ok(int @lines, "Something there");
   is(int @lines, $cases_of{$case}->{count}, "line count as expected");
   is_deeply(\@lines, $cases_of{$case}->{output}, "the output expected");
   ok($$contents, "got a message");
   is($$contents, $cases_of{$case}->{message}, "expected message ok");
   erase;
};

# Test 10 - no output file specified
unlink("unnamed_test.t");
@DB::hist = (
               '?',
               'is(0,0)',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'is(1,1)',
               'c',
             );
Devel::Command::Tdump::command("tdump");
ok(-e "unnamed_test.t", "default file now exists");
@lines = slurp("unnamed_test.t");
ok(int @lines, "Something there");
is(int @lines, 6, "six lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>2;\n),
                     qq[is(0,0);\n],
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n",
                     qq[is(1,1);\n] ], 
          "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in unnamed_test.t ... done (2 tests).\n],
     "expected message ok");
unlink("unnamed_test.t");
erase;
# Clean up on termination.
END {
  erase();
}

package Capture;
use Tie::Handle;
 
sub TIEHANDLE {
  my $class = shift;
  my $string = "";
  my $self = \$string;
  bless $self, $class;
}

sub OPEN {
  my $self = shift;
  $$self = "";
}

sub PRINT {
  my $self = shift;
  $$self .= join("", @_);
}  

sub FILENO {
 "Not really a file";
}

sub CLOSE { }
