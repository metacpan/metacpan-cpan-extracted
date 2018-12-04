use strict;
use Test::More;
use Test::DZil;

my @plugins =
eval { require Dist::Zilla::Plugin::VersionFromModule } ? 'VersionFromModule' :
eval { require Dist::Zilla::Plugin::VersionFromMainModule } ? 'VersionFromMainModule' :
plan skip_all => 'requires VersionFromModule or VersionFromMainModule';
 
@plugins = ('GatherDir', @plugins, 'FakeRelease', 'ReversionAfterRelease');

my $tzil = Builder->from_config(
    { dist_root => 't/dist/0.10' },
    { add_files => {
            'source/dist.ini' => simple_ini({ version => undef }, @plugins),
        } },
);
$tzil->release;

like $tzil->slurp_file('build/lib/DZT/Sample.pm'), qr/\$VERSION = '0.10'/;
like $tzil->slurp_file('source/lib/DZT/Sample.pm'), qr/\$VERSION = '0.11'/;
is $tzil->version, '0.11';

done_testing;
