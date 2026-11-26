#!perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::IniTemplate();
use Dist::Conformance::Snapshot::Directory();

# t/data/standards/templates/plugins.ini, with DIST filled in.
my $TEMPLATE = <<'END';
; The build.
name = Foo-Bar
license = MIT

[GatherDir]
exclude_filename = LICENSE
exclude_filename = README.md

; Commits the release.
[Git::Commit / Release_Commit]
allow_dirty = Changes

[MetaJSON]
END

my %CONFIG = ( file => 'dist.ini', template => 'templates/plugins.ini' );
my $PASS   = [ 'pass', 'is templates/plugins.ini with the overrides' ];

sub ini      (%config)          { return Fixture::make_check( Dist::Conformance::Check::IniTemplate::, { %CONFIG, %config }, DIST => 'Foo-Bar' ) }
sub snapshot ($root)            { return Dist::Conformance::Snapshot::Directory->new( root => $root ) }
sub check_of ( $root, %config ) { return [ ini(%config)->check( snapshot($root) ) ] }
sub ini_of   ($root)            { return $root->child('dist.ini')->slurp }

subtest config => sub {
    ok( lives { ini( overrides => { A => 'off', B => { k => 'v', l => [ 1, 'x' ], m => undef } }, positions => { B => 'A' }, settings => { s => [ 'a', 'b' ] } ) }, 'off, a mapping of values, lists and ~, positions and settings' );
    like( dies { ini( overrides => { A => 'on' } ) },        qr{/overrides/A},   'an override is off or a mapping' );
    like( dies { ini( overrides => { A => { k => [] } } ) }, qr{/overrides/A/k}, 'a list has an item' );
    like( dies { ini( positions => { A => q{} } ) },         qr{/positions/A},   'a position names a section' );
    ok( lives { ini( positions => { A => undef } ) }, 'or is ~' );
    like( dies { ini( overrides => { A => { k => { x => 1 } } } ) }, qr{/overrides/A/k}, 'a value is not a mapping' );
};

subtest parse => sub {
    my $ini = ini()->parse( $TEMPLATE, 'dist.ini' );
    is( $ini->{settings},                        { name => 'Foo-Bar', license => 'MIT' },                     'the keys before the first section' );
    is( $ini->{order},                           [ 'GatherDir', 'Git::Commit / Release_Commit', 'MetaJSON' ], 'the sections in their order, by their headers' );
    is( $ini->{sections}{GatherDir}{parameters}, { exclude_filename => [ 'LICENSE', 'README.md' ] },          'a key that a section gives twice has its list of values' );
    is( $ini->{sections}{MetaJSON}{parameters},  {},                                                          'and a section without keys has none' );
    like( dies { ini()->parse( "[A\n", 'dist.ini' ) }, qr/\Adist[.]ini\ does\ not\ parse\ as\ INI/, 'text that does not parse dies' );
};

subtest rewrite_lines => sub {
    my @lines = ( "; why\n", "a = 1\n", "b = 1\n", "b = 2\n", "c = 1\n" );
    is( [ ini()->rewrite_lines( \@lines, { a => 2 } ) ],                                  [ "; why\n", "a = 2\n", "b = 1\n", "b = 2\n", "c = 1\n" ],            'a value replaces the line of its key' );
    is( [ ini()->rewrite_lines( \@lines, { b => [ 3, 4, 5 ] } ) ],                        [ "; why\n", "a = 1\n", "b = 3\n", "b = 4\n", "b = 5\n", "c = 1\n" ], 'a list replaces every line of its key, where the first one was' );
    is( [ ini()->rewrite_lines( \@lines, { b => 3 } ) ],                                  [ "; why\n", "a = 1\n", "b = 3\n", "c = 1\n" ],                       'and so does a value' );
    is( [ ini()->rewrite_lines( \@lines, { b => undef, c => undef } ) ],                  [ "; why\n", "a = 1\n" ],                                             'undef removes the lines of its key' );
    is( [ ini()->rewrite_lines( \@lines, { e => 1, d => [ 1, 2 ] } ) ],                   [ @lines, "d = 1\n", "d = 2\n", "e = 1\n" ],                          'a new key goes after the last key, sorted' );
    is( [ ini()->rewrite_lines( ["; only\n"], { a => 1 } ) ],                             [ "a = 1\n", "; only\n" ],                                            'or first, in lines with no key' );
    is( [ ini()->rewrite_lines( [ "    a = 1\n", "    b = 1\n" ], { b => 2, c => 3 } ) ], [ "    a = 1\n", "    b = 2\n", "    c = 3\n" ],                      'with the indentation of the line it replaces, or of the last key' );
};

