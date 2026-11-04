#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Config();

my $NOT_VALID = qr/\A[.]conformance[.]yml\ is\ not\ valid:\n/;

sub load ($yaml) {
    return Dist::Conformance::Config::load( Dist::Conformance::Snapshot::Directory->new( root => Fixture::checkout( '.conformance.yml' => $yaml ) ) );
}

subtest load => sub {
    is(
        load("flavor: troglodyne\nsource: { directory: /bogus/std }\n"),
        { flavor => 'troglodyne', source => { directory => '/bogus/std' }, skip => [], checks => {}, variables => {} },
        'the defaults are filled in'
    );
    is( load("flavor: f\nsource: { git: /bogus/std.git, ref: v1, path: a/b }\nskip: [X]\nchecks: { Y: { k: 1 } }\nvariables: { DIST: D }\n")->{source}, { git => '/bogus/std.git', ref => 'v1', path => 'a/b' }, 'a git source' );
    like( dies { Dist::Conformance::Config::load( Dist::Conformance::Snapshot::Directory->new( root => Fixture::checkout() ) ) }, qr/has\ no\ [.]conformance[.]yml/,            'a missing file is an error' );
    like( dies { load("flavor: [\n") },                                                                                           qr/\A[.]conformance[.]yml\ does\ not\ parse/, 'and so is one that does not parse' );
    like( dies { load("flavor: [\n") },                                                                                           qr/did\ not\ find\ expected\ node\ content/,  'and the message says what YAML::XS found wrong' );
};

subtest 'load: what is refused' => sub {
    like( dies { load("source: { directory: /bogus }\n") },                         qr/$NOT_VALID.*\/flavor:\ Missing\ property/,        'the flavor is required' );
    like( dies { load("flavor: f\n") },                                             qr/$NOT_VALID.*\/source:\ Missing\ property/,        'and so is the source' );
    like( dies { load("flavor: a/b\nsource: { directory: /bogus }\n") },            qr/$NOT_VALID.*\/flavor:\ String\ does\ not/,        'a flavor is a name' );
    like( dies { load("flavor: f\nsource: { git: x, directory: y }\n") },           qr/$NOT_VALID.*\/source:\ \/oneOf\/0/,               'a source is git or a directory, not both' );
    like( dies { load("flavor: f\nsource: { path: x }\n") },                        qr/$NOT_VALID.*\/source\/git:\ \/oneOf\/0\ Missing/, 'and is one of them' );
    like( dies { load("flavor: f\nsource: { git: --upload-pack=x }\n") },           qr/$NOT_VALID.*\/source\/git:/,                      'a url that git would take for an option is refused' );
    like( dies { load("flavor: f\nsource: { directory: d, path: ../x }\n") },       qr/$NOT_VALID.*\/source\/path:/,                     'a path cannot leave the tree' );
    like( dies { load("flavor: f\nsource: { directory: d }\nskip: Workflows\n") },  qr/$NOT_VALID.*\/skip:\ Expected\ array/,            'skip is a list' );
    like( dies { load("flavor: f\nsource: { directory: d }\nchecks: { X: ~ }\n") }, qr/$NOT_VALID.*\/checks\/X:\ Expected\ object/,      'a check cannot be removed here, only skipped' );
    like( dies { load("flavor: f\nsource: { directory: d }\nsurprise: 1\n") },      qr/$NOT_VALID.*not\ allowed:\ surprise/,             'an unknown key is refused' );
};

subtest validate => sub {
    is( Dist::Conformance::Config::validate( { flavor => 'f', source => { directory => 'd' } } )->{skip}, [], 'a hash without the file' );
};

done_testing;
