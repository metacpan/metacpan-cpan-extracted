# Test the max_size method of Gzip::Faster.

use warnings;
use strict;
use Test::More;
use Gzip::Faster;

# Long enough to take several passes of the uncompression loop.
my $plain = join '', map { chr (65 + $_ % 26) } 0 .. 99_999;
my $zipped = gzip ($plain);
my $gf = Gzip::Faster->new ();
is ($gf->unzip ($zipped), $plain, "no limit by default");
$gf->max_size (length ($plain));
is ($gf->unzip ($zipped), $plain, "output of exactly max_size");
$gf->max_size (length ($plain) - 1);
ok (! eval { $gf->unzip ($zipped); 1 }, "output longer than max_size");
like ($@, qr/max_size/, "got correct error message");
$gf->max_size (100);
ok (! eval { $gf->unzip ($zipped); 1 }, "max_size shorter than one pass");
is ($gf->unzip (gzip ('ok')), 'ok', "object works after the error");
$gf->max_size ();
is ($gf->unzip ($zipped), $plain, "max_size () removes the limit");
is (gunzip ($zipped), $plain, "gunzip is not limited");

done_testing ();
