#! perl -T

use Test::More tests => 4;
use Test::Fatal;
use utf8;
use_ok( 'File::Text::CSV' );

-d "t" && chdir "t";

my $f;

is( exception { $f = File::Text::CSV->open("err01.csv") },
    undef, "open OK" );

my $row;

is( exception { $row = $f->read }, undef, "readN" );
ok( !defined($row), 'EOF' );
