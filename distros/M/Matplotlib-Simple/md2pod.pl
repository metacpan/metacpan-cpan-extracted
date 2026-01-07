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

sub insert_file_into_another {
#
# this sub inserts some lines from a donating file into a receiving file
#
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ filename => 'blah.xlsx' })\"";
	}
	my @reqd_args = (
		'donating.file',      # file that donates text
		'receiving.file',     # file that receives text
		'donate.start.str',   # line in donating file that starts text
		'receiving.start.str' # 
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'destination.file',  # by default, $args->{'receiving.file'}
		'donate.end.str',    # the string in the donating  file indicating end of saving lines
		'receiving.end.str', # the string in the receiving file indicating end of saving lines
		'substitute'         # an array of text substitutions to do
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my @missing_files = grep {not -f $args->{$_}} ('donating.file', 'receiving.file');
	if (scalar @missing_files > 0) {
		p $args;
		say STDERR 'the above args have these files missing:';
		p @missing_files;
		die 'the above files are missing';
	}
	my $file = file2string($args->{'donating.file'});
	my @donating_file = split /\n/, $file;
	my $start_idx = first_index {$_ eq $args->{'donate.start.str'}} @donating_file;
	if ($start_idx == -1) {
		die "Couldn't find start line in $args->{'donating.file'}";
	}
	my $end_idx = scalar @donating_file - 1; # 'donate.end.str' gets priority
	if (defined $args->{'donate.end.str'}) {
		$end_idx = first_index {$_ eq $args->{'donate.end.str'}} @donating_file;
	}
	die "Couldn't get end string = \"$args->{'donate.end.str'}\"" if $end_idx == -1;
	if ($end_idx <= $start_idx) {
		die "$args->{'donating.file'}: \$end_idx = $end_idx <= \$start_idx = $start_idx";
	}
	@donating_file = @donating_file[$start_idx+1..$end_idx]; # take the lines that are needed
	foreach my $sub (@{ $args->{substitute} }) {
		foreach my $line (@donating_file) {
			$line =~ s/$sub->[0]/$sub->[1]/;
		}
	}
	if (scalar @donating_file == 0) {
		p $args;
		die "there were 0 lines to save from $args->{'donating.file'}";
	}
	$file = file2string($args->{'receiving.file'});
	my @receiving_file = split /\n/, $file;
	$start_idx = first_index {$_ eq $args->{'receiving.start.str'}} @receiving_file;
	if ($start_idx == -1) {
		die "Couldn't find start line in $args->{'receiving.start.str'}";
	}
	$end_idx = scalar @receiving_file - 1;
	if (defined $args->{'receiving.end.str'}) {
		$end_idx = first_index {$_ eq $args->{'receiving.end.str'}} @receiving_file;
	}
	if ($end_idx == -1) {
		die "\"$args->{'donate.end.str'}\" wasn't found in \"$args->{'receiving.file'}\"";
	}
	if ($end_idx <= $start_idx) {
		die "$args->{'receiving.file'}: \$end_idx = $end_idx <= \$start_idx = $start_idx";
	}
	# remove the lines that are supposed to be removed; insert @donating_file
	splice @receiving_file, $start_idx + 1, $end_idx - $start_idx - 1, @donating_file;
	$args->{'destination.file'} = 
	open my $fh, '>', $args->{'receiving.file'};
	say $fh join ("\n", @receiving_file);
	return 1;
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
insert_file_into_another({
	'donating.file'       => 'mpl.examples.pl',
	'donate.start.str'    => '# Λέγω οὖν, μὴ ἀπώσατο ὁ θεὸς',
	'receiving.file'      => 't/01.all.tests.t',
	'receiving.start.str' => '# Λέγω οὖν, μὴ ἀπώσατο ὁ θεὸς',
	'receiving.end.str'   => '# σὺ δὲ τῇ πίστει ἕστηκας. μὴ ὑψηλὰ φρόνει, ἀλλὰ φοβοῦ',
});
my $test = file2string('t/01.all.tests.t');
my @test = split /\n/, $test;
my $output_idx = '-inf';
my @output_files;
foreach my ($idx, $line) (indexed @test) {
	$line =~ s/\.png'(,?)/.svg'$1/;
	$line =~ s/'output\.images\//'\/tmp\//;
	if ($line =~ m/output\.file\'\h*=\>\h+'(.+)\.svg/) {
		push @output_files, "$1.svg" unless $1 eq '/tmp/dies_ok';
		next;
	}
	if ($line =~ m/^my \@output_files\h*=\h*.+\);$/) {
		$output_idx = $idx;
	}
}
die 'Could not find @output_files declaration in t/01.all.tests.t' unless $output_idx >= 0;
die 'no output files found' if scalar @output_files == 0;
$test[$output_idx] = 'my @output_files = (\'' . join ("', '", @output_files) . "');";
open my $t, '>', 't/01.all.tests.t';
say $t join ("\n", @test);
#my $txt = file2string('mpl.examples.pl');
#my @mpl_examples = split /\n/, $txt;
#my $start_str = '# Λέγω οὖν, μὴ ἀπώσατο ὁ θεὸς';
#my $end_str   = '# σὺ δὲ τῇ πίστει ἕστηκας. μὴ ὑψηλὰ φρόνει, ἀλλὰ φοβοῦ';
#my $i1 = first_index {$_ eq $start_str} @mpl_examples;
#splice @mpl_examples, 0, $i1+1;
#my @output_files;
#foreach my $line (grep {/output\.file'\h+=\>\h*.+\.png',?\s*/} @mpl_examples) {
#	$line =~ s/\.png'(,?)/.svg'$1/;
#	if ($line =~ m/output.file\'\h*=\>\h+'(.*)\.svg/) {
#		push @output_files, "$1.svg";
#	} else {
#		die "$line failed regex.";
#	}
#}
#p @output_files;
#$txt = file2string('t/01.all.tests.t');
#my @test = split /\n/, $txt;
#$i1 = first_index {$_ eq $start_str}  @test;
#my $i2 = first_index {$_ eq $end_str} @test;
#splice @test, $i1+1, $i2-$i1-1; # remove old code
#splice @test, $i1+1, 0, @mpl_examples; # insert
#$test[$i2+1] = 'my @output_files = (\'' . join ("','", @output_files) . '\');';
#open $fh, '>', 't/01.all.tests.t';
#say $fh join ("\n", @test);
