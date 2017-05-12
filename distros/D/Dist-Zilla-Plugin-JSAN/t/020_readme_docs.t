use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Path::Class;

use Test::DZil;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/Readme' },
    );

    $tzil->build;
    
    my $build_dir = dir($tzil->tempdir, 'build');
    
    ok(-e $build_dir->file(qw(doc mmd Sample Dist.mmd)), 'Docs for Sample.Dist module were created');
    ok(-e $build_dir->file(qw(doc mmd Sample Dist1.mmd)), 'Docs for Sample.Dist1 module were created');
    
    ok(-e $build_dir->file(qw(README.md)), 'README.md was created');
    
    ok(-e $build_dir->file(qw(.. source README.md)), 'README.md was created in the distro root as well');
    
    my $dist_doc_content                = $build_dir->file(qw(doc mmd Sample Dist.mmd))->slurp;
    my $dist1_doc_content               = $build_dir->file(qw(doc mmd Sample Dist1.mmd))->slurp;
    
    ok($dist_doc_content =~ /====/s && $dist_doc_content =~ /Sample\.Dist/s, 'Docs for `Dist` are correct');
    ok($dist1_doc_content =~ /====/s && $dist1_doc_content =~ /Sample\.Dist1/s, 'Docs for `Dist1` are correct');
}

done_testing;
