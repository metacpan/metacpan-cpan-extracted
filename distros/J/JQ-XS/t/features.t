#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp ();
use File::Spec;

use JQ::XS
  qw(JQ_DEBUG_TRACE parse_json parse_json_stream to_json set_colors features);

# ---------------------------------------------------------------------------
# What this build can do
# ---------------------------------------------------------------------------

{
    my $features = features();
    is(ref $features, 'HASH', 'features() returns a hashref');
    ok(exists $features->{embedded_jq}, 'features() reports embedded_jq');
    ok(exists $features->{stderr_cb},   'features() reports stderr_cb');
    is(!!$features->{embedded_jq}, !!defined JQ::XS::jq_version(),
       'embedded_jq agrees with jq_version()');
}

# ---------------------------------------------------------------------------
# Named and positional arguments
# ---------------------------------------------------------------------------

{
    my $jq = JQ::XS->new('"\($greeting), \(.name)!"',
                         vars => { greeting => 'Hello' });
    is_deeply([$jq->process({ name => 'Alice' })], ['Hello, Alice!'],
              'vars become $variables');

    $jq = JQ::XS->new('$conf.limit',
                      vars => { conf => { limit => 5 } });
    is_deeply([$jq->process(undef)], [5], 'a var can be arbitrary Perl data');

    $jq = JQ::XS->new('$ARGS',
                      vars => { a => 1 }, args => ['x', 'y']);
    is_deeply([$jq->process(undef)],
              [{ named => { a => 1 }, positional => ['x', 'y'] }],
              '$ARGS carries both named and positional arguments');

    is_deeply([JQ::XS->new('$ARGS')->process(undef)],
              [{ named => {}, positional => [] }],
              '$ARGS is defined even with no arguments given');

    like(
        do { local $@; eval { JQ::XS->new('.', vars => 'nope') }; $@ },
        qr/vars must be a hash reference/,
        'vars is type checked'
    );
    like(
        do { local $@; eval { JQ::XS->new('.', bogus => 1) }; $@ },
        qr/Unknown option to JQ::XS->new: bogus/,
        'a misspelled option is caught'
    );
}

# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

