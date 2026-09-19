package JQ::XS;

use 5.026003;
use strict;
use warnings;

use Carp qw(croak);

require XSLoader;
use Exporter 'import';

# process() blesses JSON booleans into JSON::PP::Boolean, so that class needs
# its overloads (numification, increment, fallback, ...) loaded.  Other JSON
# modules install those operators into JSON::PP::Boolean themselves --
# Cpanel::JSON::XS does, and JSON::XS does it through Types::Serialiser -- and
# loading JSON::PP::Boolean on top of them redefines the operators, which warns
# under -w.  So only load it when nobody has set the class up yet; "((" is the
# marker overload.pm installs in every overloaded class.
#
# Load it as JSON::PP rather than JSON::PP::Boolean on its own: a later
# Cpanel::JSON::XS reads $JSON::PP::VERSION to decide whether the operators
# need installing, and warns about it being undefined if it finds the boolean
# class loaded without its parent.
BEGIN {
  require JSON::PP unless JSON::PP::Boolean->can('((');
}

our $VERSION = '2.02';

XSLoader::load('JQ::XS', $VERSION);

# Constants
sub JQ_DEBUG_TRACE ()       { 1 }
sub JQ_DEBUG_TRACE_DETAIL () { 2 }
sub JQ_DEBUG_TRACE_ALL ()    { 3 }

# jv_dump_string flags, from jq's jv.h.  Not exported: the output options
# below are the supported way to ask for these, and the bit layout is jq's
# private business.
sub JV_PRINT_PRETTY () { 1 }
sub JV_PRINT_ASCII ()  { 2 }
sub JV_PRINT_COLOR ()  { 4 }
sub JV_PRINT_SORTED () { 8 }
sub JV_PRINT_TAB ()    { 64 }

our @EXPORT_OK = qw(
  JQ_DEBUG_TRACE
  JQ_DEBUG_TRACE_DETAIL
  JQ_DEBUG_TRACE_ALL
  jq_version
  features
  set_colors
  parse_json
  parse_json_stream
  to_json
);

=head1 NAME

JQ::XS - Perl wrapper for libjq

=head1 SYNOPSIS

  use JQ::XS;

  my $jq = JQ::XS->new('.foo[] | select(. > 2)');

  # Perl data interface
  my @results = $jq->process({ foo => [1, 3, 5] });
  # Returns: (3, 5)

  # JSON text interface
  my @out = $jq->process_json('{"foo":[1,3,5]}');
  # Returns: ('3', '5')

  # Named arguments, as jq's --arg/--argjson give you
  my $greet = JQ::XS->new('"\($greeting), \(.name)!"',
                          vars => { greeting => 'Hello' });
  my ($msg) = $greet->process({ name => 'Alice' });   # "Hello, Alice!"

  # Output formatting, as jq's -S/--tab/-r give you
  my $pretty = JQ::XS->new('.', tab => 1, sort_keys => 1);
  print $pretty->process_json('{"b":1,"a":2}'), "\n";

  # Refuse filters that pull in modules from disk
  my $safe = do {
      delete local $ENV{HOME};     # ...including the ~/.jq jq adds on its own
      JQ::XS->new($untrusted, allow_includes => 0);
  };

  # The debug, stderr and input/inputs builtins
  my $sum = JQ::XS->new('[., inputs] | add',
                        inputs => [2, 3],
                        debug  => sub { warn "jq: $_[0]\n" });
  my ($total) = $sum->process(1);   # 6

  # Get the program source
  my $prog = $jq->program;

=head1 DESCRIPTION

JQ::XS provides a clean object-oriented wrapper around libjq, the C library
behind the jq command-line tool. It allows you to:

- Compile and execute jq filter programs
- Process Perl data structures (hashes, arrays, numbers, strings)
- Process JSON text
- Pass named and positional arguments to a filter
- Format JSON output the way the jq command line does
- Serve the C<input>, C<inputs>, C<debug> and C<stderr> builtins from Perl
- Restrict what a filter may load from disk
- Handle errors gracefully with Perl exceptions (croak)

=head1 METHODS

=head2 new($program, %options)

Creates a new JQ::XS object by compiling the given jq filter program.

  my $jq = JQ::XS->new('.foo');

Croaks with an error message if the program fails to compile.

