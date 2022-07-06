#! perl

use Test::More;

use Digest::BLAKE3;

my($hasher, $path, $out, $fh);

plan(tests => 3);

$hasher = Digest::BLAKE3::->new();

$path = __FILE__ . "in";

$out = "/qHpUPkDLiNqEVlpfmpTWI+7Pg1ArZgIlyq783KDbfM";

open($fh, "<", $path)
    or die "$path: open: $!\n";
binmode($fh);
is($hasher->addfile($fh)->b64digest(), $out,
   "addfile(globref)");
seek($fh,0,0);
is($hasher->addfile(*$fh)->b64digest(), $out,
   "addfile(globcopy)");
close($fh);

is($hasher->addfile($path)->b64digest(), $out,
   "addfile(path)");

