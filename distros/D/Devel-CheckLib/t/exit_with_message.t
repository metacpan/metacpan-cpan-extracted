use strict;
# compatible use warnings
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

use Test::More;
use File::Temp;

my $fh = File::Temp->new();
print {$fh} << 'ENDPRINT';
use Devel::CheckLib;
check_lib_or_exit( qw/lib hlagh/ );
ENDPRINT
$fh->close;

my $err = `$^X $fh 2>&1`;

if($err =~ /Couldn't find your C compiler/) {
    plan skip_all => "Couldn't find your C compiler";
} else {
    plan tests => 1;
    like ($err, "/^Can't link\\/include C library 'hlagh'/ms",
        "missing hlagh detected non-fatally"
    );
}
