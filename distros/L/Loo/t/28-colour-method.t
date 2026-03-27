use strict;
use warnings;
use Test::More;
use Loo;

# ── Colour getter returns hashref ────────────────────────────────
{
    my $dd = Loo->new;
    my $c = $dd->Colour;
    is(ref $c, 'HASH', 'Colour() returns hashref');
    ok(exists $c->{string_fg}, 'default has string_fg');
}

# ── Colour setter with partial spec ──────────────────────────────
{
    my $dd = Loo->new;
    $dd->Colour({ string_fg => 'red', key_fg => 'blue' });
    is($dd->Colour->{string_fg}, 'red', 'string_fg overridden');
    is($dd->Colour->{key_fg}, 'blue', 'key_fg overridden');
    # Other colours preserve their defaults
    is($dd->Colour->{number_fg}, 'cyan', 'number_fg unchanged');
}

# ── Colour setter returns $self ───────────────────────────────────
{
    my $dd = Loo->new;
    my $ret = $dd->Colour({ string_fg => 'red' });
    isa_ok($ret, 'Loo', 'Colour setter returns $self');
}

# ── Colour setter ignores unknown elements ────────────────────────
{
    my $dd = Loo->new;
    $dd->Colour({ bogus_fg => 'red', string_fg => 'yellow' });
    is($dd->Colour->{string_fg}, 'yellow', 'known key applied');
    ok(!exists $dd->Colour->{bogus_fg}, 'unknown key ignored');
}

# ── Colour setter with _bg keys ──────────────────────────────────
{
    my $dd = Loo->new;
    $dd->Colour({ string_bg => 'red', number_bg => 'blue' });
    is($dd->Colour->{string_bg}, 'red', 'string_bg set');
    is($dd->Colour->{number_bg}, 'blue', 'number_bg set');
}

# ── Colour after Theme: Theme clears, Colour patches ─────────────
{
    my $dd = Loo->new;
    $dd->Theme('monokai');
    is($dd->Colour->{string_fg}, 'yellow', 'monokai string_fg');
    $dd->Colour({ string_fg => 'red' });
    is($dd->Colour->{string_fg}, 'red', 'Colour overrides monokai');
    # Other monokai values still present
    is($dd->Colour->{number_fg}, 'magenta', 'monokai number_fg survives');
}

# ── All 17 colour element names are settable ─────────────────────
{
    my $dd = Loo->new;
    my %spec;
    for my $elem (qw(string number key brace bracket paren arrow comma
                     undef blessed regex code variable quote
                     keyword operator comment)) {
        $spec{"${elem}_fg"} = 'red';
    }
    $dd->Colour(\%spec);
    for my $k (keys %spec) {
        is($dd->Colour->{$k}, 'red', "$k set to red");
    }
}

done_testing;
