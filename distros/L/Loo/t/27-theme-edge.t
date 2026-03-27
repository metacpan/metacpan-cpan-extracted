use strict;
use warnings;
use Test::More;
use Loo;

# ── Theme getter default ─────────────────────────────────────────
{
    my $dd = Loo->new;
    is($dd->Theme, 'default', 'theme getter: default');
}

# ── Theme setter: all built-in themes ─────────────────────────────
for my $name (qw(default light monokai none)) {
    my $dd = Loo->new;
    my $ret = $dd->Theme($name);
    is($dd->Theme, $name, "theme set to $name");
    isa_ok($ret, 'Loo', "Theme('$name') returns \$self");
}

# ── Theme 'none' clears colours ──────────────────────────────────
{
    my $dd = Loo->new;
    $dd->Theme('none');
    is_deeply($dd->Colour, {}, 'none theme: empty colour hash');
}

# ── Theme switch default→monokai→default ─────────────────────────
{
    my $dd = Loo->new;
    is($dd->Colour->{string_fg}, 'green', 'start: green strings');
    $dd->Theme('monokai');
    is($dd->Colour->{string_fg}, 'yellow', 'monokai: yellow strings');
    $dd->Theme('default');
    is($dd->Colour->{string_fg}, 'green', 'back to default: green');
}

# ── Theme unknown dies ────────────────────────────────────────────
{
    my $dd = Loo->new;
    eval { $dd->Theme('nonexistent') };
    like($@, qr/Unknown theme 'nonexistent'/, 'unknown theme dies');
    like($@, qr/Available:/, 'error lists available themes');
}

# ── Theme does not affect other options ───────────────────────────
{
    my $dd = Loo->new;
    $dd->Indent(1)->Sortkeys(1);
    $dd->Theme('monokai');
    is($dd->Indent, 1, 'theme switch: indent unchanged');
    is($dd->Sortkeys, 1, 'theme switch: sortkeys unchanged');
}

# ── Light theme has expected colours ──────────────────────────────
{
    my $dd = Loo->new;
    $dd->Theme('light');
    is($dd->Colour->{string_fg}, 'red', 'light: string_fg = red');
    is($dd->Colour->{number_fg}, 'blue', 'light: number_fg = blue');
}

done_testing;
