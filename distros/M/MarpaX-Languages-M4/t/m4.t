#!perl
use strict;
use warnings FATAL   => 'all';
use File::Temp qw/tempfile/;
use File::Spec;
use Test::More;
use Log::Handler;
use Log::Any::Adapter;
use Log::Any::Adapter::Handler;
use Data::Section -setup => {
  header_re => qr/
    \A                # start
      _+!             # __!
        \s*           # any whitespace
          ([^!]+?)    # this is the actual name of the section
        \s*           # any whitespace
      !_+             # !__
      [\x0d\x0a]{1,2} # possible cariage return for windows files
    \z                # end
  /x};

my $log = Log::Handler->new(
    screen => {
        log_to   => "STDOUT",
        maxlevel => "debug",
        minlevel => "error",
        dateformat     => "%Y-%m-%d",
        timeformat     => "%H:%M:%S",
        message_layout => "%D %T %L %m",
    }
    );
Log::Any::Adapter->set('Handler', logger => $log);

BEGIN {
    use_ok('MarpaX::Languages::M4')
        || print "Bail out!\n";
}

#
# Variables used for portability
#
my $fhfoo = File::Temp->new();
print $fhfoo "bar\n";
close($fhfoo);
my $echo = File::Spec->catfile('inc', 'echo.pl');
my $tmpfile = File::Spec->catfile(File::Spec->tmpdir(), 'fooXXXXXX');

foreach (grep {/: input/} sort {$a cmp $b} __PACKAGE__->section_data_names) {
  my $testName = $_;
  my $inputRef = __PACKAGE__->section_data($testName);
  local @ARGV = ();
  if ($testName =~ /: input\((.+)\)/) {
    @ARGV = eval "($1)";
  }
  $testName =~ s/: input.*//;
  my $testIsCmp = 0;
  my $outputRef = __PACKAGE__->section_data("$testName: ANYoutput");
  if (! defined($outputRef)) {
    $outputRef = __PACKAGE__->section_data("$testName: output");
    $testIsCmp = 1;
  }
  #
  # Take care: Data::Section does not reproduce data EXACTLY
  #
  # For instance, test 112, I MIGHT write: \\-a\-b\-c\- to have it read \-a\-b\-c\-
  # ...
  #
  if ($testName eq '112 patsubst - warning') {
      $outputRef = \"abc
abc
\\-a\\-b\\-c\\-
";
  }

  my $input = ${$inputRef};
  #
  # For the special foo temporary file
  #
  $input =~ s/%%%FOO%%%/$fhfoo/g;
  $input =~ s/%%%ECHO%%%/$echo/g;
  $input =~ s/%%%TMPFILE%%%/$tmpfile/g;
  my $m4 = MarpaX::Languages::M4->new_with_options();
  #
  # Our include directory
  #
  $m4->include(['inc']);
  #
  # Global test settings so that the test-suite works on all platforms:
  # the test suite below assumes LF line-ending.
  #
  $m4->cmdtounix(1);
  $m4->inctounix(1);

  $testName =~ s/\d+\s*//;
  if ($testIsCmp) {
    cmp_ok($m4->parse($input), 'eq', ${$outputRef}, $testName);
  } else {
    ok(length($m4->parse($input)) > 0, $testName);
  }
}

done_testing();

