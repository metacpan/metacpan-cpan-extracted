package Test::DX;

use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 35;
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

my($m,@m,%m,$M);
our($o,@o,%o,$O);

$m = $o = $g = 42;
@m = @o = @g = (3,4,'foo');
%m = %o = %g = ('def' => 'ghi');

save_pads();

foreach my $var (qw(m g o Test::DX::g Test::DX::o)) {
  my $subst = substitute("\$ $var", __PACKAGE__);
  ok($subst eq "42", "subst \$\\s+$var") or diag($subst);
  my $xsubst = xsubstitute("\$ $var", __PACKAGE__);
  ok($xsubst eq "\$$var${Devel::DumpTrace::XEVAL_SEPARATOR}42",
     "xsubst \$\\s+$var") or diag($xsubst);

  $subst = substitute("\$ $var\t[ 1 ]", __PACKAGE__);
  ok($subst eq "(3,4,'foo')[ 1 ]", "subst \$\\s+$var\\s+[]") or diag($subst);

  $subst = substitute("\@   $var  \[2,3\]",__PACKAGE__);
  ok($subst eq "(3,4,'foo')[2,3]", "subst \@\\s+$var\\s+[]")
    or diag($subst);

  $subst = substitute("\$ \t $var" . "{'key'}", __PACKAGE__);
  ok($subst eq "('def'=>'ghi'){'key'}", "subst \$\\s+$var\\s+{key}")
    or diag($subst);

  $subst = substitute("sort keys \%\n$var", __PACKAGE__);
  ok($subst eq "sort keys ('def'=>'ghi')", "subst \%\\s+$var")
    or diag($subst);

  $subst = substitute("\@  $var  \{'p','q'}", __PACKAGE__);
  ok($subst eq "('def'=>'ghi'){'p','q'}", "subst \@\\s+$var\\s+{}")
    or diag($subst);
}

__END__
