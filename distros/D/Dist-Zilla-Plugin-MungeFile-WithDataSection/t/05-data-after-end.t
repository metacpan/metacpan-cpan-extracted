use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'MungeFile::WithDataSection' => { finder => ':MainModule' } ],
            ),
            'source/lib/Module.pm' => <<'MODULE'
package Module;

my $string = {{
'"our list of items are: '
. join(', ', split(' ', $DATA))   # awk-style emulation
. "...\n" . 'And that\'s just great!\n"'
}};
1;
__END__
This is content that should not be in the DATA section.
__DATA__
dog
cat
pony
MODULE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/lib/Module.pm');

    if ($content =~ m/(?:\n__END__(\n.*)?)\n__DATA__\n/sp)
    {
        print "### matched end then data\n";
    }

is(
    $content,
    <<'NEW_MODULE',
package Module;

my $string = "our list of items are: ...
And that's just great!\n";
1;
__END__
This is content that should not be in the DATA section.
__DATA__
dog
cat
pony
NEW_MODULE
    '__DATA__ after __END__ is not seen',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::MungeFile::WithDataSection',
                    config => {
                        'Dist::Zilla::Plugin::MungeFile' => {
                            finder => [ ':MainModule' ],
                            files => [ ],
                            version => Dist::Zilla::Plugin::MungeFile->VERSION,
                        },
                    },
                    name => 'MungeFile::WithDataSection',
                    version => Dist::Zilla::Plugin::MungeFile::WithDataSection->VERSION,
                },
            ),
        }),
    }),
    'distmeta is correct',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
