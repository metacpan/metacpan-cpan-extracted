#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Dist::Conformance::Schema();

subtest parse_yaml => sub {
    is( Dist::Conformance::Schema::parse_yaml( "a: 1\nb: [x]\n", 'f.yml' ), { a => 1, b => ['x'] }, 'a mapping' );
    like( dies { Dist::Conformance::Schema::parse_yaml( "a: [\n", 'f.yml' ) }, qr/\Af[.]yml\ does\ not\ parse\ as\ YAML:\ \S/, 'a syntax error names the file' );
    like( dies { Dist::Conformance::Schema::parse_yaml( "- a\n",  'f.yml' ) }, qr/\Af[.]yml\ does\ not\ hold\ a\ mapping/,     'a list is not a mapping' );
    like( dies { Dist::Conformance::Schema::parse_yaml( q{},      'f.yml' ) }, qr/\Af[.]yml\ does\ not\ hold\ a\ mapping/,     'nor is an empty file' );
};

subtest parse_json => sub {
    is( Dist::Conformance::Schema::parse_json( '{"a":[1]}', 'f.json' ), { a => [1] }, 'an object' );
    like( dies { Dist::Conformance::Schema::parse_json( '{"a":', 'f.json' ) }, qr/\Af[.]json\ does\ not\ parse\ as\ JSON:\ \S/, 'a syntax error names the file' );
    like( dies { Dist::Conformance::Schema::parse_json( '[1]',   'f.json' ) }, qr/\Af[.]json\ does\ not\ hold\ an\ object/,     'an array is not an object' );
};

subtest encode_json => sub {
    is( Dist::Conformance::Schema::encode_json( { b => 1, a => { c => [] } } ), qq{{\n  "a": {\n    "c": []\n  },\n  "b": 1\n}\n}, 'sorted, indented by two, with a final newline' );
};

subtest validate => sub {
    my $schema = {
        type                 => 'object',
        required             => ['name'],
        additionalProperties => 0,
        properties           => { name => $Dist::Conformance::Schema::NAME, on => { type => 'boolean', default => 0 }, level => $Dist::Conformance::Schema::STATUS },
    };
    my $data  = { name => 'x', on => 'true' };
    my $valid = Dist::Conformance::Schema::validate( $data, $schema, 'f.yml' );
    is( $valid, { name => 'x', on => T() },    'a boolean is coerced' );
    is( $data,  { name => 'x', on => 'true' }, 'and the caller keeps its own data' );
    is( Dist::Conformance::Schema::validate( { name => 'x' }, $schema, 'f.yml' )->{on}, F(), 'a default is filled in' );

    my $died = dies { Dist::Conformance::Schema::validate( { name => 'a/b', level => 'warn' }, $schema, 'f.yml' ) };
    like( $died, qr/\Af[.]yml\ is\ not\ valid:\n/,            'the message names the file' );
    like( $died, qr/^\ \ \/name:\ String\ does\ not\ match/m, 'and the key of each error' );
    like( $died, qr/^\ \ \/level:\ Not\ in\ enum\ list/m,     'every error, not only the first' );
    like(
        dies { Dist::Conformance::Schema::validate( { name => 'x', extra => 1 }, $schema, 'f.yml' ) },
        qr/^\ \ \/:\ Properties\ not\ allowed:\ extra[.]/m,
        'an unknown key is an error'
    );
};

subtest matches => sub {
    ok( Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME,  'troglodyne-5.040' ), 'a name matches' );
    ok( !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, 'a/b' ),              'a path is not a name' );
    ok( !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, "a\n" ),              'nor is a name with a newline after it' );
    ok( !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, undef ),              'nor is undef' );
};

subtest relative_path => sub {
    is( Dist::Conformance::Schema::relative_path( $_, 'here' ), $_, "'$_' is a relative path" ) for qw{a a/b .a a/..b ...};
    for my $bad ( qw{/a .. ../a a/.. a/../b}, q{}, "a\nb" ) {
        like( dies { Dist::Conformance::Schema::relative_path( $bad, 'here' ) }, qr/is\ not\ a\ relative\ path\ inside\ here/, "'$bad' is refused" );
    }
    like( dies { Dist::Conformance::Schema::relative_path( undef, 'here' ) }, qr/not\ a\ relative\ path/, 'and so is undef' );
};

subtest first_line => sub {
    is( Dist::Conformance::Schema::first_line("Oops at lib/X.pm line 3.\nmore\n"), 'Oops', 'the first line, without where perl died' );
    is( Dist::Conformance::Schema::first_line(undef),                              q{},    'nothing for nothing' );
};

done_testing;
