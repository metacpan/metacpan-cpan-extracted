#!/usr/bin/perl 

use strict;
use Getopt::Long;

use IMDB::Local;
use IMDB::Local::Title;
use IMDB::Local::QualifierType ':types';

my ($opt_help,
    $opt_imdbDir,
    $opt_import,
    $opt_quiet,
    $opt_download);
my $opt_title;
my $opt_format='csv';

GetOptions('help'             => \$opt_help,
	   'imdbdir=s'        => \$opt_imdbDir,
	   'import=s'         => \$opt_import,
	   'quiet'            => \$opt_quiet,
	   'title=s'          => \$opt_title,
	   'format=s'         => \$opt_format,
    ) or usage(0);

if ( $opt_help ) {
    die "no usage implemented";
}

if ( ! defined($opt_imdbDir) ) {
    die "imdbdir flag is required";
}

$opt_quiet=(defined($opt_quiet));

# lets put list files below the imdbDir
my $listsDir="$opt_imdbDir/lists";

my $db=new IMDB::Local::DB(database=>"$opt_imdbDir/imdb.db");
if ( !$db->connect() ) {
    die "moviedb connect failed:$DBI::errstr";
}

my $searchableTItle=$db->makeSearchableTitle($opt_title);
print "searching for $searchableTItle\n";

sub DumpTitle($)
{
    my ($t)=@_;

    #my $ind=" " x $index;
    print $t->toText();
    
    if ( $t->QualifierType->Name eq 'tv_series' ) {
	#print "getting episodes..\n";
	
	my $n=0;
	for my $e ($t->getEpisodes()) {
	    $n++;
	    print "=====Episode #$n:\n";
	    $e->populateAll();
	    for (split("\n", $e->toText())) {
		print "\t".$_."\n";
	    }
	    #print $e->toText();
	}
    }
}

my @list=IMDB::Local::Title::findBySearchableTitle($db, $searchableTItle, IMDB::Local::QualifierType::TV_SERIES); # any type
if ( @list ) {
    print "===== TV SERIES =====\n";
}
for my $i (@list) {

    if ( $opt_format eq 'detailed' ) {
	print "===============================: Title $i\n";

	my $t=IMDB::Local::Title::findByTitleID($db, $i);
	$t->populateAll();
	DumpTitle($t);
    }
    elsif ( $opt_format eq 'csv' ) {
	print "===============================: Title $i\n";

	my $t=IMDB::Local::Title::findByTitleID($db, $i);

	$t->populateAll();
	print $t->toText();

	if ( $t->QualifierTypeID == IMDB::Local::QualifierType::TV_SERIES ) {
	    print "----------------------------------------\n";
	    my $res=$db->select2Matrix("select SearchTitle,Title,Series,Episode,AirDate from Titles where ParentID=$i order by Series,Episode");
	    if ( $res ) {
		for my $h (@$res) {
		    print "   ".join(',', @$h)."\n";
		}
	    }
	}
    }
    
}


@list=IMDB::Local::Title::findBySearchableTitle($db, $searchableTItle, IMDB::Local::QualifierType::MOVIE); # any type
if ( @list ) {
    print "===== MOVIES =====\n";
}
for my $i (@list) {

    if ( $opt_format eq 'detailed' ) {
	print "===============================: Title $i\n";

	my $t=IMDB::Local::Title::findByTitleID($db, $i);
	$t->populateAll();
	DumpTitle($t);
    }
    elsif ( $opt_format eq 'csv' ) {
	print "===============================: Title $i\n";

	my $t=IMDB::Local::Title::findByTitleID($db, $i);

	$t->populateAll();
	print $t->toText();

	if ( $t->QualifierTypeID == IMDB::Local::QualifierType::TV_SERIES ) {
	    print "----------------------------------------\n";
	    my $res=$db->select2Matrix("select SearchTitle,Title,Series,Episode,AirDate from Titles where ParentID=$i order by Series,Episode");
	    if ( $res ) {
		for my $h (@$res) {
		    print "   ".join(',', @$h)."\n";
		}
	    }
	}
    }
    
}

exit(0);