__DATA__
__! 001 empty input: input !__
__! 001 empty input: output !__
__! 002 define - Hello World: input !__
define(`foo', `Hello world.')
foo
__! 002 define - Hello World: output !__

Hello world.
__! 003 define - Composites array/array_set: input !__
define(`array', `defn(format(``array[%d]'', `$1'))')
define(`array_set', `define(format(``array[%d]'', `$1'), `$2')')
array_set(`4', `array element no. 4')
array_set(`17', `array element no. 17')
array(`4')
array(eval(`10 + 7'))
__! 003 define - Composites array/array_set: output !__




array element no. 4
array element no. 17
__! 004 define - Composite exch: input !__
define(`exch', `$2, $1')
exch(`arg1', `arg2')
__! 004 define - Composite exch: output !__

arg2, arg1
__! 005 define - Composite exch on define: input !__
define(`exch', `$2, $1')
define(exch(``expansion text'', ``macro''))
macro
__! 005 define - Composite exch on define: output !__


expansion text
__! 006 define - $0: input !__
define(`test', ``Macro name: $0'')
test
__! 006 define - $0: output !__

Macro name: test
__! 007 define - Quoted text: input !__
define(`foo', `This is macro `foo'.')
foo
__! 007 define - Quoted text: output !__

This is macro foo.
__! 008 define - ${: input !__
define(`foo', `single quoted $`'{1} output')
define(`bar', ``double quoted $'`{2} output'')
foo(`a', `b')
bar(`a', `b')
__! 008 define - ${: output !__


single quoted ${1} output
double quoted ${2} output
__! 009 define - Composite nargs: input !__
define(`nargs', `$#')
nargs
nargs()
nargs(`arg1', `arg2', `arg3')
nargs(`commas can be quoted, like this')
nargs(arg1#inside comments, commas do not separate arguments
still arg1)
nargs((unquoted parentheses, like this, group arguments))
__! 009 define - Composite nargs: output !__

0
1
3
1
1
1
__! 010 define - #: input !__
dnl Attempt to define a macro to just `$#'
define(underquoted, $#)
oops)
underquoted
__! 010 define - #: output !__

0)
oops
__! 011 define - $*: input !__
define(`echo', `$*')
echo(arg1,    arg2, arg3 , arg4)
__! 011 define - $*: output !__

arg1,arg2,arg3 ,arg4
__! 012 define - $@: input !__
define(`echo', `$@')
echo(arg1,    arg2, arg3 , arg4)
__! 012 define - $@: output !__

arg1,arg2,arg3 ,arg4
__! 013 define - $* and $@: input !__
define(`echo1', `$*')
define(`echo2', `$@')
define(`foo', `This is macro `foo'.')
echo1(foo)
echo1(`foo')
echo2(foo)
echo2(`foo')
__! 013 define - $* and $@: output !__



This is macro This is macro foo..
This is macro foo.
This is macro foo.
foo
__! 014 define - $* and $@ and #: input !__
define(`echo1', `$*')
define(`echo2', `$@')
define(`foo', `bar')
echo1(#foo'foo
foo)
echo2(#foo'foo
foo)
__! 014 define - $* and $@ and #: output !__



#foo'foo
bar
#foobar
bar'
__! 015 define - $: input !__
define(`foo', `$$$ hello $$$')
foo
__! 015 define - $: output !__

$$$ hello $$$
__! 016 define - expand to e.g. $12: input !__
define(`foo', `no nested quote: $1')
foo(`arg')
define(`foo', `nested quote around $: `$'1')
foo(`arg')
define(`foo', `nested empty quote after $: $`'1')
foo(`arg')
define(`foo', `nested quote around next character: $`1'')
foo(`arg')
define(`foo', `nested quote around both: `$1'')
foo(`arg')
__! 016 define - expand to e.g. $12: output !__

no nested quote: arg

nested quote around $: $1

nested empty quote after $: $1

nested quote around next character: $1

nested quote around both: arg
__! 017 undefine: input !__
foo bar blah
define(`foo', `some')define(`bar', `other')define(`blah', `text')
foo bar blah
undefine(`foo')
foo bar blah
undefine(`bar', `blah')
foo bar blah
__! 017 undefine: output !__
foo bar blah

some other text

foo other text

foo bar blah
__! 018 undefine a macro inside macros's expansion: input !__
define(`f', ``$0':$1')
f(f(f(undefine(`f')`hello world')))
f(`bye')
__! 018 undefine a macro inside macros's expansion: output !__

f:f:f:hello world
f(bye)
__! 019 defn - rename undefine: input !__
define(`zap', defn(`undefine'))
zap(`undefine')
undefine(`zap')
__! 019 defn - rename undefine: output !__


undefine(zap)
__! 020 defn - use of $0: input !__
define(`foo', `This is `$0'')
define(`bar', defn(`foo'))
bar
__! 020 defn - use of $0: output !__


This is bar
__! 021 defn - avoid unwanted expansion of text: input !__
define(`string', `The macro dnl is very useful
')
string
defn(`string')
__! 021 defn - avoid unwanted expansion of text: output !__

The macro 
The macro dnl is very useful

__! 022 defn - avoid unbalanced end-quote: input !__
define(`foo', a'a)
define(`a', `A')
define(`echo', `$@')
foo
defn(`foo')
echo(foo)
__! 022 defn - avoid unbalanced end-quote: output !__



A'A
aA'
AA'
__! 023 defn - join unbalanced quotes: input !__
define(`l', `<[>')define(`r', `<]>')
changequote(`[', `]')
defn([l])defn([r])
])
defn([l], [r])
__! 023 defn - join unbalanced quotes: output !__


<[>]defn([r])
)
<[>][<]>
__! 024 defn - special tokens outside of expected context: input !__
defn(`defn')
define(defn(`divnum'), `cannot redefine a builtin token')
divnum
len(defn(`divnum'))
__! 024 defn - special tokens outside of expected context: output !__


0
0
__! 025 defn can only join text macros: input !__
define(`a', `A')define(`AA', `b')
defn(`a', `divnum', `a')
define(`mydivnum', defn(`divnum', `divnum'))mydivnum
__! 025 defn can only join text macros: output !__

AA

__! 026 pushdef/popdef: input !__
define(`foo', `Expansion one.')
foo
pushdef(`foo', `Expansion two.')
foo
pushdef(`foo', `Expansion three.')
pushdef(`foo', `Expansion four.')
popdef(`foo')
foo
popdef(`foo', `foo')
foo
popdef(`foo')
foo
__! 026 pushdef/popdef: output !__

Expansion one.

Expansion two.



Expansion three.

Expansion one.

foo
__! 027 pushdef/popdef rather than define: input !__
define(`foo', `Expansion one.')
foo
pushdef(`foo', `Expansion two.')
foo
define(`foo', `Second expansion two.')
foo
undefine(`foo')
foo
__! 027 pushdef/popdef rather than define: output !__

Expansion one.

Expansion two.

Second expansion two.

foo
__! 028 indir - invalid name: input !__
define(`$$internal$macro', `Internal macro (name `$0')')
$$internal$macro
indir(`$$internal$macro')
__! 028 indir - invalid name: output !__

$$internal$macro
Internal macro (name $$internal$macro)
__! 029 indir - arguments collection: input !__
define(`f', `1')
f(define(`f', `2'))
indir(`f', define(`f', `3'))
indir(`f', undefine(`f'))
__! 029 indir - arguments collection: output !__

1
3

__! 030 indir on defn output: input !__
indir(defn(`defn'), `divnum')
indir(`define', defn(`defn'), `divnum')
indir(`define', `foo', defn(`divnum'))
foo
indir(`divert', defn(`foo'))
__! 030 indir on defn output: output !__



0

__! 031 builtin: input !__
pushdef(`define', `hidden')
undefine(`undefine')
define(`foo', `bar')
foo
builtin(`define', `foo', defn(`divnum'))
foo
builtin(`define', `foo', `BAR')
foo
undefine(`foo')
foo
builtin(`undefine', `foo')
foo
__! 031 builtin: output !__


hidden
foo

0

BAR
undefine(foo)
BAR

foo
__! 032 builtin does not depend on --prefix-builtin: input('-P') !__
m4_builtin(`divnum')
m4_builtin(`m4_divnum')
m4_indir(`divnum')
m4_indir(`m4_divnum')
__! 032 builtin does not depend on --prefix-builtin: output !__
0


0
__! 033 builtin used to call a builtin without argument: input !__
builtin
builtin()
builtin(`builtin')
builtin(`builtin',)
builtin(`builtin', ``'
')
indir(`index')
__! 033 builtin used to call a builtin without argument: output !__
builtin





__! 034 ifdef: input !__
ifdef(`foo', ``foo' is defined', ``foo' is not defined')
define(`foo', `')
ifdef(`foo', ``foo' is defined', ``foo' is not defined')
ifdef(`no_such_macro', `yes', `no', `extra argument')
__! 034 ifdef: output !__
foo is not defined

foo is defined
no
__! 035 ifelse - one or two arguments: input !__
ifelse(`some comments')
ifelse(`foo', `bar')
__! 035 ifelse - one or two arguments: output !__


__! 036 ifelse - three or four arguments: input !__
ifelse(`foo', `bar', `true')
ifelse(`foo', `foo', `true')
define(`foo', `bar')
ifelse(foo, `bar', `true', `false')
ifelse(foo, `foo', `true', `false')
__! 036 ifelse - three or four arguments: output !__

true

true
false
__! 037 ifelse - reproduce behaviour of blind builtins: input !__
define(`foo', `ifelse(`$#', `0', ``$0'', `arguments:$#')')
foo
foo()
foo(`a', `b', `c')
__! 037 ifelse - reproduce behaviour of blind builtins: output !__

foo
arguments:1
arguments:3
__! 038 ifelse - more than four arguments: input !__
ifelse(`foo', `bar', `third', `gnu', `gnats')
ifelse(`foo', `bar', `third', `gnu', `gnats', `sixth')
ifelse(`foo', `bar', `third', `gnu', `gnats', `sixth', `seventh')
ifelse(`foo', `bar', `3', `gnu', `gnats', `6', `7', `8')
__! 038 ifelse - more than four arguments: output !__
gnu

seventh
7
__! 039 shift: input !__
shift
shift(`bar')
shift(`foo', `bar', `baz')
__! 039 shift: output !__
shift

bar,baz
__! 040 shift - composite reverse: input !__
define(`reverse', `ifelse(`$#', `0', , `$#', `1', ``$1'',
                          `reverse(shift($@)), `$1'')')
reverse
reverse(`foo')
reverse(`foo', `bar', `gnats', `and gnus')
__! 040 shift - composite reverse: output !__


foo
and gnus, gnats, bar, foo
__! 041 shift - composite cond: input !__
define(`cond',
`ifelse(`$#', `1', `$1',
        `ifelse($1, `$2', `$3',
                `$0(shift(shift(shift($@))))')')')dnl
define(`side', `define(`counter', incr(counter))$1')dnl
define(`example1',
`define(`counter', `0')dnl
ifelse(side(`$1'), `yes', `one comparison: ',
       side(`$1'), `no', `two comparisons: ',
       side(`$1'), `maybe', `three comparisons: ',
       `side(`default answer: ')')counter')dnl
define(`example2',
`define(`counter', `0')dnl
cond(`side(`$1')', `yes', `one comparison: ',
     `side(`$1')', `no', `two comparisons: ',
     `side(`$1')', `maybe', `three comparisons: ',
     `side(`default answer: ')')counter')dnl
example1(`yes')
example1(`no')
example1(`maybe')
example1(`feeling rather indecisive today')
example2(`yes')
example2(`no')
example2(`maybe')
example2(`feeling rather indecisive today')
__! 041 shift - composite cond: output !__
one comparison: 3
two comparisons: 3
three comparisons: 3
default answer: 4
one comparison: 1
two comparisons: 2
three comparisons: 3
default answer: 4
__! 042 shift - composites join/joinall: input !__
include(`join.m4')
join,join(`-'),join(`-', `'),join(`-', `', `')
joinall,joinall(`-'),joinall(`-', `'),joinall(`-', `', `')
join(`-', `1')
join(`-', `1', `2', `3')
join(`', `1', `2', `3')
join(`-', `', `1', `', `', `2', `')
joinall(`-', `', `1', `', `', `2', `')
join(`,', `1', `2', `3')
define(`nargs', `$#')dnl
nargs(join(`,', `1', `2', `3'))
__! 042 shift - composites join/joinall: output !__

,,,
,,,-
1
1-2-3
123
1-2
-1---2-
1,2,3
1
__! 043 shift - composites quote/dquote/dquote_elt: input !__
include(`quote.m4')
-quote-dquote-dquote_elt-
-quote()-dquote()-dquote_elt()-
-quote(`1')-dquote(`1')-dquote_elt(`1')-
-quote(`1', `2')-dquote(`1', `2')-dquote_elt(`1', `2')-
define(`n', `$#')dnl
-n(quote(`1', `2'))-n(dquote(`1', `2'))-n(dquote_elt(`1', `2'))-
dquote(dquote_elt(`1', `2'))
dquote_elt(dquote(`1', `2'))
__! 043 shift - composites quote/dquote/dquote_elt: output !__

----
--`'-`'-
-1-`1'-`1'-
-1,2-`1',`2'-`1',`2'-
-1-1-2-
``1'',``2''
``1',`2''
__! 044 shift - composite argn: input !__
define(`argn', `ifelse(`$1', 1, ``$2'',
  `argn(decr(`$1'), shift(shift($@)))')')
argn(`1', `a')
define(`foo', `argn(`11', $@)')
foo(`a', `b', `c', `d', `e', `f', `g', `h', `i', `j', `k', `l')
__! 044 shift - composite argn: output !__

a

k
__! 045 composite forloop: input !__
include(`forloop.m4')
forloop(`i', `1', `8', `i ')
__! 045 composite forloop: output !__

1 2 3 4 5 6 7 8 
__! 046 composite forloop - nested: input !__
include(`forloop.m4')
forloop(`i', `1', `4', `forloop(`j', `1', `8', ` (i, j)')
')
__! 046 composite forloop - nested: output !__

 (1, 1) (1, 2) (1, 3) (1, 4) (1, 5) (1, 6) (1, 7) (1, 8)
 (2, 1) (2, 2) (2, 3) (2, 4) (2, 5) (2, 6) (2, 7) (2, 8)
 (3, 1) (3, 2) (3, 3) (3, 4) (3, 5) (3, 6) (3, 7) (3, 8)
 (4, 1) (4, 2) (4, 3) (4, 4) (4, 5) (4, 6) (4, 7) (4, 8)

__! 047 composites foreach/foreachq: input !__
include(`foreach.m4')
foreach(`x', (foo, bar, foobar), `Word was: x
')dnl
include(`foreachq.m4')
foreachq(`x', `foo, bar, foobar', `Word was: x
')dnl
__! 047 composites foreach/foreachq: output !__

Word was: foo
Word was: bar
Word was: foobar

Word was: foo
Word was: bar
Word was: foobar
__! 048 composites foreach/foreachq - generate a shell case statement: input !__
include(`foreach.m4')
define(`_case', `  $1)
    $2=" $1";;
')dnl
define(`_cat', `$1$2')dnl
case $`'1 in
foreach(`x', `(`(`a', `vara')', `(`b', `varb')', `(`c', `varc')')',
        `_cat(`_case', x)')dnl
esac
__! 048 composites foreach/foreachq - generate a shell case statement: output !__

case $1 in
  a)
    vara=" a";;
  b)
    varb=" b";;
  c)
    varc=" c";;
esac
__! 049 composites foreach/foreachq - comparison: input !__
define(`a', `1')define(`b', `2')define(`c', `3')
include(`foreach.m4')
include(`foreachq.m4')
foreach(`x', `(``a'', ``(b'', ``c)'')', `x
')
foreachq(`x', ```a'', ``(b'', ``c)''', `x
')dnl
__! 049 composites foreach/foreachq - comparison: output !__



1
(2)1

, x
)
a
(b
c)
__! 050 composite foreachq limitation: input !__
include(`foreach.m4')include(`foreachq.m4')
foreach(`name', `(`a', `b')', ` defn(`name')')
foreachq(`name', ``a', `b'', ` defn(`name')')
__! 050 composite foreachq limitation: output !__

 a b
 _arg1(`a', `b') _arg1(shift(`a', `b'))
__! 051 composite stack: input !__
include(`stack.m4')
pushdef(`a', `1')pushdef(`a', `2')pushdef(`a', `3')
define(`show', ``$1'
')
stack_foreach(`a', `show')dnl
stack_foreach_lifo(`a', `show')dnl
__! 051 composite stack: output !__



1
2
3
3
2
1
__! 052 composite define_blind: input !__
define(`define_blind', `ifelse(`$#', `0', ``$0'',
`_$0(`$1', `$2', `$'`#', `$'`0')')')
define(`_define_blind', `define(`$1',
`ifelse(`$3', `0', ``$4'', `$2')')')
define_blind
define_blind(`foo', `arguments were $*')
foo
foo(`bar')
define(`blah', defn(`foo'))
blah
blah(`a', `b')
defn(`blah')
__! 052 composite define_blind: output !__


define_blind

foo
arguments were bar

blah
arguments were a,b
ifelse(`$#', `0', ``$0'', `arguments were $*')
__! 053 composite curry: input !__
include(`curry.m4')include(`stack.m4')
define(`reverse', `ifelse(`$#', `0', , `$#', `1', ``$1'',
                          `reverse(shift($@)), `$1'')')
pushdef(`a', `1')pushdef(`a', `2')pushdef(`a', `3')
stack_foreach(`a', `:curry(`reverse', `4')')
curry(`curry', `reverse', `1')(`2')(`3')
__! 053 composite curry: output !__



:1, 4:2, 4:3, 4
3, 2, 1
__! 054 composites copy/rename: input !__
include(`curry.m4')include(`stack.m4')
define(`rename', `copy($@)undefine(`$1')')dnl
define(`copy', `ifdef(`$2', `errprint(`$2 already defined
')m4exit(`1')',
   `stack_foreach(`$1', `curry(`pushdef', `$2')')')')dnl
pushdef(`a', `1')pushdef(`a', defn(`divnum'))pushdef(`a', `2')
copy(`a', `b')
rename(`b', `c')
a b c
popdef(`a', `c')c a
popdef(`a', `c')a c
__! 054 composites copy/rename: output !__




2 b 2
 0
1 1
__! 055 dumpdef: input !__
define(`foo', `Hello world.')
dumpdef(`foo')
dumpdef(`define')
__! 055 dumpdef: output !__



__! 056 dumpdef 2: input !__
pushdef(`f', ``$0'1')pushdef(`f', ``$0'2')
f(popdef(`f')dumpdef(`f'))
f(popdef(`f')dumpdef(`f'))
__! 056 dumpdef 2: output !__

f2
f1
__! 057 dnl: input !__
define(`foo', `Macro `foo'.')dnl A very simple macro, indeed.
foo
__! 057 dnl: output !__
Macro foo.
__! 058 dnl warning: input !__
dnl(`args are ignored, but side effects occur',
define(`foo', `like this')) while this text is ignored: undefine(`foo')
See how `foo' was defined, foo?
__! 058 dnl warning: output !__
See how foo was defined, like this?
__! 059 dnl warning at eof: input !__
m4wrap(`m4wrap(`2 hi
')0 hi dnl 1 hi')
define(`hi', `HI')
__! 059 dnl warning at eof: output !__


0 HI 2 HI
__! 060 changequote: input !__
changequote(`[', `]')
define([foo], [Macro [foo].])
foo
__! 060 changequote: output !__


Macro foo.
__! 061 changequote multi-characters: input !__
changequote(`[[[', `]]]')
define([[[foo]]], [[[Macro [[[[[foo]]]]].]]])
foo
__! 061 changequote multi-characters: output !__


Macro [[foo]].
__! 062 changequote utf8: input !__
changequote(`ᚠ', `ᛗ')
define(ᚠfooᛗ, ᚠMacro ᚠfooᛗ.ᛗ)
foo
__! 062 changequote utf8: output !__


Macro foo.
__! 063 changequote arguments: input !__
define(`foo', `Macro `FOO'.')
changequote(`', `')
foo
`foo'
changequote(`,)
foo
__! 063 changequote arguments: output !__


Macro `FOO'.
`Macro `FOO'.'

Macro FOO.
__! 064 changequote  - macros recognized before strings: input !__
define(`echo', `$@')
define(`hi', `HI')
changequote(`q', `Q')
q hi Q hi
echo(hi)
changequote
changequote(`-', `EOF')
- hi EOF hi
changequote
changequote(`1', `2')
hi1hi2
hi 1hi2
__! 064 changequote  - macros recognized before strings: output !__



q HI Q HI
qHIQ


 hi  HI


hi1hi2
HI hi
__! 065 changequote  - quotes recognized before argument collection: input !__
define(`echo', `$#:$@:')
define(`hi', `HI')
changequote(`(',`)')
echo(hi)
changequote
changequote(`((', `))')
echo(hi)
echo((hi))
changequote
changequote(`,', `)')
echo(hi,hi)bye)
__! 065 changequote  - quotes recognized before argument collection: output !__



0::hi


1:HI:
0::hi


1:HIhibye:
__! 066 changequote  - compute a quoted string: input !__
changequote(`[', `]')dnl
define([a], [1, (b)])dnl
define([b], [2])dnl
define([quote], [[$*]])dnl
define([expand], [_$0(($1))])dnl
define([_expand],
  [changequote([(], [)])$1changequote`'changequote(`[', `]')])dnl
expand([a, a, [a, a], [[a, a]]])
quote(a, a, [a, a], [[a, a]])
__! 066 changequote  - compute a quoted string: output !__
1, (2), 1, (2), a, a, [a, a]
1,(2),1,(2),a, a,[a, a]
__! 067 changequote  - when end-string is a prefix of start-string: input !__
define(`hi', `HI')
changequote(`""', `"')
""hi"""hi"
""hi" ""hi"
""hi"" "hi"
changequote
`hi`hi'hi'
changequote(`"', `"')
"hi"hi"hi"
__! 067 changequote  - when end-string is a prefix of start-string: output !__


hihi
hi hi
hi" "HI"

hi`hi'hi

hiHIhi
__! 068 changequote  - EOF within a quoted string: input !__
`hello world'
`dangling quote
__! 068 changequote  - EOF within a quoted string: output !__
hello world
__! 069 changecom: input !__
define(`comment', `COMMENT')
# A normal comment
changecom(`/*', `*/')
# Not a comment anymore
But: /* this is a comment now */ while this is not a comment
__! 069 changecom: output !__

# A normal comment

# Not a COMMENT anymore
But: /* this is a comment now */ while this is not a COMMENT
__! 070 changecom without arguments: input !__
define(`comment', `COMMENT')
changecom
# Not a comment anymore
changecom(`#', `')
# comment again
__! 070 changecom without arguments: output !__


# Not a COMMENT anymore

# comment again
__! 071 changecom - comments have precedence to macro: input !__
define(`hi', `HI')
define(`hi1hi2', `hello')
changecom(`q', `Q')
q hi Q hi
changecom(`1', `2')
hi1hi2
hi 1hi2
__! 071 changecom - comments have precedence to macro: output !__



q hi Q HI

hello
HI 1hi2
__! 072 changecom - comments have precedence to arguments collection: input !__
define(`echo', `$#:$*:$@:')
define(`hi', `HI')
changecom(`(',`)')
echo(hi)
changecom
changecom(`((', `))')
echo(hi)
echo((hi))
changecom(`,', `)')
echo(hi,hi)bye)
changecom
echo(hi,`,`'hi',hi)
echo(hi,`,`'hi',hi`'changecom(`,,', `hi'))
__! 072 changecom - comments have precedence to arguments collection: output !__



0:::(hi)


1:HI:HI:
0:::((hi))

1:HI,hi)bye:HI,hi)bye:

3:HI,,HI,HI:HI,,`'hi,HI:
3:HI,,`'hi,HI:HI,,`'hi,HI:
__! 073 changecom  - EOF within a comment: input !__
changecom(`/*', `*/')
/*dangling comment
__! 073 changecom  - EOF within a comment: output !__

__! 074 changeword: input !__
ifdef(`changeword', `', `errprint(` skipping: no changeword support
')m4exit(`77')')dnl
changeword(`[_a-zA-Z0-9]+')
define(`1', `0')1
__! 074 changeword: output !__

0
__! 075 changeword - prevent accidentical call of builtin !__
ifdef(`changeword', `', `errprint(` skipping: no changeword support
')m4exit(`77')')dnl
define(`_indir', defn(`indir'))
changeword(`_[_a-zA-Z0-9]*')
esyscmd(`foo')
_indir(`esyscmd', `perl %%%ECHO%%% hi')
__! 075 changeword - prevent accidentical call of builtin: output !__


esyscmd(foo)
hi

__! 076 changeword - word-regexp is character per character - perl engine: input('--regexp-type', 'perl') !__
ifdef(`changeword', `', `errprint(` skipping: no changeword support
')m4exit(`77')')dnl
define(`foo
', `bar
')
dnl This example wants to recognize changeword, dnl, and `foo\n'.
dnl First, we check that our regexp will match.
regexp(`changeword', `[cd][a-z]*|foo[
]')
regexp(`foo
', `[cd][a-z]*|foo[
]')
regexp(`f', `[cd][a-z]*|foo[
]')
foo
changeword(`[cd][a-z]*|foo[
]')
dnl Even though `foo\n' matches, we forgot to allow `f'.
foo
changeword(`[cd][a-z]*|fo*[
]?')
dnl Now we can call `foo\n'.
foo
__! 076 changeword - word-regexp is character per character - perl engine: output !__

0
0
-1
foo

foo

bar
__! 076 changeword - word-regexp is character per character - GNU Emacs engine: input !__
ifdef(`changeword', `', `errprint(` skipping: no changeword support
')m4exit(`77')')dnl
define(`foo
', `bar
')
dnl This example wants to recognize changeword, dnl, and `foo\n'.
dnl First, we check that our regexp will match.
regexp(`changeword', `[cd][a-z]*\|foo[
]')
regexp(`foo
', `[cd][a-z]*\|foo[
]')
regexp(`f', `[cd][a-z]*\|foo[
]')
foo
changeword(`[cd][a-z]*\|foo[
]')
dnl Even though `foo\n' matches, we forgot to allow `f'.
foo
changeword(`[cd][a-z]*\|fo*[
]?')
dnl Now we can call `foo\n'.
foo
__! 076 changeword - word-regexp is character per character - GNU Emacs engine: output !__

0
0
-1
foo

foo

bar
__! 077 changeword - change of symbol lookup - perl engine: input('--regexp-type', 'perl') !__
define(`foo', `bar')dnl
define(`echo', `$*')dnl
changecom(`/*', `*/')dnl Because comment have higher precedence to word
changeword(`#([_a-zA-Z0-9]*)')#dnl
#echo(`foo #foo')
__! 077 changeword - change of symbol lookup - perl engine: output !__
foo bar
__! 077 changeword - change of symbol lookup - GNU emacs engine: input !__
define(`foo', `bar')dnl
define(`echo', `$*')dnl
changecom(`/*', `*/')dnl Because comment have higher precedence to word
changeword(`#\([_a-zA-Z0-9]*\)')#dnl
#echo(`foo #foo')
__! 077 changeword - change of symbol lookup - GNU emacs engine: output !__
foo bar
__! 078 changeword - Difference v.s. TeX - perl engine: input('--regexp-type', 'perl') !__
ifdef(`changeword', `', `errprint(` skipping: no changeword support
')m4exit(`77')')dnl
define(`a', `errprint(`Hello')')dnl
changeword(`@([_a-zA-Z0-9]*)')
@a
__! 078 changeword - Difference v.s. TeX - perl engine: output !__

errprint(Hello)
__! 078 changeword - Difference v.s. TeX - GNU emacs engine: input !__
ifdef(`changeword', `', `errprint(` skipping: no changeword support
')m4exit(`77')')dnl
define(`a', `errprint(`Hello')')dnl
changeword(`@\([_a-zA-Z0-9]*\)')
@a
__! 078 changeword - Difference v.s. TeX - GNU emacs engine: output !__

errprint(Hello)
__! 079 m4wrap: input !__
define(`cleanup', `This is the `cleanup' action.
')
m4wrap(`cleanup')
This is the first and last normal input line.
__! 079 m4wrap: output !__


This is the first and last normal input line.
This is the cleanup action.
__! 080 m4wrap - emulate FIFO behaviour: input !__
include(`wrapfifo.m4')
m4wrap(`a`'m4wrap(`c
', `d')')m4wrap(`b')
__! 080 m4wrap - emulate FIFO behaviour: output !__


abc
__! 081 m4wrap - emulate LIFO behaviour: input !__
include(`wraplifo.m4')
m4wrap(`a`'m4wrap(`c
', `d')')m4wrap(`b')
__! 081 m4wrap - emulate LIFO behaviour: output !__


bac
__! 081 m4wrap - factorial: input !__
define(`f', `ifelse(`$1', `0', `Answer: 0!=1
', eval(`$1>1'), `0', `Answer: $2$1=eval(`$2$1')
', `m4wrap(`f(decr(`$1'), `$2$1*')')')')
f(`10')
__! 081 m4wrap - factorial: output !__


Answer: 10*9*8*7*6*5*4*3*2*1=3628800
__! 082 m4wrap - concatenation and rescan: input !__
define(`aa', `AA
')
m4wrap(`a')m4wrap(`a')
__! 082 m4wrap - concatenation and rescan: output !__


AA
__! 083 m4wrap - transition between recursion levels: input !__
m4wrap(`m4wrap(`)')len(abc')
__! 083 m4wrap - transition between recursion levels: output !__

__! 084 include - warnings: input !__
include(`none')
include()
sinclude(`none')
sinclude()
__! 084 include - warnings: output !__




__! 085 include - incl.m4: input !__
define(`foo', `FOO')
include(`incl.m4')
__! 085 include - incl.m4: output !__

Include file start
FOO
Include file end

__! 086 include - incl.m4 v2: input !__
define(`bar', include(`incl.m4'))
This is `bar':  >>bar<<
__! 086 include - incl.m4 v2: output !__

This is bar:  >>Include file start
foo
Include file end
<<
__! 087 divert: input !__
divert(`1')
This text is diverted.
divert
This text is not diverted.
__! 087 divert: output !__

This text is not diverted.

This text is diverted.
__! 088 divert - m4wrap precedence: input !__
define(`text', `TEXT')
divert(`1')`diverted text.'
divert
m4wrap(`Wrapped text precedes ')
__! 088 divert - m4wrap precedence: output !__



Wrapped TEXT precedes diverted text.
__! 089 divert - discard: input !__
divert(`-1')
define(`foo', `Macro `foo'.')
define(`bar', `Macro `bar'.')
divert
__! 089 divert - discard: output !__

__! 090 divert - number > 10: input !__
divert(eval(`1<<28'))world
divert(`2')hello
__! 090 divert - number > 10: output !__
hello
world
__! 091 divert - is a common english word -;: input !__
We decided to divert the stream for irrigation.
define(`divert', `ifelse(`$#', `0', ``$0'', `builtin(`$0', $@)')')
divert(`-1')
Ignored text.
divert(`0')
We decided to divert the stream for irrigation.
__! 091 divert - is a common english word -;: output !__
We decided to  the stream for irrigation.


We decided to divert the stream for irrigation.
__! 092 undivert: input !__
divert(`1')
This text is diverted.
divert
This text is not diverted.
undivert(`1')
__! 092 undivert: output !__

This text is not diverted.

This text is diverted.

__! 093 undivert - undivert into a diversion and to an empty string: input !__
divert(`1')diverted text
divert
undivert()
undivert(`0')
undivert
divert(`1')more
divert(`2')undivert(`1')diverted text`'divert
undivert(`1')
undivert(`2')
__! 093 undivert - undivert into a diversion and to an empty string: output !__



diverted text



more
diverted text
__! 094 undivert - cannot bring back a diverted text more than once: input !__
divert(`1')
This text is diverted first.
divert(`0')undivert(`1')dnl
undivert(`1')
divert(`1')
This text is also diverted but not appended.
divert(`0')undivert(`1')dnl
__! 094 undivert - cannot bring back a diverted text more than once: output !__

This text is diverted first.


This text is also diverted but not appended.
__! 095 undivert - undiverting current diversion is silently ignored: input !__
divert(`1')one
divert(`2')two
divert(`3')three
divert(`2')undivert`'dnl
divert`'undivert`'dnl
__! 095 undivert - undiverting current diversion is silently ignored: output !__
two
one
three
__! 096 undivert - undiverting a named file: input !__
define(`bar', `BAR')
undivert(`%%%FOO%%%')
include(`%%%FOO%%%')
__! 096 undivert - undiverting a named file: output !__

bar

BAR

__! 097 undivert - intermix files and diversion numbers: input !__
divert(`1')diversion one
divert(`2')undivert(`%%%FOO%%%')dnl
divert(`3')diversion three
divert`'dnl
undivert(`1', `2', `%%%FOO%%%', `3')dnl
__! 097 undivert - intermix files and diversion numbers: output !__
diversion one
bar
bar
diversion three
__! 098 divnum: input !__
Initial divnum
divert(`1')
Diversion one: divnum
divert(`2')
Diversion two: divnum
__! 098 divnum: output !__
Initial 0

Diversion one: 1

Diversion two: 2
__! 099 composite cleardivert: input !__
define(`cleardivert',
`pushdef(`_n', divnum)divert(`-1')undivert($@)divert(_n)popdef(`_n')')
__! 099 composite cleardivert: output !__

__! 100 len: input !__
len()
len(`abcdef')
__! 100 len: output !__
0
6
__! 101 index: input !__
index(`gnus, gnats, and armadillos', `nat')
index(`gnus, gnats, and armadillos', `dag')
__! 101 index: output !__
7
-1
__! 102 index - empty substring: input !__
index(`abc')
index(`abc', `')
index(`abc', `b')
__! 102 index - empty substring: output !__
0
0
1
__! 103 regexp - perl: input('--regexp-type', 'perl') !__
regexp(`GNUs not Unix', `\b[a-z]\w+')
regexp(`GNUs not Unix', `\bQ\w*')
regexp(`GNUs not Unix', `\w(\w+)$', `*** \& *** \1 ***')
regexp(`GNUs not Unix', `\bQ\w*', `*** \& *** \1 ***')
__! 103 regexp - perl: output !__
5
-1
*** Unix *** nix ***

__! 103 regexp - GNU emacs: input !__
regexp(`GNUs not Unix', `\<[a-z]\w+')
regexp(`GNUs not Unix', `\<Q\w*')
regexp(`GNUs not Unix', `\w\(\w+\)$', `*** \& *** \1 ***')
regexp(`GNUs not Unix', `\<Q\w*', `*** \& *** \1 ***')
__! 103 regexp - GNU emacs: output !__
5
-1
*** Unix *** nix ***

__! 104 regexp warnings - perl: input('--regexp-type', 'perl') !__
regexp(`abc', `(b)', `\\\10\a')
regexp(`abc', `b', `\1\')
regexp(`abc', `((d)?)(c)', `\1\2\3\4\5\6')
__! 104 regexp warnings - perl: output !__
\\b0a

c
__! 104 regexp warnings - GNU Emacs: input !__
regexp(`abc', `\(b\)', `\\\10\a')
regexp(`abc', `b', `\1\')
regexp(`abc', `\(\(d\)?\)\(c\)', `\1\2\3\4\5\6')
__! 104 regexp warnings - GNU Emacs: output !__
\\b0a

c
__! 105 regexp - ommiting regexp -;: input !__
regexp(`abc')
regexp(`abc', `')
regexp(`abc', `', `\\def')
__! 105 regexp - ommiting regexp -;: output !__
0
0
\\def
_! 106 substr: input !__
substr(`gnus, gnats, and armadillos', `6')
substr(`gnus, gnats, and armadillos', `6', `5')
_! 106 substr: output !__
gnats, and armadillos
gnats
_! 107 substr warning: input !__
substr(`abc')
substr(`abc',)
_! 107 substr warning: output !__
abc
abc
_! 108 translit: input !__
translit(`GNUs not Unix', `-G', `&!')
translit(`GNUs not Unix', `G-', `&!')
translit(`GNUs-not-Unix', `GU', `&')
translit(`GNUs not Unix', `A-Z')
translit(`GNUs not Unix', `a-z', `A-Z')
translit(`GNUs not Unix', `A-Z', `z-a')
translit(`+,-12345', `+--1-5', `<;>a-c-a')
translit(`abcdef', `aabdef', `bcged')
_! 108 translit: output !__
!NUs not Unix
&NUs not Unix
&Ns-not-nix
s not nix
GNUS NOT UNIX
tmfs not fnix
<;>abcba
bgced
_! 109 patsubst: input !__
patsubst(`GNUs not Unix', `^', `OBS: ')
patsubst(`GNUs not Unix', `\<', `OBS: ')
patsubst(`GNUs not Unix', `\w*', `(\&)')
patsubst(`GNUs not Unix', `\w+', `(\&)')
patsubst(`GNUs not Unix', `[A-Z][a-z]+')
patsubst(`GNUs not Unix', `not', `NOT\')
_! 109 patsubst: output !__
OBS: GNUs not Unix
OBS: GNUs OBS: not OBS: Unix
(GNUs)() (not)() (Unix)()
(GNUs) (not) (Unix)
GN not 
GNUs NOT Unix
_! 110 patsubst - composites upcase/downcase/capitalize: input !__
include(`capitalize.m4')
upcase(`GNUs not Unix')
downcase(`GNUs not Unix')
capitalize(`GNUs not Unix')
_! 110 patsubst - composites upcase/downcase/capitalize: output !__

GNUS NOT UNIX
gnus not unix
Gnus Not Unix
_! 111 patsubst - cont'ed: input !__
define(`patreg',
`patsubst($@)
regexp($@)')dnl
patreg(`bar foo baz Foo', `foo\|Foo', `FOO')
patreg(`aba abb 121', `\(.\)\(.\)\1', `\2\1\2')
_! 111 patsubst - cont'ed: output !__
bar FOO baz FOO
FOO
bab abb 212
bab
_! 112 patsubst - warning: input !__
patsubst(`abc')
patsubst(`abc', `')
patsubst(`abc', `', `\\-')
_! 112 patsubst - warning: output !__
#
# C.f. MAIN PROGRAM
#
_! 113 format: input !__
dnl the followings are a priori portable and will give the
dnl same result regardless from Perl or with GNU M4
define(`foo', `The brown fox jumped over the lazy dog')
format(`The string "%s" uses %d characters', foo, len(foo))
format(`%*.*d', `-1', `-1', `1')
format(`%.0f', `56789.9876')
len(format(`%-*X', `5000', `1'))
dnl The followings are not.
dnl ifelse(format(`%010F', `infinity'), `       INF', `success',
dnl        format(`%010F', `infinity'), `  INFINITY', `success',
dnl        format(`%010F', `infinity'))
dnl ifelse(format(`%.1A', `1.999'), `0X1.0P+1', `success',
dnl        format(`%.1A', `1.999'), `0X2.0P+0', `success',
dnl        format(`%.1A', `1.999'))
dnl format(`%g', `0xa.P+1')
_! 113 format: output !__

The string "The brown fox jumped over the lazy dog" uses 38 characters
1
56790
5000
_! 114 format - forloop: input !__
include(`forloop.m4')
forloop(`i', `1', `10', `format(`%6d squared is %10d
', i, eval(i**2))')
_! 114 format - forloop: output !__

     1 squared is          1
     2 squared is          4
     3 squared is          9
     4 squared is         16
     5 squared is         25
     6 squared is         36
     7 squared is         49
     8 squared is         64
     9 squared is         81
    10 squared is        100

_! 115 incr/decr: input !__
incr(`4')
decr(`7')
incr()
decr()
_! 115 incr/decr: output !__
5
6
1
-1
_! 116 eval: input !__
eval(`2 = 2')
eval(`++0')
eval(`0 |= 1')
_! 116 eval: output !__
1


_! 117 eval cont'ed: input !__
eval(`1 == 2 > 0')
eval(`(1 == 2) > 0')
eval(`! 0 * 2')
eval(`! (0 * 2)')
eval(`1 | 1 ^ 1')
eval(`(1 | 1) ^ 1')
eval(`+ + - ~ ! ~ 0')
eval(`2 || 1 / 0')
eval(`0 || 1 / 0')
eval(`0 && 1 % 0')
eval(`2 && 1 % 0')
_! 117 eval cont'ed: output !__
1
0
2
1
1
0
1
1

0

_! 118 eval cont'ed 2: input !__
eval(`2 ** 3 ** 2')
eval(`(2 ** 3) ** 2')
eval(`0 ** 1')
eval(`2 ** 0')
eval(`0 ** 0')
eval(`4 ** -2')
_! 118 eval cont'ed 2: output !__
512
64
0
1


_! 119 eval cont'ed 3: input !__
eval(`-3 * 5')
eval(`-99 / 10')
eval(`-99 % 10')
eval(`99 % -10')
eval(index(`Hello world', `llo') >= 0)
eval(`0r1:0111 + 0b100 + 0r3:12')
define(`square', `eval(`($1) ** 2')')
square(`9')
square(square(`5')` + 1')
define(`foo', `666')
eval(`foo / 6')
eval(foo / 6)
_! 119 eval cont'ed 3: output !__
-15
-9
-9
9
1
12

81
676


111
_! 120 eval cont'ed 4: input !__
define(`max_int', eval(`0x7fffffff'))
define(`min_int', incr(max_int))
eval(min_int` < 0')
eval(max_int` > 0')
ifelse(eval(min_int` / -1'), min_int, `overflow occurred')
min_int
eval(`0x80000000 % -1')
eval(`-4 >> 1')
eval(`-4 >> 33')
_! 120 eval cont'ed 4: output !__


1
1
overflow occurred
-2147483648
0
-2
-2
_! 121 eval and radix: input !__
eval(`666', `10')
eval(`666', `11')
eval(`666', `6')
eval(`666', `6', `10')
eval(`-666', `6', `10')
eval(`10', `', `0')
`0r1:'eval(`10', `1', `11')
eval(`10', `16')
eval(`1', `37')
eval(`1', , `-1')
eval()
_! 121 eval and radix: output !__
666
556
3030
0000003030
-0000003030
10
0r1:01111111111
a


0
_! 122 extensions: input !__
__gnu__
__gnu__(`ignored')
Extensions are ifdef(`__gnu__', `active', `inactive')
_! 122 extensions: output !__


Extensions are active
_! 123 traditional: input('-G') !__
__gnu__
__gnu__(`ignored')
Extensions are ifdef(`__gnu__', `active', `inactive')
_! 123 traditional: output !__
__gnu__
__gnu__(ignored)
Extensions are inactive
_! 124 platform detection: input !__
define(`provided', `0')
ifdef(`__unix__', `define(`provided', incr(provided))')
ifdef(`__windows__', `define(`provided', incr(provided))')
ifdef(`__os2__', `define(`provided', incr(provided))')
provided
_! 124 platform detection: output !__




1
_! 125 syscmd: input !__
define(`foo', `FOO')
syscmd(`perl inc/echo.pl foo')
_! 125 syscmd: output !__

foo
_! 126 esyscmd: input !__
define(`foo', `FOO')
esyscmd(`perl inc/echo.pl foo')
_! 126 esyscmd: output !__

FOO
_! 127 sysval: input !__
sysval
syscmd(`perl inc/false.pl')
ifelse(sysval, `0', `zero', `non-zero')
syscmd(`perl inc/exit.pl 2')
sysval
syscmd(`perl inc/true.pl')
sysval
esyscmd(`perl inc/false.pl')
ifelse(sysval, `0', `zero', `non-zero')
esyscmd(`perl inc/dnlAndExit.pl 127')
sysval
esyscmd(`perl inc/true.pl')
sysval
_! 127 sysval: output !__
0

non-zero

2

0

non-zero

127

0
_! 128 maketemp: input !__
define(`tmp', `oops')
maketemp(`%%%TMPFILE%%%')
ifdef(`mkstemp', `define(`maketemp', defn(`mkstemp'))',
      `define(`mkstemp', defn(`maketemp'))dnl
errprint(`warning: potentially insecure maketemp implementation
')')
mkstemp(`doc')
_! 128 maketemp: ANYoutput !__

/tmp/fooa07346

docQv83Uw
_! 129 errprint: input !__
errprint(`Invalid arguments to forloop
')
errprint(`1')errprint(`2',`3
')
_! 129 errprint: output !__


_! 130 file/line/program: input !__
errprint(__program__:__file__:__line__: `input error
')
errprint(__program__:__file__:__line__: `input error
')
_! 130 file/line/program: output !__


__! 131 warn-macro-sequence: input !__
define(`foo', `$001 ${1} $1')
foo(`bar')
__! 131 warn-macro-sequence: output !__

bar ${1} bar
__! 132 warn-macro-sequence and -E twice: input('--warn_macro_sequence', '-E', '-E') !__
define(`foo', `$001 ${1} $1')
foo(`bar')
__! 132 warn-macro-sequence and -E twice: output !__
__! 133 regexp error: input !__
regexp(`GNUs not Unix', `\(')
__! 133 regexp error: output !__

__! 134 changeword - when word-regexp is not character per character - perl engine: input('--regexp-type', 'perl', '--no-changeword-is-character-per-character') !__
define(`test', `hi')dnl
changecom(`/*', `*/')dnl
changeword(`#<([_a-zA-Z0-9]*)>')#<dnl>
#<test>
__! 134 changeword - when word-regexp is not character per character - perl engine: output !__
hi
__! 134 changeword - when word-regexp is not character per character - GNU Emacs engine: input('--regexp-type', 'GNU', '--no-changeword-is-character-per-character') !__
define(`test', `hi')dnl
changecom(`/*', `*/')dnl
changeword(`#<\([_a-zA-Z0-9]*\)>')#<dnl>
#<test>
__! 134 changeword - when word-regexp is not character per character - GNU Emacs engine: output !__
hi
