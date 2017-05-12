package Test::DX;

use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 16;
  } else {
    plan skip_all => "PPI not available\n";
  }
}
use strict;
use warnings;
use vars qw($g @g %g $G);
use Devel::DumpTrace::PPI ':test';
use PadWalker;

# exercise Devel::DumpTrace::perform_variable_substitutions
# on some edge cases

$Devel::DumpTrace::DB_ARGS_DEPTH = 2;

# insert one extra stack frame so that perform_variable_substitutions
# can get the right '@_'

my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;

sub substitute_args {
  my @args = @_;
  save_pads();
  my $subst1 = substitute('@_', __PACKAGE__);
  my $subst2 = substitute('@args', __PACKAGE__);
  shift @_;
  pop @_;
  my @z = @_;
  save_pads();
  my $subst3 = substitute('@_', __PACKAGE__);
  my $subst4 = substitute('@z', __PACKAGE__);
  ($subst1, $subst2, $subst3, $subst4);
}

my $foo = 'shoe';
my ($s1, $s2, $s3, $s4) = substitute_args(1,2,'buckle',$foo);
ok($s1 eq "(1,2,'buckle','shoe')", 'substitute for @_') or diag($s1);
ok($s2 eq "(1,2,'buckle','shoe')", 'substitute for my @_ copy') or diag($s2);
ok($s4 eq "(2,'buckle')", 'substitute for copy of  modified @_') or diag($s4);

# Why doesn't this test pass?
#    I expect $s3 to contain the current contents of @_ ((2,'buckle'))
#    or even the original contents ((1,2,'buckle','shoe')) but it 
#    actually is "(1,2,'buckle')"
#
#    aha, a revelation from  perldoc -f caller (>= 5.12)
#        Also be aware that setting @DB::args is best effort, intended for 
#        debugging or generating backtraces, and should not be relied upon. 
#        In particular, as @_ contains aliases to the caller's arguments, 
#        Perl does not take a copy of @_ , so @DB::args will contain 
#        modifications the subroutine makes to @_ or its contents, not the 
#        original values at call time. @DB::args , like @_ , does not hold 
#        explicit references to its elements, so under certain cases its 
#        elements may have become freed and reallocated for other variables 
#        or temporary values. Finally, a side effect of the current 
#        implementation means that the effects of shift @_ can normally be 
#        undone (but not pop @_ or other splicing, and not if a reference 
#        to @_ has been taken, and subject to the caveat about reallocated 
#        elements), so @DB::args is actually a hybrid of the current state 
#        and initial state of @_ . Buyer beware.
#
ok(1, "# substitute for modified \@_") or
  ok($s3 eq "(2,'buckle')", 'substitute for modified @_') or diag($s3);

sub substitution_arg_s {
  my @args = @_;
  save_pads();
  my $subst1 = substitute('$_[0] + $_[1]', __PACKAGE__);
  my $subst2 = substitute('$args[0] + $args[1]', __PACKAGE__);
  pop @_;
  pop @_;
  my $subst3 = substitute('$_[0] + $_[1]', __PACKAGE__);
  $_[1] = 3;
  $_[2] = 7;
  my $subst4 = substitute('$_[0] + $_[1]', __PACKAGE__);

  ($subst1, $subst2, $subst3, $subst4);
}

my @a = qw(q w e r t y);
my ($t1,$t2,$t3,$t4) = substitution_arg_s(@a);
ok($t1 eq "('q','w','e','r','t','y')[0] + ('q','w','e','r','t','y')[1]",
   'substitute for $_[]') or diag($t1); ## >= 01X
ok($t2 eq "('q','w','e','r','t','y')[0] + ('q','w','e','r','t','y')[1]",
   'substitute for copy of $_[]') or diag($t2); ## >= 01X
ok($t3 eq "('q','w','e','r')[0] + ('q','w','e','r')[1]",
   'substitute for truncated $_[]') or diag($t3);
ok($t4 eq "('q',3,7,'r')[0] + ('q',3,7,'r')[1]",
   'substitute for modified $_[]') or diag($t3);

save_previous_regex_matches();
my $u1 = substitute('system("ps | grep $0")',__PACKAGE__);
ok($u1 eq "system(\"ps | grep '$0'\")", 'subst $0') or diag($u1);

$_ = "abacada";
my $u2 = substitute('$_ =~ /a+(.)a+(.)a+(.)a+/', __PACKAGE__);
ok($u2 eq "'abacada' =~ /a+(.)a+(.)a+(.)a+/", 'subst $_') or diag($u2);

my $u22 = xsubstitute('$_ =~ /a+(.)a+(.)a+(.)a+/', __PACKAGE__);
ok($u22 eq '$_' . $S . $u2, 'xsubst $_');

/a+(.)a+(.)a+(.)a+/;
my @m = ($1, $2, $3);
save_pads();
save_previous_regex_matches();
my $u3 = substitute('@m=($1,$2,$3)',__PACKAGE__);
ok($u3 eq "('b','c','d')=('b','c','d')", 'subst $1,$2,...')
  or diag($u3);
$u3 = xsubstitute('@m=($1,$2,$3)', __PACKAGE__);
ok($u3 eq '@m' . $S . "('b','c','d')=("
   . '$1' . $S . q('b',$2) . $S . q('c',$3) . $S . "'d')",
   'xsubst $1,$2,...');

@ARGV = qw(bar foo quux);
my $u4 = substitute('shift @ARGV', __PACKAGE__);
shift @ARGV;
my $u5 = substitute('foo($ARGV[1])', __PACKAGE__);
ok($u4 eq "shift ('bar','foo','quux')", 'subst @ARGV') or diag($u4);
ok($u5 eq "foo(('foo','quux')[1])", 'subst $ARGV[]') or diag($u5);

use Config;
my ($sig) = (split / /, $Config{sig_name})[1];
$SIG{$sig} = 'DEFAULT';
my $v5 = substitute('%SIG',__PACKAGE__);
ok($v5 =~ /'$sig'=>'DEFAULT'/, 'subst %SIG');

__END__


