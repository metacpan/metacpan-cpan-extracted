#! /usr/bin/env perl

use strict;
use warnings;

use Benchmark 'cmpthese';
use File::Slurp qw/read_file/;
use File::Slurper qw/read_text read_lines read_binary/;
use POSIX ();
use Unicode::UTF8 'decode_utf8';

my $filename = shift or die "No argument given";
my $count = shift || 1000;
my $factor = 10;

my $length = -s $filename;
my $compare = read_binary($filename);
print "Slurping into a scalar\n";
cmpthese($count * $factor, {
	'Slurp'       => sub { my $content = read_file($filename, binmode => ":raw") },
	'Slurper'     => sub { my $content = read_binary($filename) },
	'Traditional' => sub { open my $fh, '<', $filename or die $!; my $content = do { local $/; <$fh> } },
	'Unix'        => sub { open my $fh, '<:unix', $filename or die $!; my $content = do { local $/; <$fh> } },
	'POSIX'       => sub { open my $fh, '<', $filename or die $!; POSIX::read(fileno $fh, my $content, -s $fh) },
});

print "\nSlurping into an array\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = read_file($filename) },
	'Slurp+ref'   => sub { my $lines = read_file($filename, array_ref => 1) },
	'Slurper'     => sub { my @lines = read_lines($filename, 'latin1', 0, 1) },
	'Traditional' => sub { open my $fh, '<', $filename; my @lines = <$fh> },
});

print "\nSlurping into a loop\n";
cmpthese($count, {
	'Slurp'       => sub { for(read_file($filename)) {} },
	'Slurp+ref'   => sub { for(@{ read_file($filename, array_ref => 1) }) {} },
	'Slurper'     => sub { for(read_lines($filename, 'latin1', 0, 1)) {} },
	'Traditional' => sub { open my $fh, '<', $filename; while(<$fh>) {} },
});

print "\nSlurping into an array, chomped\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = read_file($filename, chomp => 1) },
	'Slurp+ref'   => sub { my $lines = read_file($filename, array_ref => 1, chomp => 1) },
	'Slurper'     => sub { my @lines = read_lines($filename, 'latin1', 0, 0) },
	'Traditional' => sub { open my $fh, '<', $filename; my @lines = <$fh>; chomp @lines },
});


print "\nSlurping crlf into a scalar\n";
cmpthese($count * $factor, {
	'Slurper'     => sub { my $content = read_text($filename, 'latin1', 1, 1) },
	'Slurp'       => sub { my $content = read_file($filename, binmode => ':crlf') },
	'Traditional' => sub { open my $fh, '<:crlf', $filename or die $!; my $content = do { local $/; <$fh> } },
	'Smart'       => sub { open my $fh, '<:crlf:perlio', $filename or die $!; my $content = do { local $/; <$fh> } },
	'Explicit'    => sub { my $content = read_binary($filename); $content =~ s/\r\n/\n/g },
});

print "\nSlurping crlf into an array\n";
cmpthese($count, {
	'Slurper'     => sub { my @lines = read_lines($filename, 'latin1', 1, 1) },
	'Slurp'       => sub { my @lines = read_file($filename, binmode => ':crlf') },
	'Traditional' => sub { open my $fh, '<:crlf', $filename; my @lines = <$fh> },
	'Explicit'    => sub { my $content = read_binary($filename); $content =~ s/\r\n/\n/g; my @lines = $content =~ /(.*?\n|.+\z)/sg },
});

print "\nSlurping crlf into an array, chomped\n";
cmpthese($count, {
	'Slurper'     => sub { my @lines = read_lines($filename, 'latin1', 1, 0) },
	'Slurp'       => sub { my @lines = read_file($filename, binmode => ':crlf', chomp => 1) },
	'Traditional' => sub { open my $fh, '<:crlf', $filename; my @lines = <$fh>; chomp @lines },
});
print "\nNote that File::Slurp (as of 9999.19) does not validate its input, falsely improving its performance\n";

print "\nSlurping utf8 into a scalar\n";
cmpthese($count, {
	'Slurp'       => sub { my $content = read_file($filename, binmode => ':raw:encoding(utf-8)') },
	'Slurper'     => sub { my $content = read_text($filename) },
	'Traditional' => sub { open my $fh, '<:raw:encoding(utf-8)', $filename or die $!; my $content = do { local $/; <$fh> } },
	'Strict'      => sub { open my $fh, '<:raw:utf8_strict', $filename or die $!; my $content = do { local $/; <$fh> } },
	'Explicit'    => sub { my $content = read_binary($filename); utf8::decode($content); },
	'Explicit2'    => sub { my $content = read_binary($filename); decode_utf8($content); },
});

print "\nSlurping utf8 into an array\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = read_file($filename, binmode => ':raw:encoding(utf-8)') },
	'Slurp+ref'   => sub { my $lines = read_file($filename, array_ref => 1, binmode => ':raw:encoding(utf-8)') },
	'Slurper'     => sub { my @lines = read_lines($filename, 'utf-8', 0, 1) },
	'Traditional' => sub { open my $fh, '<:raw:encoding(utf-8)', $filename; my @lines = <$fh> },
	'Strict'      => sub { open my $fh, '<:unix:utf8_strict', $filename; my @lines = <$fh> },
	'Explicit'    => sub { my @lines = map { utf8::decode($_); $_ } read_lines($filename, 'latin1', 0, 1) },
});

print "\nSlurping utf8 into an array, chomped\n";
cmpthese($count, {
	'Slurp'       => sub { my @lines = read_file($filename, chomp => 1, binmode => ':raw:encoding(utf-8)') },
	'Slurper'     => sub { my @lines = read_lines($filename, 'utf-8', 0, 0) },
	'Traditional' => sub { open my $fh, '<:raw:encoding(utf-8)', $filename; my @lines = <$fh>; chomp @lines },
	'Strict'      => sub { open my $fh, '<:unix:utf8_strict', $filename; my @lines = <$fh>; chomp @lines },
});

