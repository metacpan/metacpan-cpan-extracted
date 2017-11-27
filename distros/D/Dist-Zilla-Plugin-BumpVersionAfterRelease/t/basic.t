use strict;
use warnings;
use Test::More 0.96;
use utf8;

use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Version::Next qw/next_version/;

sub _new_tzil {
    my $c       = shift;
    my @plugins = (
        [ GatherDir => { exclude_filename => ['Makefile.PL'] } ],
        'FakeRelease',
        'MakeMaker',
        'MetaConfig',
        [
            RewriteVersion => {
                $c->{global}           ? ( global           => 1 ) : (),
                $c->{add_tarball_name} ? ( add_tarball_name => 1 ) : (),
            }
        ],
        [
            BumpVersionAfterRelease => {
                $c->{global}           ? ( global           => 1 ) : (),
                $c->{all_matching}     ? ( all_matching     => 1 ) : (),
                $c->{add_tarball_name} ? ( add_tarball_name => 1 ) : (),
            }
        ],
    );

    return Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {
            add_files => { 'source/dist.ini' => simple_ini( { version => undef }, @plugins ), },
        },
    );
}

my @cases = (
    {
        label   => "identity rewrite",
        version => "0.001",
    },
    {
        label    => "simple rewrite",
        version  => "0.005",
        override => 1,
    },
    {
        label   => "identity trial version",
        version => "0.001",
        trial   => 1,
    },
    {
        label    => "rewrite trial version",
        version  => "0.005",
        override => 1,
        trial    => 1,
    },
    {
        label    => "global replacement",
        version  => "0.005",
        override => 1,
        trial    => 1,
        global   => 1,
    },
    {
        label            => "simple rewrite, add_tarball_name",
        version          => "0.005",
        override         => 1,
        add_tarball_name => 1,
    },

    {
        label    => "all matching replacement, identity",
        version  => "0.001",
        override => 1,
        all_matching => 1,
    },

    {
        label    => "all matching replacement, final file matches once",
        version  => "0.003",
        override => 1,
        all_matching => 1,
    },

);

sub _regex_for_version {
    my ( $q, $version, $trailing ) = @_;
    my $exp = $trailing
      ? qr{^our \$VERSION = $q\Q$version\E$q; \Q$trailing\E}m
      : qr{^our \$VERSION = $q\Q$version\E$q;}m;
    return $exp;
}

sub _regex_for_makefilePL {
    my ($version) = @_;
    return qr{"VERSION" => "\Q$version\E"}m;
}

