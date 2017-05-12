package Test::DX;

use Devel::DumpTrace ':test';
use PadWalker;
use Test::More tests => 2;
use strict;
use warnings;
use English;
use vars qw($g @g %g $G);

# exercise  Devel::DumpTrace::perform_variable_substitutions
# on some edge cases

$Devel::DumpTrace::DB_ARGS_DEPTH = 2;

# insert one extra stack frame so that perform_variable_substitutions
# can get the right '@_'

my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;

my $s2 = substitute('$PID',__PACKAGE__);
ok($$ eq $s2, "\$__PKG__::PID retrieved pid $$") or diag($s2);

# hash ordering may of cached %!,%ERRNO may differ in v5.17.10?
local $Devel::DumpTrace::HASHREPR_SORT = $] >= 5.017010;
my $s3 = substitute('%ERRNO', __PACKAGE__);
my $s4 = hash_repr(\%!);
ok($s3 eq "($s4)", 'subst for %__PKG__::ERRNO')
  or diag("$s3 \n\nne\n\n " . hash_repr(\%!), "\n\n",$s4);