The remaining arguments are name/value pairs. Every one of them has a
matching method, so anything that can be passed here can also be changed
later; the exceptions are C<vars>, C<args>, C<attrs>, C<library_paths> and
C<allow_includes>, which take effect while the program is being compiled and
so have to be given up front.

=over 4

=item vars => \%hash

Named arguments, as C<jq --arg> and C<jq --argjson> pass them. Each key
becomes a C<$variable> in the program, and the values are arbitrary Perl data
converted the same way C<process()> converts its input.

  my $jq = JQ::XS->new('.[] | select(.dept == $dept)',
                       vars => { dept => 'sales' });

=item args => \@list

Positional arguments, as C<jq --args> passes them. They are available to the
program as C<$ARGS.positional>.

C<$ARGS> is always defined, whether or not either option was given:
C<$ARGS.named> holds C<vars> and C<$ARGS.positional> holds C<args>, exactly
as on the jq command line.

=item allow_includes => 0

Reject the program if it contains an C<include> or C<import> directive,
rather than compiling it and letting it read C<.jq> files from disk. Defaults
to true, i.e. modules work as they always have. It does not stop jq importing
F<~/.jq> -- see L</RESTRICTING MODULE LOADING> for that.

=item library_paths => \@dirs

Where C<include> and C<import> look for modules -- jq's C<-L> option, and its
C<JQ_LIBRARY_PATH> attribute. See L</RESTRICTING MODULE LOADING> for what
this does and does not prevent.

Defaults to empty, which is not what the jq command line defaults to: jq adds
two directories beside its own binary, and a library embedded in someone
else's program has no business reading those uninvited. It does not keep
F<~/.jq> out, which jq imports without consulting the library path at all --
see L</RESTRICTING MODULE LOADING>.

=item attrs => \%hash

jq attributes to set before the program is compiled, for anything
C<library_paths> does not cover: C<JQ_ORIGIN>, C<PROGRAM_ORIGIN>, and
C<JQ_LIBRARY_PATH> itself. See L<attr()|/attr($name)> and
L<set_attr()|/set_attr($name, $value)>.

=item flags => $flags

Flags for each run of the program, OR'd together from L</CONSTANTS>. Only
jq's execution tracing lives here. See L<flags()|/flags($flags)>.

=item die_on_halt_error => 1

Turn a filter's C<halt_error> into a Perl exception. See
L<die_on_halt_error()|/die_on_halt_error($bool)>.

=item debug => \&code

=item stderr => \&code

=item inputs => \&code | \@values

Perl code behind the C<debug>, C<stderr> and C<input>/C<inputs> builtins,
which do nothing at all otherwise. See
L<set_debug_cb()|/set_debug_cb(\&code)>,
L<set_stderr_cb()|/set_stderr_cb(\&code)> and
L<set_inputs()|/set_inputs($source)>.

=item pretty, indent, tab, sort_keys, ascii, color, raw

How C<process_json()> formats its output. See
L<set_output()|/set_output(%options)>.

=back

=head2 process($data)

Processes Perl data through the compiled jq filter. Takes a Perl scalar
(which can be a reference to a hash or array) and returns a list of
results. Each result is a Perl data structure.

  my @results = $jq->process({ name => 'Alice' });

In scalar context, returns an arrayref of results.

  my $results_ref = scalar($jq->process($data));

Croaks if the jq filter produces a runtime error or if the processing fails.

=head2 Boolean handling

JSON booleans returned by a filter become L<JSON::PP::Boolean> objects,
which behave as true/false in boolean context and stringify to C<1> and
C<0>. They compare equal to the C<JSON::PP::true> and C<JSON::PP::false>
constants.

  my ($is_big) = JQ::XS->new('. > 2')->process(5);   # JSON::PP::true

On input, the following are converted to JSON C<true>/C<false>:

=over 4

=item * L<JSON::PP::Boolean>, C<Types::Serialiser::Boolean>, or L<boolean>
objects (by their truth value)

=item * unblessed references to a plain scalar, e.g. C<\1> and C<\0>

=item * Perl's native boolean values, i.e. the results of comparison and
logical operators and of C<builtin::true>/C<builtin::false>

  $jq->process($x > $y);   # jq sees true or false, not 1 or ""

