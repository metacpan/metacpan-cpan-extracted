#! perl

use strict;
use warnings;

use File::Spec::Functions qw/catfile/;
use File::Slurper qw/read_text read_binary read_lines write_text read_dir/;
use File::Temp 'tempfile';

use Test::More;

my $content = do { local $/; open my $fh, '<:raw', $0; <$fh> };
is(read_text($0), $content, 'read_file() works');
is(read_binary($0), $content, 'read_binary() works');

my @content = split /(?<=\n)/, $content;

is_deeply([ read_lines($0, 'utf-8', 0, 1) ], \@content, 'read_lines returns the right thing (no chomp)');
chomp @content;

is_deeply([ read_lines($0) ], \@content, 'read_lines returns the right thing (chomp)');

is_deeply([ read_dir('lib') ], [ 'File' ], 'read_dir appears to work');

my ($fh, $filename) = tempfile(UNLINK => 1);

ok(eval { write_text($filename, $content); 1 }, 'File has been written') or diag "Error: $@";
is(read_text($filename), $content, 'New file has correct content');

done_testing;
