#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Digest::SHA 'sha512_base64';
use Term::ANSIColor;

sub file2string ($file) {
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}

sub list_regex_files ($regex, $directory = '.', $case_sensitive = 'yes') {
	die "\"$directory\" doesn't exist" unless -d $directory;
	my @files;
	opendir (my $dh, $directory);
	if ($case_sensitive eq 'yes') {
		$regex = qr/$regex/;
	} else {
		$regex = qr/$regex/i;
	}
	while (my $file = readdir $dh) {
		next if $file !~ $regex;
		next if $file =~ m/^\.{1,2}$/;
		my $f = "$directory/$file";
		next unless -f $f;
		if ($directory eq '.') {
			push @files, $file
		} else {
			push @files, $f
		}
	}
	@files
}
#sub compare_2_files ($f1, $f2) {
#	my @str = (file2string($f1), file2string($f2));
#	my @lines;
#	foreach my $t (@str) {
#		my @text = split /\n/, $t;
#		printf("Starting with %u lines\n", scalar @text);
#		@text = grep {$_ !~ m/^\h*\<dc:title\>made.+\/Simple\.pm\<\/dc:title\>$/} @text;
#		@text = grep {$_ !~ m/^\h*\<dc:date\>/}        @text;
#		@text = grep {$_ !~ m/^\h*\<path\h+id="/}      @text;
#		@text = grep {$_ !~ m/^\h*\<use\h*xlink:href="/} @text;
#		@text = grep {$_ !~ m/clipPath/}           @text;
#		@text = grep {$_ !~ m/^\h*clip\-path="/}       @text;
#		printf("Ending with %u lines\n", scalar @text);
#		push @lines, [@text];
#	}
#	my @different_i = grep { $lines[0][$_] ne $lines[1][$_] } 0..scalar @{ $lines[0] } - 1;
#	@{ $lines[0] } = @{ $lines[0] }[@different_i];
#	@{ $lines[1] } = @{ $lines[1] }[@different_i];
#	p @lines;
#}

#compare_2_files('output.images/add.single.svg', '/tmp/add.single.svg');
my $filename = 'sha.sums.tsv';
my $files_done = 0;
open my $tsv, '>', $filename;
foreach my $file (list_regex_files('\.svg$', 'output.images')) {
	my $text = file2string($file);
	my @text = split /\n/, $text;
	printf("$file: Starting with %u lines\n", scalar @text);
	@text = grep {$_ !~ m/^\h*\<dc:title\>made.+\/Simple\.pm\<\/dc:title\>$/} @text;
	@text = grep {$_ !~ m/^\h*\<dc:date\>/}        @text;
	@text = grep {$_ !~ m/^\h*\<path\h+id="/}      @text;
	@text = grep {$_ !~ m/^\h*\<use\h*xlink:href="/} @text;
	@text = grep {$_ !~ m/clipPath/}           @text;
	@text = grep {$_ !~ m/clip\-path="/}       @text;
	foreach my $line (grep {/id="image[a-z\d]+"/} @text) {
		$line =~ s/\h+id="image[a-z\d]+"//;
	}
	printf("$file: Ending with %u lines\n", scalar @text);
	say '------------';
	$text = join ("\n", @text);
	$file =~ s/^output\.images/\/tmp/;
	say $tsv "$file\t" . sha512_base64($text);
	$files_done++;
}
die 'No files were done' if $files_done == 0;
say 'wrote ' . colored(['white on_blue'], $filename);
