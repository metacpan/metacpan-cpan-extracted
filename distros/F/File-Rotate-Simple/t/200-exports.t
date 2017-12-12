use Test::Most;
use Path::Tiny 0.018;

use_ok('File::Rotate::Simple', 'rotate_files');

my $dir  = Path::Tiny->tempdir;
my $base = 'test.log';
my $file = path($dir, $base);

$file->touch;

ok $file->exists, "$file exists";

lives_ok {

    rotate_files(
        file => $file,
        );

} "rotate_files";

ok !$file->exists, "$file does not exist";

my $rotated = path( $file . '.1' );

ok $rotated->exists, "$rotated exists";

done_testing;
