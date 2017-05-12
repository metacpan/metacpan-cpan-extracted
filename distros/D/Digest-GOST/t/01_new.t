use strict;
use warnings;
use Test::More;
use Digest::GOST;
use Digest::GOST::CryptoPro;

for my $m (qw(Digest::GOST Digest::GOST::CryptoPro)) {
    new_ok($m, [], 'new');
    can_ok($m, qw(clone reset add digest hexdigest b64digest));
    for my $f (qw(gost gost_hex gost_base64)) {
        ok eval "defined &${m}::${f}", "function is exported: $f";
    }

    my $d1 = $m->new();
    $d1->add('foo bar')->reset;
    is($d1->hexdigest, $m->new()->hexdigest, 'explicit reset');

    is(
        eval { $d1->reset->add('a')->digest; $d1->add('a')->hexdigest },
        $d1->reset->add('a')->hexdigest,
        'implicit reset'
    );

    $d1->add('foobar');
    my $d2 = $d1->clone;
    is($d1->hexdigest, $d2->hexdigest, 'clone');
}

done_testing;
