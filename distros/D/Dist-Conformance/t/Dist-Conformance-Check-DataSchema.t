#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::DataSchema();
use Dist::Conformance::Snapshot::Directory();

my %CONFIG = (
    file   => '.perl-slop.json',
    schema => { type => 'object', additionalProperties => 0, properties => { before_edit => { type => 'object' }, before_commit => { type => 'object' } } },
);

sub config_check (%config)          { return Fixture::make_check( Dist::Conformance::Check::DataSchema::, { %CONFIG, %config } ) }
sub check_of     ( $root, %config ) { return [ config_check(%config)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }

subtest check => sub {
    is( check_of( Fixture::checkout() ),                                                              [ 'info', 'there is no .perl-slop.json' ],                                    'an absent file is info' );
    is( check_of( Fixture::checkout(), missing => 'fail' ),                                           [ 'fail', 'there is no .perl-slop.json' ],                                    'or what the flavor says' );
    is( check_of( Fixture::checkout( '.perl-slop.json' => '{"before_edit":' ) ),                      [ 'fail', match(qr/\A[.]perl-slop[.]json\ does\ not\ parse\ as\ JSON/) ],     'a file that does not parse fails' );
    is( check_of( Fixture::checkout( '.perl-slop.json' => '[]' ) ),                                   [ 'fail', '.perl-slop.json does not hold an object at its top level' ],       'and so does one that is not an object' );
    is( check_of( Fixture::checkout( '.perl-slop.json' => '{"before_edit":{},"before_comit":{}}' ) ), [ 'fail', match(qr/schema:\ \/:\ Properties\ not\ allowed:\ before_comit/) ], 'a misspelled key fails, and is named' );
    is( check_of( Fixture::checkout( '.perl-slop.json' => '{"before_edit":[]}' ) ),                   [ 'fail', match(qr/\/before_edit:\ Expected\ object/) ],                      'and so does a value of the wrong type' );
    is( check_of( Fixture::checkout( '.perl-slop.json' => '{"before_edit":{"lib/":["x"]}}' ) ),       [ 'pass', 'valid' ],                                                          'a file that matches passes' );
};

subtest format => sub {
    is( check_of( Fixture::checkout( 'conf.yml' => "before_edit: {}\n" ), file => 'conf.yml' ),                [ 'pass', 'valid' ],                                                                                                             'a .yml file is read as YAML' );
    is( check_of( Fixture::checkout( 'conf.YAML' => "before_edit: []\n" ), file => 'conf.YAML' ),              [ 'fail', match(qr/\/before_edit:\ Expected\ object/) ],                                                                         'and so is a .yaml file, whatever its case' );
    is( check_of( Fixture::checkout( 'conf.yml' => "- a\n" ), file => 'conf.yml' ),                            [ 'fail', 'conf.yml does not hold a mapping at its top level' ],                                                                 'YAML that is not a mapping fails' );
    is( check_of( Fixture::checkout( '.perl-slop.json' => "before_edit: {}\n" ) ),                             [ 'fail', match(qr/does\ not\ parse\ as\ JSON/) ],                                                                               'a .json file is read as JSON, even when it holds YAML' );
    is( check_of( Fixture::checkout( '.perl-slop.json' => "before_edit: {}\n" ), format => 'yaml' ),           [ 'pass', 'valid' ],                                                                                                             'unless format says otherwise' );
    is( check_of( Fixture::checkout( 'config' => '{"before_edit":{}}' ), file => 'config', format => 'json' ), [ 'pass', 'valid' ],                                                                                                             'a file with no extension takes a format' );
    is( dies { config_check( file => 'config' ) },                                                             "the check DataSchema is not valid:\n  /format: config does not end in .json, .yml, .yaml or .ini, so give json, yaml or ini\n", 'and cannot be read without one' );
    like( dies { config_check( file   => 'conf.toml' ) }, qr/\/format:\ conf[.]toml\ /, 'nor can one with an extension that names no format' );
    like( dies { config_check( format => 'toml' ) },      qr/\/format:\ Not\ in\ enum/, 'a format that the check does not parse is refused' );
};

subtest ini => sub {
    my %dist_ini = (
        file   => 'dist.ini',
        schema => {
            type              => 'object',
            properties        => { 'Run::Test'                 => { type => 'object', properties => { run  => { type => 'array' } } } },
            patternProperties => { '\AGithubMeta(?:\s*/.*)?\z' => { type => 'object', properties => { user => { not  => {} } } } },
        },
    );
    my $ini = "name = Foo\n[Run::Test]\nrun = a\nrun = b\n[GithubMeta]\nissues = 1\n";
    is( check_of( Fixture::checkout( 'dist.ini' => $ini ),                              %dist_ini ), [ 'pass', 'valid' ],                                            'a .ini file is read as INI, with a repeated key as a list' );
    is( check_of( Fixture::checkout( 'dist.ini' => "${ini}user = someone\n" ),          %dist_ini ), [ 'fail', match(qr{\ /GithubMeta/user:\ }) ],                   'and a key that the schema refuses is named, with its section' );
    is( check_of( Fixture::checkout( 'dist.ini' => "[GithubMeta / Meta]\nuser = x\n" ), %dist_ini ), [ 'fail', match(qr{\ /GithubMeta\ ~1\ Meta/user:\ }) ],         'a section of a plugin with a name of its own is a key of its own' );
    is( check_of( Fixture::checkout( 'dist.ini' => "[GithubMeta\n" ),                   %dist_ini ), [ 'fail', match(qr/\Adist[.]ini\ does\ not\ parse\ as\ INI/) ], 'and one that does not parse fails' );
};

subtest update => sub {
    my $root   = Fixture::checkout( '.perl-slop.json' => '{"typo":1}' );
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( config_check(), $root );
    is( $update->changes,                                                   [],                                                          'nothing is written' );
    is( Fixture::tree_of($root),                                            $before,                                                     'at all' );
    is( $update->manual,                                                    [ match(qr/typo.*:\ DataSchema\ has\ no\ automatic\ fix/) ], 'and a person is told what is wrong' );
    is( Fixture::run_update( config_check(), Fixture::checkout() )->manual, [],                                                          'an absent optional file needs nothing' );
};

done_testing;
