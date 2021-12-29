#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use IO::Compress::Zip qw(zip);

use Test::More tests => 11;

BEGIN {
  use_ok 'Mail::Exim::Blacklist::Attachments', qw(check_filename check_zip);
}

my $good_zip;
zip(\q{} => \$good_zip, Name => 'test.txt');

my $macro_zip;
zip(\q{} => \$macro_zip, Name => 'test.docm');

my $bad_zip;
zip(\q{} => \$bad_zip, Name => 'test.exe');

my $garbage = 'garbage';

is check_filename('test.docm'), 'blacklisted',
  'Macro-enabled Word file is blacklisted';
isnt check_filename('test.docx'), 'blacklisted', 'Plain Word file is accepted';
is check_filename('test.exe'), 'blacklisted', 'Executable file is blacklisted';
is check_filename('TEST.EXE'), 'blacklisted', 'Uppercase filenames are handled';

is check_filename('test.001'), 'blacklisted', 'Split archive is blacklisted';
is check_filename('test.r15'), 'blacklisted', 'Split archive is blacklisted';

is check_zip(\$good_zip), 'ok', 'Zip archive is accepted';
is check_zip(\$macro_zip), 'blacklisted',
  'Zip archive contains macro-enabled file';
is check_zip(\$bad_zip), 'blacklisted', 'Zip archive contains executable file';
is check_zip(\$garbage), 'blacklisted', 'Garbage is blacklisted';