On perls before 5.36 this only works for a boolean passed directly to
C<process()>; a copy (e.g. stored in a hash or array first) loses its
boolean identity and is treated as an ordinary number/string. On perl
5.36 and later, copies keep their boolean flag and are recognized
anywhere in the structure.

=back

=head2 process_json($json_text, %options)

Like process, but takes JSON text as input and returns a list of JSON
strings (one for each output).

  my @json_out = $jq->process_json('{"name":"Alice"}');

Croaks if the JSON input is invalid or if the jq filter produces a runtime
error.

Any options given here are merged over the object's own output options for
this one call, and are the same ones L<set_output()|/set_output(%options)>
takes:

  my @pretty = $jq->process_json($json, indent => 4, sort_keys => 1);

=head2 program()

Returns the source code of the compiled jq filter program.

  my $src = $jq->program;

=head1 OUTPUT FORMATTING

=head2 set_output(%options)

Sets how C<process_json()> formats its results, and returns the object.
Options not mentioned are reset to their defaults, so this replaces the
current settings rather than adding to them; to change one and keep the rest,
merge L</output_options()> yourself, or pass the option to C<process_json()>
for a single call.

  $jq->set_output(indent => 2, sort_keys => 1);

Each option corresponds to a jq command-line switch:

=over 4

=item pretty => 1

Indent output by two spaces, one value per line, as jq does by default. The
JQ::XS default is jq's C<-c>: everything on one line.

=item indent => $n

Indent by C<$n> spaces, C<$n> being 0 to 7 -- jq's C<--indent n>. As in jq,
C<indent =E<gt> 0> still puts one value per line, just without indentation;
it is not the same as compact output.

=item tab => 1

Indent with tabs -- jq's C<--tab>. Wins over C<indent> and C<pretty>, as it
does in jq.

=item sort_keys => 1

Emit object keys in sorted order -- jq's C<-S>.

=item ascii => 1

Escape all non-ASCII characters -- jq's C<-a>.

=item color => 1

Colorize the output with ANSI escapes -- jq's C<-C>.
L<set_colors()|/set_colors($spec)> chooses the colors.

=item raw => 1

Emit a result that is a JSON string as the string itself, without quotes or
escapes -- jq's C<-r>. Results of every other type are still JSON.

Note that C<raw> with C<ascii> behaves as C<jq -r -a> does, which is to say
that C<ascii> wins and strings come out quoted and escaped.

=back

=head2 output_options()

Returns a hashref copy of the options L<set_output()|/set_output(%options)>
was last given.

=head1 HALT AND EXIT

A filter can stop itself with jq's C<halt> or C<halt_error>. Neither is an
error as far as C<process()> is concerned -- results produced before the halt
are still returned -- so these three methods, all of which describe the most
recent run, are how you find out that it happened.

=head2 halted()

True if the last run ended in C<halt> or C<halt_error>.

=head2 exit_code()

The exit code the filter halted with, or C<undef> if it did not halt (or
halted without one). This is what the jq command line would have exited with.

=head2 error_message()

The message C<halt_error> was given, or C<undef>. Usually a string, but
C<halt_error> accepts any JSON value and this returns it converted like any
other result.

=head2 die_on_halt_error($bool)

Sets whether C<halt_error> raises a Perl exception carrying its message, and
returns the previous setting. Off by default, which is why the message would
otherwise be silently dropped -- there is no stderr for it to go to. Plain
C<halt> never raises, having no message; use L</halted()> for that.

  $jq->die_on_halt_error(1);
  my @out = eval { $jq->process($data) };
  warn "filter gave up: $@" if $@;

=head1 CALLBACKS

libjq leaves the C<debug>, C<stderr>, C<input> and C<inputs> builtins
unconnected, so until you give them somewhere to go, C<debug> and C<stderr>
discard their input and C<inputs> produces nothing.

An exception thrown by a callback is not lost, but it cannot be raised from
where it happens either -- that would abandon a jq program mid-run. A C<debug>
or C<stderr> exception is re-raised by C<process()> once the run has finished;
an C<inputs> exception becomes a jq error, which the filter's own C<try>/
C<catch> can see, and which otherwise surfaces as the run's runtime error.

=head2 set_debug_cb(\&code)

