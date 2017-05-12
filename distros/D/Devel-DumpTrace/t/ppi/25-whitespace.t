package Test::DX;

use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 27;
  } else {
    plan skip_all => "PPI not available\n";
  }
}
use strict qw(vars subs);
use warnings;
use vars qw($g @g %g $G);
use Devel::DumpTrace::PPI ':test';
use PadWalker;

# exercise a few more edge cases for  
# Devel::DumpTrace::perform_variable_substitutions

my ($m,@m,%m,$M);
our ($o,@o,%o,$O);

$m = $o = $g = 42;
@m = @o = @g = (3,4,'foo');
%m = %o = %g = ('def' => 'ghi');

my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;

save_pads();
foreach my $var (qw(g m o)) {
  my $subst = substitute("\$ $var", __PACKAGE__);
  ok($subst eq "42", "subst \$\\s+$var");

  my $xsubst = xsubstitute("\$ $var", __PACKAGE__);
  ok($xsubst eq "\$$var${S}42", "xsubst \$\\s+$var");

  $subst = substitute("\$ $var\t[ 1 ]", __PACKAGE__);
  ok($subst eq "(3,4,'foo')[ 1 ]", "subst \$\\s+$var\\s+[]");

  $subst = substitute("\@   $var  \[2,3\]",__PACKAGE__);
  ok($subst eq "(3,4,'foo')[2,3]", "subst \@\\s+$var\\s+[]")
    or diag($subst);

  $subst = substitute("\$ \t $var" . "{'key'}", __PACKAGE__);
  ok($subst eq "('def'=>'ghi'){'key'}", "subst \$\\s+$var\\s+{key}");

  $subst = substitute("sort keys \%\n$var", __PACKAGE__);
  ok($subst eq "sort keys ('def'=>'ghi')", "subst \%\\s+$var");
  $xsubst = xsubstitute("sort keys \%\n$var", __PACKAGE__);
  ok($xsubst eq "sort keys \%$var${S}('def'=>'ghi')", "xsubst \%\\s+$var");

  $subst = substitute("\@  $var  \{'p','q'}", __PACKAGE__);
  ok($subst eq "('def'=>'ghi'){'p','q'}", "subst \@\\s+$var\\s+{}");
  $xsubst = xsubstitute("\@  $var  \{'p','q'}", __PACKAGE__);
  ok($xsubst eq "\@$var${S}('def'=>'ghi'){'p','q'}", 
     "xsubst \@\\s+$var\\s+{}");
}

__END__