subtest expected => sub {
    is( ini()->expected, $TEMPLATE, 'with no overrides, the template with its variables filled in' );
    is(
        ini( overrides => { 'Git::Commit / Release_Commit' => { allow_dirty => [ 'Changes', 'README.md' ], add_files_in => q{/} }, MetaJSON => 'off', GatherDir => { exclude_filename => undef } }, settings => { license => undef, version => '1.0' } )->expected,
        <<'END', 'a list of values, a new key, a section turned off, a key removed, and the settings' );
; The build.
name = Foo-Bar
version = 1.0

[GatherDir]

; Commits the release.
[Git::Commit / Release_Commit]
allow_dirty = Changes
allow_dirty = README.md
add_files_in = /

END
    is( ini( overrides => { Own => { k => 'v' }, Later => {}, Last => {} }, positions => { Own => 'GatherDir', Later => 'Own' } )->expected, <<'END', 'a section of its own goes after the section that positions names, a template one or another of its own, or at the end' );
; The build.
name = Foo-Bar
license = MIT

[GatherDir]
exclude_filename = LICENSE
exclude_filename = README.md

[Own]
k = v

[Later]

; Commits the release.
[Git::Commit / Release_Commit]
allow_dirty = Changes

[MetaJSON]

; The overrides of .conformance.yml
[Last]
END
    is( ini( overrides => { First => { k => 'v' }, Second => {} }, positions => { First => undef, Second => 'First' } )->expected, <<'END', '~ puts a section before every section, after the keys before them' );
; The build.
name = Foo-Bar
license = MIT

[First]
k = v

[Second]

[GatherDir]
exclude_filename = LICENSE
exclude_filename = README.md

; Commits the release.
[Git::Commit / Release_Commit]
allow_dirty = Changes

[MetaJSON]
END
    like( dies { ini( positions => { GatherDir => 'MetaJSON' } )->expected },                            qr/places\ the\ section\ GatherDir,\ which\ the\ template\ has/, 'positions does not move a section of the template' );
    like( dies { ini( positions => { Own       => 'MetaJSON' } )->expected },                            qr/Own,\ which\ the\ overrides\ do\ not/,                        'nor places one that the overrides lack' );
    like( dies { ini( overrides => { Own       => {} }, positions => { Own => 'Nowhere' } )->expected }, qr/after\ Nowhere,\ which\ neither/,                             'nor after one that is nowhere' );
    like( dies { Fixture::make_check( Dist::Conformance::Check::IniTemplate::, \%CONFIG )->expected }, qr/needs\ the\ variables\ DIST/, 'a placeholder that nothing fills dies' );
};