Sets the code called for each C<debug> in the filter, with the value being
debugged as its only argument. Pass no argument, or C<undef>, to disconnect it
again. Returns nothing.

  $jq->set_debug_cb(sub { warn 'DEBUG: ' . to_json($_[0]) . "\n" });

=head2 set_stderr_cb(\&code)

The same, for the C<stderr> builtin.

jq grew C<jq_set_stderr_cb> in 1.7, so under C<JQ_SYSTEM=1> against an older
libjq this croaks rather than silently doing nothing, and
L<features()|/features()> reports C<stderr_cb> as false. The vendored build
always has it.

=head2 set_inputs($source)

Connects the C<input> and C<inputs> builtins to C<$source>, and returns the
object. C<$source> is either an arrayref, whose elements are handed out in
order, or a code ref called once per value:

  $jq->set_inputs(sub { my $line = <$fh>; defined $line ? $line : () });

Returning an empty list ends the stream. Returning C<undef> does not: that is
one more value, JSON C<null>. Pass C<undef> as C<$source> to disconnect.

=head1 RESTRICTING MODULE LOADING

A jq program can pull definitions in from C<.jq> files on disk:

  include "foo";                     # ./foo.jq, or a library path
  import "bar" as bar {search:"/x"}; # /x/bar.jq

Which is worth thinking about if the programs you compile come from somewhere
you do not control.

A definition gets in from disk two ways -- a directive in the program, or the
F<~/.jq> jq imports on its own -- and they need different answers. Both happen
while the program is being compiled, which is to say inside C<new()>: nothing
is loaded later, and nothing you change on an object afterwards unloads what
it compiled with.

=head2 Directives in the program

C<allow_includes =E<gt> 0> rejects any program containing one of these
directives, at compile time, before jq has looked at the filesystem:

  my $jq = JQ::XS->new($untrusted, allow_includes => 0);   # croaks on include

This is decided from the program text, but it is exact rather than a guess:
jq's grammar only accepts C<include> and C<import> in the program prologue, so
that is the only place they can be, and legal programs that merely use the
words elsewhere -- C<{include: 1}>, C<.foo.include> -- still compile.

=head2 Where those directives look

C<library_paths> does not decide whether a directive may load anything, only
where it looks, as jq's C<-L> does:

  my $jq = JQ::XS->new($prog, library_paths => ['/usr/share/myapp/jq']);

but it cannot by itself stop a program from loading anything, because jq
searches the current directory when a program does not say where to look, and
a program that does say -- C<include "x" {search:"/tmp"};> -- is not searching
the library paths at all. C<allow_includes =E<gt> 0> is the one that decides
whether a program may load modules; C<library_paths> only steers the ones it
is already allowed to load.

=head2 The F<~/.jq> jq imports on its own

jq imports F<~/.jq> into every program it compiles, whether or not the program
asks for it, and neither option above prevents it:

=over 4

=item *

C<allow_includes =E<gt> 0> does not see it. That option reads the program
text, and this import is not in the program text -- jq's linker prepends it to
every program on its way to being compiled.

=item *

C<library_paths> does not apply to it. The import carries its own search path,
the home directory, and jq consults C<JQ_LIBRARY_PATH> only for an import that
names no path of its own. An empty C<library_paths> is simply not consulted.

=back

So whatever F<~/.jq> defines is in scope for the program, and can shadow
builtins for it. The import is marked optional, so it is silent when there is
no such file, which is why this tends to go unnoticed on hosts that do not
happen to have one.

jq locates that file through C<$HOME>, and skips the import when C<$HOME> is
unset. Take C<HOME> out of the environment for the call and nothing is
imported:

  my $jq = do {
      delete local $ENV{HOME};
      JQ::XS->new($prog);
  };

Only C<new()> has to be inside that scope. The import is resolved as the
program is compiled and is then fixed in the compiled program, so restoring
C<HOME> before you run anything neither unloads a F<~/.jq> that was already
imported nor lets one in afterwards. Nothing else in jq reads C<$HOME>, and
unsetting it changes nothing else about how a program runs.

Use C<delete local>, not C<local $ENV{HOME} = ''>. An empty C<HOME> is still a
home directory as far as jq is concerned, one whose F<~/.jq> is F</.jq>: the
import is skipped only because that file usually does not exist, not because
jq declined to look for it. C<delete local> is what makes it not look.

