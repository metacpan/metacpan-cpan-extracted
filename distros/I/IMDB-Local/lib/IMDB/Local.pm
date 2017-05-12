package IMDB::Local;

#
# Suggestions for improvements
# - 
#
#

use 5.006;
use strict;
use warnings;

=head1 NAME

IMDB::Local - Tools to dowload and manage a local copy of the IMDB list files in a database.

=cut

our $VERSION = '1.5';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    my $foo = new IMDB::Local('imdbDir'  =>  "./imdb-data",
                              'listsDir' =>  "./imdb-data/lists",
                              'showProgressBar' => 1);

    for my $type ( $foo->listTypes() ) {
        if ( $foo->importList($type) != 0 ) {
           warn("$type import failed, check $foo->{imdbDir}/stage-$type.log");
        }
    }
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

# Use Term::ProgressBar if installed.
use constant Have_bar => eval {
    require Term::ProgressBar;
    $Term::ProgressBar::VERSION >= 2;
};

use IMDB::Local::DB;
use IMDB::Local::QualifierType ':types';

=head2 new

Create new IMDB::Local object.

Arguments:

   imdbDir - required or die

   verbose - optional, default is 0. 

   listsDir - folder where list files exist (see IMDB::Local::Download).

   showProgressBar - if non-zero and Term::ProgressBar is available progress bars in import methods will be displayed. Ignored if Term::ProgressBar is not available.

=cut

sub new
{
    my ($type) = shift;
    my $self={ @_ };            # remaining args become attributes

    for ('imdbDir', 'verbose') {
	die "invalid usage - no $_" if ( !defined($self->{$_}));
    }
    
    #$self->{stages} = { 1=>'movies', 2=>'directors', 3=>'actors', 4=>'actresses', 5=>'genres', 6=>'ratings', 7=>'keywords', 8=>'plot' };
    #$self->{optionalStages} = { 'keywords' => 7, 'plot' => 8 };     # list of optional stages - no need to download files for these

    $self->{moviedbInfo}="$self->{imdbDir}/moviedb.info";
    $self->{moviedbOffline}="$self->{imdbDir}/moviedb.offline";
    
    if ( defined($self->{listsDir}) ) {
	$self->{listFiles}=new IMDB::Local::ListFiles(listsDir=>$self->{listsDir});
    }
    
    # only leave progress bar on if its available
    if ( !Have_bar ) {
	$self->{showProgressBar}=0;
    }

    bless($self, $type);
    return($self);
}

#sub openDB
#{
#    my ($self)=@_;
#
#    my $DB=new IMDB::Local::DB(database=>"$self->{imdbDir}/imdb.db");
#
#    if ( !$DB->connect() ) {
#	carp "imdbdb connect failed:$DBI::errstr";
#    }
#    $self->{DB}=$DB;
#
#    return($DB);
#}
#
#sub closeDB
#{
#    my ($self)=@_;
#
#    $self->{DB}->disconnect();
#    undef $self->{DB};
#}

=head2 listTypes

Returns an array of list files supported (currently 'movies', 'directors', 'actors', 'actresses', 'genres', 'ratings', 'keywords', 'plot')

=cut

sub listTypes($)
{
    my $self=shift;

    return( $self->{listFiles}->types() );
}


sub error($$)
{
    my $self=shift;
    if ( defined($self->{logfd}) ) {
	print {$self->{logfd}} $_[0]."\n";
	$self->{errorCountInLog}++;
    }
    else {
	print STDERR $_[0]."\n";
    }
}

sub status($$)
{
    my $self=shift;

    if ( $self->{verbose} ) {
	print STDERR $_[0]."\n";
    }
}

sub withThousands ($)
{
    my ($val) = @_;
    $val =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
    return $val;
}

use constant Have_gunzip => eval {
    require IO::Uncompress::Gunzip;
};


sub openMaybeGunzip($)
{
    my ($file)=@_;
    
    if ($file=~m/\.gz$/ ) {
	if ( Have_gunzip ) {
	    return new IO::Uncompress::Gunzip($file);
	}
	else {
	    my $fd;

	    if ( open($fd, "gzip -d < $file |") ) {
		return($fd);
	    }
	    carp("no suitable gzip decompression found");
	}
    }
    else {
	require IO::File;
	return new IO::File("< $file");
    }
}

sub closeMaybeGunzip($$)
{
    my ($file, $fd)=@_;

    if ($file=~m/\.gz$/ ) {
	if ( Have_gunzip ) {
	    $fd->close();
	}
	else {
	    close($fd);
	}
    }
    else {
	$fd->close();
    }
}

