 # Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Pro.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1+4*8+2*7 };
use HTML::Template::Pro;
use lib "t";
use HTML::Template::Pro::CommonTest;
ok(1); # If we made it this far, we're ok.

#########################

my $DEBUG=$ENV{HTMLTEMPLATEPRODEBUG};
$DEBUG||=0;

HTML::Template::Pro->register_function('registered_func'=>sub { return shift(); });
HTML::Template::Pro->register_function('hello_string'=>sub { return 'hello!'; });
HTML::Template::Pro->register_function('arglist'=>sub { return '['.join('][',@_).']'; });
HTML::Template::Pro->register_function( f1 => sub { return "F1: @_"; });
HTML::Template::Pro->register_function( f2 => sub { return "F2: @_"; });
HTML::Template::Pro->register_function( fUNDEF => sub { return undef; });

my @exprset1=(ONE=>1,TWO=>2,THREE=>3,ZERO=>0,MINUSTEN=>-10, FILE=>'test_if1.tmpl', TWENTY=>20,FOURTY=>50, EMPTYSTR=>'');
my @brunoext=('FOO.BAR'=>'<test passed>');
my @refset1=(
HASHREF0=>[],
HASHREF2=>[{},{}],
HASHREF1=>[
{LOOPVAR1=>'LOOP1-VAR1',LOOPVAR2=>'LOOP1-VAR2',LOOPVAR3=>'LOOP1-VAR3',LOOPVAR10=>'LOOP1-VAR10'},
{LOOPVAR1=>'LOOP2-VAR1',LOOPVAR2=>'LOOP2-VAR2',LOOPVAR3=>'LOOP2-VAR3',LOOPVAR10=>'LOOP2-VAR10'},
{LOOPVAR1=>'LOOP3-VAR1',LOOPVAR2=>'LOOP3-VAR2',LOOPVAR3=>'LOOP3-VAR3',LOOPVAR10=>'LOOP3-VAR10'},
{LOOPVAR1=>'LOOP4-VAR1',LOOPVAR2=>'LOOP4-VAR2',LOOPVAR3=>'LOOP4-VAR3',LOOPVAR10=>'LOOP4-VAR10'},
]);

test_tmpl_std('test_expr1', @exprset1);
test_tmpl_std('test_expr2', @exprset1);
test_tmpl_std('test_expr3', @exprset1);
test_tmpl_std('test_expr4', @brunoext);
test_tmpl_std('test_expr5', @exprset1);
test_tmpl_std('test_expr6', @exprset1);
test_tmpl_std('test_expr7', @refset1);
test_tmpl_std('test_expr8', @exprset1);
test_tmpl('test_expr9',[], n=>2);
test_tmpl_expr('test_userfunc1', @exprset1);
test_tmpl_expr('test_userfunc2', @exprset1);
test_tmpl_expr('test_userfunc3', @exprset1);
test_tmpl_expr('test_userfunc4', @exprset1);
test_tmpl_expr('test_userfunc5', @exprset1);
test_tmpl_expr('test_userfunc6', @exprset1);

# -------------------------

__END__

### Local Variables: 
### mode: perl
### End: 
