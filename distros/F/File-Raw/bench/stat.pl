#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Raw qw(import);

my $tmpdir = tempdir(CLEANUP => 1);
my $file = "$tmpdir/stat.txt";
File::Raw::spew($file, "benchmark content\n");

print "=== Stat / Test Benchmarks ===\n\n";

print "--- size ---\n";
cmpthese(-3, {
    'File::Raw::size'      => sub { File::Raw::size($file) },
    'file_size (custom op)' => sub { file_size($file) },
    'Perl -s'               => sub { -s $file },
    'Perl stat()'           => sub { (stat($file))[7] },
});

File::Raw::clear_stat_cache();

print "\n--- exists ---\n";
cmpthese(-3, {
    'File::Raw::exists'      => sub { File::Raw::exists($file) },
    'file_exists (custom op)' => sub { file_exists($file) },
    'Perl -e'                 => sub { -e $file },
});

File::Raw::clear_stat_cache();

print "\n--- is_file ---\n";
cmpthese(-3, {
    'File::Raw::is_file'      => sub { File::Raw::is_file($file) },
    'file_is_file (custom op)' => sub { file_is_file($file) },
    'Perl -f'                  => sub { -f $file },
});

File::Raw::clear_stat_cache();

print "\n--- is_dir ---\n";
cmpthese(-3, {
    'File::Raw::is_dir'      => sub { File::Raw::is_dir($tmpdir) },
    'file_is_dir (custom op)' => sub { file_is_dir($tmpdir) },
    'Perl -d'                 => sub { -d $tmpdir },
});

File::Raw::clear_stat_cache();

print "\n--- mtime ---\n";
cmpthese(-3, {
    'File::Raw::mtime' => sub { File::Raw::mtime($file) },
    'Perl stat mtime'   => sub { (stat($file))[9] },
});

File::Raw::clear_stat_cache();

print "\n--- is_readable ---\n";
cmpthese(-3, {
    'File::Raw::is_readable' => sub { File::Raw::is_readable($file) },
    'Perl -r'                 => sub { -r $file },
});

File::Raw::clear_stat_cache();

print "\n--- is_writable ---\n";
cmpthese(-3, {
    'File::Raw::is_writable' => sub { File::Raw::is_writable($file) },
    'Perl -w'                 => sub { -w $file },
});
