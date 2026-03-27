use strict;
use warnings;
use Test::More;
use Loo;

sub dd {
    my ($data, %opts) = @_;
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    while (my ($k, $v) = each %opts) {
        my $method = ucfirst($k);
        $dd->$method($v) if $dd->can($method);
    }
    return $dd->Dump;
}

# ── Sortkeys on ───────────────────────────────────────────────────
my $out = dd({z => 1, a => 2, m => 3}, sortkeys => 1);
like($out, qr/'a'.*'m'.*'z'/s, 'sortkeys: alphabetical order');

# ── Sortkeys off (default) ────────────────────────────────────────
my $off = dd({z => 1, a => 2, m => 3});
ok(defined $off, 'sortkeys off: output produced');

# ── Sortkeys with coderef ────────────────────────────────────────
{
    my $dd = Loo->new([{z => 1, a => 2, m => 3}]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(sub { return [reverse sort keys %{$_[0]}] });
    my $custom = $dd->Dump;
    like($custom, qr/'z'.*'m'.*'a'/s, 'sortkeys coderef: reverse order');
}

# ── Nested sortkeys ───────────────────────────────────────────────
my $nested = dd({b => {d => 1, c => 2}, a => 3}, sortkeys => 1);
like($nested, qr/'a'.*'b'/s, 'nested sortkeys: outer sorted');
like($nested, qr/'c'.*'d'/s, 'nested sortkeys: inner sorted');

done_testing;
