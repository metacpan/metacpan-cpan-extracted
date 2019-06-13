#!/usr/bin/env perl
# ABSTRACT: Remove tags by content from ABI traces
# PODNAME: strip_tags
use 5.018;
use warnings;
use Data::Dumper;
use Bio::Trace::ABIF;
use Term::ANSIColor;
my ($file, $REMOVE_TAG) = @ARGV;

# STRIP TAGS FROM AB1 FILE IF CONTENT MATCHES $REMOVE_TAG

die "Missing argument <AB1File>\n" unless (-e "$file");
die "Missing argument TAG (usage: FileABI TagContentToStrip)\n" unless (defined $REMOVE_TAG);
say "Processing $file";

if ($file !~/bak$/) {
	# OPENING REGULAR FILE: TO BE BACKUPPED
	unless (-e "$file.bak") {
		say "Backing up...";
		`cp "$file" "$file.bak"`;
		die "Unable to backup\n" if ($?);
	}
} else {
	# THIS IS A BACKUP
	say "De-Backing up...";
	$file =~s/.bak$//;
	`cp "$file.bak" "$file"`;
	die "Unable to de-backup $file.bak\n" if ($?);
}

my $trace = Bio::Trace::ABIF->new();
$trace->open_abif("$file", 1);

unless ($trace->is_abif_format() ) {
	die " $file is not ABIF\n";
}

my $num = $trace->num_dir_entries();
my @tag = $trace->tags();
say join(', ', @tag);
my $true = 1;


for my $t (@tag) {
	my $num = chop($t);
		say color('bold'),  "[$t] $num" , color('reset');
	my %DirEntry = $trace->get_directory($t, $num);

	#
	# $VAR1 = {
	#           'DATA_ITEM' => '
	# Gingol-H09',
	#           'ELEMENT_SIZE' => 1,
	#           'TAG_NUMBER' => '1',
	#           'TAG_NAME' => 'SMPL',
	#           'ELEMENT_TYPE' => 'pString',
	#           'NUM_ELEMENTS' => 11,
	#           'DATA_SIZE' => 11
	#         };

	if ($DirEntry{'DATA_ITEM'} =~/$REMOVE_TAG/i) {
		my $data = '';
		$trace->write_tag($t, $num, \$data);
		say Dumper \%DirEntry;
	}
}
