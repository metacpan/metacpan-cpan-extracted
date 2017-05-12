#! /usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Benchmark 'cmpthese', ':hireswallclock';

sub read_text {
	my ($filename, $layers) = @_;
	open my $fh, "<$layers", $filename or die "Can't open $filename:#!";
	my $foo = do { local $/; <$fh> };
	return;
}

sub read_lines {
	my ($filename, $layers) = @_;
	open my $fh, "<$layers", $filename or die "Can't open $filename:#!";
	my @foo = <$fh>;
	return;
}

my $filename = shift // 'test.txt';
my $count = shift // 200;
my $encoding = shift // 'utf-8';

say "Read utf8 encoded Unix text file, decode with :encoding\n";
cmpthese($count, {
	':encoding'        => sub { read_text($filename, ':encoding(utf-8-strict)') },
	':encoding:perlio' => sub { read_text($filename, ':encoding(utf-8-strict):perlio') },
});

say "\nRead utf8 encoded Unix text file into lines, decode with :encoding\n";
cmpthese($count, {
	':encoding'        => sub { read_lines($filename, ':encoding(utf-8-strict)') },
	':encoding:perlio' => sub { read_lines($filename, ':encoding(utf-8-strict):perlio') },
});

say "Read utf8 encoded Windows text file, decode with :encoding\n";
cmpthese($count, {
	'c:e'       => sub { read_text($filename, ":crlf:encoding(utf-8-strict)") },
	'c:p:e'     => sub { read_text($filename, ":crlf:perlio:encoding(utf-8-strict)") },
	'u:c:e'     => sub { read_text($filename, ":unix:crlf:encoding(utf-8-strict)") },
	'u:c:p:e'   => sub { read_text($filename, ":unix:crlf:perlio:encoding(utf-8-strict)") },
	'u:c:e:p'   => sub { read_text($filename, ":unix:crlf:encoding(utf-8-strict):perlio") },
	'u:c:p:e:p' => sub { read_text($filename, ":unix:crlf:perlio:encoding(utf-8-strict):perlio") },
	'c:p:e:p'   => sub { read_text($filename, ":crlf:perlio:encoding(utf-8-strict):perlio") },
	'e:c'       => sub { read_text($filename, ":raw:encoding(utf-8-strict):crlf") },
	'e:c:p'     => sub { read_text($filename, ":raw:encoding(utf-8-strict):crlf:perlio") },
	'e:p:c:p'   => sub { read_text($filename, ":raw:encoding(utf-8-strict):perlio:crlf:perlio") },
});


say "\nRead utf8 encoded text file, decode with :utf8_strict\n";
cmpthese($count * 10, {
	':utf8_strict'             => sub { read_text($filename, ":utf8_strict") },
	':unix:utf8_strict'        => sub { read_text($filename, ":unix:utf8_strict") },
	':unix:utf8_strict:perlio' => sub { read_text($filename, ":unix:utf8_strict:perlio") },
});

say "\nRead utf8 encoded text file with optional crlf line endings, decode with :utf8_strict\n";
cmpthese($count * 10, {
	':crlf:utf8_strict'        => sub { read_text($filename, ":crlf:utf8_strict") },
	':utf8_strict:crlf'        => sub { read_text($filename, ":utf8_strict:crlf") },
	':utf8_strict:crlf:perlio' => sub { read_text($filename, ":utf8_strict:crlf:perlio") },
	':utf8_strict:perlio'      => sub { read_text($filename, ":utf8_strict:perlio") },
	':utf8_strict'             => sub { read_text($filename, ":utf8_strict") },
});

say "\nRead lines of utf8 encoded text file with optional crlf line endings, decode with :utf8_strict\n";
cmpthese($count * 10, {
	':crlf:utf8_strict'        => sub { read_lines($filename, ":crlf:utf8_strict") },
	':utf8_strict:crlf'        => sub { read_lines($filename, ":utf8_strict:crlf") },
	':utf8_strict:crlf:perlio' => sub { read_lines($filename, ":utf8_strict:crlf:perlio") },
	':utf8_strict:perlio'      => sub { read_lines($filename, ":utf8_strict:perlio") },
	':utf8_strict'             => sub { read_lines($filename, ":utf8_strict") },
});

say "\nRead text file doing crlf translation\n";
cmpthese($count * 10, {
	':unix:crlf'        => sub { read_text($filename, ":unix:crlf") },
	':unix:crlf:perlio' => sub { read_text($filename, ":unix:crlf:perlio") },
#	':unix'             => sub { read_text($filename, ":unix") },
#	':raw'              => sub { read_text($filename, ":raw") },
});

say "\nRead text file into lines doing crlf translation\n";
cmpthese($count * 10, {
	':unix:crlf'        => sub { read_lines($filename, ":unix:crlf") },
	':unix:crlf:perlio' => sub { read_lines($filename, ":unix:crlf:perlio") },
#	':raw'              => sub { read_lines($filename, ":raw") },
});