On anything but Windows, C<HOME> is the only variable jq consults. On Windows
it falls back to C<USERPROFILE>, and then to C<HOMEDRIVE> and C<HOMEPATH>,
when C<HOME> is unset, so all of them have to go:

  delete local @ENV{qw(HOME USERPROFILE HOMEDRIVE HOMEPATH)};

=head2 Loading nothing at all

Together, for a program you did not write:

  my $jq = do {
      delete local $ENV{HOME};
      JQ::XS->new($untrusted, allow_includes => 0);
  };

C<library_paths> does not appear because it does not need to: it already
defaults to empty, and with includes refused there is nothing left to steer.

=head2 library_paths(\@dirs)

Without an argument, returns the current module search path as an arrayref.
With one, replaces it and returns the object.

Setting it after construction does not retroactively change what the compiled
program included; it is the C<modulemeta> builtin and jq's C<$__loc__>
machinery that read it later.

=head1 RESTRICTING ENVIRONMENT ACCESS

A jq program can read the process environment two different ways, and they are
independent of each other:

=over 4

=item *

C<$ENV> is resolved while the program is compiled. jq's compiler rewrites
every reference to C<$ENV> that nothing else has already bound into a constant
built by walking the process's environment -- the same object C<jq -n '$ENV'>
prints on the command line.

=item *

C<env> is an ordinary builtin function. It reads the environment itself,
fresh, each time it runs.

=back

Neither is behind an attribute or a flag the way L</RESTRICTING MODULE
LOADING> is: libjq offers no switch for either, and JQ::XS adds no option of
its own. What follows is something you do to the program text yourself, before
it is compiled, rather than anything the module does for you.

=head2 Shadowing both

jq only substitutes the real environment for C<$ENV> when nothing has bound
that name already, and C<env> is only special until something earlier in the
program redefines it -- an ordinary C<def> shadows a builtin exactly as it
would shadow any other definition, for everything lexically after it. Put both
ahead of a program and neither name reaches the real environment:

  def env: {};
  {} as $ENV | (
  ... the program ...
  )

C<env> and C<$ENV> both come back C<{}> inside the parentheses, and C<env.FOO>
/ C<$ENV.FOO> come back C<null>, whatever C<FOO> actually holds in the process
running it.

=head2 Mind the closing paren

jq comments run to the end of the line, so the wrapper's own closing paren is
easy to lose inside one if the program being wrapped ends in a C<#> comment
with no newline of its own after it:

  # BUG: that ')' is inside the comment, not code
  my $wrapped = 'def env: {}; {} as $ENV | (' . $program . ')';

That particular case fails safely -- jq reports a syntax error for the
now-unclosed paren rather than compiling into something unintended -- but it
is still a confusing way to make an otherwise fine program stop working. Give
the closing paren its own line instead, so a trailing comment can only ever
reach the newline before it:

  my $wrapped = 'def env: {}; {} as $ENV | (' . "\n"
              . $program . "\n"
              . ')';
  my $jq = JQ::XS->new($wrapped, allow_includes => 0);

=head2 Programs that use import/include

This prologue is textual, so it has to come before whatever the program does,
and that only works when the program has no C<import> or C<include> directive
of its own: jq's grammar allows those only at the very start of a program, a
position this prologue has just taken for itself. Wrap a program that begins
with one and jq reports a plain syntax error -- C<unexpected import> -- rather
than the clearer "not allowed" L</RESTRICTING MODULE LOADING> gives, because
the parse never gets far enough for that check to run.

Pairing the prologue with C<allow_includes =E<gt> 0> costs nothing, then: such
a program was never going to be allowed a directive in the first place, so the
prologue rules out no case that was still open. That is the combination to
reach for when the program is one you did not write, as in the example above.

For a program you do control and want both for, put the prologue after the
directives rather than before them -- C<import "x" as m; def env: {}; {} as
$ENV | ( ... )> compiles fine. Doing the same to a program you did not write
means finding where its prologue ends, which is jq lexing rather than a
regexp, so it is worth it only when you already know the shape of what you are
wrapping.

=head2 Exposing a filtered subset instead

