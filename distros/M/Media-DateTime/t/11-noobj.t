use strict;
use warnings;

use Test::More;
use Media::DateTime;
use DateTime;
use File::Which;

use DateTime::TimeZone;
eval { my $tz = DateTime::TimeZone->new( name => 'local' ); };
plan( skip_all => 'Local timezone is not configured, see DateTime::TimeZone' )
  if $@ =~ /determine local time/;
plan( skip_all => 'Need the touch command to run these tests' )
  unless which 'touch';
plan tests => 5;

my $s = 't/ex/src';

system("touch -m -t 200602071323.18 $s/textfile.txt");
system("touch -m -t 200602071323.18 $s/empty.jpg");
system("touch -m -t 200602071323.18 $s/exif-corrupt.jpg");
system("touch -m -t 200602071323.18 $s/no-exif.jpg");
system("touch -m -t 200602071323.18 $s/zero-in-exif.jpg");

# Should work
is(
    Media::DateTime->datetime("$s/normal.jpg"),
    date( 2005, 7, 29, 15, 00, 42 ),
    'date from normal jpg'
);
is(
    Media::DateTime->datetime("$s/textfile.txt"),
    date( 2006, 2, 7, 13, 23, 18 ),
    'date from timestamp'
);

# cygwin - gets it out of the exif
# linux - falls back to file timestamp
# is( Media::DateTime->datetime( "$s/exif-corrupt.jpg" ), date(2005,5,7,8,27,40), 'date from exif even though corrupt');

# Should fall back
is(
    Media::DateTime->datetime("$s/empty.jpg"),
    date( 2006, 2, 7, 13, 23, 18 ),
    'corrects for empty .jpg'
);
is(
    Media::DateTime->datetime("$s/no-exif.jpg"),
    date( 2006, 2, 7, 13, 23, 18 ),
    'corrects for no exif'
);
is(
    Media::DateTime->datetime("$s/zero-in-exif.jpg"),
    date( 2006, 2, 7, 13, 23, 18 ),
    'corrects for 00:00:00 in exif'
);

sub date {
    return DateTime->new(
        year   => $_[0],
        month  => $_[1],
        day    => $_[2],
        hour   => $_[3],
        minute => $_[4],
        second => $_[5],
    );
}
