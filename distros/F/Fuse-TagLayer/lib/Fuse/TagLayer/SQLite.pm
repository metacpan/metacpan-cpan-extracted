package Fuse::TagLayer::SQLite;

use DBI;

use Exporter;
push @Fuse::TagLayer::SQLite::ISA, 'Exporter';
our @EXPORT = ('db_init','db_sync','db_disconnect','db_tags_add','db_tags_all','db_files_add','db_files_for_tags');

our $dbh;
our $mysql_file_insert;
our $mysql_tags_insert;
our $opts;

## SQLite currently uses two tables:
## tags: an index of all tags
## files: path+basename for each file, with a tag-string for regex matching

sub db_init {
	$opts = { @_ };

	my $sql = "create table if not exists `tags` (
		`tag` varchar(255) null,
		`count` integer DEFAULT '0'
	);";
	database()->do($sql) or die database()->errstr;
	my $empty = database()->prepare("DELETE FROM `tags`; ") or die database()->errstr;	# no TRUNCATE TABLE in SQLite
	$empty->execute();

	$sql = "create table if not exists `file_tags` (
		`dir` varchar(255) null,
		`basename` varchar(255) null,
		`tags` varchar(255) null
	);";
	database()->do($sql) or die database()->errstr;
	my $empty2 = database()->prepare("DELETE FROM `file_tags`; ") or die database()->errstr;	# no TRUNCATE TABLE in SQLite
	$empty2->execute();

	database()->{AutoCommit} = 0;

	## prepare statements
	our $mysql_file_insert = database()->prepare("INSERT INTO `file_tags` (`dir`,`basename`,`tags`) VALUES (?,?,?); ") or die database()->errstr;
	our $mysql_tags_insert = database()->prepare("INSERT INTO `tags` (`tag`,`count`) VALUES (?,?); ") or die database()->errstr;
}

sub database {
	unless($dbh){
		$dbh = DBI->connect("dbi:SQLite::memory:", "", "");
	#	$dbh = DBI->connect("dbi:SQLite:dbname=/tmp/taglayer.sqlite", "", "");	# for debug only, make sure you delete the file after each mount!!
	}
	return $dbh;
}

sub db_sync {
	database()->commit;
}

sub db_disconnect {
	database()->disconnect;
}

sub db_tags_add {
	my ($tag,$cnt) = @_;
	print "##  SQLite::db_tags_add: $tag, $cnt\n" if $opts->{debug} > 2;
	$mysql_tags_insert->execute($tag, $cnt) or die database()->errstr;
}

sub db_tags_all {
	my $dirs = database()->selectcol_arrayref("SELECT `tag` FROM `tags`; "); # push first row into arrayref
	return $dirs;
}

sub db_files_add {
	my ($dir,$basename,@tags) = @_;
	print "##  SQLite::db_files_add: dir:$dir, basename:$basename, tags:@tags\n" if $opts->{debug} > 2;

	my $tagstring = join(', ', @tags);

	$mysql_file_insert->execute( $dir, $basename, $tagstring ) or die database()->errstr;
}

## returns:
## ref to a list of files tagged with input tags, and
## ref to a hash of subtags (all tags associated with returned files, minus the input tags)
sub db_files_for_tags {
	my (@tags) = @_;

	my $sql = join(" AND ", map { "`tags` REGEXP '$_'" } @tags );

	print "##  SQLite::db_files_for_tags: @tags ; sql:$sql\n" if $opts->{debug};

	$entries = database()->prepare("SELECT * FROM `file_tags` WHERE $sql; "); # push first row into arrayref
	$entries->execute();

	my @files_for_tags;
	my %subtags;
	while( my $entry = $entries->fetchrow_hashref ){
		push(@files_for_tags, $entry->{dir} .'/'. $entry->{basename});

		for( split(/,\s*/,$entry->{tags}) ){
		# already clean
		#	my $tag_cleaned = lc($_);
		#	$tag_cleaned =~ s/[^\p{L}\p{N}]//g;	# matches all (Unicode) characters that are neither letters nor numbers
			$subtags{$_}++;
		}
	}

	print "##  SQLite::db_files_for_tags: ".$entries->rows." files ; ".scalar(keys(%subtags))." subtags (before minus)\n" if $opts->{debug} > 1;

	for(@tags){ delete($subtags{$_}); }

	return (\@files_for_tags, \%subtags);
}

1;
