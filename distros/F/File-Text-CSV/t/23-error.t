#! perl -T

use Test::More tests => 2;
use Test::Fatal;
use utf8;
use_ok( 'File::Text::CSV' );

-d "t" && chdir "t";

my $f;

like( exception { $f = File::Text::CSV->open("err01.csv", { header => 1 }) },
      qr/Incomplete or missing header line/, "open OK" );
