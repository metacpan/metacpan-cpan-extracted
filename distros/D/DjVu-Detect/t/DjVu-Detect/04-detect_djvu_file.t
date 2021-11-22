use strict;
use warnings;

use DjVu::Detect qw(detect_djvu_file);
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $ret = detect_djvu_file($data_dir->file('11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu')->s);
is($ret, 1, 'Detection of DjVu file successed.');

# Test.
$ret = detect_djvu_file($data_dir->file('bad.djvu')->s);
is($ret, 0, 'Detection of DjVu file failed (blank file).');

# Test.
$ret = detect_djvu_file($data_dir->file('bad2.djvu')->s);
is($ret, 0, 'Detection of DjVu file failed (random 8 bytes).');

# Test.
eval {
	detect_djvu_file('__NO_FILE__');
};
is($EVAL_ERROR, "Cannot open file '__NO_FILE__'.\n", "Cannot open file.");
clean();