{
    my $json = '{"b":1,"a":[1,2]}';

    is_deeply([JQ::XS->new('.')->process_json($json)],
              ['{"b":1,"a":[1,2]}'], 'compact by default, like jq -c');

    is_deeply([JQ::XS->new('.', sort_keys => 1)->process_json($json)],
              ['{"a":[1,2],"b":1}'], 'sort_keys, like jq -S');

    is_deeply([JQ::XS->new('.', pretty => 1)->process_json($json)],
              ["{\n  \"b\": 1,\n  \"a\": [\n    1,\n    2\n  ]\n}"],
              'pretty indents by two spaces');

    is_deeply([JQ::XS->new('.', indent => 4)->process_json($json)],
              ["{\n    \"b\": 1,\n    \"a\": [\n        1,\n        2\n    ]\n}"],
              'indent => 4');

    # jq's --indent 0 is one value per line, unindented -- not compact.
    is_deeply([JQ::XS->new('.', indent => 0)->process_json($json)],
              ["{\n\"b\": 1,\n\"a\": [\n1,\n2\n]\n}"],
              'indent => 0 still breaks lines, as in jq');

    is_deeply([JQ::XS->new('.', tab => 1)->process_json('{"a":1}')],
              ["{\n\t\"a\": 1\n}"], 'tab indents with tabs');

    is_deeply([JQ::XS->new('.', tab => 1, indent => 4)->process_json('{"a":1}')],
              ["{\n\t\"a\": 1\n}"], 'tab wins over indent, as in jq');

    is_deeply([JQ::XS->new('.', ascii => 1)->process_json('"héllo"')],
              ['"h\\u00e9llo"'], 'ascii escapes non-ASCII, like jq -a');

    is_deeply([JQ::XS->new('.', raw => 1)->process_json('"a\"b"')],
              ['a"b'], 'raw emits a string result unquoted, like jq -r');

    is_deeply([JQ::XS->new('.[]', raw => 1)->process_json('["s",1,null]')],
              ['s', '1', 'null'], 'raw only affects string results');

    # jq -r -a prints the string quoted and escaped; this follows suit.
    is_deeply([JQ::XS->new('.', raw => 1, ascii => 1)->process_json('"é"')],
              ['"\\u00e9"'], 'ascii wins over raw, as in jq -r -a');

    my ($colored) = JQ::XS->new('.', color => 1)->process_json('{"a":1}');
    like($colored, qr/\e\[/, 'color emits ANSI escapes');

    ok(set_colors('0;90:0;39:0;39:0;39:0;32:1;39:1;39:34;1'),
       'set_colors accepts a JQ_COLORS specification');
    ok(!set_colors('not a color spec'), 'set_colors rejects nonsense');

    like(
        do { local $@; eval { JQ::XS->new('.', indent => 9) }; $@ },
        qr/indent must be an integer from 0 to 7/,
        'indent is range checked'
    );
    like(
        do { local $@; eval { JQ::XS->new('.')->set_output(shiny => 1) }; $@ },
        qr/Unknown output option: shiny/,
        'a misspelled output option is caught'
    );
}

{
    # Per-call options merge over the object's, and leave it alone.
    my $jq = JQ::XS->new('.', sort_keys => 1);
    is_deeply($jq->output_options, { sort_keys => 1 }, 'output_options reads back');

    is_deeply([$jq->process_json('{"b":1,"a":2}', pretty => 1)],
              ["{\n  \"a\": 2,\n  \"b\": 1\n}"],
              'a per-call option merges over the object option');

    is_deeply([$jq->process_json('{"b":1,"a":2}')],
              ['{"a":2,"b":1}'], 'the object option survives the override');

    # set_output replaces rather than merges.
    $jq->set_output(pretty => 1);
    is_deeply($jq->output_options, { pretty => 1 }, 'set_output replaces');

    my $copy = $jq->output_options;
    $copy->{pretty} = 0;
    is_deeply($jq->output_options, { pretty => 1 },
              'output_options hands back a copy');
}

# ---------------------------------------------------------------------------
# to_json / parse_json / parse_json_stream
# ---------------------------------------------------------------------------

{
    is(to_json({ b => 1, a => 2 }, sort_keys => 1), '{"a":2,"b":1}',
       'to_json with sort_keys');
    is(to_json([1, 2], indent => 2), "[\n  1,\n  2\n]", 'to_json with indent');
    is(to_json('héllo', ascii => 1), '"h\\u00e9llo"', 'to_json with ascii');

    is_deeply(parse_json('{"a":[1,2]}'), { a => [1, 2] }, 'parse_json');
    ok(!defined parse_json('null'), 'parse_json of null');
    is_deeply([parse_json_stream(qq({"a":1}\n2 3 "x"))],
              [{ a => 1 }, 2, 3, 'x'],
              'parse_json_stream reads a stream of values');
    is_deeply([parse_json_stream('')], [], 'parse_json_stream of nothing');

    like(
        do { local $@; eval { parse_json('1 2') }; $@ },
        qr/Invalid JSON/,
        'parse_json rejects more than one value'
    );
    like(
        do { local $@; eval { parse_json_stream('{"a":') }; $@ },
        qr/Invalid JSON/,
        'parse_json_stream reports a truncated value'
    );
    like(
        do { local $@; eval { to_json(1, raw => 1) }; $@ },
        qr/to_json does not take a raw option/,
        'to_json rejects the raw option'
    );
}

# ---------------------------------------------------------------------------
# Module loading: allow_includes and library_paths
# ---------------------------------------------------------------------------

my $libdir = File::Temp::tempdir(CLEANUP => 1);
{
    open my $fh, '>', File::Spec->catfile($libdir, 'mod.jq')
      or die "cannot write the test module: $!";
    print {$fh} "def answer: 42;\n";
    close $fh or die "cannot write the test module: $!";
}

{
    my $jq = JQ::XS->new('include "mod"; answer', library_paths => [$libdir]);
    is_deeply([$jq->process(undef)], [42], 'library_paths is searched');
    is_deeply($jq->library_paths, [$libdir], 'library_paths reads back');

    $jq->library_paths(['/somewhere/else']);
    is_deeply($jq->library_paths, ['/somewhere/else'], 'library_paths is settable');

    $jq = JQ::XS->new('import "mod" as m; m::answer', library_paths => [$libdir]);
    is_deeply([$jq->process(undef)], [42], 'import works too');
}

{
    # allow_includes => 0 turns both directives away at compile time.
    for my $prog (
        'include "mod"; answer',
        'import "mod" as m; m::answer',
        qq(include "mod"  {search:"$libdir"}; answer),
        qq(\n\n  include "mod";\nanswer),
        qq(# a comment\ninclude "mod"; answer),
        qq(module {name:"x"}; include "mod"; answer),
        qq(module {name:"x;y"}; include "mod"; answer),   # ';' inside a string
      )
    {
        like(
            do { local $@; eval { JQ::XS->new($prog, allow_includes => 0) }; $@ },
            qr/include\/import is not allowed/,
            'refused: ' . ($prog =~ s/\n/\\n/gr)
        );
        ok(JQ::XS::_program_has_imports($prog), '  and detected as importing');
    }
}

{
    # Legal jq that merely uses the words has to keep working.  "include" is
    # one of parser.y's Keywords, so it is a valid object key and field name.
    my @fine = (
        '{include: 1} | .include',
        '.foo.include',
        '{"import": 2} | .import',
        'def includes: 1; includes',
        '"include \"mod\";"',                 # a string, not a directive
        '# include "mod";
.',                                            # commented out
        'module {name:"x"}; .',
        '{module: 1}',
    );

    for my $prog (@fine) {
        ok(!JQ::XS::_program_has_imports($prog),
           'no import seen in: ' . ($prog =~ s/\n/\\n/gr));
        ok(
            do { local $@; eval { JQ::XS->new($prog, allow_includes => 0) }; !$@ },
            '  and it still compiles'
        );
    }
}

{
    # The one program the two jq lexers read differently: 1.6 ends a comment
    # at the newline, so the include is a directive; 1.7 and later honour the
    # trailing backslash, so it is more comment.  The scanner takes the union
    # and calls it importing, which is the reading that cannot let a module
    # through behind allow_includes => 0.
    my $ambiguous = qq(# continued \\\ninclude "mod";\n.);

    ok(JQ::XS::_program_has_imports($ambiguous),
       'a comment continuation hiding an include counts as importing');
    like(
        do { local $@; eval { JQ::XS->new($ambiguous, allow_includes => 0) }; $@ },
        qr/include\/import is not allowed/,
        'and allow_includes => 0 refuses it'
    );
  SKIP: {
        # Only the 1.7-and-later lexer reads this as a comment; on jq 1.6 it
        # is a real directive, so allowing includes means trying to load the
        # module and failing to find it.
        skip 'this libjq predates the comment continuation', 1
          unless JQ::XS::features()->{stderr_cb};

        ok(
            do { local $@; eval { JQ::XS->new($ambiguous) }; !$@ },
            'while allowing includes still compiles it'
        );
    }
}

{
    # Emptying the library path is not a sandbox: jq falls back on "." for a
    # directive that names no search path.  This is why allow_includes exists,
    # and the test records the behaviour rather than wishing it away.
    my $cwd = File::Spec->rel2abs('.');
    chdir $libdir or die "chdir: $!";
    my $ok = eval {
        my $jq = JQ::XS->new('include "mod"; answer', library_paths => []);
        is_deeply([$jq->process(undef)], [42],
                  'an empty library path still lets jq search the cwd');
        1;
    };
    my $err = $@;
    chdir $cwd or die "chdir back: $!";
    die $err unless $ok;
}

# ---------------------------------------------------------------------------
# ~/.jq: load_program() in src/linker.c prepends an *optional* import of
# "~/.jq" to every program it compiles, unconditionally -- it is not part of
# the program's own text. That is why neither allow_includes => 0 (a text
# scan of the program's own prologue) nor library_paths => [] (which only
# matters to a directive that names no search path of its own; this
# synthetic import already carries $HOME as its search metadata) can keep it
# out. Only removing $HOME from the environment before compiling stops it.
#
# This is a libjq implementation detail rather than something the module
# implements, and some distro-patched libjq builds may not carry it (or may
# carry a differently-behaved version), so this whole section is skipped
# under a JQ_SYSTEM=1 build and only exercises the vendored engine whose
# source (.jq-build/jq-1.8.2/src/linker.c) this was verified against.
# ---------------------------------------------------------------------------

SKIP: {
    skip 'the automatic ~/.jq import is a libjq implementation detail this '
       . 'system build may not share', 5
      unless JQ::XS::features()->{embedded_jq};

    my $fakehome = File::Temp::tempdir(CLEANUP => 1);
    {
        open my $fh, '>', File::Spec->catfile($fakehome, '.jq')
          or die "cannot write the fake \$HOME/.jq: $!";
        print {$fh} qq(def leaked_marker: "from-dot-jq";\n);
        close $fh or die "cannot write the fake \$HOME/.jq: $!";
    }

    {
        # Scoped to this block: the fake $HOME must not survive to leak into
        # any later test, and the real $HOME/.jq (whoever runs this suite)
        # must never be touched at all.
        local $ENV{HOME} = $fakehome;

        my $jq = JQ::XS->new('leaked_marker');
        is_deeply([$jq->process(undef)], ['from-dot-jq'],
                  'a plain new() picks up ~/.jq');

        $jq = JQ::XS->new('leaked_marker', allow_includes => 0);
        is_deeply([$jq->process(undef)], ['from-dot-jq'],
                  'allow_includes => 0 does not stop it: the import is not '
                  . 'in the program text it scans');

        $jq = JQ::XS->new('leaked_marker',
                           allow_includes => 0, library_paths => []);
        is_deeply([$jq->process(undef)], ['from-dot-jq'],
                  'library_paths => [] does not stop it either: the import '
                  . 'carries $HOME as its own search metadata');
    }

    {
        # get_home() (src/util.c) returns an invalid jv, and load_program()
        # skips the import entirely, only when HOME is unset outright --
        # local $ENV{HOME} = '' is not the same thing, since getenv("HOME")
        # then returns a defined empty string. delete local is the one that
        # actually disables the lookup, and it restores HOME at the end of
        # this block either way.
        local $@;
        delete local $ENV{HOME};
        eval { JQ::XS->new('leaked_marker') };
        like($@, qr/not defined/,
             'unsetting $ENV{HOME} entirely leaves the name genuinely '
             . 'undefined');
    }

    {
        # And it is resolved at compile time, not at process() time: an
        # object compiled while HOME pointed at the fake directory keeps
        # working once HOME is gone.
        local $ENV{HOME} = $fakehome;
        my $jq = JQ::XS->new('leaked_marker');
        delete local $ENV{HOME};
        is_deeply([$jq->process(undef)], ['from-dot-jq'],
                  '~/.jq is imported at compile time, so process() still '
                  . 'sees it after $ENV{HOME} disappears');
    }
}

# ---------------------------------------------------------------------------
# Attributes
# ---------------------------------------------------------------------------

{
    my $jq = JQ::XS->new('.', attrs => { JQ_ORIGIN => '/opt/jq' });
    is($jq->attr('JQ_ORIGIN'), '/opt/jq', 'attrs are set before compiling');
    ok(!defined $jq->attr('NO_SUCH_ATTRIBUTE'), 'an unset attribute is undef');

    $jq->set_attr('MY_ATTR', { a => 1 });
    is_deeply($jq->attr('MY_ATTR'), { a => 1 }, 'set_attr/attr round-trip');
}

# ---------------------------------------------------------------------------
# halt and halt_error
# ---------------------------------------------------------------------------

{
    my $jq = JQ::XS->new('1, 2, halt, 3');
    is_deeply([$jq->process(undef)], [1, 2], 'results before a halt are kept');
    ok($jq->halted, 'halted() is true after halt');
    ok(!defined $jq->error_message, 'plain halt leaves no message');

    $jq = JQ::XS->new('halt_error(3)');
    is_deeply([$jq->process("boom\n")], [], 'halt_error produces no output');
    ok($jq->halted, 'halted() is true after halt_error');
    is($jq->exit_code, 3, 'exit_code() is the code halt_error was given');
    is($jq->error_message, "boom\n", 'error_message() is the halted value');

    # A non-string message comes back converted like any other result.
    $jq = JQ::XS->new('{code: 1} | halt_error');
    $jq->process(undef);
    is_deeply($jq->error_message, { code => 1 },
              'error_message() of a non-string halt_error');

    # A run that does not halt clears what the last one left behind.
  SKIP: {
        # jq 1.6 corrupts its own heap in jq_teardown() after a halt_error --
        # reproducible with no JQ::XS involvement beyond calling jq_teardown,
        # and fixed upstream since.  The embedded build is unaffected; a
        # JQ_SYSTEM=1 build against a libjq that old would abort the process
        # while this object was being freed, so do not build one.  Missing
        # jq_set_stderr_cb is the detectable marker of a pre-1.7 libjq.
        skip 'this libjq predates jq 1.7 and double-frees after halt_error', 4
          unless JQ::XS::features()->{stderr_cb};

        # halt_error/1 takes the exit code; the message is its input.
        my $reset =
          JQ::XS->new('if . then "nope\n" | halt_error else "fine" end');
        $reset->process(1);
        ok($reset->halted, 'halted on the first run');
        # null, not 0: jq counts every value but false and null as true.
        is_deeply([$reset->process(undef)], ['fine'],
                  'the second run produces normally');
        ok(!$reset->halted, 'halted() is reset by the next run');
        ok(!defined $reset->exit_code, 'exit_code() is reset too');
    }
}

{
    my $jq = JQ::XS->new('halt_error(3)');
    is($jq->die_on_halt_error(1), 0, 'die_on_halt_error returns the old value');
    is($jq->die_on_halt_error, 1, 'and reads back');

    my @out = eval { $jq->process("boom\n") };
    is($@, "boom\n", 'die_on_halt_error raises the halt_error message');
    ok($jq->halted, 'and the halt is still recorded');

    # Plain halt has no message, so it never raises.
    my $plain = JQ::XS->new('1, halt', die_on_halt_error => 1);
    is_deeply([eval { $plain->process(undef) }], [1], 'plain halt does not raise');
    is($@, '', 'no exception from plain halt');
}

# ---------------------------------------------------------------------------
# debug and stderr callbacks
# ---------------------------------------------------------------------------

{
    my @seen;
    my $jq = JQ::XS->new('debug | . + 1',
                         debug => sub { push @seen, $_[0] });
    is_deeply([$jq->process(1)], [2], 'debug passes the value through');
    is_deeply(\@seen, [1], 'the debug callback saw the value');

    @seen = ();
    $jq->set_debug_cb(undef);
    is_deeply([$jq->process(1)], [2], 'a disconnected debug still passes through');
    is_deeply(\@seen, [], 'and calls nothing');

    # The stderr builtin needs a libjq from jq 1.7 or later.
  SKIP: {
        skip 'this libjq has no jq_set_stderr_cb', 2
          unless JQ::XS::features()->{stderr_cb};

        my @errs;
        my $err = JQ::XS->new('stderr', stderr => sub { push @errs, $_[0] });
        is_deeply([$err->process({ a => 1 })], [{ a => 1 }],
                  'stderr passes through');
        is_deeply(\@errs, [{ a => 1 }], 'the stderr callback saw the value');
    }

    like(
        do { local $@; eval { JQ::XS->new('.', debug => 'not code') }; $@ },
        qr/debug callback must be a code reference/,
        'a callback is type checked'
    );
}

{
    # An exception cannot be thrown out of libjq, so it is raised once the run
    # is over.  The results of that run are dropped with it.
    my $jq = JQ::XS->new('.[] | debug',
                         debug => sub { die "callback failed\n" });
    my @out = eval { $jq->process([1, 2]) };
    like($@, qr/^callback failed$/m, 'a debug exception reaches the caller');
    is_deeply(\@out, [], 'and the run produces nothing');
}

# ---------------------------------------------------------------------------
# input / inputs
# ---------------------------------------------------------------------------

{
    my $jq = JQ::XS->new('[., inputs]', inputs => [2, 3]);
    is_deeply([$jq->process(1)], [[1, 2, 3]], 'inputs from an array ref');

    # The queue is per-set_inputs, so a second run sees an exhausted one.
    is_deeply([$jq->process(1)], [[1]], 'the array is consumed, not restarted');

    $jq->set_inputs([9]);
    is_deeply([$jq->process(1)], [[1, 9]], 'set_inputs refills it');

    my @queue = (1, undef, 2);
    $jq = JQ::XS->new('[inputs]',
                      inputs => sub { @queue ? shift @queue : () });
    is_deeply([$jq->process(undef)], [[1, undef, 2]],
              'a callback returning undef yields JSON null, not end of stream');

    $jq = JQ::XS->new('[inputs]');
    is_deeply([$jq->process(undef)], [[]],
              'inputs yields nothing when unconnected');

    $jq = JQ::XS->new('input', inputs => []);
    is_deeply([eval { $jq->process(undef) }], [],
              'input on an exhausted stream produces no output');

    like(
        do { local $@; eval { JQ::XS->new('.', inputs => 'nope') }; $@ },
        qr/inputs must be a code reference or an array reference/,
        'inputs is type checked'
    );
}

{
    # An exception in the input callback becomes a jq error, so the filter can
    # catch it -- and if it does not, the run fails.
    my $jq = JQ::XS->new('try input catch "caught: \(.)"',
                         inputs => sub { die "no more\n" });
    is_deeply([$jq->process(undef)], ["caught: no more\n"],
              'an input exception is catchable inside the filter');

    $jq = JQ::XS->new('input', inputs => sub { die "no more\n" });
    eval { $jq->process(undef) };
    like($@, qr/no more/, 'an uncaught input exception surfaces as a runtime error');
}

{
    # libjq is not reentrant, so reentering process() has to be refused
    # rather than left to corrupt the jq_state.
    my $jq;
    $jq = JQ::XS->new('[inputs]', inputs => sub { $jq->process(1); () });
    eval { $jq->process(undef) };
    like($@, qr/cannot reenter process/, 'reentering process() is refused');
}

# ---------------------------------------------------------------------------
# Execution flags
# ---------------------------------------------------------------------------

{
    my $jq = JQ::XS->new('.');
    is($jq->flags, 0, 'flags default to none');
    is($jq->flags(JQ_DEBUG_TRACE), 0, 'flags() returns the previous value');
    is($jq->flags, JQ_DEBUG_TRACE, 'and sets the new one');
    $jq->flags(0);

    my $traced = JQ::XS->new('.', flags => JQ_DEBUG_TRACE);
    is($traced->flags, JQ_DEBUG_TRACE, 'flags can be set from new()');
}

done_testing();
