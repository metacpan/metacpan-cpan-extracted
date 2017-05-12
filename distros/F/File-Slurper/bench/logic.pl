#! /usr/bin/env perl

use strict;
use warnings;
use Carp 'croak';
use File::Slurp 'read_file';
use File::Slurper 'read_binary';

use Benchmark 'cmpthese';

my $filename = shift or die "No argument given";
my $count = shift || -0.5;

sub read_complicated {
	my $filename = shift;
	my $buf;

	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	my $size = -s $fh;
	my ($pos, $read) = 0;
	do {
		defined($read = read $fh, $buf, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
		$pos += $read;
	} while ($read && $pos < $size);
	return $buf;
}

sub read_complicated_ref {
	my $filename = shift;
	my $buf = shift;

	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	my $size = -s $fh;
	my ($pos, $read) = 0;
	do {
		defined($read = read $fh, ${$buf}, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
		$pos += $read;
	} while ($read && $pos < $size);
	return ${$buf};
}

sub read_simple {
	my $filename = shift;

	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	return do { local $/; <$fh> };
}

sub read_naive {
	my $filename = shift;

	open my $fh, '<:raw', $filename or croak "Couldn't open $filename: $!";
	return do { local $/; <$fh> };
}

sub read_sysread {
	my $filename = shift;
	my $buf;

	open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
	my $size = -s $fh;
	my ($pos, $read) = 0;
	do {
		defined($read = sysread $fh, $buf, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
		$pos += $read;
	} while ($read && $pos < $size);
	return $buf;
}

cmpthese($count, {
	complicated => sub { read_complicated($filename) },
	ref         => sub { read_complicated_ref($filename, \my $content) },
	simple      => sub { read_simple($filename) },
	naive       => sub { read_naive($filename) },
	sysread     => sub { read_sysread($filename) },
	slurp       => sub { read_file($filename, binmode => ':raw') },
	slurper     => sub { read_binary($filename) },
});

cmpthese($count, {
	complicated => sub { my $content = read_complicated($filename) },
	simple      => sub { my $content = read_simple($filename) },
	naive       => sub { my $content = read_naive($filename) },
	sysread     => sub { my $content = read_sysread($filename) },
	ref         => sub { read_complicated_ref($filename, \my $content) },
	slurp       => sub { my $content = read_file($filename, binmode => ':raw') },
	slurper     => sub { my $content = read_binary($filename) },
});
