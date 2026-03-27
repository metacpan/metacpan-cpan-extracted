use strict;
use warnings;
use Test::More;

# ── Module loads ──────────────────────────────────────────────────
use_ok('Loo');

# ── Exports ───────────────────────────────────────────────────────
can_ok('Loo', qw(Dump cDump ncDump strip_colour));

{
    package Test::Loo::Exports;
    use Loo qw(Dump cDump ncDump);
    ::can_ok(__PACKAGE__, 'Dump');
    ::can_ok(__PACKAGE__, 'cDump');
    ::can_ok(__PACKAGE__, 'ncDump');
}

# ── Constructor ───────────────────────────────────────────────────
my $dd = Loo->new([1, 'hello'], ['a', 'b']);
isa_ok($dd, 'Loo');

is_deeply($dd->{values}, [1, 'hello'], 'values stored');
is_deeply($dd->{names},  ['a', 'b'],   'names stored');

# defaults
is($dd->Indent,    2,      'default indent = 2');
is($dd->Terse,     0,      'default terse = 0');
is($dd->Purity,    0,      'default purity = 0');
is($dd->Useqq,     0,      'default useqq = 0');
is($dd->Quotekeys, 1,      'default quotekeys = 1');
is($dd->Sortkeys,  0,      'default sortkeys = 0');
is($dd->Maxdepth,  0,      'default maxdepth = 0');
is($dd->Maxrecurse,1000,   'default maxrecurse = 1000');
is($dd->Pair,      ' => ', 'default pair');
is($dd->Varname,   'VAR',  'default varname');
is($dd->Deparse,   0,      'default deparse = 0');

# ── Accessor chaining ────────────────────────────────────────────
my $ret = $dd->Indent(1)->Terse(1)->Sortkeys(1);
isa_ok($ret, 'Loo', 'chaining returns $self');
is($dd->Indent,   1, 'indent set to 1');
is($dd->Terse,    1, 'terse set to 1');
is($dd->Sortkeys, 1, 'sortkeys set to 1');

# ── Sortkeys with coderef ────────────────────────────────────────
my $sorter = sub { return [ sort @{$_[0]} ] };
$dd->Sortkeys($sorter);
is($dd->Sortkeys, 1, 'sortkeys flag stays 1 with coderef');
is($dd->{sortkeys_cb}, $sorter, 'sortkeys_cb stored');

$dd->Sortkeys(0);
is($dd->Sortkeys, 0, 'sortkeys reset to 0');
is($dd->{sortkeys_cb}, undef, 'sortkeys_cb cleared');

# ── Colour() method ──────────────────────────────────────────────
$dd->Colour({ string_fg => 'green', key_fg => 'cyan' });
my $colour = $dd->Colour;
is($colour->{string_fg}, 'green', 'colour string_fg set');
is($colour->{key_fg},    'cyan',  'colour key_fg set');

$dd->Colour({ number_fg => 'red', bogus_fg => 'blue' });
is($colour->{number_fg}, 'red',   'colour number_fg set');
ok(!exists $colour->{bogus_fg},   'unknown colour key ignored');

# ── Theme() method ───────────────────────────────────────────────
$dd->Theme('monokai');
is($dd->Theme, 'monokai', 'theme set to monokai');
is($dd->Colour->{string_fg}, 'yellow', 'monokai string_fg = yellow');

$dd->Theme('none');
is($dd->Theme, 'none', 'theme set to none');
is_deeply($dd->Colour, {}, 'none theme has empty colour hash');

$dd->Theme('default');
is($dd->Colour->{string_fg}, 'green', 'default string_fg = green');

$dd->Theme('light');
is($dd->Colour->{string_fg}, 'red', 'light string_fg = red');

eval { $dd->Theme('nonexistent') };
like($@, qr/Unknown theme/, 'unknown theme dies');

# ── Dump() ────────────────────────────────────────────────────────
my $out = Loo->new([42])->Dump;
ok(defined $out, 'Dump returns defined output');
like($out, qr/VAR/, 'Dump output contains VAR (placeholder)');

# ── strip_colour ─────────────────────────────────────────────────
my $coloured = "\033[32mhello\033[0m \033[31mworld\033[0m";
my $plain = Loo::strip_colour($coloured);
is($plain, 'hello world', 'strip_colour removes ANSI escapes');

my $no_ansi = "just plain text";
is(Loo::strip_colour($no_ansi), $no_ansi, 'strip_colour passthrough for plain text');

# ── _detect_colour ───────────────────────────────────────────────
{
    local $Loo::USE_COLOUR = 1;
    is(Loo::_detect_colour(), 1, 'USE_COLOUR=1 overrides');

    local $Loo::USE_COLOUR = 0;
    is(Loo::_detect_colour(), 0, 'USE_COLOUR=0 overrides');
}

{
    local $Loo::USE_COLOUR;
    local $ENV{NO_COLOR} = '';
    is(Loo::_detect_colour(), 0, 'NO_COLOR env disables colour');
}

{
    local $Loo::USE_COLOUR;
    delete local $ENV{NO_COLOR};
    local $ENV{TERM} = 'dumb';
    is(Loo::_detect_colour(), 0, 'TERM=dumb disables colour');
}

done_testing;
