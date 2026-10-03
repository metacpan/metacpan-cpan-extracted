# Test the max_size method of Deflate::Faster.

use warnings;
use strict;
use Test::More;
use Deflate::Faster;

my $plain = join '', map { chr (65 + $_ % 26) } 0 .. 99_999;
my $zipped = gzip ($plain);
my $df = Deflate::Faster->new ();

is ($df->unzip ($zipped), $plain, "no limit by default");
$df->max_size (length ($plain));
is ($df->unzip ($zipped), $plain, "output of exactly max_size");

$df->max_size (length ($plain) - 1);
ok (! eval { $df->unzip ($zipped); 1 }, "output longer than max_size");
like ($@, qr/max_size/, "got correct error message");

$df->max_size (100);
ok (! eval { $df->unzip ($zipped); 1 }, "max_size shorter than one pass");

is ($df->unzip (gzip ('ok')), 'ok', "object works after the error");
$df->max_size ();
is ($df->unzip ($zipped), $plain, "max_size () removes the limit");
is (gunzip ($zipped), $plain, "gunzip is not limited");

done_testing ();
