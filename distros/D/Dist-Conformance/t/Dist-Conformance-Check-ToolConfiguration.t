#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::ToolConfiguration();
use Dist::Conformance::Snapshot::Directory();

my %FILES = ( '.perltidyrc' => 'templates/perltidyrc', '.pod_stopwords' => 'templates/pod_stopwords', '.handmade' => undef );

sub tools ()         { return Fixture::make_check( Dist::Conformance::Check::ToolConfiguration::, { files => \%FILES } ) }
sub check_of ($root) { return [ tools()->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }

subtest check => sub {
    is( check_of( Fixture::checkout() ),                                           [ 'fail', 'missing: .handmade, .perltidyrc, .pod_stopwords' ], 'every missing file, sorted' );
    is( check_of( Fixture::checkout( '.perltidyrc' => q{}, '.handmade' => q{} ) ), [ 'fail', 'missing: .pod_stopwords' ],                         'only the missing ones' );
    is( check_of( Fixture::checkout( map { $_ => 'mine' } keys %FILES ) ),         [ 'pass', 'all present' ],                                     'all present passes, whatever they hold' );
    like( dies { Fixture::make_check( Dist::Conformance::Check::ToolConfiguration::, {} ) }, qr/\/files:\ Missing\ property/, 'files is required' );
};

subtest update => sub {
    my $root   = Fixture::checkout( '.pod_stopwords' => "mine\n" );
    my $update = Fixture::run_update( tools(), $root );
    is( $update->changes,                      [ { action => 'create', path => '.perltidyrc' } ],                'a missing file with a template is written' );
    is( $root->child('.perltidyrc')->slurp,    "-l=400\n-i=4\n",                                                 'from the template' );
    is( $root->child('.pod_stopwords')->slurp, "mine\n",                                                         'and a file that exists is left alone' );
    is( $update->manual,                       ['Write .handmade by hand: the flavor names no template for it'], 'a file without a template is left to a person' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout();
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( tools(), $root, 1 );
    is( [ map { $_->{path} } @{ $update->changes } ], [qw{.perltidyrc .pod_stopwords}], 'says what it would write' );
    is( Fixture::tree_of($root),                      $before,                          'and changes nothing on disk' );
};

done_testing;