Rather than writing the replacement into the program text -- and having to
think about escaping whatever it contains -- pass it through
L<new()|/new($program, %options)>'s C<vars> option instead, and reference it
from the prologue:

  my $jq = JQ::XS->new(
      'def env: $__jqxs_env; $__jqxs_env as $ENV | (' . "\n"
    . $program . "\n"
    . ')',
      vars => { __jqxs_env => { PATH => $ENV{PATH} } },  # Perl's %ENV here
  );

C<env> and C<$ENV> now both come back C<{"PATH": ...}> inside the program,
with the rest of the process's environment out of reach -- a way to hand a
filter the one or two variables it legitimately needs without handing it
everything.

=head1 ATTRIBUTES

=head2 attr($name)

Returns the jq attribute C<$name>, or C<undef> if it was never set. jq keeps
C<JQ_LIBRARY_PATH>, C<JQ_ORIGIN> and C<PROGRAM_ORIGIN> here.

=head2 set_attr($name, $value)

Sets one. Attributes that affect compilation have to be set through
C<new()>'s C<attrs> option instead, since by the time you have an object the
program is already compiled.

=head1 EXECUTION FLAGS

=head2 flags($flags)

Sets the flags each run passes to jq, and returns the previous value. The
only flags jq defines are the execution traces in L</CONSTANTS>, which write
to the process's standard error.

  $jq->flags(JQ_DEBUG_TRACE);

=head2 dump_disassembly($indent)

Writes the compiled program's bytecode to standard output, as jq's
C<--debug-dump-disasm> does. C<$indent> defaults to 0.

jq prints this from C, to the process's file descriptor 1 rather than through
Perl's C<STDOUT> handle, so reopening C<STDOUT> in Perl will not capture it;
redirect the file descriptor if you need to.

=head1 FUNCTIONS

These are all exportable.

=head2 jq_version()

Returns the version of the jq compiled into this build, e.g. C<'1.8.2'>, or
C<undef> if the module was built against the libjq the operating system
packages (see L</EMBEDDED JQ>).

  use JQ::XS qw(jq_version);
  print jq_version();      # 1.8.2

=head2 parse_json($text)

Parses one JSON value with jq's own parser and returns it as Perl data, with
the same type mapping C<process()> uses. Croaks if the text is not a single
valid JSON value.

=head2 parse_json_stream($text)

The same, for text holding any number of JSON values one after another --
which is what the jq command line reads from a file or a pipe, and what
C<parse_json()> rejects. Returns them as a list.

  my @values = parse_json_stream("1 2 {\"a\":3}");   # (1, 2, {a=>3})

=head2 to_json($data, %options)

Serializes Perl data to JSON with jq's own printer. Takes the formatting
options L<set_output()|/set_output(%options)> takes, apart from C<raw>:

  print to_json($data, indent => 2, sort_keys => 1), "\n";

=head2 set_colors($spec)

Sets the colors C<color =E<gt> 1> output uses, in the format of jq's
C<JQ_COLORS> environment variable -- a colon-separated list of ANSI SGR
sequences for null, false, true, numbers, strings, arrays, objects and object
keys:

  set_colors('0;90:0;39:0;39:0;39:0;32:1;39:1;39:34;1');

Returns true if the specification was understood. This is a global setting
inside libjq, not a per-object one, so it affects every JQ::XS object in the
process.

=head2 features()

Returns a hashref describing what this build of the module can do, which
under C<JQ_SYSTEM=1> depends on the libjq it was linked against:

=over 4

=item embedded_jq

True if the jq engine is compiled into the module, false under
C<JQ_SYSTEM=1>. The same distinction L<jq_version()|/jq_version()> reports by
returning C<undef>.

=item stderr_cb

True if L<set_stderr_cb()|/set_stderr_cb(\&code)> works, i.e. if the libjq
has the C<jq_set_stderr_cb> that jq 1.7 added.

=back

=head1 CONSTANTS

The following constants are available via @EXPORT_OK:

  JQ_DEBUG_TRACE        - value 1
  JQ_DEBUG_TRACE_DETAIL - value 2
  JQ_DEBUG_TRACE_ALL    - value 3

They are the flags L<flags()|/flags($flags)> accepts.

=head1 EMBEDDED JQ

