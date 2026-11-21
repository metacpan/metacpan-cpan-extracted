#!/usr/bin/env perl
use 5.020;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) the T2 handle, which the policy does not see used
use Test2::Plugin::NoWarnings;
use Test::DZil       qw{Builder simple_ini};
use Test::MockModule ();
use File::Temp       ();
use FindBin::libs;
use Dist::Zilla::Plugin::Git::ChangelogFromTrailers ();

# A plugin object, with no git repository behind it.  Each test mocks the git
# calls that the sub under test makes.
sub plugin {
    my (%config) = @_;
    my $tzil = Builder->from_config(
        { dist_root => File::Temp->newdir()->dirname },
        {
            add_files => {
                'source/dist.ini' => simple_ini( 'GatherDir', [ 'Git::ChangelogFromTrailers' => \%config ] ),
                'source/Changes'  => "Revision history for DZT\n",
            },
        },
    );
    return $tzil->plugin_named('Git::ChangelogFromTrailers');
}

T2->subtest(
    last_release_tag => sub {
        my $p   = plugin();
        my $git = Test::MockModule->new( 'Git::Wrapper', no_auto => 1 );

        $git->define( tag => sub { () } );
        T2->is( scalar $p->last_release_tag, undef, 'a repository with no tags has no release tag' );

        $git->redefine( tag => sub { qw{1.009 1.010 v1.0.2 1.0-rc foo} } );
        T2->is( $p->last_release_tag, '1.010', 'the highest version wins, compared as versions' );

        $git->redefine( tag => sub { qw{v1.002 1.001} } );
        T2->is( $p->last_release_tag, 'v1.002', 'a leading v is allowed by default' );

        $git->redefine( tag => sub { qw{release-3 release-12 4.0} } );
        T2->is( plugin( version_regexp => '^release-(\d+)$' )->last_release_tag, 'release-12', 'version_regexp chooses the tags' );

        $git->redefine( tag => sub { qw{foo bar} } );
        T2->is( scalar $p->last_release_tag, undef, 'no tag that matches is no release tag' );
    }
);

T2->subtest(
    items => sub {
        my $p   = plugin( trailer => 'Changes-Entry' );
        my $git = Test::MockModule->new( 'Git::Wrapper', no_auto => 1 );
        Dist::Zilla::Plugin::Git::ChangelogFromTrailers->meta->make_mutable;
        my $sut = Test::MockModule->new( 'Dist::Zilla::Plugin::Git::ChangelogFromTrailers', no_auto => 1 );
        $git->define( rev_parse => sub { 'a' x 40 } );
        $sut->redefine( last_release_tag => sub { '1.000' } );

        my @args;
        $git->redefine(
            RUN => sub {
                ( undef, undef, @args ) = @_;
                return ( 'First', q{}, q{}, '  Second  ', 'Third', q{}, 'First' );
            }
        );
        T2->is( [ $p->items ],    [qw{First Second Third}],                         'each value is an item, trimmed, with no empty or repeated ones' );
        T2->is( $args[0]{format}, '%(trailers:key=Changes-Entry,valueonly,unfold)', 'it reads the trailer that the configuration names' );
        T2->ok( $args[0]{reverse}, 'oldest commit first' );
        T2->is( $args[1], '1.000..HEAD', 'with a tag, only the commits after it count' );

        $sut->redefine( last_release_tag => sub { return } );
        $p->items;
        T2->is( $args[1], 'HEAD', 'with no tag, every commit counts' );

        $git->redefine( rev_parse => sub { die "fatal: Needed a single revision\n" } );
        T2->is( [ $p->items ], [], 'a repository with no commits has no items' );
    }
);

T2->done_testing;
