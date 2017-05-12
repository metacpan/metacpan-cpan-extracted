# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Macrame.t'

#########################
BEGIN { print STDERR "IN  TEST SCRIPT\n"}
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw/no_plan/; # tests => 3;
# BEGIN { use_ok('Macrame') };
use Macrame;
BEGIN{ pass('file loaded OK')};
my $fish = { salmon => 'pink', quant => 700 };
#macro MYPASS(expl){pass('expl');}
#MYPASS(this_should_pass)
is($fish->{salmon} , 'pink', "unmunged ");

no Macrame;

ok(!0, 'still going after no');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


use Macrame;

macro foo { warn "incrementing to ".++$x::x."\n" }

warn "there is a comment\n"; #after this line
# there is a house, in new orleans # it's called the rising sun
# ooh nasty -- a single quotemark in a comment fools the
# parser in Filter::Simple ' there is the match for it

foo; foo; foo;

is($x::x, 3, 'ran foo macro three times');
no Macrame;
sub foo(){$x::yz++};
foo; foo;
is($x::x, 3, 'outside of macrame block macros not applied');
is($x::yz, 2, 'not applied at all');
use Macrame;
foo;
no Macrame;
is($x::x, 4, 'macros persist between Macrame blocks');


use Macrame;
macro setxx val {$x::x = val}
pass ('macro signature syntax no parens');

setxx '7';
is($x::x, 7, ' macro invocation quotelike argument');
setxx (27 + 4);
is($x::x, 31, ' macro invocation grouped argument');

macro  plusmeansminus left+right {left-right};
macro  plusmeansminus left - right {left+right};
pass ('macro syntax including pynctuation');

is((37-30), (plusmeansminus (7 + 15 * 2) + 30), "syntax triggered sig");
is((37+30), (plusmeansminus (7 + 15 * 2) - 30), "alternate syn trgrd sig");

no Macrame;
pass ('Whew!');


SKIP:{
skip("variadic arguments idea not implemented");
#the idea here is that a bracketed bareword till
#represent the entire contents of the brackets
#instead of exactly one lexeme in there
# this is deferred
use constant HaveVariadicArgumentSyntax => 0;
HaveVariadicArgumentSyntax and eval <<'LAVE';
use Macrame;
macro pmacro name (sig) [body] {
   macro name sig {body}
   macro name (sig) {body}
}

pmacro X(a,b)[ ( (a) x (b) ) ]
is(X('A',4),'AAAA', "mac in mac 1 of 2");
is(X'A',4,'AAAA', "mac in mac 2 of 2");
no Macrame
LAVE
} ################ end skip VariadicArgumentSyntax bit

use Macrame;
is(3, 9 SLASH 3, "predefined SLASH macro");
macro  plusmeansminus left SLASH right {left+right};
pass ('macro in macro definition signature part');
is((37+30), (plusmeansminus (7 + 15 * 2) SLASH 30), "macro in sig");
eval {
	plusmeansminus (7 + 15 * 2) *  30
};
ok($@, "should have failed to match anything");


macro keytest this 'and' that {this.that}

is("123",keytest "1" and 23,'matching keyword within macro sig');
no Macrame;


#use Macrame;
#
#macro expand '{term}' 'for' '(list)' {
#	EXPAND join ";\n", (map  term  list);
#};
#
#no Macrame;
use Macrame;

macro Xx x { EXPAND join(1,8,x); }
macro deferred_Xx x { join(1,8,x) }
my $EW;
is("8177",Xx 77, $EW="EXPAND works");

no Macrame;
use Macrame;

is($EW,"EXPAND works","EXPAND does not clobber remaining tokens in block");

no Macrame;
use Macrame;

macro pushJ T {push  @x::J, T;()} 

no Macrame;

# expand {
# 	warn "in expand macro with topic $_";
# 	# pushJ (Xx $_)  # co-erce macro into one token with parens
# 	# the problem with that is, the $_ gets filled during
# 	# the inner expansion -- of Xx -- not during the mapping
# 	# so, we can't have nested EXPANDs, at least not involving $_
# 	#
# 	"pushJ (deferred_Xx $_)"  # co-erce macro into one token with parens
# } for (1..3);

use Macrame;
EXPAND join ";\n",map {warn "in expand with topic $_"; "pushJ (Xx $_);" } (1..3);
is("@x::J","811 812 813","EXPAND can be used internally works");

no Macrame;

# use Macrame;
# is('abcdefgh',
# EXPAND Q T Q . FOR T : a bcd ef g ; 'h', '"EXPAND code FOR topic : arg" works');
# is('x aYZ bcd123 efgh',
# EXPAND QQ T i QQ . FOR T i: x a YZ bcd 123 efg ; 'h',
# '"EXPAND code FOR topic : arg" works with two topics');
# no Macrame;
# 

SKIP: {
	skip "EXPAND ... FOR topic: LIST; #syntax deferred"

};

	pass "something between no and use";


use Macrame;

my %stash;
# macro definestashaccessor0 NAME { macro NAME {NOMACROS $stash{Q NAME Q}} }
macro definestashaccessor0 NAME { macro NAME {(NOMACROS $stash{ NAME })} }

macro definestashaccessor NAME {
	sub NAME() : lvalue {
		$stash{NAME}
	};
};

# expand {definestashaccessor $_ } for (qw{A B C D E});
EXPAND join "\n", map {"definestashaccessor $_"}(qw{A B C D E});
C = 'cheese';
is('cheese', $stash{'C'}, "definition of accessors worked");

no Macrame; 
# can't really put this in a macro -- well a filter::macro maybe
use Macrame; 

EXPAND join "\n", map {"definestashaccessor0 $_"}(qw{J});
J = 'lemon';
is('lemon', (NOMACROS $stash{J}), "definition of accessors worked, involving a NOMACRO");
__END__


