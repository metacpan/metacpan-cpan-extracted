use strict;
use warnings;
use Test::More tests => 19;
use Digest::Luffa;

new_ok('Digest::Luffa' => [$_], "algorithm $_") for qw(224 256 384 512);

is(eval { Digest::Luffa->new },     undef, 'no algorithm specified');
is(eval { Digest::Luffa->new(10) }, undef, 'invalid algorithm specified');

can_ok('Digest::Luffa',
    qw(clone reset algorithm hashsize add digest hexdigest b64digest)
);

for my $alg (qw(224 256 384 512)) {
    my $d1 = Digest::Luffa->new($alg);
    $d1->add('foo bar')->reset;
    is(
        $d1->hexdigest,
        Digest::Luffa->new($alg)->hexdigest,
        "explicit reset of $alg"
    );
    is(
        eval { $d1->reset->add('a')->digest; $d1->add('a')->hexdigest },
        $d1->reset->add('a')->hexdigest,
        "implicit reset of $alg"
    );

    $d1->add('foobar');
    my $d2 = $d1->clone;
    is($d1->hexdigest, $d2->hexdigest, "clone of $alg");
}
