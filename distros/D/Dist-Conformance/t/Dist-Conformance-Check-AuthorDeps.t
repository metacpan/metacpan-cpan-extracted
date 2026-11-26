#!perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::AuthorDeps();
use Dist::Conformance::Snapshot::Directory();

# t/data/standards/templates/dist.ini asks for Blurbs 0.004, List 0 and Covering 0.002.
my %CONFIG = ( file => 'dist.ini', template => 'templates/dist.ini' );

my $OLD = <<'END';
name = Foo
[@Basic]
; Blurbs needs 0.002, which trusts =for Pod::Coverage.
;   authordep   Pod::Weaver::Section::Blurbs   =  0.002   ; the old reason
; authordep Pod::Elemental::Transformer::List
; authordep Perl::Tests::Covering = 0.003
; authordep Local::Plugin = 1
; not an authordep Foo = 1

[Prereqs]
Bar = 1
END

my $NEW = <<'END';
name = Foo
[@Basic]
; Blurbs needs 0.002, which trusts =for Pod::Coverage.
;   authordep   Pod::Weaver::Section::Blurbs   =  0.004   ; the old reason
; authordep Pod::Elemental::Transformer::List
; authordep Perl::Tests::Covering = 0.003
; authordep Local::Plugin = 1
; not an authordep Foo = 1

[Prereqs]
Bar = 1
END

my $PASS = [ 'pass', 'asks for each authordep of the template, at its version or later' ];

sub deps     (%config)          { return Fixture::make_check( Dist::Conformance::Check::AuthorDeps::, { %CONFIG, %config } ) }
sub snapshot ($root)            { return Dist::Conformance::Snapshot::Directory->new( root => $root ) }
sub check_of ( $root, %config ) { return [ deps(%config)->check( snapshot($root) ) ] }
sub ini_of   ($root)            { return $root->child('dist.ini')->slurp }

subtest config => sub {
    ok( lives { deps( overrides => { 'Foo::Bar' => 'off', 'Baz' => '1.2', 'Qux' => '>= 1, < 2' } ) }, 'an override is off, a version or a range' );
    like( dies { deps( overrides => { 'Foo::Bar'     => q{} } ) }, qr{/overrides/Foo::Bar:\ }, 'but not empty' );
    like( dies { deps( overrides => { 'not a module' => 1 } ) },   qr{/overrides},             'and is named by a module' );
    like( dies { Fixture::make_check( Dist::Conformance::Check::AuthorDeps::, { file => 'dist.ini' } ) }, qr{template}, 'the template is required' );
};

subtest authordeps_of => sub {
    is(
        [ map { [ @{$_}{qw{line module version}} ] } Dist::Conformance::Check::AuthorDeps::authordeps_of($OLD) ],
        [ [ 3, 'Pod::Weaver::Section::Blurbs', '0.002' ], [ 4, 'Pod::Elemental::Transformer::List', 0 ], [ 5, 'Perl::Tests::Covering', '0.003' ], [ 6, 'Local::Plugin', '1' ] ],
        'each authordep line, as dzil authordeps reads it: spaces anywhere, a comment after the version, no version as 0, and not another comment'
    );
    my ($blurbs) = Dist::Conformance::Check::AuthorDeps::authordeps_of($OLD);
    is( substr( ( split /^/, $OLD )[3], $blurbs->{from}, $blurbs->{to} - $blurbs->{from} ),                   '0.002',                                                                                 'with the offsets of the version in its line' );
    is( [ Dist::Conformance::Check::AuthorDeps::authordeps_of(";authordep Foo =1.2\n") ],                     [ { line => 0, module => 'Foo', version => '1.2', from => 16, to => 19, after => 14 } ], 'and with no space after the =' );
    is( [ map { $_->{module} } Dist::Conformance::Check::AuthorDeps::authordeps_of(";authordep Foo=1.2\n") ], ['Foo=1.2'],                                                                             'but none before it is part of the name, as dzil authordeps reads it' );
};