subtest check => sub {
    is( check_of( Fixture::checkout() ), [ 'fail', 'dist.ini is missing' ], 'a missing file fails' );
    is( check_of( Fixture::checkout( 'dist.ini' => $TEMPLATE ) ),                             $PASS,                                                  'the text of the template and the overrides passes' );
    is( check_of( Fixture::checkout( 'dist.ini' => $TEMPLATE =~ s/^;\ The\ build[.]\n//r ) ), [ 'info', match(qr/only\ in\ comments\ and\ layout/) ], 'other comments are info' );
    my $drifted = "name = Foo-Bar\nversion = 1\nlicense = MIT\n[Git::Commit / Release_Commit]\nallow_dirty = Changes\nallow_dirty = dist.ini\n[GatherDir]\nexclude_filename = LICENSE\nexclude_filename = README.md\n[Own]\n";
    is(
        check_of( Fixture::checkout( 'dist.ini' => $drifted ) ),
        [ 'fail', 'lacks the section [MetaJSON]; has the section [Own], which neither the template nor the overrides name; sets other keys in the section [Git::Commit / Release_Commit]; puts the sections in another order; sets other keys before the first section, which conformance update corrects' ],
        'each difference in sections, keys, order and settings is named'
    );
    is( check_of( Fixture::checkout( 'dist.ini' => "[A\n" ) ), [ 'fail', match(qr/does\ not\ parse.*conformance\ update\ replaces\ it/) ], 'a file that does not parse fails' );
};

subtest update => sub {
    my $root   = Fixture::checkout( 'dist.ini' => "name = Old\n" );
    my $update = Fixture::run_update( ini(), $root );
    is( $update->changes,                                           [ { action => 'replace', path => 'dist.ini' } ], 'the file is replaced' );
    is( ini_of($root),                                              $TEMPLATE,                                       'with the text' );
    is( check_of($root),                                            $PASS,                                           'so it then passes' );
    is( Fixture::run_update( ini(), $root )->changes,               [],                                              'and a second update has nothing to do' );
    is( Fixture::run_update( ini(), Fixture::checkout() )->changes, [ { action => 'create', path => 'dist.ini' } ],  'a missing file is written' );
    my $left = Fixture::run_update( Fixture::make_check( Dist::Conformance::Check::IniTemplate::, \%CONFIG ), Fixture::checkout() );
    is( $left->manual, [ match(qr/needs\ the\ variables\ DIST.*cannot\ write\ dist[.]ini/) ], 'a placeholder that nothing fills is left for a person' );

    my $dry    = Fixture::checkout( 'dist.ini' => "name = Old\n" );
    my $before = Fixture::tree_of($dry);
    is( Fixture::run_update( ini(), $dry, 1 )->changes, [ { action => 'replace', path => 'dist.ini' } ], 'a dry run says what it would write' );
    is( Fixture::tree_of($dry),                         $before,                                         'and changes nothing on disk' );
};

subtest adopt => sub {
    is( ini()->adopt( snapshot( Fixture::checkout() ) ),                          undef, 'nothing for a missing file' );
    is( ini()->adopt( snapshot( Fixture::checkout( 'dist.ini' => $TEMPLATE ) ) ), undef, 'nor for the text of the template' );
    my $mine    = "name = Foo-Bar\nversion = 1\n[GatherDir]\nexclude_filename = LICENSE\n[Own]\nk = v\n[Git::Commit / Release_Commit]\nallow_dirty = Changes\nallow_dirty = dist.ini\n[Other]\n";
    my $root    = Fixture::checkout( 'dist.ini' => $mine );
    my $adopted = ini()->adopt( snapshot($root) );
    is(
        $adopted,
        {
            overrides => { GatherDir => { exclude_filename => 'LICENSE' }, Own => { k => 'v' }, 'Git::Commit / Release_Commit' => { allow_dirty => [ 'Changes', 'dist.ini' ] }, Other => {} },
            positions => { Own       => 'GatherDir', Other   => 'Git::Commit / Release_Commit' },
            settings  => { version   => '1',         license => undef },
        },
        'the keys that differ, the sections of its own and where they are, and the settings; not the section of the template that it lacks'
    );
    is( check_of( $root, %$adopted ), [ 'fail', 'lacks the section [MetaJSON], which conformance update corrects' ], 'with them, only what the template gained later is left' );

    my $first = Fixture::checkout( 'dist.ini' => $TEMPLATE =~ s/^(?=\[GatherDir\])/[Bootstrap]\n/mr );
    is( ini()->adopt( snapshot($first) ),                          { overrides => { Bootstrap => {} }, positions => { Bootstrap => undef } }, 'a section of its own before every section has the position ~' );
    is( check_of( $first, %{ ini()->adopt( snapshot($first) ) } ), [ 'info', match(qr/only\ in\ comments\ and\ layout/) ],                    'which keeps it first' );
};

done_testing;
