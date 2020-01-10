#!/usr/bin/env perl
# ABSTRACT: List tags by content from ABI traces
# PODNAME: list_tags

use 5.018;
use warnings;
use Data::Dumper;
use Bio::Trace::ABIF;
use Term::ANSIColor;
my ($file) = @ARGV;

# STRIP TAGS FROM AB1 FILE IF CONTENT MATCHES $REMOVE_TAG

die "Missing argument <AB1File>\n" if (not defined $file or not -e "$file");
say STDERR "#Processing $file";

if ($file !~/bak$/) {
	# OPENING REGULAR FILE: TO BE BACKUPPED
	unless (-e "$file.bak") {
		say STDERR qq(Backing up "$file" to "$file.bak");
		`cp "$file" "$file.bak"`;
		die "Unable to backup\n" if ($?);
	}
} else {
	# THIS IS A BACKUP
	say STDERR "De-Backing up...";
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

		#say Dumper \$t;
}
