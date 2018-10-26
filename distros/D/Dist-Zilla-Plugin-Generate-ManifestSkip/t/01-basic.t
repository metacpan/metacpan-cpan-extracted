#!perl

use Test::Most;
use Test::DZil;

use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                [ 'GatherDir' ],
                [ 'MetaConfig' ],
                [ 'Generate::ManifestSkip' => {
                    add => '\.tar\.gz$',
                    remove => [ '^MANIFEST\.bak$', '\.bak$' ],
                  }
                ],
                ),
            'source/MANIFEST.bak' => '',
            'source/random-stuff.tar.gz' => '',
            'source/lib/Module.pm' => <<'MODULE'
package Module;

1;
MODULE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/MANIFEST.SKIP');

ok $content, 'has content';

# note $content;

my $builddir = path($tzil->tempdir, 'build');
my @files = map { $_->relative($builddir)->stringify } $builddir->children();

is_filelist( \@files, [qw/ MANIFEST.bak dist.ini MANIFEST.SKIP lib /], 'expected files' );

done_testing;
