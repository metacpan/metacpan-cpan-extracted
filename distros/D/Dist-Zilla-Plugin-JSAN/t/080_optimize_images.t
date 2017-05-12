use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Path::Class;

use Test::DZil;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/ImageOptimizer' },
    );
    
    my $png_image_file  = file(qw(test_data ImageOptimizer static icons Captive.png));
    
    my $before_size     = $png_image_file->stat->size;
    
    ok($before_size, "Before size is non zero");



    $ENV{ DZIL_RELEASING } = 1;

    $tzil->build;
    
    my $optimized_file  = $tzil->tempdir->file(qw(build lib Digest MD5 static icons Captive.png));
    
    my $after_size      = $optimized_file->stat->size;
    
    ok($after_size, "After size is non zero");
    
    
    ok($after_size < $before_size, 'Image has been optimized');
}

done_testing;
