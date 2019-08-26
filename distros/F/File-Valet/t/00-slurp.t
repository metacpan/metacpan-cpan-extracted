#!/bin/env perl

use strict;
use warnings;
use Test::Most;
use Errno;

use lib "./lib";
use File::Valet;

my $filename = 'xxx';
my $content  = "yyy\nzzz";
my $fh;

# tests for rd_f:
is rd_f(),               undef,                 'rd_f handles undef filename';
is $File::Valet::OK,    'ERROR',                'rd_f sets ok on undef filename';
is $File::Valet::ERROR, 'no filename supplied', 'rd_f sets error on undef filename';
is $File::Valet::ERRNO, -1,                     'rd_f sets errno on undef filename';

is rd_f(''),             undef,                 'rd_f handles empty filename';
is $File::Valet::OK,    'ERROR',                'rd_f sets ok on empty filename';
is $File::Valet::ERROR, 'no filename supplied', 'rd_f sets error on empty filename';
is $File::Valet::ERRNO, -1,                     'rd_f sets errno on empty filename';

is rd_f($filename),     undef,                       'rd_f handles missing file';
is $File::Valet::OK,    'ERROR',                     'rd_f sets ok on missing filename';
is $File::Valet::ERROR, 'cannot open for reading',   'rd_f sets error on missing filename';
is $File::Valet::ERRNUM, &Errno::ENOENT,             'rd_f sets errno on missing filename';

ok open($fh, '>', $filename) && chmod(000, $filename) && close($fh), 'created unreadable file';
# TTK here 2019-08-22: Since nothing is unreadable to root, these tests fail when run as root.  Disabling them for now.
# is rd_f($filename),      undef,                     'rd_f handles unreadable file';
# is $File::Valet::OK,     'ERROR',                   'rd_f sets ok on unreadable filename';
# is $File::Valet::ERROR,  'cannot open for reading', 'rd_f sets error on unreadable file';
# is $File::Valet::ERRNUM, &Errno::EACCES,            'rd_f sets errno on unreadable file';
unlink($filename);

ok open($fh, '>', $filename) && (print $fh $content) && close($fh), 'created readable file';
is rd_f($filename),      $content, 'rd_f handles file';
is $File::Valet::OK,     'OK',     'rd_f sets ok on file';
is $File::Valet::ERROR,  '',       'rd_f sets error on file';
is $File::Valet::ERRNUM,  0,       'rd_f sets errno on file';
unlink($filename);

ok open($fh, '>', $filename) && close($fh), 'created readable empty file';
is rd_f($filename),      '',      'rd_f handles empty file';
is $File::Valet::OK,     'OK',    'rd_f sets ok on empty file';
is $File::Valet::ERROR,  '',      'rd_f sets error on empty file';
is $File::Valet::ERRNUM,  0,      'rd_f sets errno on empty file';
unlink($filename);

# tests for wr_f:
is wr_f(),               undef,                 'wr_f handles undef filename';
is $File::Valet::OK,    'ERROR',                'wr_f sets ok on undef filename';
is $File::Valet::ERROR, 'no filename supplied', 'wr_f sets error on undef filename';
is $File::Valet::ERRNO, -1,                     'wr_f sets errno on undef filename';

is wr_f(''),             undef,                 'wr_f handles empty filename';
is $File::Valet::OK,    'ERROR',                'wr_f sets ok on empty filename';
is $File::Valet::ERROR, 'no filename supplied', 'wr_f sets error on empty filename';
is $File::Valet::ERRNO, -1,                     'wr_f sets errno on empty filename';

is wr_f($filename, $content), 'OK', 'wr_f handles writing file';
is $File::Valet::OK,    'OK',       'wr_f sets ok on success';
is $File::Valet::ERROR, '',         'wr_f sets error on success';
is $File::Valet::ERRNUM, 0,         'wr_f sets errno on success';
is rd_f($filename), $content,       'wr_f wrote content as expected';

is wr_f($filename, $content), 'OK', 'wr_f handles overwriting file';
is $File::Valet::OK,    'OK',       'wr_f overwrite sets ok on success';
is $File::Valet::ERROR, '',         'wr_f overwrite sets error on success';
is $File::Valet::ERRNUM, 0,         'wr_f overwrite sets errno on success';
is rd_f($filename), $content,       'wr_f overwrote content as expected';
unlink($filename);

ok open($fh, '>', $filename) && chmod(000, $filename), 'created unwritable file';
close($fh);
# TTK here 2019-08-22: Since nothing is unwritable to root, these tests fail when run as root.  Disabling them for now.
# is wr_f($filename, $content), undef,                'wr_f handles unwritable file';
# is $File::Valet::OK,     'ERROR',                   'wr_f sets ok on unwritable filename';
# is $File::Valet::ERROR,  'cannot open for writing', 'wr_f sets error on unwritable file';
# is $File::Valet::ERRNUM, &Errno::EACCES,            'wr_f sets errno on unwritable file';
unlink($filename);

# tests for ap_f:
is ap_f(),               undef,                 'ap_f handles undef filename';
is $File::Valet::OK,    'ERROR',                'ap_f sets ok on undef filename';
is $File::Valet::ERROR, 'no filename supplied', 'ap_f sets error on undef filename';
is $File::Valet::ERRNO, -1,                     'ap_f sets errno on undef filename';

is ap_f(''),             undef,                 'ap_f handles empty filename';
is $File::Valet::OK,    'ERROR',                'ap_f sets ok on empty filename';
is $File::Valet::ERROR, 'no filename supplied', 'ap_f sets error on empty filename';
is $File::Valet::ERRNO, -1,                     'ap_f sets errno on empty filename';

is ap_f($filename, $content), 'OK', 'ap_f handles writing new file';
is $File::Valet::OK,    'OK',       'ap_f sets ok on success';
is $File::Valet::ERROR, '',         'ap_f sets error on success';
is $File::Valet::ERRNO, '',         'ap_f sets errno on success';
is rd_f($filename), $content,       'ap_f wrote content as expected';

is ap_f($filename, $content), 'OK',     'ap_f handles appending to file';
is $File::Valet::OK,    'OK',           'ap_f sets ok on append';
is $File::Valet::ERROR, '',             'ap_f sets error on append';
is $File::Valet::ERRNO, '',             'ap_f sets errno on append';
is rd_f($filename), "$content$content", 'ap_f appended content as expected';
unlink($filename);

ok open($fh, '>', $filename) && chmod(000, $filename), 'created unwritable file';
close($fh);
# TTK here 2019-08-22: Since nothing is unwritable to root, these tests fail when run as root.  Disabling them for now.
# is ap_f($filename, $content), undef,                  'ap_f handles unwritable file';
# is $File::Valet::OK,     'ERROR',                     'ap_f sets ok on unwritable filename';
# is $File::Valet::ERROR,  'cannot open for appending', 'ap_f sets error on unwritable file';
# is $File::Valet::ERRNUM, &Errno::EACCES,              'ap_f sets errno on unwritable file';
unlink($filename);

done_testing();
exit(0);
