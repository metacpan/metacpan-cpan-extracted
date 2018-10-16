use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path);

use File::Slurp qw(read_dir write_file);
use Test::More;

plan tests => 9;

# try to honor possible tempdirs
my $test_dir = temp_file_path(); # a good temporary filename

mkdir( $test_dir, 0700) || die "mkdir $test_dir: $!";
my @dir_entries = read_dir($test_dir);
ok(@dir_entries == 0, 'empty dir');

@dir_entries = read_dir($test_dir, keep_dot_dot => 1);
ok(@dir_entries == 2, 'empty dir with . ..');

@dir_entries = read_dir($test_dir, {keep_dot_dot => 1});
ok(@dir_entries == 2, 'empty dir with . .. - args ref');

write_file(File::Spec->catfile($test_dir, 'x'), "foo\n");
@dir_entries = read_dir($test_dir);
ok(@dir_entries == 1, 'dir with 1 file');
is($dir_entries[0], 'x', 'dir with file x');


my $file_cnt = 23;
my @expected_entries = sort('x', 1 .. $file_cnt);

for my $file (1 .. $file_cnt) {
    write_file(File::Spec->catfile($test_dir, $file), "foo\n");
}

@dir_entries = read_dir($test_dir);
@dir_entries = sort @dir_entries;

is_deeply(\@dir_entries, \@expected_entries, "dir with $file_cnt files");

my $dir_entries_ref = read_dir($test_dir);
@{$dir_entries_ref} = sort @{$dir_entries_ref};

is_deeply($dir_entries_ref, \@expected_entries, "dir in array ref");

my @prefixed_entries;
@prefixed_entries = read_dir( $test_dir, { prefix => 1 } ) ;
is_deeply(
    [ sort @prefixed_entries ],
    [ map File::Spec->catfile($test_dir, $_), @dir_entries ],
	'prefix option in hash ref'
);

@prefixed_entries = read_dir( $test_dir, prefix => 1 ) ;
is_deeply(
    [ sort @prefixed_entries ],
    [ map File::Spec->catfile($test_dir, $_), @dir_entries ],
	'prefix option as key-value pair'
);

# clean up

unlink map File::Spec->catfile($test_dir, $_), @dir_entries;
rmdir($test_dir) || die "rmdir $test_dir: $!";
