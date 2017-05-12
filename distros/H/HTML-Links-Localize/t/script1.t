use strict;
use warnings;

use Test::More tests => 1;

use File::Path;
use File::Spec;

my $src_dir = File::Spec->catdir(File::Spec->curdir(), "t", "temp-dir-src");
my $dest_dir = File::Spec->catdir(File::Spec->curdir(), "t", "temp-dir-dest");
mkpath($src_dir, $dest_dir);

# TEST
ok (
    !system($^X, "html-to-hd", $src_dir, $dest_dir),
    "Can invoke html-to-hd",
);

rmtree($src_dir, $dest_dir);
