#! /usr/bin/env perl
use Modern::Perl;
use Test::More;
use File::Temp qw/tempfile/;

my $module = 'File::Utils';
my @methods = qw/read_handle write_handle/;
use_ok($module, @methods);

for my $method (@methods) {
  can_ok($module, $method);
}


my ($fh, $filename) = tempfile;

system("echo 'test content' |gzip > $filename.gz");

my $line = read_handle("$filename.gz")->getline;
is("test content\n", $line, "compare gz");

done_testing;

