package Test::DX;

use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 4;
  } else {
    plan skip_all => "PPI not available\n";
  }
}
use strict;
use warnings;
use English;
use vars qw($g @g %g $G);
use Devel::DumpTrace::PPI ':test';
use PadWalker;

# exercise Devel::DumpTrace::perform_variable_substitutions
# on some edge cases

$Devel::DumpTrace::DB_ARGS_DEPTH = 2;

# insert one extra stack frame so that perform_variable_substitutions
# can get the right '@_'

my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;

my $s1 = evaluate('$','$','','','<magic>');
my $s2 = substitute('$PID',__PACKAGE__);
ok($$ eq $s2, "\$__PKG__::PID retrieved pid $$") or diag($s2);
ok($s1 eq $s2, "\$__PKG__::PID retrieved pid $$") or diag($s1, $s2);

local $Devel::DumpTrace::HASHREPR_SORT = 1;
my $s3 = substitute('%ERRNO', __PACKAGE__);
my $s4 = evaluate('%','!','','','<magic>');
ok($s3 eq "(".hash_repr(\%!).")", 'subst for %__PKG__::ERRNO')
  or diag("$s3 \n\nne\n\n " . hash_repr(\%!));
ok($s3 eq $s4, 'subst for %__PKG__::ERRNO')
  or diag("$s3 \n\nne\n\n $s4");

