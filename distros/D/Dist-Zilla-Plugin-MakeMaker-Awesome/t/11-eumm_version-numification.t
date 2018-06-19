use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

subtest "eumm_version = $_" => sub {
    my $eumm_version = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                  'GatherDir',
                    [ 'MakeMaker::Awesome' => { eumm_version => $eumm_version } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $content = $tzil->slurp_file('build/Makefile.PL');

    like(
        $content,
        qr/^use ExtUtils::MakeMaker '$eumm_version';$/m,
        'EUMM version uses quotes to prevent losing information from numification',
    );

    (my $eumm_version_sanitized = $eumm_version) =~ s/_//g;

    $content =~ /(['"])CONFIGURE_REQUIRES\1\s+=>\s+\{/mg;
    my $start = pos($content);
    ok($content =~ /\},$/mg, 'found end of CONFIGURE_REQUIRES %WriteMakefileArgs section');
    my $end = pos($content);
    my $configure_requires_writemakefileargs = substr($content, $start, $end - $start - 2);

    my (undef, $eumm_writemakefileargs) =
        $configure_requires_writemakefileargs =~ /(['"])ExtUtils::MakeMaker\1\W+([\d._]+)/;
    is(
        $eumm_writemakefileargs,
        $eumm_version_sanitized,
        'ExtUtils::MakeMaker prereq in %WriteMakefileArgs CONFIGURE_REQUIRES is numerically equal to what was specified, with no underscore',
    );

    my $eumm_prereq = $tzil->distmeta->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'};
    is(
        $eumm_prereq,
        $eumm_version_sanitized,
        'ExtUtils::MakeMaker prereq in metadata is numerically equal to what was specified, with no underscore',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach ('7.00', '6.55_02');

done_testing;