From version 2.00, JQ::XS does not use the libjq the operating system packages.
It ships an upstream jq release under F<vendor/>, compiles it at install time
and links it statically, so the installed module has no libjq to find at
runtime and behaves the same way on every distribution regardless of the jq
version that distribution ships. L</jq_version()> reports which jq that is.

Building needs only a C compiler, C<make> and a POSIX shell; jq's own release
tarball is self-contained, and its bundled oniguruma is built too, so the regex
builtins (C<test>, C<match>, C<capture>, C<sub>, C<gsub>, C<scan>, C<splits>)
work without an external library.

To link the OS libjq instead, configure with:

  perl Makefile.PL JQ_SYSTEM=1

in which case L</jq_version()> returns C<undef> and the filter semantics are
whatever the installed libjq implements. Everything the XS uses has been in
libjq since jq 1.5 bar one: C<jq_set_stderr_cb>, behind
L<set_stderr_cb()|/set_stderr_cb(\&code)>, arrived in 1.7, and Makefile.PL
link-probes for it -- against an older libjq the build says so and
L<features()|/features()> reports C<stderr_cb> as false.

One caveat worth knowing before choosing that build, since it cannot be
worked around from here: the jq 1.6 that RHEL 8 and Debian 11 ship corrupts
its own heap in C<jq_teardown> after a filter has called C<halt_error>, which
aborts the process when the JQ::XS object is freed. Later jq releases are
fine, and so is the embedded build.

=head1 AUTHOR

James Rouzier E<lt>rouzier@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 James Rouzier

This library is free software; you can redistribute it and/or modify
it under the terms of the MIT license. See the LICENSE file included
with this distribution.

=cut

# program(), the accessors, the callback setters and DESTROY are implemented
# in XS; the object is a blessed pointer to a C struct (T_PTROBJ), not a
# hashref, which is why every option below has to be stored on the C side.

my %OUTPUT_OPTION = map { $_ => 1 }
  qw(pretty indent tab sort_keys ascii color raw);

my %NEW_OPTION = map { $_ => 1 } qw(
  vars args attrs library_paths allow_includes
  flags die_on_halt_error debug stderr inputs
);

# Compile a set of output options down to the (jv_dump_string flags, raw)
# pair the XS side works with.
sub _output_flags {
    my ($opts) = @_;

    my @unknown = sort grep { !$OUTPUT_OPTION{$_} } keys %$opts;
    croak 'Unknown output option: ' . join(', ', @unknown) if @unknown;

    my $flags = 0;

    # jq's own precedence, from its main.c: --tab beats --indent, and the
    # default is -c (compact) rather than the pretty output jq gives a tty.
    if ($opts->{tab}) {
        $flags |= JV_PRINT_TAB | JV_PRINT_PRETTY;
    }
    elsif (defined $opts->{indent}) {
        croak 'indent must be an integer from 0 to 7'
          unless $opts->{indent} =~ /\A[0-7]\z/;
        # jq's JV_PRINT_INDENT_FLAGS: the width goes in bits 8-10.  Zero is
        # not compact, it is "one value per line, unindented", same as jq.
        $flags |= JV_PRINT_PRETTY | ($opts->{indent} << 8);
    }
    elsif ($opts->{pretty}) {
        $flags |= JV_PRINT_PRETTY | (2 << 8);
    }

    $flags |= JV_PRINT_SORTED if $opts->{sort_keys};
    $flags |= JV_PRINT_ASCII  if $opts->{ascii};
    $flags |= JV_PRINT_COLOR  if $opts->{color};

    return ($flags, $opts->{raw} ? 1 : 0);
}

