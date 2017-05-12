use strict;
use warnings;
use Test::More tests => 19;
use Digest::BLAKE;

new_ok('Digest::BLAKE' => [$_], "algorithm $_") for qw(224 256 384 512);

is(eval { Digest::BLAKE->new },     undef, 'no algorithm specified');
is(eval { Digest::BLAKE->new(10) }, undef, 'invalid algorithm specified');

can_ok('Digest::BLAKE',
    qw(clone reset algorithm hashsize add digest hexdigest b64digest)
);

for my $alg (qw(224 256 384 512)) {
    my $d1 = Digest::BLAKE->new($alg);
    $d1->add('foo bar')->reset;
    is(
        $d1->hexdigest,
        Digest::BLAKE->new($alg)->hexdigest,
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
