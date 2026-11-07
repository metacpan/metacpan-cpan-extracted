#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;
use File::Temp();
use FindBin();
use Mojo::File();

use Dist::Conformance::Source::Directory();
use Dist::Conformance::Flavor();

my $FIXTURES = Dist::Conformance::Source::Directory->new( directory => "$FindBin::Bin/data/standards" );

# A source of its own, with one file for each flavor given as YAML text.
sub standards (%flavors) {
    my $root = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    my $dir  = $root->child('conformance')->make_path;
    $dir->child("$_.yml")->spew( $flavors{$_} ) for keys %flavors;
    return Dist::Conformance::Source::Directory->new( directory => "$root" );
}

my $HAVE_NO   = qr/the\ standards\ at\ \S+\ have\ no\ /;
my $NOT_VALID = qr/\ is\ not\ valid:\n\ \ /;

sub load ( $source, $name ) { return Dist::Conformance::Flavor->load( $source, $name ) }

subtest 'load: the fixture flavors' => sub {
    my $strict = load( $FIXTURES, 'troglodyne-5.040' );
    is( $strict->lineage,                           [qw{troglodyne troglodyne-5.040}],                                                                                        'a flavor comes after the one it extends' );
    is( $strict->description,                       'A troglodyne distribution that declares use 5.040 or later',                                                             'the description is its own' );
    is( $strict->variables,                         { PERL_FLOOR => '5.040' },                                                                                                'its variables' );
    is( [ $strict->check_names ],                   [qw{ClaudeMd ClaudeSettings CriticProfile DistFiles GitHooks PerlSlopConfig SystemPackages ToolConfiguration Workflows}], 'its checks and those it extends, by name' );
    is( $strict->checks->{CriticProfile}{template}, 'templates/perlcriticrc',                                                                                                 'the strict profile' );

    my $compat = load( $FIXTURES, 'troglodyne-compat' );
    is( $compat->checks->{CriticProfile}{template}, 'templates/perlcriticrc.compat', 'the compat flavor names the other profile' );
    is( $compat->variables->{PERL_FLOOR},           '5.014',                         'and the other floor' );
    is( $compat->checks->{ClaudeMd},                $strict->checks->{ClaudeMd},     'and shares the rest' );

    my $base = load( $FIXTURES, 'troglodyne' );
    ok( !exists $base->checks->{CriticProfile}, 'the base names no profile' );
    is( $base->description, match(qr/agent\ harness/), 'the base has a description of its own' );
};

subtest 'load: a flavor that extends two others' => sub {
    my $service = load( $FIXTURES, 'troglodyne-service' );
    is( $service->lineage, [qw{troglodyne troglodyne-5.040 github-ci troglodyne-service}], 'each parent with its ancestors first, in the order of extends' );
    ok( !exists $service->checks->{DistFiles}, 'a check set to ~ is removed' );
    is( $service->checks->{Workflows}{required},                         { 'ci.yml' => 'templates/workflows/ci.yml' },                                                            'the second parent replaces a check key of the first' );
    is( $service->checks->{CriticProfile}{template},                     'templates/perlcriticrc',                                                                                'what only the first parent has stays' );
    is( $service->checks->{ClaudeSettings},                              { file => '.claude/settings.json', missing => 'fail', plugins => ['perl-slop@troglodyne-marketplace'] }, 'a key of the flavor itself replaces that key, and the others stay' );
    is( [ sort keys %{ $service->checks->{ToolConfiguration}{files} } ], [qw{.perltidyrc .preferred_modules.ini .tests-covering-map.pl}],                                         'a mapping is replaced whole, not merged' );
};

subtest 'load: a diamond' => sub {
    my $source = standards(
        base    => "name: base\nvariables: { A: base, B: base }\nchecks: { X: { k: base, j: base } }\n",
        left    => "name: left\nextends: [base]\nvariables: { A: left }\nchecks: { X: { k: left } }\n",
        right   => "name: right\nextends: [base]\nvariables: { B: right }\n",
        service => "name: service\nextends: [left, right]\nchecks: { X: { j: ~ } }\n",
    );
    my $flavor = load( $source, 'service' );
    is( $flavor->lineage,   [qw{base left right service}], 'the shared ancestor is merged once, first' );
    is( $flavor->variables, { A => 'left', B => 'right' }, 'so the right parent does not undo the left one' );
    is( $flavor->checks,    { X => { k => 'left' } },      'and a key set to ~ is removed' );
};

