#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Markdown::To::POD 'markdown_to_pod';
use HTML::Table;
use List::MoreUtils 'first_index';

sub file2string ($file) {
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}

my $md = file2string('README.md');
my @md = split /\n/, $md;
my @idx = grep {$md[$_] =~ m/\|.+\|/} 0..$#md; # indices with tables
my @table_end = grep {
	($idx[$_+1] - $idx[$_]) > 1
	} 0..$#idx-1; # get table ends
my @table_start = (0, map {$_ + 1} @table_end);
push @table_end, $#idx; # assume that last index is the end of a table (it should be)
foreach my ($table_i, $table_start) (indexed reverse @table_start) {
	my @md_table = @md[@idx[$table_start..$table_end[$table_i]]];
	splice @md, $idx[$table_start], scalar @md_table; # remove the original MD code
	my @table;
	foreach my $line (@md_table) {
		push @table, [grep {$_ ne ''} split /\h*\|\h*/, $line];
	}
	my $t =  HTML::Table->new(-data => \@table);
	my $table = $t->getTable;
	@table = grep {$_ ne ''} split /\n/, $table;
	foreach my $line (@table) {
		$line =~ s/`([^`]+)`/\<code\>$1\<\/code\>/g;
	}
	splice @md, $idx[$table_start], 0, @table; # insert the HTML code
}
$md = join ("\n", @md);
my $pod = markdown_to_pod($md);
say 'Writing README.pod from README.md, which must be copied into lib/Matplotlib/Simple.pm';
open my $tmp, '>', 'README.pod';
say $tmp $pod;
close $tmp;
$pod = file2string('README.pod');
my @pod = split /\n/, $pod;
# get table start and end indices
foreach my $i ( grep {$pod[$_] =~ /^<img\h/} reverse 0..$#pod) {
	next if $pod[$i-1] eq '<p>' eq $pod[$i+1]; # html paragraph
#	my @p = @pod[$i-3..$i+3];
#	p @p;
	splice @pod, $i+1, 0, '<p>', ''; # end
	splice @pod, $i, 0, '', '=for html', '<p>',; # start
#	@p = @pod[$i-3..$i+3];
#	p @p;
}
foreach my $i (grep {$pod[$_] eq '<table>'} reverse 0..$#pod) {
	splice @pod, $i, 0, '=for html';
}
unshift @pod, "=encoding utf8\n";
#p @pod;
open my $fh, '>', 'README.pod';
say $fh join ("\n", @pod);
close $fh;
my $lib = file2string('lib/Matplotlib/Simple.pm');
my @lib = split /\n/, $lib;
my $line = first_index {$_ eq '# from md2pod.pl πατερ ημων ο εν τοις ουρανοις, ἁγιασθήτω τὸ ὄνομά σου'} @lib;
if ($line == -1) {
	die 'Could not find correct line index';
}
splice @lib, 1-(scalar @lib - $line);
push @lib, @pod; # add properly formatted POD text
open $fh, '>', 'lib/Matplotlib/Simple.pm';
say $fh join ("\n", @lib);
close $fh;
# now get 02.make.files.t ready
my $txt = file2string('mpl.examples.pl');
my @mpl_examples = split /\n/, $txt;
my $start_str = '# Λέγω οὖν, μὴ ἀπώσατο ὁ θεὸς';
my $end_str   = '# σὺ δὲ τῇ πίστει ἕστηκας. μὴ ὑψηλὰ φρόνει, ἀλλὰ φοβοῦ';
my $i1 = first_index {$_ eq $start_str} @mpl_examples;
splice @mpl_examples, 0, $i1+1;
my @output_files;
foreach my $line (grep {/output\.file'\h+=\>\h*.+\.png',?\s*/} @mpl_examples) {
	$line =~ s/\.png'(,?)/.svg'$1/;
	if ($line =~ m/output.file\'\h*=\>\h+'(.*)\.svg/) {
		push @output_files, "$1.svg";
	} else {
		die "$line failed regex.";
	}
}
p @output_files;
$txt = file2string('t/01.all.tests.t');
my @test = split /\n/, $txt;
$i1 = first_index {$_ eq $start_str}  @test;
my $i2 = first_index {$_ eq $end_str} @test;
splice @test, $i1+1, $i2-$i1-1; # remove old code
splice @test, $i1+1, 0, @mpl_examples; # insert
$test[$i2+1] = 'my @output_files = (\'' . join ("','", @output_files) . '\');';
open $fh, '>', 't/01.all.tests.t';
say $fh join ("\n", @test);