sub new {
    my ($class, $program, %opts) = @_;

    # The output options share the one flat option list, so split them out
    # before checking what is left for typos.
    my %output;
    for my $key (keys %OUTPUT_OPTION) {
        $output{$key} = delete $opts{$key} if exists $opts{$key};
    }

    my @unknown = sort grep { !$NEW_OPTION{$_} } keys %opts;
    croak 'Unknown option to JQ::XS->new: ' . join(', ', @unknown) if @unknown;

    my $vars = $opts{vars} || {};
    ref $vars eq 'HASH' or croak 'vars must be a hash reference';
    my $args = $opts{args} || [];
    ref $args eq 'ARRAY' or croak 'args must be an array reference';

    # What jq's main.c hands jq_compile_args: the named arguments, plus an
    # ARGS that collects them next to the positional ones.  Always passing
    # ARGS is what makes $ARGS defined in every program, as it is in jq.
    my %compile_args = (
        %$vars,
        ARGS => { named => {%$vars}, positional => [@$args] },
    );

    my %attrs = %{ $opts{attrs} || {} };
    if (my $paths = $opts{library_paths}) {
        ref $paths eq 'ARRAY'
          or croak 'library_paths must be an array reference';
        $attrs{JQ_LIBRARY_PATH} = [@$paths];
    }

    # Always leave JQ_LIBRARY_PATH holding an array, never unset.  An empty
    # one is the right default for a library -- jq's command line defaults to
    # searching ~/.jq, which is not somewhere a module embedded in someone
    # else's program should read from uninvited -- and it also steps around a
    # jq 1.6 bug that a JQ_SYSTEM=1 build can still meet: 1.6's
    # jq_get_lib_dirs() hands the unset attribute straight to jv_array_concat
    # without checking it, and the failed assertion aborts the process while
    # any program containing an include is being compiled.
    $attrs{JQ_LIBRARY_PATH} = [] unless exists $attrs{JQ_LIBRARY_PATH};

    my $allow_includes =
      exists $opts{allow_includes} ? ($opts{allow_includes} ? 1 : 0) : 1;

    my $self =
      _new($class, $program, \%compile_args, \%attrs, $allow_includes);

    # Everything from here on is settable after the fact, so it goes through
    # the same methods a caller would use.
    $self->set_output(%output);
    $self->flags($opts{flags})                if defined $opts{flags};
    $self->die_on_halt_error(1)               if $opts{die_on_halt_error};
    $self->set_debug_cb($opts{debug})         if defined $opts{debug};
    $self->set_stderr_cb($opts{stderr})       if defined $opts{stderr};
    $self->set_inputs($opts{inputs})          if defined $opts{inputs};

    return $self;
}

sub set_output {
    my ($self, %opts) = @_;
    my ($flags, $raw) = _output_flags(\%opts);
    _set_output($self, \%opts, $flags, $raw);
    return $self;
}

sub set_inputs {
    my ($self, $source) = @_;

    if (!defined $source) {
        $self->set_input_cb(undef);
    }
    elsif (ref $source eq 'CODE') {
        $self->set_input_cb($source);
    }
    elsif (ref $source eq 'ARRAY') {
        # One element per call, then the empty list that ends the stream.  The
        # elements are copied, so that a caller mutating their array partway
        # through a run cannot move the cursor out from under it.
        my @queue = @$source;
        my $i     = 0;
        $self->set_input_cb(sub { $i < @queue ? $queue[ $i++ ] : () });
    }
    else {
        croak 'inputs must be a code reference or an array reference';
    }

    return $self;
}

sub library_paths {
    my $self = shift;

    if (@_) {
        my $paths = shift;
        $paths = [] unless defined $paths;
        ref $paths eq 'ARRAY'
          or croak 'library_paths must be an array reference';
        $self->set_attr('JQ_LIBRARY_PATH', [@$paths]);
        return $self;
    }

    my $paths = $self->attr('JQ_LIBRARY_PATH');
    return defined $paths ? $paths : [];
}

# Pass $_[0] through unaliased: copying it (my $data = ...) would strip
# the identity of Perl's native boolean SVs on perls before 5.36.
sub process {
    my $self = shift;
    my $results = _xs_process($self, $_[0], 0, -1, 0);
    return wantarray ? @$results : $results;
}

sub process_json {
    my $self = shift;
    my $text = shift;

    # -1 tells the XS side to use the object's own output options; anything
    # given here is merged over them for this call only.
    my ($flags, $raw) = (-1, 0);
    if (@_) {
        my %opts = (%{ $self->output_options }, @_);
        ($flags, $raw) = _output_flags(\%opts);
    }

    my $results = _xs_process($self, $text, 1, $flags, $raw);
    return wantarray ? @$results : $results;
}

sub to_json {
    my $data = shift;
    my %opts = @_;
    croak 'to_json does not take a raw option' if $opts{raw};
    my ($flags) = _output_flags(\%opts);
    return _to_json($data, $flags);
}

# Don't clone the underlying C struct into new ithreads.
sub CLONE_SKIP { 1 }

1;