subtest 'load: a removed check can come back' => sub {
    my $source = standards(
        base  => "name: base\nchecks: { X: { k: 1 } }\n",
        drop  => "name: drop\nextends: [base]\nchecks: { X: ~ }\n",
        again => "name: again\nextends: [drop]\nchecks: { X: { j: 2 } }\n",
    );
    is( load( $source, 'drop' )->checks,  {},                  'removed' );
    is( load( $source, 'again' )->checks, { X => { j => 2 } }, 'and added again, without what was removed' );
};

subtest 'load: errors' => sub {
    my $source = standards(
        loop1    => "name: loop1\nextends: [loop2]\n",
        loop2    => "name: loop2\nextends: [loop1]\n",
        self     => "name: self\nextends: [self]\n",
        orphan   => "name: orphan\nextends: [nowhere]\n",
        broken   => "name: broken\nchecks: [\n",
        list     => "- name\n",
        wrong    => "name: other\n",
        badkey   => "name: badkey\nsurprise: 1\n",
        badcheck => "name: badcheck\nchecks: { X: [1] }\n",
        badname  => "name: badname\nchecks: { 'a/b': {} }\n",
    );
    like( dies { load( $source, 'loop1' ) },    qr/in\ a\ cycle:\ loop1\ ->\ loop2\ ->\ loop1/,                'a cycle is refused, and named' );
    like( dies { load( $source, 'self' ) },     qr/in\ a\ cycle:\ self\ ->\ self/,                             'and so is a flavor that extends itself' );
    like( dies { load( $source, 'missing' ) },  qr/flavor\ missing:\ ${HAVE_NO}conformance\/missing[.]yml/,    'a missing flavor names the file' );
    like( dies { load( $source, 'orphan' ) },   qr/nowhere,\ which\ conformance\/orphan[.]yml\ extends/,       'and the flavor that extends it' );
    like( dies { load( $source, '../x' ) },     qr/is\ not\ the\ name\ of\ a\ flavor/,                         'a name cannot be a path' );
    like( dies { load( $source, 'broken' ) },   qr/\Aconformance\/broken[.]yml\ does\ not\ parse\ as\ YAML/,   'a file that does not parse is named' );
    like( dies { load( $source, 'list' ) },     qr/\Aconformance\/list[.]yml\ does\ not\ hold\ a\ mapping/,    'a file must be a mapping' );
    like( dies { load( $source, 'wrong' ) },    qr/\Aconformance\/wrong[.]yml$NOT_VALID\/name:\ is\ other/,    'the name must be the file name' );
    like( dies { load( $source, 'badkey' ) },   qr/\Aconformance\/badkey[.]yml$NOT_VALID.+allowed:\ surprise/, 'an unknown key is named' );
    like( dies { load( $source, 'badcheck' ) }, qr/\ \ \/checks\/X:\ Expected\ object/,                        'the configuration of a check is a mapping' );
    like( dies { load( $source, 'badname' ) },  qr/\ \ \/checks\/a\/b:\ is\ not\ the\ name\ of\ a\ check/,     'and its name is a name' );
};

subtest 'load: an unquoted version' => sub {
    my $source = standards( number => "name: number\nvariables: { PERL_FLOOR: 5.040, LIST: [1] }\n" );
    like( dies { load( $source, 'number' ) }, qr/\ \ \/variables\/LIST:\ Expected\ string/, 'a variable is a string' );
    $source = standards( number => "name: number\nvariables: { PERL_FLOOR: 5.040 }\n" );
    is( load( $source, 'number' )->variables->{PERL_FLOOR}, '5.040', 'and an unquoted version keeps its text, not 5.04' );
};

subtest merge_checks => sub {
    my $shared = { k => 1 };
    my %checks = ( A => $shared, B => { k => 1 } );
    Dist::Conformance::Flavor::merge_checks( \%checks, { A => { j => 2, k => undef }, B => undef, C => { n => 3 } } );
    is( \%checks, { A => { j => 2 }, C => { n => 3 } }, 'merges, removes a key, removes a check and adds one' );
    is( $shared, { k => 1 }, 'and replaces a configuration rather than changing it' );
};

done_testing;
