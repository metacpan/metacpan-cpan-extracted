#!perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::DistIni();
use Dist::Conformance::Snapshot::Directory();

# t/data/standards/templates/dist.ini, with DIST filled in.
my $TEMPLATE = <<'END';
name = Foo-Bar

[@Basic]

; Pod::Weaver loads these, so dzil authordeps cannot see them.
; authordep Pod::Weaver::Section::Blurbs = 0.004
; authordep Pod::Elemental::Transformer::List = 0
; authordep Perl::Tests::Covering = 0.002
END

my %CONFIG = ( file => 'dist.ini', template => 'templates/dist.ini' );
my $PASS   = [ 'pass', 'is templates/dist.ini with the overrides' ];

sub dist_ini (%config)          { return Fixture::make_check( Dist::Conformance::Check::DistIni::, { %CONFIG, %config }, DIST => 'Foo-Bar' ) }
sub snapshot ($root)            { return Dist::Conformance::Snapshot::Directory->new( root => $root ) }
sub check_of ( $root, %config ) { return [ dist_ini(%config)->check( snapshot($root) ) ] }

subtest config => sub {
    ok( lives { dist_ini( authordeps => { 'Foo::Bar' => 'off', 'Baz' => '1.2' } ) }, 'authordeps is off or a version, by module' );
    like( dies { dist_ini( authordeps => { 'not a module' => 1 } ) }, qr{/authordeps}, 'named by a module' );
    ok( lives { dist_ini( overrides => { '@Basic' => 'off' }, positions => {}, settings => {} ) }, 'and the keys of IniTemplate' );
};

subtest expected => sub {
    is( dist_ini()->expected( snapshot( Fixture::checkout() ) ), $TEMPLATE, 'with no overrides, the template' );
    is(
        dist_ini( authordeps => { 'Pod::Weaver::Section::Blurbs' => '0.003', 'Perl::Tests::Covering' => 'off', 'Local::Plugin' => '1' } )->expected( snapshot( Fixture::checkout() ) ),
        $TEMPLATE =~ s/Blurbs\ =\ 0[.]004/Blurbs = 0.003/r =~ s/^;\ authordep\ Perl::Tests::Covering[^\n]*\n//mr . "; authordep Local::Plugin = 1\n",
        'authordeps sets a version, leaves one out, and adds one after the last authordep line'
    );
    is(
        dist_ini( authordeps => { 'Own::Thing' => '1' } )->expected( snapshot( Fixture::checkout( 'lib/Perl/Tests/Covering.pm' => "1;\n", 'lib/Own/Thing.pm' => "1;\n" ) ) ),
        $TEMPLATE =~ s/^;\ authordep\ Perl::Tests::Covering[^\n]*\n//mr,
        'and never asks for a module that the repository has under lib/'
    );
    is(
        dist_ini( overrides => { '@Basic' => 'off', GatherDir => {} }, authordeps => { 'Local::Plugin' => '1' } )->expected( snapshot( Fixture::checkout() ) ),
        "name = Foo-Bar\n\n\n; Pod::Weaver loads these, so dzil authordeps cannot see them.\n; authordep Pod::Weaver::Section::Blurbs = 0.004\n; authordep Pod::Elemental::Transformer::List = 0\n; authordep Perl::Tests::Covering = 0.002\n; authordep Local::Plugin = 1\n\n; The overrides of .conformance.yml\n[GatherDir]\n",
        'with the overrides of the sections too'
    );
};

subtest check => sub {
    is( check_of( Fixture::checkout( 'dist.ini' => $TEMPLATE ) ), $PASS, 'the template passes' );
    is(
        check_of( Fixture::checkout( 'dist.ini' => $TEMPLATE =~ s/Blurbs\ =\ 0[.]004/Blurbs = 0.002/r . "; authordep Local::Plugin = 1\n" ) ),
        [ 'fail', 'asks for Pod::Weaver::Section::Blurbs 0.002, not 0.004; has the authordep Local::Plugin, which neither the template nor the overrides name, which conformance update corrects' ],
        'an authordep that differs fails, although it is a comment'
    );
    is(
        check_of( Fixture::checkout( 'dist.ini' => $TEMPLATE =~ s/^;\ authordep\ Perl::Tests::Covering[^\n]*\n//mr ) ),
        [ 'fail', 'lacks the authordep Perl::Tests::Covering 0.002, which conformance update corrects' ],
        'and so does a missing one'
    );
    is( check_of( Fixture::checkout( 'dist.ini' => $TEMPLATE =~ s/^;\ Pod::Weaver[^\n]*\n//mr ) ), [ 'info', match(qr/only\ in\ comments\ and\ layout/) ], 'another comment is only info' );
    is(
        check_of( Fixture::checkout( 'dist.ini' => "name = Foo-Bar\nversion = 1\n" ) ), [ 'fail', 'lacks the section [@Basic]; sets other keys before the first section; lacks the authordep Perl::Tests::Covering 0.002; lacks the authordep Pod::Elemental::Transformer::List 0; lacks the authordep Pod::Weaver::Section::Blurbs 0.004, which conformance update corrects' ],
        'sections and authordeps are both named'
    );
};

subtest update => sub {
    my $root = Fixture::checkout( 'dist.ini' => "name = Foo-Bar\nversion = 1\n; authordep Local::Plugin = 1\n" );
    Fixture::run_update( dist_ini( authordeps => { 'Local::Plugin' => '1' } ), $root );
    is( $root->child('dist.ini')->slurp,                             "$TEMPLATE; authordep Local::Plugin = 1\n", 'the update writes the template, with the authordeps of the overrides' );
    is( check_of( $root, authordeps => { 'Local::Plugin' => '1' } ), $PASS,                                      'so it then passes' );
};

subtest adopt => sub {
    is( dist_ini()->adopt( snapshot( Fixture::checkout( 'dist.ini' => $TEMPLATE ) ) ), undef, 'nothing for the template' );
    my $root    = Fixture::checkout( 'dist.ini' => "name = Foo-Bar\n[\@Basic]\n; authordep Pod::Weaver::Section::Blurbs = 0.002\n; authordep Local::Plugin = 1\n; authordep Own::Thing = 1\n", 'lib/Own/Thing.pm' => "1;\n" );
    my $adopted = dist_ini()->adopt( snapshot($root) );
    is( $adopted, { authordeps => { 'Pod::Weaver::Section::Blurbs' => '0.002', 'Local::Plugin' => '1' } }, 'the authordeps that differ from the template; none that the file lacks, and none of a module of its own' );
    is(
        check_of( $root, %$adopted ),
        [ 'fail', 'lacks the authordep Perl::Tests::Covering 0.002; lacks the authordep Pod::Elemental::Transformer::List 0; has the authordep Own::Thing, which neither the template nor the overrides name, which conformance update corrects' ],
        'with them, what the template gained later is left, and a module of its own is never asked for'
    );
};

done_testing;
