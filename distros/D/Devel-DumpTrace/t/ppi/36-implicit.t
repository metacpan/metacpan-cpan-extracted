package ImplicitTest;
use Test::More tests => 21;
use Devel::DumpTrace::PPI ':test';
use PPI;
use strict;
use warnings;

# more implicit argument tests, see also t/ppi/32-implicit.t

*preval = \&Devel::DumpTrace::PPI::preval;
*__add_implicit_elements = \&Devel::DumpTrace::PPI::__add_implicit_elements;

$_ = "FOOasdfBAR";
$. = 10;
@ARGV = ('squeam', '73');
$ENV{TEST_36} = "value 36";




my $doc = new PPI::Document(\<<'__EOD__');
if ($ENV{BEGIN_BIG_BLOCK} != 7) {
  m+asdf+ && print "Contains asdf\n";
  s/bar/quux/i && print "$_ world\n";
  my $r = y/0-9/a-j/;
  if (my $z=log) {
    print;
  }
  my $zz = ref;
  if (sin ... 17) {
    my $zzz = 512;
  }
  my $zzz = shift;
  some_function(-f);
  while (42 .. $zzz) {
      chomp;
  }
  while (<FOO>) {
      my $done = 1;
      while (<$BAZ{$done}>) {
          $done--;
      }
      while (!$done && <BAR>) {
          $done = 0;
      }
  }
  print "END_BIG_BLOCK\n" if -t;
}
__EOD__





my $s = $doc->find('PPI::Statement');
for (@$s) {
    __add_implicit_elements($_);
    Devel::DumpTrace::PPI::__add_implicit_to_given_when_blocks($_);
}

my @z1 = preval($s->[0], 1, __PACKAGE__);  # big if (...) {...}

ok("@z1" =~ /BEGIN_BIG_BLOCK/ && "@z1" =~ /END_BIG_BLOCK/,
   'captures big if statement');
ok("@z1" =~ /\$_:'FOOasdfBAR'/, '$_ attached value');
ok("@z1" =~ /\$_.*=~.*m\+asdf\+/, 'implicit $_ to m//');
ok("@z1" =~ m[\$_.*=~.*s/bar/], 'implicit $_ to s///');
ok("@z1" =~ m[\$_.*=~.*y/0-9/], 'implicit $_ to y//,tr//');
ok("@z1" =~ m[\$z\s+=\s+log\s+\$_], 'implicit $_ to log');
ok("@z1" =~ m[\$zz\s+=\s+ref\s+\$_], 'implicit $_ to ref');
ok("@z1" =~ m[sin\s+\$_], 'implicit $_ to sin');
ok("@z1" =~ m[\$\..*\s+==\s+17], 'implicit $. to number in ...');
ok("@z1" =~ m[\.\.\.\s+\$\.:10], '$. attached value ...');
ok("@z1" =~ m[\$zzz\b.*shift\s+\@ARGV], 'implicit @ARGV');
ok("@z1" =~ m[\@ARGV:\(\'squeam], '@ARGV attached value');
ok("@z1" =~ m[-f\s+\$_], 'implicit $_ to -f');
ok("@z1" =~ m[-f\s+\$_:'FOO], '$_ attached value');
ok("@z1" =~ m[while\s+\(\s*\$\.], 'implicit $. to number in ..');
ok("@z1" =~ m[\$\.:10\s+==\s+42\s+\.\.\s], '$. attached value ..');
ok("@z1" =~ m[while\s+\(\s*\$_\s*=\s*<FOO>], 'implicit $_ to <HANDLE>');
ok("@z1" =~ m[<\s*BAR\s*>] && "@z1" !~ m[\$_\s*=\s*<\s*BAR\s*>],
   'no implicit $_ to <HANDLE> in expr');
ok("@z1" =~ m[<\s*\$BAZ] && "@z1" !~ m[\$_\s*=\s*<\$BAZ],
   'no implicit $_ to <complex HANDLE>');
ok("@z1" =~ m[-t\b] && !m[-t\b\s+\$_], 'no implicit $_ to -t');

ok("@z1" =~ /TEST_36.*value 36/, '%ENV attached value');

