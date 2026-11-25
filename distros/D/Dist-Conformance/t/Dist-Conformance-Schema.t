#!perl
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

subtest parse_ini => sub {
    my $ini = "name = Foo\n[Run::Test]\nrun = a\nrun = b\n[GithubMeta]\nissues = 1\n[Git::Commit / Release]\nallow_dirty = Changes\n";
    is(
        Dist::Conformance::Schema::parse_ini( $ini, 'dist.ini' ),
        { _ => { name => 'Foo' }, 'Run::Test' => { run => [qw{a b}] }, GithubMeta => { issues => 1 }, 'Git::Commit / Release' => { allow_dirty => 'Changes' } },
        'a hash of sections, with the keys before the first in _, and each repeated key as a list of its values in order'
    );
    is( Dist::Conformance::Schema::parse_ini( "[A]\nx = 1\n[B]\n[A]\nx = 2\n", 'f.ini' ), { A => { x => [ 1, 2 ] }, B => {} }, 'a key repeated in a section that comes twice is a list too' );
    like( dies { Dist::Conformance::Schema::parse_ini( "[A\n", 'f.ini' ) }, qr/\Af[.]ini\ does\ not\ parse\ as\ INI:\ \S/, 'a syntax error names the file' );
};

subtest encode_json => sub {
    is( Dist::Conformance::Schema::encode_json( { b => 1, a => { c => [] } } ), qq{{\n  "a": {\n    "c": []\n  },\n  "b": 1\n}\n}, 'sorted, indented by two, with a final newline' );
};

subtest insert_yaml => sub {
    my $insert = \&Dist::Conformance::Schema::insert_yaml;
    is( $insert->( "# top\na:\n    b: 1   # mine\nc: 2", ['a'],     { d => 3 } ), "# top\na:\n    b: 1   # mine\n    d: 3\nc: 2\n", 'an entry goes at the end of its block, at its indentation' );
    is( $insert->( "a:\n  - x\n  # the end\nb: 1\n",     ['a'],     ['y'] ),      "a:\n  - x\n  - y\n  # the end\nb: 1\n",          'and an item at the end of a list, before a comment after it' );
    is( $insert->( "a:\n  b:\n    - x\n  c: 1\n",        [qw{a b}], ['y'] ),      "a:\n  b:\n    - x\n    - y\n  c: 1\n",           'a path reaches a nested collection' );
    is( $insert->( "a:\n  c: 1\n",                       [qw{a b}], ['y'] ),      "a:\n  c: 1\n  b:\n  - y\n",                      'a key that is not there goes at the end of the block above it' );
    is( $insert->( "c: 1",                               [qw{a b}], { d => 1 } ), "c: 1\na:\n  b:\n    d: 1\n",                     'or of the text' );
    is( $insert->( "a:\nb: 1\n",                         ['a'],     { d => 1 } ), "a:\n  d: 1\nb: 1\n",                             'an empty block gets an indentation of two' );
    like( dies { $insert->( "a: { b: 1 }\n",   ['a'], { d => 1 } ) }, qr/\Aa\ has\ something\ after\ it/, 'a key in flow style dies' );
    like( dies { $insert->( "a: &x\n  b: 1\n", ['a'], { d => 1 } ) }, qr/\Aa\ has\ something\ after\ it/, 'and so does a key with an anchor' );
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

subtest refuse => sub {
    is( dies { Dist::Conformance::Schema::refuse( 'f.yml', '/a: is wrong', '/b: too' ) }, "f.yml is not valid:\n  /a: is wrong\n  /b: too\n", 'each error on a line of its own, under the file' );
};

subtest matches => sub {
    ok( Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME,  'troglodyne-5.040' ), 'a name matches' );
    ok( !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, 'a/b' ),              'a path is not a name' );
    ok( !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, "a\n" ),              'nor is a name with a newline after it' );
    ok( !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, undef ),              'nor is undef' );
};

subtest relative_path => sub {
    for my $path (qw{a a/b .a a/..b ...}) { is( Dist::Conformance::Schema::relative_path( $path, 'here' ), $path, "'$path' is a relative path" ) }
    for my $bad  ( qw{/a .. ../a a/.. a/../b}, q{}, "a\nb" ) {
        like( dies { Dist::Conformance::Schema::relative_path( $bad, 'here' ) }, qr/is\ not\ a\ relative\ path\ inside\ here/, "'$bad' is refused" );
    }
    like( dies { Dist::Conformance::Schema::relative_path( undef, 'here' ) }, qr/not\ a\ relative\ path/, 'and so is undef' );
};

subtest first_line => sub {
    is( Dist::Conformance::Schema::first_line("Oops at lib/X.pm line 3.\nmore\n"), 'Oops', 'the first line, without where perl died' );
    is( Dist::Conformance::Schema::first_line(undef),                              q{},    'nothing for nothing' );
};

done_testing;
