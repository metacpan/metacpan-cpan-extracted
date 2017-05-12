# -*- perl -*-

use Test::More tests => 6;

use FindBin;
use lib $FindBin::Bin. '/../lib/';
use Format::LongNumber;

my $seconds = 3600*24*3 + 3600*3 + 60*5 + 11;
is short_time($seconds), '3.13d', 'short_time()';
is full_time($seconds), '3d 3h 5m 11s', 'full_time()';

is full_time(-1), '0s', 'full_time(0)';
is short_time(-1), '0s', 'short_time(0)';


my $bytes = 123456789;
is short_traffic($bytes), '117.74Mb', 'short_traffic()';
is full_traffic($bytes), '117Mb 755Kb 277b', 'full_traffic()';


#my $number = 123456789;
#is short_number($number), '123.46', 'short_number()';
#is full_number($number), '123.456.789', 'full_number()';