subtest wanted => sub {
    is( [ map { [ @{$_}{qw{module version}} ] } deps()->wanted( snapshot( Fixture::checkout() ) ) ], [ [ 'Pod::Weaver::Section::Blurbs', '0.004' ], [ 'Pod::Elemental::Transformer::List', 0 ], [ 'Perl::Tests::Covering', '0.002' ] ], 'the authordeps of the template, in its order' );
    is(
        [ map { [ @{$_}{qw{module version text}} ] } deps( overrides => { 'Pod::Weaver::Section::Blurbs' => 'off', 'Perl::Tests::Covering' => '0.001', 'Extra::Plugin' => '2' } )->wanted( snapshot( Fixture::checkout() ) ) ],
        [ [ 'Pod::Elemental::Transformer::List', 0, "; authordep Pod::Elemental::Transformer::List = 0\n" ], [ 'Perl::Tests::Covering', '0.001', "; authordep Perl::Tests::Covering = 0.001\n" ], [ 'Extra::Plugin', '2', "; authordep Extra::Plugin = 2\n" ] ],
        'with the overrides: off leaves one out, a version replaces the template one, and a module the template lacks is added'
    );
    is(
        [ map { $_->{module} } deps( overrides => { 'Own::Helper' => '1' } )->wanted( snapshot( Fixture::checkout( 'lib/Perl/Tests/Covering.pm' => "1;\n", 'lib/Own/Helper.pm' => "1;\n" ) ) ) ],
        [ 'Pod::Weaver::Section::Blurbs', 'Pod::Elemental::Transformer::List' ],
        'and not a module that the repository has under lib/, which it builds with, whether the template or an override names it'
    );
};

subtest check => sub {
    is( check_of( Fixture::checkout() ),                     [ 'info', 'there is no dist.ini' ],                                            'an absent file is info' );
    is( check_of( Fixture::checkout(), missing => 'fail' ),  [ 'fail', 'there is no dist.ini' ],                                            'or what the flavor says' );
    is( check_of( Fixture::checkout( 'dist.ini' => $NEW ) ), $PASS,                                                                         'every authordep at its version or later passes, and one of the repository its own is no failure' );
    is( check_of( Fixture::checkout( 'dist.ini' => $OLD ) ), [ 'fail', 'dist.ini asks for Pod::Weaver::Section::Blurbs 0.002, not 0.004' ], 'a lower version fails' );
    is(
        check_of( Fixture::checkout( 'dist.ini' => "name = Foo\n" ) ),
        [ 'fail', 'dist.ini lacks Pod::Weaver::Section::Blurbs 0.004; lacks Pod::Elemental::Transformer::List 0; lacks Perl::Tests::Covering 0.002' ],
        'and so does each missing authordep'
    );
    is( check_of( Fixture::checkout( 'dist.ini' => $OLD ), overrides => { 'Pod::Weaver::Section::Blurbs' => '0.002' } ), $PASS, 'an override can ask for a lower version' );
    is( check_of( Fixture::checkout( 'dist.ini' => $NEW ), overrides => { 'Perl::Tests::Covering' => '0.004' } ), [ 'fail', 'dist.ini asks for Perl::Tests::Covering 0.003, not 0.004' ], 'or for a higher one' );
    is( check_of( Fixture::checkout( 'dist.ini' => $NEW ), overrides => { 'Missing::Plugin'       => '1' } ),     [ 'fail', 'dist.ini lacks Missing::Plugin 1' ],                         'or for a module that the template lacks' );
    my $ranged = $NEW =~ s/Covering\ =\ 0[.]003/Covering = >= 0.002/r;
    is( check_of( Fixture::checkout( 'dist.ini' => $ranged ) ),                                [ 'fail', 'dist.ini asks for Perl::Tests::Covering >= 0.002, which cannot be compared with 0.002' ], 'a version that is not a plain version fails' );
    is( check_of( Fixture::checkout( 'dist.ini' => $NEW ), template => 'templates/nonesuch' ), [ 'fail', match(qr/nonesuch/) ],                                                                     'a template that the source lacks fails' );
};