for my $c (@cases) {
    my ( $label, $version ) = @{$c}{qw/label version/};
    subtest $label => sub {
        local $ENV{TRIAL} = $c->{trial};
        local $ENV{V} = $version if $c->{override};
        my $tzil = _new_tzil($c);
        $tzil->chrome->logger->set_debug(1);

        $tzil->build;

        pass("dzil build");

        my $sample_src = $tzil->slurp_file('source/lib/DZT/Sample.pm');
        like(
            $sample_src,
            _regex_for_version( q['], '0.001', "# comment" ),
            "single-quoted version line correct in source file",
        );

        my $sample_bld = $tzil->slurp_file('build/lib/DZT/Sample.pm');
        my $sample_re = _regex_for_version( q['], $version,
            $c->{trial} || $c->{add_tarball_name}
            ? '# '
              . ( $c->{trial} ? "TRIAL" : '' )
              . ( $c->{add_tarball_name} ? "from DZT-Sample-$version.tar.gz" : '' )
            : '' );

        like( $sample_bld, $sample_re, "single-quoted version line correct in built file" );

        my $count =()= $sample_bld =~ /$sample_re/mg;
        my $exp   = !$c->{add_tarball_name}
          && ( $c->{global} || ( !$c->{trial} && $label =~ /identity/ ) ) ? 2 : 1;
        is( $count, $exp, "right number of replacements" )
          or diag $sample_bld;

        like(
            $tzil->slurp_file('source/lib/DZT/DQuote.pm'),
            _regex_for_version( q["], '0.001', "# comment" ),
            "double-quoted version line correct in source file",
        );

        my $dquote_bld = $tzil->slurp_file('build/lib/DZT/DQuote.pm');
        like(
            $dquote_bld,
            _regex_for_version( q['], $version, $c->{trial} ? "# TRIAL" : "" ),
            "double-quoted version line changed to single in build file"
        );

        like( $dquote_bld, qr/1;\s+# last line/, "last line correct in double-quoted file" );

        ok(
            grep( { /updating \$VERSION assignment/ } @{ $tzil->log_messages } ),
            "we log updating a version",
        ) or diag join( "\n", @{ $tzil->log_messages } );

        my $makefilePL = $tzil->slurp_file('build/Makefile.PL');

        like( $makefilePL, _regex_for_makefilePL($version), "Makefile.PL version bumped" );

        # after release

        $tzil->release;

        pass("dzil release");

        ok(
            grep( { /fake release happen/i } @{ $tzil->log_messages } ),
            "we log a fake release when we fake release",
        );

        my $orig = $tzil->slurp_file('source/lib/DZT/Sample.pm');
        my $next_re = _regex_for_version( q['], next_version($version) );
        $next_re = qr/$next_re$/m;

        local $TODO = 'qr/...$/m is broken before 5.10' if $] lt '5.010000';
        if (!$c->{all_matching} || $version eq '0.001') {
            like( $orig, $next_re, "version line updated in single-quoted source file" );
        }
        else {
            unlike( $orig, $next_re, "version line not updated in source file - did not match release version");
        }
        local $TODO;

        $count =()= $orig =~ /$next_re/mg;
        $exp = $c->{global} || ($c->{all_matching} && $version eq '0.001') ? 2 : 1;
        $exp =
            $c->{global} ? 2
          : $c->{all_matching} ? ($version eq '0.001' ? 2 : 0)
          : 1;
        is( $count, $exp, "right number of replacements" )
          or diag $orig;

        like( $orig, qr/1;\s+# last line/,
            "last line correct in single-quoted source file" );

        $orig = $tzil->slurp_file('source/lib/DZT/DQuote.pm');

        local $TODO = 'qr/...$/m is broken before 5.10' if $] lt '5.010000';
        if (!$c->{all_matching} || $version eq '0.001') {
            like( $orig, $next_re, "version line updated from double-quotes to single-quotes in source file");
        }
        else {
            unlike( $orig, $next_re, "version line not updated in source file - did not match release version");
        }
        local $TODO;

        like( $orig, qr/1;\s+# last line/, "last line correct in revised source file" );

        $orig = $tzil->slurp_file('source/lib/DZT/Mismatched.pm');

        local $TODO = 'qr/...$/m is broken before 5.10' if $] lt '5.010000';

        if ($c->{all_matching} && $version ne '0.003' && $version ne '0.004') {
            unlike( $orig, $next_re, "version line not updated in source file - did not match release version");
        }
        else {
            like( $orig, $next_re, "version line updated unconditionally in source file");
        }
        local $TODO;

        $count =()= $orig =~ /$next_re/mg;
        $exp =
            $c->{global} ? 2
          : $c->{all_matching} ? ($version eq '0.003' || $version eq '0.004' ? 1 : 0)
          : 1;

        is( $count, $exp, "right number of replacements" )
          or diag $orig;

        $makefilePL = $tzil->slurp_file('source/Makefile.PL');

        like(
            $makefilePL,
            _regex_for_makefilePL( next_version($version) ),
            "Makefile.PL version bumped"
        );

        cmp_deeply(
            $tzil->distmeta,
            superhashof(
                {
                    x_Dist_Zilla => superhashof(
                        {
                            plugins => supersetof(
                                {
                                    class  => 'Dist::Zilla::Plugin::RewriteVersion',
                                    config => {
                                        'Dist::Zilla::Plugin::RewriteVersion' => {
    global                => bool( $c->{global} ),
    skip_version_provider => bool( $c->{skip_version_provider} ),
    add_tarball_name      => bool( $c->{add_tarball_name} ),
    finders               => [ ':ExecFiles', ':InstallModules' ],
                                        },
                                    },
                                    name    => 'RewriteVersion',
                                    version => Dist::Zilla::Plugin::RewriteVersion->VERSION,
                                },
                                {
                                    class  => 'Dist::Zilla::Plugin::BumpVersionAfterRelease',
                                    config => {
                                        'Dist::Zilla::Plugin::BumpVersionAfterRelease' => {
    global            => bool( $c->{global} ),
    munge_makefile_pl => bool(1),
    finders           => [ ':ExecFiles', ':InstallModules' ],
                                        },
                                    },
                                    name    => 'BumpVersionAfterRelease',
                                    version => Dist::Zilla::Plugin::BumpVersionAfterRelease->VERSION,
                                },
                            ),
                        }
                    ),
                }
            ),
            'plugin metadata, including dumped configs',
        ) or diag 'got distmeta: ', explain $tzil->distmeta;

        cmp_deeply(
            [
                map {
                    my $txt = $_;
                    $txt =~ s/\\/\//g if $txt =~ /^\[BumpVersionAfterRelease\]/;
                    $txt
                } @{ $tzil->log_messages }
            ],
            superbagof(
                '[RewriteVersion] updating $VERSION assignment in lib/DZT/Sample.pm',
                $c->{all_matching} && $version ne '0.001' ? () :
                '[BumpVersionAfterRelease] bumped $VERSION in '
                  . path( $tzil->tempdir, qw(source lib DZT Sample.pm) ),
            ),
            'got appropriate log messages about updating both $VERSION statements, in both locations',
        );
    };
}

done_testing;
