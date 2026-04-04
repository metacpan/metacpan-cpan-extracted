#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Raw qw(import);
use File::Basename ();
use File::Spec     ();

my $path     = '/usr/local/share/doc/example/README.txt';
my $rel_path = 'foo/bar/baz.txt';
my $no_ext   = 'Makefile';

print "=== Path Manipulation Benchmarks ===\n\n";

print "--- basename ---\n";
cmpthese(-3, {
    'File::Raw::basename'      => sub { File::Raw::basename($path) },
    'file_basename (custom op)' => sub { file_basename($path) },
    'File::Basename::basename'  => sub { File::Basename::basename($path) },
    'Perl regex'                => sub { (my $b = $path) =~ s|.*/||; $b },
});

print "\n--- dirname ---\n";
cmpthese(-3, {
    'File::Raw::dirname'      => sub { File::Raw::dirname($path) },
    'file_dirname (custom op)' => sub { file_dirname($path) },
    'File::Basename::dirname'  => sub { File::Basename::dirname($path) },
    'Perl regex'               => sub { (my $d = $path) =~ s|/[^/]+$||; $d },
});

print "\n--- extname ---\n";
cmpthese(-3, {
    'File::Raw::extname'      => sub { File::Raw::extname($path) },
    'file_extname (custom op)' => sub { file_extname($path) },
    'Perl regex'               => sub { $path =~ /(\.[^.\/]+)$/ ? $1 : '' },
});

print "\n--- join ---\n";
cmpthese(-3, {
    'File::Raw::join'  => sub { File::Raw::join('usr', 'local', 'bin', 'perl') },
    'File::Spec->catfile' => sub { File::Spec->catfile('usr', 'local', 'bin', 'perl') },
    'Perl join /'       => sub { join('/', 'usr', 'local', 'bin', 'perl') },
});

print "\n--- basename (no extension path) ---\n";
cmpthese(-3, {
    'File::Raw::basename'     => sub { File::Raw::basename($no_ext) },
    'File::Basename::basename' => sub { File::Basename::basename($no_ext) },
});
