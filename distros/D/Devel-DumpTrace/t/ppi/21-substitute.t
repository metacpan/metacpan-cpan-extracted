package Test::DX;

use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 24;
  } else {
    plan skip_all => "PPI not available\n";
  }
}
use strict;
use warnings;
use vars qw($g @g %g $G);
use Devel::DumpTrace::PPI ':test';
use PadWalker;

# exercise  Devel::DumpTrace::perform_variable_substitutions  on array/hash
# element access

my ($m,@m,%m,$M);
our ($o,@o,%o,$O);

my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;

$g = $m = $o = ['foo','bar'];
@g = @m = @o = (1,2,3,'bar');
%g = %m = %o = (abc => 'def', xyz => [42]);
save_pads();

foreach my $var (qw($g->[2] $m->[2] $o->[2])) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "['foo','bar']->[2]", "subst $var");

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq substr($var,0,2) . $S . $subst,
     "xsubst $var") or diag $xsubst;
}

foreach my $var (qw($g[1] $m[1] $o[1])) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "(1,2,3,'bar')[1]", "subst $var");

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq substr($var,0,2) . $S . $subst,
     "xsubst $var");
}

my $s1 = "('abc'=>'def';'xyz'=>[42]){'xyz'}";
my $s2 = "('xyz'=>[42];'abc'=>'def'){'xyz'}";

foreach my $var (qw($g{'xyz'} $m{'xyz'} $o{'xyz'})) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq $s1 || $subst eq $s2, "subst $var");

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq substr($var,0,2) . $S . $s1 ||
     $xsubst eq substr($var,0,2) . $S . $s2,
     "xsubst $var");
}

$g = $m = $o = { 'qrs' => 'tuv' };
foreach my $var (qw($g->{'key'} $m->{'key'} $o->{'key'})) {
  my  $subst = substitute($var, __PACKAGE__);
  ok($subst eq "{'qrs'=>'tuv'}->{'key'}", "subst $var");  

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq substr($var,0,2) . $S . $subst,
     "xsubst $var");
}