sub decodeImdbKey($$$)
{
    my ($self, $DB, $dbkey, $year, $titleID)=@_;
    
    my %hash;
    
    $hash{parentId}=0;
    $hash{series}=0;
    $hash{episode}=0;
    $hash{airdate}=0;
    

    # drop episode information - ex: "Studio One" (1948) {Twelve Angry Men (#7.1)}
    if ( $dbkey=~s/\s*\{([^\}]+)\}//o ) {
	my $s=$1;
	if ( $s=~s/\s*\(\#(\d+)\.(\d+)\)$// ) {
	    $hash{series}=$1;
	    $hash{episode}=$2;
	    $hash{title}=$s;
	    #print "title: $s\n";

	    # attempt to locate parentId matching series title
	    #my $parentKey=$dbkey;
	    #$parentKey=~s/^\"//o;
	    #$parentKey=~s/\" \(/ \(/o;

	    #warn("checkskey $dbkey");
	    #if ( defined($self->{seriesKeys}->{$parentKey}) ) {
	    #$hash{parentId}=$self->{seriesKeys}->{$parentKey};
	    #}
	}
 	# "EastEnders" (1985) {(1991-10-15)}                      1991
	elsif ( $s=~m/^\((\d\d\d\d)\-(\d\d)\-(\d\d)\)$/ ) {
	    $hash{airdate}=int("$1$2$3");
	    $hash{title}=$s;
	}
	else {
	    $hash{title}=$s;
	}

	# attempt to locate parentId matching series title
	my $parentKey=$dbkey;
	$parentKey=~s/^\"//o;
	$parentKey=~s/\" \(/ \(/o;
	
	#warn("checkskey $dbkey");
	if ( defined($self->{seriesKeys}->{$parentKey}) ) {
	    $hash{parentId}=$self->{seriesKeys}->{$parentKey};
	}
    }
    
		
    # change double-quotes around title to be (made-for-tv) suffix instead 
    if ( $dbkey=~s/^\"//o && $dbkey=~s/\" \(/ \(/o) {
	if ( $dbkey=~s/\s+\(mini\)$//o ) {
	    if ( $hash{parentId} == 0 ) {
		$hash{qualifier}=IMDB::Local::QualifierType::TV_MINI_SERIES;
		$self->{seriesKeys}->{$dbkey}=$titleID;
	    }
	    else {
		$hash{qualifier}=IMDB::Local::QualifierType::EPISODE_OF_TV_MINI_SERIES
	    }
	}
	else {
	    if ( $hash{parentId} == 0 ) {
		$hash{qualifier}=IMDB::Local::QualifierType::TV_SERIES;
		$self->{seriesKeys}->{$dbkey}=$titleID;
	    }
	    else {
		$hash{qualifier}=IMDB::Local::QualifierType::EPISODE_OF_TV_SERIES;
	    }
	}
    }
    elsif ( $dbkey=~s/\s+\(TV\)$//o ) {
	# how rude, some entries have (TV) appearing more than once.
	#$dbkey=~s/\s*\(TV\)$//o;
	$hash{qualifier}=IMDB::Local::QualifierType::TV_MOVIE;
    }
    elsif ( $dbkey=~s/\s+\(V\)$//o ) {
	$hash{qualifier}=IMDB::Local::QualifierType::VIDEO_MOVIE;
    }
    elsif ( $dbkey=~s/\s+\(VG\)$//o ) {
	$hash{qualifier}=IMDB::Local::QualifierType::VIDEO_GAME;
    }
    else {
	$hash{qualifier}=IMDB::Local::QualifierType::MOVIE;
    }
    
    #if ( $dbkey=~s/\s+\((tv_series|tv_mini_series|tv_movie|video_movie|video_game)\)$//o ) {
    #   $qualifier=$1;
    #}
    $hash{dbkey}=$dbkey;

    my $title=$dbkey;
	
    # todo - this is the wrong year for episode titles
    if ( $title=~m/^\"/o && $title=~m/\"\s*\(/o ) { #"
	$title=~s/^\"//o; #"
	$title=~s/\"(\s*\()/$1/o; #"
    }
    
    if ( $title=~s/\s+\((\d\d\d\d)\)$//o ||
	 $title=~s/\s+\((\d\d\d\d)\/[IVXL]+\)$//o ) {
	# over-ride with what is given
	if ( !defined($year) ) {
	    $hash{year}=$1;
	}
	else {
	    $hash{year}=$year;
	}
    }
    elsif ( $title=~s/\s+\((\?\?\?\?)\)$//o ||
	    $title=~s/\s+\((\?\?\?\?)\/[IVXL]+\)$//o ) {
	# over-ride with what is given
	if ( !defined($year) ) {
	    $hash{year}=0;
	}
	else {
	    $hash{year}=$year;
	}
    }
    else {
	$self->error("movie list format failed to decode year from title '$title'");
	
	# over-ride with what is given
	if ( ! defined($year) ) {
	    $hash{year}=0;
	}
	else {
	    $hash{year}=$year;
	}
    }
    $title=~s/(.*),\s*(The|A|Une|Las|Les|Los|L\'|Le|La|El|Das|De|Het|Een)$/$2 $1/og;

    # leave searchtitle empty for tv series'
    if( $hash{qualifier} == IMDB::Local::QualifierType::EPISODE_OF_TV_SERIES ||
	$hash{qualifier} == IMDB::Local::QualifierType::EPISODE_OF_TV_MINI_SERIES ) {
	#$hash{title}=$title;
	$hash{searchTitle}=$DB->makeSearchableTitle($hash{title}, 0);;
    }
    else {
	if ( !defined($hash{title}) ) {
	    $hash{title}=$title;
	    $hash{searchTitle}=$DB->makeSearchableTitle($title, 0);

	    # todo - is this more useful ?
	    #$hash{searchTitleWithYear}=MakeSearchtitle($DB, $title."(".$hash{year}.")", 0);
	}
	else {
	    $hash{searchTitle}=$DB->makeSearchableTitle($title, 0);
	    #$hash{searchTitle}=$DB->makeSearchableTitle($title."(".$hash{year}.")", 0);
	    
	    # todo - is this more useful ?
	    #$hash{searchTitleWithYear}=$DB->makeSearchableTitle($title."(".$hash{year}.")", 0);
	}
    }

    return(\%hash);
}

sub importMovies($$$$)
{
    my ($self, $countEstimate, $file, $DB)=@_;
    my $startTime=time();
    my $lineCount=0;

    my $fh = openMaybeGunzip($file) || return(-2);
    while(<$fh>) {
	$lineCount++;
	if ( m/^MOVIES LIST/o ) {
	    if ( !($_=<$fh>) || !m/^===========/o ) {
		$self->error("missing ======= after 'MOVIES LIST' at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^\s*$/o ) {
		$self->error("missing empty line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    last;
	}
	elsif ( $lineCount > 1000 ) {
	    $self->error("$file: stopping at line $lineCount, didn't see \"MOVIES LIST\" line");
	    closeMaybeGunzip($file, $fh);
	    return(-1);
	}
    }

    my $progress=Term::ProgressBar->new({name  => "importing Movies",
					 count => $countEstimate,
					 ETA   => 'linear'})
	if ( $self->{showProgressBar} );

    $progress->minor(0) if ($self->{showProgressBar});
    $progress->max_update_rate(1) if ($self->{showProgressBar});
    my $next_update=0;

    #$DB->runSQL("BEGIN TRANSACTION");

    my $count=0;
    my $tableInsert_sth=$DB->prepare('INSERT INTO Titles (TitleID, SearchTitle, Title, QualifierTypeID, Year, ParentID, Series, Episode, AirDate) VALUES (?,?,?,?,?,?,?,?,?)');

    my $potentialEntries=0;
    
    while(<$fh>) {
	$lineCount++;
	my $line=$_;

	# end is line consisting of only '-'
	last if ( $line=~m/^\-\-\-\-\-\-\-+/o );

	next if ( $line=~m/\{\{SUSPENDED\}\}/o );
	$line=~s/\n$//o;
	
	#next if ( !($line=~m/biography/io) );

	#print "read line $lineCount:$line\n";
	$potentialEntries++;

	my $tab=index($line, "\t");
	if ( $tab != -1 ) {
	    my $ykey=substr($line, $tab+1);
	    if ( $ykey=m/\s+(\d\d\d\d)$/ ) {
		$ykey=$1;
	    }
	    elsif ( $ykey=m/\s+(\?\?\?\?)$/ ) {
		$ykey=undef;
	    }
	    elsif ( $ykey=m/\s+(\d\d\d\d)\-(\?\?\?\?)$/ ) {
		$ykey=$1;
	    }
	    elsif ( $ykey=m/\s+(\d\d\d\d)\-(\d\d\d\d)$/ ) {
		$ykey=$1;
	    }
	    else {
		warn("invalid year ($ykey) - $line");
		#$ykey=undef;
	    }
	    
	    my $mkey=substr($line, 0, $tab);

	    # returned count is number of titles found
	    $count++;

	    my $decoded=$self->decodeImdbKey($DB, $mkey, $ykey, $count);

	    $tableInsert_sth->execute($count,
				      $decoded->{searchTitle},
				      $decoded->{title},
				      $decoded->{qualifier},
				      $decoded->{year},
				      $decoded->{parentId},
				      $decoded->{series},
				      $decoded->{episode},
				      $decoded->{airdate});
	    
	    $self->{imdbMovie2DBKey}->{$mkey}=$count;

	    #if ( ($count % 50000) == 0 ) {
	    #$DB->commit();
	    #}
	    #}
	
	    if ( $self->{showProgressBar} ) {
		# re-adjust target so progress bar doesn't seem too wonky
		if ( $count > $countEstimate ) {
		    $countEstimate = $progress->target($count+1000);
		    $next_update=$progress->update($count);
		}
		elsif ( $count > $next_update ) {
		    $next_update=$progress->update($count);
		}
	    }
	}
	else {
	    $self->error("$file:$lineCount: unrecognized format (missing tab)");
	}
    }
    #$DB->runSQL("END TRANSACTION");

    $progress->update($countEstimate) if ($self->{showProgressBar});

    $self->status(sprintf("importing Movies found ".withThousands($count)." in ".
			  withThousands($potentialEntries)." entries in %d seconds",time()-$startTime));

    closeMaybeGunzip($file, $fh);
    $DB->commit();
    return($count);
}

sub importGenres($$$$)
{
    my ($self, $countEstimate, $file, $DB)=@_;
    my $startTime=time();
    my $lineCount=0;

    my $fh = openMaybeGunzip($file) || return(-2);
    while(<$fh>) {
	$lineCount++;
	if ( m/^8: THE GENRES LIST/o ) {
	    if ( !($_=<$fh>) || !m/^===========/o ) {
		$self->error("missing ======= after 'THE GENRES LIST' at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^\s*$/o ) {
		$self->error("missing empty line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    last;
	}
	elsif ( $lineCount > 1000 ) {
	    $self->error("$file: stopping at line $lineCount, didn't see \"THE GENRES LIST\" line");
	    closeMaybeGunzip($file, $fh);
	    return(-1);
	}
    }

    my $progress=Term::ProgressBar->new({name  => "importing Genres",
					 count => $countEstimate,
					 ETA   => 'linear'})
	if ( $self->{showProgressBar} );

    $progress->minor(0) if ($self->{showProgressBar});
    $progress->max_update_rate(1) if ($self->{showProgressBar});
    my $next_update=0;

    #$DB->runSQL("BEGIN TRANSACTION");

    my $count=0;
    my $potentialEntries=0;
    my $tableInsert_sth=$DB->prepare('INSERT INTO Titles2Genres (TitleID, GenreID) VALUES (?,?)');

    while(<$fh>) {
	$lineCount++;
	my $line=$_;
	#print "read line $lineCount:$line\n";

	# end is line consisting of only '-'
	last if ( $line=~m/^\-\-\-\-\-\-\-+/o );
	next if ( $line=~m/\s*\{\{SUSPENDED\}\}/o);

	$potentialEntries++;

	$line=~s/\n$//o;

	my $tab=index($line, "\t");
	if ( $tab != -1 ) {
	    my $mkey=substr($line, 0, $tab);

	    # ignore {Twelve Angry Men (1954)}
	    # TODO - do we want this ?
	    #$mkey=~s/\s*\{[^\}]+\}//go;
	    
	    # skip enties that have {} in them since they're tv episodes
	    #next if ( $mkey=~s/\s*\{[^\}]+\}$//o );
	    
	    my $genre=substr($line, $tab);
	    
	    # genres sometimes has more than one tab
	    $genre=~s/^\t+//og;
	    
	    if ( $self->{imdbMovie2DBKey}->{$mkey} ) {
		# insert into db as discovered
		if ( ! defined($self->{GenreID}->{$genre}) ) {
		    $self->{GenreID}->{$genre}=$DB->insert_row('Genres', 'GenreID', Name=>$genre);
		}
		$tableInsert_sth->execute($self->{imdbMovie2DBKey}->{$mkey},
					  $self->{GenreID}->{$genre});
		
		# returned count is number of titles found
		$count++;
		
		if ( ($count % 50000) ==0 ) {
		    $DB->commit();
		}
	    }
	
	    if ( $self->{showProgressBar} ) {
		# re-adjust target so progress bar doesn't seem too wonky
		if ( $count > $countEstimate ) {
		    $countEstimate = $progress->target($count+1000);
		    $next_update=$progress->update($count);
		}
		elsif ( $count > $next_update ) {
		    $next_update=$progress->update($count);
		}
	    }
	}
	else {
	    $self->error("$file:$lineCount: unrecognized format (missing tab)");
	}
    }
    #$DB->runSQL("END TRANSACTION");

    $progress->update($countEstimate) if ($self->{showProgressBar});

    $self->status(sprintf("importing Genres found ".withThousands($count)." in ".
			  withThousands($potentialEntries)." entries in %d seconds",time()-$startTime));

    closeMaybeGunzip($file, $fh);
    $DB->commit();
    return($count);
}

sub importActors($$$$)
{
    my ($self, $whichCastType, $castCountEstimate, $file, $DB)=@_;
    my $startTime=time();

    if ( $whichCastType eq "Actors" ) {
	if ( $DB->table_row_count('Actors') > 0 ||
	     $DB->table_row_count('Titles2Actors') > 0 ||
	     $DB->table_row_count('Titles2Hosts') > 0 ||
	     $DB->table_row_count('Titles2Narrators') > 0 ) {
	    $self->status("clearing previously loaded data..");
	    $DB->table_clear('Actors');
	    $DB->table_clear('Titles2Actors');
	    $DB->table_clear('Titles2Hosts');
	    $DB->table_clear('Titles2Narrators');
	}
    }

    my $header;
    my $whatAreWeParsing;
    my $lineCount=0;

    if ( $whichCastType eq "Actors" ) {
	$header="THE ACTORS LIST";
	$whatAreWeParsing=1;
    }
    elsif ( $whichCastType eq "Actresses" ) {
	$header="THE ACTRESSES LIST";
	$whatAreWeParsing=2;
    }
    else {
	die "why are we here ?";
    }

    my $fh = openMaybeGunzip($file) || return(-2);
    my $progress=Term::ProgressBar->new({name  => "importing $whichCastType",
					 count => $castCountEstimate,
					 ETA   => 'linear'})
      if ($self->{showProgressBar});
    $progress->minor(0) if ($self->{showProgressBar});
    $progress->max_update_rate(1) if ($self->{showProgressBar});
    my $next_update=0;
    
    while(<$fh>) {
	$lineCount++;
	if ( m/^$header/ ) {
	    if ( !($_=<$fh>) || !m/^===========/o ) {
		$self->error("missing ======= after $header at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^\s*$/o ) {
		$self->error("missing empty line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^Name\s+Titles\s*$/o ) {
		$self->error("missing name/titles line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^[\s\-]+$/o ) {
		$self->error("missing name/titles suffix line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    last;
	}
	elsif ( $lineCount > 1000 ) {
	    $self->error("$file: stopping at line $lineCount, didn't see \"$header\" line");
	    closeMaybeGunzip($file, $fh);
	    return(-1);
	}
    }

    my $cur_name;
    my $count=0;
    my $castNames=0;
    my $tableInsert_sth1=$DB->prepare('INSERT INTO Actors           (ActorID, SearchName, Name) VALUES (?,?,?)');
    my $tableInsert_sth2=$DB->prepare('INSERT INTO Titles2Hosts     (TitleID, ActorID) VALUES (?,?)');
    my $tableInsert_sth3=$DB->prepare('INSERT INTO Titles2Narrators (TitleID, ActorID) VALUES (?,?)');
    my $tableInsert_sth4=$DB->prepare('INSERT INTO Titles2Actors    (TitleID, ActorID, Billing) VALUES (?,?,?)');
    
    my $cur_actorId=$DB->select2Scalar('Select MAX(ActorID) from Actors');
    if ( !defined($cur_actorId) ) {
	$cur_actorId=0;
    }

    my $potentialEntries=0;
    while(<$fh>) {
	$lineCount++;
	my $line=$_;
	$line=~s/\n$//o;
	#$self->status("read line $lineCount:$line");

	# end is line consisting of only '-'
	last if ( $line=~m/^\-\-\-\-\-\-\-+/o );
	
	next if ( length($line) == 0 );

	# try ignoring these
	next if ($line=~m/\s*\{\{SUSPENDED\}\}/o);

	$potentialEntries++;
	my $billing=9999;
	
	# actors or actresses
	if ( $line=~s/\s*<(\d+)>//o ) {
	    $billing=int($1);
	    next if ( $billing >3 );
	}
	
	if ( $line=~s/^([^\t]+)\t+//o ) {
	    $cur_name=$1;
	    $castNames++;

	    $cur_actorId++;

	    my $c=$cur_name;
	    $c=~s/\s*\([IVXL]+\)//o;
	    $tableInsert_sth1->execute($cur_actorId, $DB->makeSearchableTitle($c, 0), $cur_name);

	    if ( $self->{showProgressBar} ) {
		# re-adjust target so progress bar doesn't seem too wonky
		if ( $castNames > $castCountEstimate ) {
		    $castCountEstimate = $progress->target($castNames+100);
		    $next_update=$progress->update($castNames);
		}
		elsif ( $castNames > $next_update ) {
		    $next_update=$progress->update($castNames);
		}
	    }
	}
	
	my $isHost=0;
	my $isNarrator=0;
	if ( (my $start=index($line, " [")) != -1 ) {
	    #my $end=rindex($line, "]");
	    my $ex=substr($line, $start+1);
	    
	    if ( $ex=~s/Host//o ) {
		$isHost=1;
	    }
	    if ( $ex=~s/Narrator//o ) {
		$isNarrator=1;
	    }
	    $line=substr($line, 0, $start);
	    # ignore character name
	}
	
	# TODO - do we want to just ignore these ?
	if ( $line=~s/\s*\(aka ([^\)]+)\).*$//o ) {
	    #$attrs=$1;
	}
	
	# TODO - what are we ignoring here ?
	if ( $line=~s/  (\(.*)$//o ) {
	    #$attrs=$1;
	}
	$line=~s/^\s+//og;
	$line=~s/\s+$//og;

	# TODO - does this exist ?
	if ( $line=~s/\s+Narrator$//o ) {
	    $self->error("extra narrator on line: $lineCount");
	    # TODO - do we want to store this ? Does it actually occur ?
	    # ignore
	}

	#if ( $line=~s/\s*\([A-Z]+\)$//o ) {
	#}

	my $titleID=$self->{imdbMovie2DBKey}->{$line};
	if ( $titleID ) {
	    if ( $isHost ) {
		$tableInsert_sth2->execute($titleID, $cur_actorId);
	    }
	    if ( $isNarrator ) {
		$tableInsert_sth3->execute($titleID, $cur_actorId);
	    }
	    if ( !$isHost && !$isNarrator ) {
		$tableInsert_sth4->execute($titleID, $cur_actorId, $billing);
	    }
	    
	    $count++;
	    if ( ($count % 50000) == 0 ) {
		$DB->commit();
	    }
	}
	else {
	    #warn($line);
	}
    }
    $progress->update($castCountEstimate) if ($self->{showProgressBar});

    $self->status(sprintf("importing $whichCastType found ".withThousands($castNames)." names, ".
			  withThousands($count)." titles in ".withThousands($potentialEntries)." entries in %d seconds",time()-$startTime));
    
    closeMaybeGunzip($file, $fh);

    $DB->commit();
    return($castNames);
}

sub importDirectors($$$)
{
    my ($self, $castCountEstimate, $file, $DB)=@_;
    my $startTime=time();

    my $lineCount=0;

    if ( $DB->table_row_count('Directors') > 0 ||
	 $DB->table_row_count('Titles2Directors') > 0 ) {
	$self->status("clearing previously loaded data..");
	$DB->table_clear('Directors');
	$DB->table_clear('Titles2Directors');
    }

    my $fh = openMaybeGunzip($file) || return(-2);
    my $progress=Term::ProgressBar->new({name  => "importing Directors",
					 count => $castCountEstimate,
					 ETA   => 'linear'})
      if ($self->{showProgressBar});
    $progress->minor(0) if ($self->{showProgressBar});
    $progress->max_update_rate(1) if ($self->{showProgressBar});
    my $next_update=0;
    while(<$fh>) {
	$lineCount++;
	if ( m/^THE DIRECTORS LIST/ ) {
	    if ( !($_=<$fh>) || !m/^===========/o ) {
		$self->error("missing ======= after THE DIRECTORS LIST at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^\s*$/o ) {
		$self->error("missing empty line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^Name\s+Titles\s*$/o ) {
		$self->error("missing name/titles line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^[\s\-]+$/o ) {
		$self->error("missing name/titles suffix line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    last;
	}
	elsif ( $lineCount > 1000 ) {
	    $self->error("$file: stopping at line $lineCount, didn't see \"THE DIRECTORS LIST\" line");
	    closeMaybeGunzip($file, $fh);
	    return(-1);
	}
    }

    my $cur_name;
    my $count=0;
    my $castNames=0;
    my %found;
    my $directorCount=0;
    my $potentialEntries=0;

    my $tableInsert_sth=$DB->prepare('INSERT INTO Directors (DirectorID, SearchName, Name) VALUES (?,?,?)');
    my $tableInsert_sth2=$DB->prepare('INSERT INTO Titles2Directors (TitleID, DirectorID) VALUES (?,?)');
    while(<$fh>) {
	$lineCount++;
	
	#last if ( $lineCount > 10000);
	my $line=$_;
	$line=~s/\n$//o;
	#$self->status("read line $lineCount:$line");

	# end is line consisting of only '-'
	last if ( $line=~m/^\-\-\-\-\-\-\-+/o );
	next if ( length($line) == 0 );
	
	# try ignoring these
	next if ($line=~m/\s*\{\{SUSPENDED\}\}/o);
	
	$potentialEntries++;
	
	if ( $line=~s/^([^\t]+)\t+//o ) {
	    $cur_name=$1;
	    $castNames++;

	    if ( $self->{showProgressBar} ) {
		# re-adjust target so progress bar doesn't seem too wonky
		if ( $castNames > $castCountEstimate ) {
		    $castCountEstimate = $progress->target($castNames+100);
		    $next_update=$progress->update($castNames);
		}
		elsif ( $castNames > $next_update ) {
		    $next_update=$progress->update($castNames);
		}
	    }
	}
	
	# BUG
	# ##ignore {Twelve Angry Men (1954)}
	#$line=~s/\s*\{[^\}]+\}//o;

	# sometimes there are extra bits of info attached at the end of lines, we'll ignore these
	#
	# examples:
	# Deszcz (1997)  (as Tomasz Baginski)
	# Adventures of Modest Mouse (2008)  (co-director)
	# Vida (2010)  (collaborating director)
	# Rex Harrison Presents Stories of Love (1974) (TV)  (segment "Epicac")
	if ( $line=~s/  (\(.*)$//o ) {
	    # $attrs=$1;
	}
	
	$line=~s/^\s+//og;
	$line=~s/\s+$//og;

	if ( $self->{imdbMovie2DBKey}->{$line} ) {

	    if ( !defined($found{$cur_name}) ) {
		$directorCount++;
		$found{$cur_name}=$directorCount;

		my $c=$cur_name;
		$c=~s/\s*\([IVXL]+\)//o;
		$tableInsert_sth->execute($directorCount, $DB->makeSearchableTitle($c, 0), $cur_name);
	    }

	    $tableInsert_sth2->execute($self->{imdbMovie2DBKey}->{$line}, $found{$cur_name});
	    $count++;
	    if ( ($count % 50000) == 0 ) {
		$DB->commit();
	    }
	}
	else {
	    $self->error("$lineCount: unable to match title key '$line'");
	}
    }
    $progress->update($castCountEstimate) if ($self->{showProgressBar});

    $self->status(sprintf("importing Directors found ".withThousands($castNames)." names, ".
			  withThousands($count)." titles in ".withThousands($potentialEntries)." entries in %d seconds",time()-$startTime));
    
    closeMaybeGunzip($file, $fh);

    $DB->commit();
    return($castNames);
}

sub importRatings($$)
{
    my ($self, $countEstimate, $file, $DB)=@_;
    my $startTime=time();
    my $lineCount=0;

    if ( $DB->table_row_count('Ratings') > 0 ) {
	$self->status("clearing previously loaded data..");
	$DB->table_clear('Ratings');
    }

    my $fh = openMaybeGunzip($file) || return(-2);
    while(<$fh>) {
	$lineCount++;
	if ( m/^MOVIE RATINGS REPORT/o ) {
	    if ( !($_=<$fh>) || !m/^\s*$/o) {
		$self->error("missing empty line after \"MOVIE RATINGS REPORT\" at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^New  Distribution  Votes  Rank  Title/o ) {
		$self->error("missing \"New  Distribution  Votes  Rank  Title\" at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    last;
	}
	elsif ( $lineCount > 1000 ) {
	    $self->error("$file: stopping at line $lineCount, didn't see \"MOVIE RATINGS REPORT\" line");
	    closeMaybeGunzip($file, $fh);
	    return(-1);
	}
    }

    my $progress=Term::ProgressBar->new({name  => "importing Ratings",
					 count => $countEstimate,
					 ETA   => 'linear'})
      if ($self->{showProgressBar});

    $progress->minor(0) if ($self->{showProgressBar});
    $progress->max_update_rate(1) if ($self->{showProgressBar});
    my $next_update=0;

    my $countImported=0;
    my $count=0;
    my $potentialEntries=0;
    my $tableInsert_sth=$DB->prepare('INSERT INTO Ratings (TitleID, Distribution, Votes, Rank) VALUES (?,?,?,?)');
    while(<$fh>) {
	$lineCount++;
	my $line=$_;
	#print "read line $lineCount:$line";

	$line=~s/\n$//o;
	
	# skip empty lines (only really appear right before last line ending with ----
	next if ( $line=~m/^\s*$/o );
	# end is line consisting of only '-'
	last if ( $line=~m/^\-\-\-\-\-\-\-+/o );

	$potentialEntries++;
	    
        # e.g. New  Distribution  Votes  Rank  Title
        #            0000000133  225568   8.9  12 Angry Men (1957)
	if ( $line=~m/^\s+([\.|\*|\d]+)\s+(\d+)\s+(\d+\.\d+)\s+(.+)$/o ) {

	    if ( $self->{imdbMovie2DBKey}->{$4} ) {
		$tableInsert_sth->execute($self->{imdbMovie2DBKey}->{$4}, $1, $2, $3);
		$countImported++;
		if ( ($countImported % 50000) == 0 ) {
		    $DB->commit();
		}
	    }
	    
	    $count++;

	    #$self->{movies}{$line}=[$1,$2,"$3.$4"];
	    if ( $self->{showProgressBar} ) {
		# re-adjust target so progress bar doesn't seem too wonky
		if ( $count > $countEstimate ) {
		    $countEstimate = $progress->target($count+1000);
		    $next_update=$progress->update($count);
		}
		elsif ( $count > $next_update ) {
		    $next_update=$progress->update($count);
		}
	    }
	}
	else {
	    $self->error("$file:$lineCount: unrecognized format");
	}
    }
    $progress->update($countEstimate) if ($self->{showProgressBar});

    $self->status(sprintf("importing Ratings found ".withThousands($count)." in ".
			  withThousands($potentialEntries)." entries in %d seconds",time()-$startTime));
    
    closeMaybeGunzip($file, $fh);
    
    $DB->commit();
    return($count);
}

sub importKeywords($$$$)
{
    my ($self, $countEstimate, $file, $DB)=@_;
    my $startTime=time();
    my $lineCount=0;

    if ( $DB->table_row_count('Keywords') > 0 ) {
	$self->status("clearing previously loaded data..");
	$DB->table_clear('Keywords');
    }

    my $fh = openMaybeGunzip($file) || return(-2);
    while(<$fh>) {
	$lineCount++;

	if ( m/THE KEYWORDS LIST/ ) {
	    if ( !($_=<$fh>) || !m/^===========/o ) {
		$self->error("missing ======= after \"THE KEYWORDS LIST\" at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^\s*$/o ) {
		$self->error("missing empty line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    last;
	}
	elsif ( $lineCount > 200000 ) {
	    $self->error("$file: stopping at line $lineCount, didn't see \"THE KEYWORDS LIST\" line");
	    closeMaybeGunzip($file, $fh);
	    return(-1);
	}
    }

    my $progress=Term::ProgressBar->new({name  => "importing Keywords",
					 count => $countEstimate,
					 ETA   => 'linear'})
      if ($self->{showProgressBar});

    $progress->minor(0) if ($self->{showProgressBar});
    $progress->max_update_rate(1) if ($self->{showProgressBar});
    my $next_update=0;

    my $count=0;
    my $countImported=0;
    my %found;
    my $tableInsert_sth1=$DB->prepare('INSERT INTO Keywords (KeywordID, Name) VALUES (?,?)');
    my $tableInsert_sth2=$DB->prepare('INSERT INTO Titles2Keywords (TitleID, KeywordID) VALUES (?,?)');
    my $keywordCount=0;
    my $potentialEntries=0;
    
    while(<$fh>) {
	$lineCount++;
	my $line=$_;
	chomp($line);
	next if ($line =~ m/^\s*$/);
	
	$potentialEntries++;
	
	my ($title, $keyword) = ($line =~ m/^(.*)\s+(\S+)\s*$/);
	if ( defined($title) and defined($keyword) ) {

            my ($episode) = $title =~ m/\s+(\{.*\})$/o;
            
	    if ( $self->{imdbMovie2DBKey}->{$title} ) {
		if ( !defined($found{$keyword}) ) {
		    $keywordCount++;
		    
		    $found{$keyword}=$keywordCount;
		    $tableInsert_sth1->execute($keywordCount, $keyword);
		    #=$DB->insert_row('Keywords', 'KeywordID', Name=>$keyword);
		}
		$tableInsert_sth2->execute($self->{imdbMovie2DBKey}->{$title}, $found{$keyword});
		
		#$DB->insert_row('Titles2Keywords', undef, TitleID=>$self->{imdbMovie2DBKey}->{$title}, KeywordID=>$found{$keyword});
		$countImported++;
		if ( ($countImported % 50000) == 0 ) {
		    $DB->commit();
		}
	    }
	    $count++;
	    if ( $self->{showProgressBar} ) {
		# re-adjust target so progress bar doesn't seem too wonky
		if ( $count > $countEstimate ) {
		    $countEstimate = $progress->target($count+1000);
		    $next_update=$progress->update($count);
		}
		elsif ( $count > $next_update ) {
		    $next_update=$progress->update($count);
		}
	    }
        } else {
	    $self->error("$file:$lineCount: unrecognized format \"$line\"");
	}
	
    }
    $progress->update($countEstimate) if ($self->{showProgressBar});

    $self->status(sprintf("importing Keywords found ".withThousands($count)." in ".
			  withThousands($potentialEntries)." entries in %d seconds",time()-$startTime));

    closeMaybeGunzip($file, $fh);
    $DB->commit();
    return($count);
}

sub importPlots($$$$)
{
    my ($self, $countEstimate, $file, $DB)=@_;
    my $startTime=time();
    my $lineCount=0;

    if ( $DB->table_row_count('Plots') > 0 ) {
	$self->status("clearing previously loaded data..");
	$DB->table_clear('Plots');
    }

    my $fh = openMaybeGunzip($file) || return(-2);
    while(<$fh>) {
	$lineCount++;

	if ( m/PLOT SUMMARIES LIST/ ) {
	    if ( !($_=<$fh>) || !m/^===========/o ) {
		$self->error("missing ======= after \"PLOT SUMMARIES LIST\" at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    if ( !($_=<$fh>) || !m/^-----------/o ) {
		$self->error("missing ------- line after ======= at line $lineCount");
		closeMaybeGunzip($file, $fh);
		return(-1);
	    }
	    last;
	}
	elsif ( $lineCount > 500 ) {
	    $self->error("$file: stopping at line $lineCount, didn't see \"PLOT SUMMARIES LIST\" line");
	    closeMaybeGunzip($file, $fh);
	    return(-1);
	}
    }

    my $progress=Term::ProgressBar->new({name  => "importing Plots",
					 count => $countEstimate,
					 ETA   => 'linear'})
      if ($self->{showProgressBar});

    $progress->minor(0) if ($self->{showProgressBar});
    $progress->max_update_rate(1) if ($self->{showProgressBar});
    my $next_update=0;

    my $count=0;
    my $potentialEntries=0;
    my $tableInsert_sth=$DB->prepare('INSERT INTO Plots (TitleID, Sequence, Description, Author) VALUES (?,?,?,?)');
    while(<$fh>) {
	$lineCount++;
	my $line=$_;
	chomp($line);
	next if ($line =~ m/^\s*$/);
	next if ($line=~m/\s*\{\{SUSPENDED\}\}/o);
	
	$potentialEntries++;

	my ($title, $episode) = ($line =~ m/^MV:\s(.*?)\s?(\{.*\})?$/);
	if ( defined($title) ) {
            
	    $line =~s/^MV:\s*//;

	    my $sequence=1;
	    my $plot = '';

	    while ( my $l = <$fh> ) {
		$lineCount++;
		chomp($l);
		
		next if ($l =~ m/^\s*$/);
		
		if ( $l =~ m/PL:\s(.*)$/ ) {     # plot summary is a number of lines starting "PL:"
		    $plot .= ($plot ne '' ?' ':'') . $1;
		}

		if ( $l =~ m/BY:\s(.*)$/ || $l =~ m/^(\-\-\-\-\-\-\-\-)/o ) {
		    my $token=$1;
		    my $author=$1;
		    
		    if ( $token eq "\-\-\-\-\-\-\-\-" ) {
			if ( $plot eq '' ) {
			    last;
			}
			$author='';
		    }
		    
		    if ( $self->{imdbMovie2DBKey}->{$line} ) {
			$tableInsert_sth->execute($self->{imdbMovie2DBKey}->{$line}, $sequence, $plot, $author);
			
			$count++;
			if ( ($count % 50000) == 0 ) {
			    $DB->commit();
			}
		    } 
		    else {
			$self->error("$lineCount: unable to match title key '$line'");
		    }
		    
		    $plot='';
		    $sequence++;

		    if ( $token eq "\-\-\-\-\-\-\-\-" ) {
			last;
		    }
		}
	    }

	    if ( length($plot) ) {
		$self->error("$lineCount: truncated plot with title key '$line'");
	    }
	    
	    if ( $self->{showProgressBar} ) {
		# re-adjust target so progress bar doesn't seem too wonky
		if ( $count > $countEstimate ) {
		    $countEstimate = $progress->target($count+1000);
		    $next_update=$progress->update($count);
		}
		elsif ( $count > $next_update ) {
		    $next_update=$progress->update($count);
		}
	    }
        } else {
            # skip lines up to the next "MV:"
            if ($line !~ m/^(---|PL:|BY:)/ ) {
                $self->error("$file:$lineCount: unrecognized format \"$line\"");
            }
	    #$next_update=$progress->update($count) if ($self->{showProgressBar});
	    if ( $count > $next_update ) {
		if ($self->{showProgressBar}) {
		    $next_update=$progress->update($count) ;
		    warn "next $count -> $next_update";
		}
	    }
	}
    }
    $progress->update($countEstimate) if ($self->{showProgressBar});

    $self->status(sprintf("importing Plots found ".withThousands($count)." in ".
			  withThousands($potentialEntries)." entries in %d seconds",time()-$startTime));

    closeMaybeGunzip($file, $fh);
    $DB->commit();
    return($count);
}

sub loadDBInfo($)
{
    my $file=shift;
    my $info;

    open(INFO, "< $file") || return("imdbDir index file \"$file\":$!");
    while(<INFO>) {
	chop();
	if ( s/^([^:]+)://o ) {
	    $info->{$1}=$_;
	}
    }
    close(INFO);
    return($info);
}

sub dbinfoLoad($)
{
    my $self=shift;

    my $info=loadDBInfo($self->{moviedbInfo});
    if ( ref $info ne 'HASH' ) {
	return(1);
    }
    $self->{dbinfo}=$info;
    return(undef);
}

sub dbinfoAdd($$$)
{
    my ($self, $key, $value)=@_;
    $self->{dbinfo}->{$key}=$value;
}

sub dbinfoGet($$$)
{
    my ($self, $key, $defaultValue)=@_;
    if ( defined($self->{dbinfo}->{$key}) ) {
	return($self->{dbinfo}->{$key});
    }
    return($defaultValue);
}

sub dbinfoSave($)
{
    my $self=shift;
    open(INFO, "> $self->{moviedbInfo}") || return(1);
    for (sort keys %{$self->{dbinfo}}) {
	print INFO "".$_.":".$self->{dbinfo}->{$_}."\n";
    }
    close(INFO);
    return(0);
}

sub dbinfoGetFileSize($$)
{
    my ($self, $key)=@_;
    

    if ( !defined($self->{listFiles}->paths_isset($key) ) ) {
	die ("invalid call for $key");
    }
    my $filePath=$self->{listFiles}->paths_index($key);
    if ( ! -f $filePath ) {
	return(0);
    }

    my $fileSize=int(-s $filePath);

    # if compressed, then attempt to run gzip -l
    if ( $filePath=~m/.gz$/) {
	if ( open(my $fd, "gzip -l $filePath |") ) {
	    # if parse fails, then defalt to wild ass guess of compression of 65%
	    $fileSize=int(($fileSize*100)/(100-65));

	    while(<$fd>) {
		if ( m/^\s*\d+\s+(\d+)/ ) {
		    $fileSize=$1;
		}
	    }
	    close($fd);
	}
	else {
	    # wild ass guess of compression of 65%
	    $fileSize=int(($fileSize*100)/(100-65));
	}
    }
    return($fileSize);
}

sub _redirect($$)
{
    my ($self, $file)=@_;
    
    if ( defined($file) ) {
	if ( !open($self->{logfd}, "> $file") ) {
	    print STDERR "$file:$!\n";
	    return(0);
	}
	$self->{errorCountInLog}=0;
    }
    else {
	close($self->{logfd});
	$self->{logfd}=undef;
    }
    return(1);
}

=head2 importListComplete

Check to see if spcified list file has been successfully imported

=cut

sub importListComplete($)
{
    my ($self, $type)=@_;

    if ( -f "$self->{imdbDir}/stage-$type.log" ) {
	return(1);
    }
    return(0);
}

sub _prepStage
{
    my ($self, $type)=@_;
    
    my $DB=new IMDB::Local::DB(database=>"$self->{imdbDir}/imdb.db");

    # if we're restarting, lets start fresh
    if ( $type eq 'movies' ) {
	#warn("recreating db ".$DB->database());
	$DB->delete();

	for my $type ( $self->listTypes() ) {
	    unlink("$self->{imdbDir}/stage-$type.log");
	}

    }
    
    if ( !$self->_redirect(sprintf("%s/stage-$type.log", $self->{imdbDir})) ) {
	return(1);
    }
   
    if ( !$DB->connect() ) {
	die "imdbdb connect failed:$DBI::errstr";
    }

    $DB->runSQL("PRAGMA synchronous = OFF");
    return($DB);

}

sub _unprepStage
{
    my ($self, $db)=@_;
    
    $db->commit();
    $db->disconnect();

    $self->_redirect(undef);
}

sub _importListFile($$$)
{
    my ($self, $DB, $type)=@_;


    if ( !grep(/^$type$/, $self->listTypes()) ) {
	die "invalid type $type";
    }
    
    my $dbinfoCalcEstimate=sub {
	my ($self, $key)=@_;
	
	my %estimateSizePerEntry=(movies=>47,
				  directors=>258,
				  actors=>695,
				  actresses=>779,
				  genres=>38,
				  ratings=>68,
				  keywords=>47,
				  plot=>731);
	my $fileSize=$self->dbinfoGetFileSize($key);
	
	my $countEstimate=int($fileSize/$estimateSizePerEntry{$key});
	
	my $filePath=$self->{listFiles}->paths_index($key);
	
	$self->dbinfoAdd($key."_list_file", $filePath);
	$self->dbinfoAdd($key."_list_file_size", "".int(-s $filePath));
	$self->dbinfoAdd($key."_list_file_size_uncompressed", $fileSize);
	$self->dbinfoAdd($key."_list_count_estimate", $countEstimate);
	return($countEstimate);
    };

    my $dbinfoCalcBytesPerEntry = sub {
	my ($self, $key, $calcActualForThisNumber)=@_;
	my $fileSize=$self->dbinfoGetFileSize($key);
	return(int($fileSize/$calcActualForThisNumber));
    };


    if ( ! -f $self->{listFiles}->paths_index($type) ) {
	$self->status("no $type file available");
	return(1);
    }

    if ( $type eq 'movies') {

	$DB->drop_table_indexes('Titles');
	
	my $countEstimate=&$dbinfoCalcEstimate($self, "movies");

	my $num=$self->importMovies($countEstimate, $self->{listFiles}->paths_index('movies'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('movies')." from ftp.imdb.com");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.10 ) {
	    my $better=&$dbinfoCalcBytesPerEntry($self, "movies", $num);
	    $self->status("ARG estimate of $countEstimate for movies needs updating, found $num ($better bytes/entry)");
	}

	open(OUT, "> $self->{imdbDir}/titles.tsv") || die "$self->{imdbDir}/titles.tsv:$!";
	for my $mkey (sort keys %{$self->{imdbMovie2DBKey}}) {
	    print OUT "".$self->{imdbMovie2DBKey}->{$mkey}."\t".$mkey."\n";
	}
	close(OUT);

	$self->dbinfoAdd("db_stat_movie_count", "$num");

	$self->status("Creating Table indexes..");
	$DB->create_table_indexes('Titles');

	return(0);
    }

    # read in keys so we have them for follow-up stages
    if ( !defined($self->{imdbMovie2DBKey}) ) {
	#$self->{imdbMovie2DBKey}=$DB->select2Hash("select IMDBKey, TitleID from Titles");
	
	if ( 1 ) {
	    open(IN, "< $self->{imdbDir}/titles.tsv") || die "$self->{imdbDir}/titles.tsv:$!";
	    while (<IN>) {
		chomp();
		if ( m/^(\d+)\t(.+)/o ) {
		    $self->{imdbMovie2DBKey}->{$2}=$1;
		}
	    }
	    close(IN);
	}
    }

    # need to read-movie kesy
    if ( $type eq 'directors') {

	$DB->drop_table_indexes('Directors');
	
	my $countEstimate=&$dbinfoCalcEstimate($self, "directors");

	my $num=$self->importDirectors($countEstimate, $self->{listFiles}->paths_index('directors'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('directors')." from ftp.imdb.com (see http://www.imdb.com/interfaces)");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.10 ) {
	    my $better=&$dbinfoCalcBytesPerEntry($self, "directors", $num);
	    $self->status("ARG estimate of $countEstimate for directors needs updating, found $num ($better bytes/entry)");
	}
	$self->dbinfoAdd("db_stat_director_count", "$num");
	
	$self->status("Creating Table indexes..");
	$DB->create_table_indexes('Directors');

	return(0);
    }

    if ( $type eq 'actors') {
	$DB->drop_table_indexes('Actors');

	#print "re-reading movies into memory for reverse lookup..\n";
	my $countEstimate=&$dbinfoCalcEstimate($self, "actors");

	#my $num=$self->readCast("Actors", $countEstimate, "$self->{imdbListFiles}->{actors}");
	my $num=$self->importActors("Actors", $countEstimate, $self->{listFiles}->paths_index('actors'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('actors')." from ftp.imdb.com (see http://www.imdb.com/interfaces)");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.10 ) {
	    my $better=&$dbinfoCalcBytesPerEntry($self, "actors", $num);
	    $self->status("ARG estimate of $countEstimate for actors needs updating, found $num ($better bytes/entry)");
	}
	$self->dbinfoAdd("db_stat_actor_count", "$num");
	return(0);
    }
    
    if ( $type eq 'actresses') {

	my $countEstimate=&$dbinfoCalcEstimate($self, "actresses");
	my $num=$self->importActors("Actresses", $countEstimate, $self->{listFiles}->paths_index('actresses'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('actresses')." from ftp.imdb.com (see http://www.imdb.com/interfaces)");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.10 ) {
	    my $better=&$dbinfoCalcBytesPerEntry($self, "actresses", $num);
	    $self->status("ARG estimate of $countEstimate for actresses needs updating, found $num ($better bytes/entry)");
	}
	$self->dbinfoAdd("db_stat_actress_count", "$num");
	
	$self->status("Creating Table indexes..");
	$DB->create_table_indexes('Actors');
	
	return(0);
    }
    
    if ( $type eq 'genres') {
	$DB->drop_table_indexes('Genres');
	
	my $countEstimate=&$dbinfoCalcEstimate($self, "genres");

	my $num=$self->importGenres($countEstimate, $self->{listFiles}->paths_index('genres'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('genres')." from ftp.imdb.com");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.10 ) {
	    my $better=&$dbinfoCalcBytesPerEntry($self, "genres", $num);
	    $self->status("ARG estimate of $countEstimate for genres needs updating, found $num ($better bytes/entry)");
	}
	$self->dbinfoAdd("db_stat_genres_count", "$num");
	
	$self->status("Creating Table indexes..");
	$DB->create_table_indexes('Genres');

	return(0);
    }
    
    if ( $type eq 'ratings') {
	$DB->drop_table_indexes('Ratings');
	
	my $countEstimate=&$dbinfoCalcEstimate($self, "ratings");

	my $num=$self->importRatings($countEstimate, $self->{listFiles}->paths_index('ratings'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('ratings')." from ftp.imdb.com");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.10 ) {
	    my $better=&$dbinfoCalcBytesPerEntry($self, "ratings", $num);
	    $self->status("ARG estimate of $countEstimate for ratings needs updating, found $num ($better bytes/entry)");
	}
	$self->dbinfoAdd("db_stat_ratings_count", "$num");

	$self->status("Creating Table indexes..");
	$DB->create_table_indexes('Ratings');

	return(0);
    }
    
    if ( $type eq 'keywords') {
	$DB->drop_table_indexes('Keywords');
	
	my $countEstimate=&$dbinfoCalcEstimate($self, "keywords");
	#my $countEstimate=5554178;

	my $num=$self->importKeywords($countEstimate, $self->{listFiles}->paths_index('keywords'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('keywords')." from ftp.imdb.com");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.05 ) {
	    $self->status("ARG estimate of $countEstimate for keywords needs updating, found $num");
	}
	$self->dbinfoAdd("keywords_list_file",         $self->{listFiles}->paths_index('keywords'));
	$self->dbinfoAdd("keywords_list_file_size", -s $self->{listFiles}->paths_index('keywords'));
	$self->dbinfoAdd("db_stat_keywords_count", "$num");

	$self->status("Creating Table indexes..");
	$DB->create_table_indexes('Keywords');

	return(0);
    }

    if ( $type eq 'plot') {
	$DB->drop_table_indexes('Plots');
	
	my $countEstimate=&$dbinfoCalcEstimate($self, "plot");
	my $num=$self->importPlots($countEstimate, $self->{listFiles}->paths_index('plot'), $DB);
	if ( $num < 0 ) {
	    if ( $num == -2 ) {
		$self->error("you need to download ".$self->{listFiles}->paths_index('plot')." from ftp.imdb.com");
	    }
	    return(1);
	}
	elsif ( abs($num - $countEstimate) > $countEstimate*.05 ) {
	    $self->status("ARG estimate of $countEstimate for plots needs updating, found $num");
	}
	$self->dbinfoAdd("plots_list_file",         $self->{listFiles}->paths_index('plot'));
	$self->dbinfoAdd("plots_list_file_size", -s $self->{listFiles}->paths_index('plot'));
	$self->dbinfoAdd("db_stat_plots_count", "$num");
	
	$self->status("Creating Table indexes..");
	$DB->create_table_indexes('Plots');
	
	return(0);
    }

    $self->error("invalid type $type");
    return(1);
}

=head2 importList

Import a list file from 'listsDir' into the IMDB::Local Database.
Note: when 'movies' type is specified the database is reset from scratch

=cut

sub importList($$)
{
    my ($self, $type)=@_;

    my $DB=$self->_prepStage($type);

    # lets load our stats
    $self->dbinfoLoad();

    my $startTime=time();
    if ( $self->_importListFile($DB, $type) != 0 ) {
	$DB->disconnect();
	return(1);
    }

    $self->dbinfoAdd("seconds_to_complete_prep_stage_$type", (time()-$startTime));
    $self->dbinfoSave();

    $self->_unprepStage($DB);
    return(0);
}

=head2 importAll

Import all available list files from 'listsDir' into the IMDB::Local Database.
Returns # of list files that produced errors.

=cut

sub importAll($$)
{
    my ($self, $type)=@_;

    my $err=0;
    for my $type ( $self->listTypes() ) {
        if ( $self->importList($type) != 0 ) {
           warn("list import $type failed to load, $self->{errorCountInLog} errors in $self->{imdbDir}/stage-$type.log");
	   $err++;
        }
    }
    return($err);
}

=head2 optimize

Optimize the database for better performance.

=cut
sub optimize($)
{
    my ($self)=@_;

    my $DB=new IMDB::Local::DB(database=>"$self->{imdbDir}/imdb.db", db_AutoCommit=>1);
    
    if ( !$DB->connect() ) {
	die "imdbdb connect failed:$DBI::errstr";
    }

    $DB->runSQL("VACUUM");
    $DB->disconnect();
    return(1);
}

sub _NOT_USED_checkSantity($)
{
    my ($self)=@_;

    $self->dbinfoAdd("db_version", $IMDB::Local::VERSION);

    if ( $self->dbinfoSave() ) {
	$self->error("$self->{moviedbInfo}:$!");
	return(1);
    }
    
    $self->status("running quick sanity check on database indexes...");
    my $imdb=new IMDB::Local('imdbDir' => $self->{imdbDir},
			     'verbose' => $self->{verbose});
    
    if ( -e "$self->{moviedbOffline}" ) {
	unlink("$self->{moviedbOffline}");
    }
    
    if ( my $errline=$imdb->sanityCheckDatabase() ) {
	open(OFF, "> $self->{moviedbOffline}") || die "$self->{moviedbOffline}:$!";
	print OFF $errline."\n";
	print OFF "one of the prep stages' must have produced corrupt data\n";
	print OFF "report the following details to xmltv-devel\@lists.sf.net\n";
	
	my $info=loadDBInfo($self->{moviedbInfo});
	if ( ref $info eq 'HASH' ) {
	    for my $key (sort keys %{$info}) {
		print OFF "\t$key:$info->{$key}\n";
	    }
	}
	else {
	    print OFF "\tdbinfo file corrupt\n";
	    print OFF "\t$info";
	}
	print OFF "database taken offline\n";
	close(OFF);
	open(OFF, "< $self->{moviedbOffline}") || die "$self->{moviedbOffline}:$!";
	while(<OFF>) {
	    chop();
	    $self->error($_);
	}
	close(OFF);
	return(1);
    }
    $self->status("sanity intact :)");
    return(0);
}

=head1 AUTHOR

jerryv, C<< <jerry.veldhuis at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imdb-local at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMDB-Local>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IMDB::Local


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMDB-Local>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IMDB-Local>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IMDB-Local>

=item * Search CPAN

L<http://search.cpan.org/dist/IMDB-Local/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 jerryv.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of IMDB::Local
