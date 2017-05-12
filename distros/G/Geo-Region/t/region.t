use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::Most tests => 11;
use Geo::Region;

subtest 'default empty region' => sub {
    plan tests => 2;
    my $r = Geo::Region->new;

    ok        !$r->is_within(1),     'not within world';
    is_deeply [$r->countries],   [], 'no countries';
};

subtest 'explicit empty region' => sub {
    plan tests => 2;
    my $r = Geo::Region->new(include => []);

    ok        !$r->is_within(1),     'not within world';
    is_deeply [$r->countries],   [], 'no countries';
};

subtest 'single-argument constructor' => sub {
    plan tests => 1;
    my $r = Geo::Region->new(53);

    is_deeply [$r->countries], [qw( AU NF NZ )], 'expected countries';
};

subtest 'hashref constructor' => sub {
    plan tests => 1;
    my $r = Geo::Region->new({ include => 53 });

    is_deeply [$r->countries], [qw( AU NF NZ )], 'expected countries';
};

subtest 'deprecated region param' => sub {
    plan tests => 2;
    my $r;
    warning_like {
        $r = Geo::Region->new(region => 53)
    } qr/deprecated/, 'deprecated argument warning';

    is_deeply [$r->countries], [qw( AU NF NZ )], 'expected countries';
};

subtest 'World (001) superregion' => sub {
    plan tests => 42;
    my $r = Geo::Region->new(include => 1);

    ok $r->is_within(1),    'region is within itself';
    ok $r->contains(1),     'region contains itself';
    ok $r->contains(2),     'region contains subregion';
    ok $r->contains(11),    'region contains subsubregion';
    ok $r->contains('011'), 'region contains subsubregion string';
    ok $r->contains('BF'),  'region contains country';
    ok $r->contains('bf'),  'region contains lowercase country';

    my @countries = $r->countries;
    is         @countries,  256,               'expected # of countries';
    like      "@countries", qr/^[A-Z ]+$/,     'countries are uppercase';
    is_deeply \@countries,  [sort @countries], 'countries are sorted';

    my %returns_country = map { $_ => 1 } @countries;
    # these codes are: 1. deprecated; 2. grouping; and 3. aliases
    for my $code (qw(
        AN BU CS DD FX NT QU SU TP YD YU ZR
        EU QO
        QU UK
    )) {
        ok $r->contains($code),      "contains code $code";
        ok !$returns_country{$code}, "does not return code $code";
    }

};

subtest 'Mexico (MX) country' => sub {
    plan tests => 10;
    my $r = Geo::Region->new(include => 'MX');

    ok $r->contains('MX'),  'country contains itself';
    ok $r->contains('mx'),  'country contains itself, case insensitive';
    ok $r->is_within('MX'), 'country is within itself';
    ok $r->is_within('mx'), 'country is within itself, case insensitive';
    ok $r->is_within(13),   'within Central America (013) region';
    ok $r->is_within(19),   'within Americas (019) region';
    ok $r->is_within(1),    'within World (001) region';
    ok $r->is_within(3),    'within North America (003) grouping';
    ok $r->is_within(419),  'within Latin America (419) grouping';
    is_deeply [$r->countries], ['MX'], 'only one country in a country';
};

subtest 'Central Asia (143) + Russia (RU)' => sub {
    plan tests => 7;
    my $r = Geo::Region->new(include => [143, 'RU']);

    ok $r->contains(143),    'contains included region';
    ok $r->contains('RU'),   'contains included country';
    ok $r->contains('KZ'),   'contains country within any included region';
    ok $r->is_within(1),     'within regions shared by all included';
    ok !$r->is_within(143),  'not within either included region';
    ok !$r->is_within('RU'), 'not within either included region';

    is_deeply(
        [$r->countries],
        [qw( KG KZ RU TJ TM UZ )],
        'return all countries within any included'
    );
};

subtest 'Europe (150) − European Union (EU)' => sub {
    plan tests => 5;
    my $r = Geo::Region->new(include => 150, exclude => 'EU');

    ok $r->contains('CH'),  'contains countries !within excluded region';
    ok $r->contains(155),   'contains regions within included region';
    ok !$r->contains('EU'), '!contains excluded region';
    ok !$r->contains('FR'), '!contains countries within excluded region';

    is_deeply [$r->countries], [qw(
        AD AL AX BA BY CH FO GG GI IM IS JE LI
        MC MD ME MK NO RS RU SJ SM UA VA XK
    )], 'return all countries within included except excluded';
};

subtest 'deprecated alias QU for EU' => sub {
    plan tests => 6;
    my $r = Geo::Region->new(include => 'QU');

    ok $r->is_within('EU'), 'within official region';
    ok $r->is_within('QU'), 'within deprecated region';
    ok $r->contains('EU'),  'contains official region';
    ok $r->contains('QU'),  'contains deprecated region';
    ok $r->contains('GB'),  'contains official country';
    ok $r->contains('UK'),  'contains deprecated country';
};

subtest 'deprecated alias UK for GB' => sub {
    plan tests => 5;
    my $r = Geo::Region->new(include => 'UK');

    ok $r->is_within('GB'), 'within official country';
    ok $r->is_within('UK'), 'within deprecated country';
    ok $r->contains('GB'),  'contains official country';
    ok $r->contains('UK'),  'contains deprecated country';
    is_deeply [$r->countries], ['GB'], 'only official countries';
};