subtest update => sub {
    my $root   = Fixture::checkout( 'dist.ini' => $OLD );
    my $update = Fixture::run_update( deps(), $root );
    is( $update->changes,                              [ { action => 'replace', path => 'dist.ini' } ], 'a file that asks for too little is rewritten' );
    is( ini_of($root),                                 $NEW,                                            'with the version raised, and every other character of every line as it was' );
    is( $update->manual,                               [],                                              'with nothing left for a person' );
    is( check_of($root),                               $PASS,                                           'so it then passes' );
    is( Fixture::run_update( deps(), $root )->changes, [],                                              'and a second update has nothing to do' );

    my $bare = Fixture::checkout( 'dist.ini' => "; authordep Pod::Weaver::Section::Blurbs ; why\n" );
    Fixture::run_update( deps( overrides => { 'Pod::Elemental::Transformer::List' => 'off', 'Perl::Tests::Covering' => 'off' } ), $bare );
    is( ini_of($bare), "; authordep Pod::Weaver::Section::Blurbs = 0.004 ; why\n", 'a line without a version gets one after the module, before its comment' );

    my $lacking = Fixture::checkout( 'dist.ini' => "name = Foo\n; authordep Perl::Tests::Covering = 0.002\n[Prereqs]\nBar = 1" );
    Fixture::run_update( deps(), $lacking );
    is(
        ini_of($lacking),
        "name = Foo\n; authordep Perl::Tests::Covering = 0.002\n; authordep Pod::Weaver::Section::Blurbs = 0.004\n; authordep Pod::Elemental::Transformer::List = 0\n[Prereqs]\nBar = 1",
        'a missing authordep is added after the last authordep line, as the template has it, in its order, and a last line without a newline stays so'
    );

    my $none = Fixture::checkout( 'dist.ini' => "name = Foo" );
    Fixture::run_update( deps( overrides => { 'Pod::Weaver::Section::Blurbs' => 'off', 'Perl::Tests::Covering' => 'off' } ), $none );
    is( ini_of($none), "name = Foo\n; authordep Pod::Elemental::Transformer::List = 0\n", 'in a file without one, at its end' );

    my $ranged = Fixture::checkout( 'dist.ini' => $NEW =~ s/Covering\ =\ 0[.]003/Covering = >= 0.002/r );
    my $left   = Fixture::run_update( deps(), $ranged );
    is( $left->changes, [],                                                                                                                           'a version that cannot be compared is not touched' );
    is( $left->manual,  ['In dist.ini, make the authordep of Perl::Tests::Covering ask for 0.002 or later: its version >= 0.002 cannot be compared'], 'and is left for a person' );

    is( Fixture::run_update( deps(), Fixture::checkout() )->changes, [], 'an absent file needs nothing' );
    my $broken = Fixture::run_update( deps( template => 'templates/nonesuch' ), Fixture::checkout( 'dist.ini' => $OLD ) );
    is( $broken->manual, [ match(qr/nonesuch.*:\ fix\ it\ by\ hand\z/) ], 'a template that the source lacks is left for a person' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout( 'dist.ini' => $OLD );
    my $before = Fixture::tree_of($root);
    is( Fixture::run_update( deps(), $root, 1 )->changes, [ { action => 'replace', path => 'dist.ini' } ], 'says what it would rewrite' );
    is( Fixture::tree_of($root),                          $before,                                         'and changes nothing on disk' );
};

subtest adopt => sub {
    is( deps()->adopt( snapshot( Fixture::checkout() ) ),                     undef, 'nothing for an absent file' );
    is( deps()->adopt( snapshot( Fixture::checkout( 'dist.ini' => $NEW ) ) ), undef, 'nor for one that passes' );
    my $root    = Fixture::checkout( 'dist.ini' => "; authordep Pod::Weaver::Section::Blurbs = 0.002\n; authordep Pod::Elemental::Transformer::List\n" );
    my $adopted = deps( overrides => { 'Pod::Elemental::Transformer::List' => '0', 'Absent::Plugin' => '1' } )->adopt( snapshot($root) );
    is(
        $adopted,
        { overrides => { 'Pod::Elemental::Transformer::List' => '0', 'Absent::Plugin' => 'off', 'Pod::Weaver::Section::Blurbs' => '0.002', 'Perl::Tests::Covering' => 'off' } },
        'the overrides that accept the file as it is: an override that the file meets stays, and one that it does not is replaced'
    );
    is( check_of( $root, %$adopted ), $PASS, 'and with them the check passes' );
};

done_testing;
