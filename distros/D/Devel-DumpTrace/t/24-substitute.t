package Test::DX;

use Devel::DumpTrace ':test';
use PadWalker;
use Test::More tests => 9;
use strict;
use warnings;
use vars qw($g @g %g $G);

# exercise a few more edge cases for  
# Devel::DumpTrace::perform_variable_substitutions

my ($m,@m,%m,$M);
our ($o,@o,%o,$O);

my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;

$m = $o = $g = sub { my $u = shift @_; print "Anonymous sub $u\n" };

save_pads();
foreach my $var (qw($g->(42) $m->(42) $o->(42))) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst =~ /\(REF\(0x\w+\)\)->\(42\)/, "subst $var") or diag($subst);

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok(index($xsubst, substr($var,0,2) . $S)==0, "xsubst $var");
  ok($xsubst =~ /\(REF\(0x\w+\)\)->\(42\)/, "xsubst $var") or diag($subst);
}

__END__
