use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Fatal;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
            ) . <<'END_INI',

[MakeMaker::Awesome]
eumm_version = 6.01
WriteMakefile_arg = CCFLAGS => '-Wall'
header = my $string = 'oh hai';
delimiter = |
footer = |package MY;
footer = |use File::Spec;
footer = |sub postamble {
footer = |	my $self = shift;
footer = |	my ($s2p, $psed) = map { File::Spec->catfile('script', $_) } qw/s2p psed/;
footer = |	return $self->SUPER::postamble . <<"END";
footer = |$psed: $s2p
footer = |	\$(CP) $s2p $psed
footer = |END
footer = |}
END_INI
            path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/Makefile.PL');

cmp_ok(
    index($content, "my \$string = 'oh hai';\n\nmy \%WriteMakefileArgs"),
    '>=', 200,
    'header appears as normal, not munged',
);

like(
    $content,
    qr/^%WriteMakefileArgs = \(\n^    %WriteMakefileArgs,\n^    CCFLAGS => '-Wall',\n^\);\n/m,
    'additional WriteMakefile argument is set, unmunged',
);

cmp_ok(
    index($content,
<<'POSTAMBLE'
package MY;
use File::Spec;
sub postamble {
	my $self = shift;
	my ($s2p, $psed) = map { File::Spec->catfile('script', $_) } qw/s2p psed/;
	return $self->SUPER::postamble . <<"END";
$psed: $s2p
	\$(CP) $s2p $psed
POSTAMBLE
    ),
    '>=', 200,
    'MY::postamble appears right before the end of the file',
);

subtest 'run the generated Makefile.PL' => sub
{
    my $wd = pushd path($tzil->tempdir)->child('build');
    is(
        exception { $tzil->plugin_named('MakeMaker::Awesome')->build },
        undef,
        'Makefile.PL can be run successfully',
    );
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
