package Test::DX;

use Devel::DumpTrace ':test';
use PadWalker;
use Test::More tests => 20;
use strict;
use warnings;
use vars qw($g @g %g $G);

# exercise  Devel::DumpTrace::perform_variable_substitutions  function

my ($m,@m,%m,$M);
our ($o,@o,%o,$O);

my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;

$g = $m = $o = 'foo';
@g = @m = @o = (1,2,3,'bar');
%g = %m = %o = (abc => 'def', xyz => [42]);
save_pads();

foreach my $var (qw($g $m $o)) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "'foo'", 'subst ' . $var);

  my $xsubst = xsubstitute($var,__PACKAGE__);
  ok($xsubst eq "$var${S}'foo'", 'xsubst ' . $var) or diag($xsubst);
}
my $subst = substitute('$g . $m . $o', __PACKAGE__);
ok($subst eq "'foo' . 'foo' . 'foo'", 'subst $glob $my $our')
	or diag("<$subst>");
my $xsubst = xsubstitute('$g . $m . $o', __PACKAGE__);
ok($xsubst eq "\$g${S}'foo' . \$m${S}'foo' . \$o${S}'foo'", 
   'xsubst $glob $my $curr');

foreach my $var (qw(@g @m @o)) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "(1,2,3,'bar')", "subst $var");

  $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq "$var${S}(1,2,3,'bar')", "xsubst $var");
}


my $s1 = "('abc'=>'def';'xyz'=>[42])";
my $s2 = "('xyz'=>[42];'abc'=>'def')";

foreach my $var (qw(%g %m %o)) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq $s1 || $subst eq $s2, "subst $var");

  $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq "$var${S}$s1" || $xsubst eq "$var${S}$s2", "xsubst $var");
}
