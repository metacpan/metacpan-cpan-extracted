use strict;
use warnings;
use Test::More;
use Loo;

sub dump_hash {
    my ($h, $quotekeys) = @_;
    my $dd = Loo->new([$h]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1)->Quotekeys($quotekeys);
    return $dd->Dump;
}

my $h = {
    abc => 1,
    'a b' => 2,
    '123' => 3,
    'x-y' => 4,
    _ok => 5,
};

{
    my $out = dump_hash($h, 1);
    like($out, qr/'abc' => 1/, 'quotekeys on: bareword quoted');
    like($out, qr/'a b' => 2/, 'quotekeys on: spaced key quoted');
    like($out, qr/'123' => 3/, 'quotekeys on: numeric key quoted');
    like($out, qr/'x-y' => 4/, 'quotekeys on: punctuation key quoted');
}

{
    my $out = dump_hash($h, 0);
    like($out, qr/abc => 1/, 'quotekeys off: bareword unquoted');
    like($out, qr/'a b' => 2/, 'quotekeys off: spaced key still quoted');
    like($out, qr/'123' => 3/, 'quotekeys off: numeric key still quoted');
    like($out, qr/'x-y' => 4/, 'quotekeys off: punctuation key still quoted');
    like($out, qr/_ok => 5/, 'quotekeys off: underscore key unquoted');
}

done_testing;
