#! perl

use strict;
use warnings;

use File::Spec::Functions qw/catfile/;
use File::Slurp::Tiny qw/read_file read_lines write_file read_dir/;
use File::Temp qw/tempdir/;

use Test::More;

my $content = do { local $/; open my $fh, '<:raw', $0; <$fh> };
is(read_file($0), $content, 'read_file() works');
is(read_file($0, binmode => ':raw'), $content, 'read_file(binmode => :raw) works');
my $ref = read_file($0, scalar_ref => 1);
ok(ref($ref) && ${$ref} eq $content, 'read_file(scalar_ref => 1) works');
read_file($0, buf_ref => \my $buf);
is($buf, $content, 'read_file(buf_ref => $buf) works');

my @content = split /(?<=\n)/, $content;

is_deeply([ read_lines($0) ], \@content, 'read_lines returns the right thing');
chomp @content;
is_deeply([ read_lines($0, chomp => 1) ], \@content, 'read_lines(chomp => 1) returns the right thing');

is_deeply([ read_dir('lib') ], [ 'File' ], 'read_dir appears to work');
is_deeply([ read_dir('lib', prefix => 1) ], [ catfile(qw/lib File/) ], 'read_dir(prefix => 1) appears to work');

my $dir = tempdir( CLEANUP => 1 );
my $filename = catfile($dir, 'out.txt');
write_file($filename, $content);
is(read_file($filename), $content, 'write_file + readfile = noop');
write_file($filename, $content, append => 1);
is(read_file($filename), $content x 2, 'write_file + readfile = noop');

done_testing;
