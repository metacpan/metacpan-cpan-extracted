#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl} -sw-
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
# ----------------------------------------------------------
# 
# 			 mp3tocddb
# 		Tue Oct  6 11:25:52 SGT 1998
#			    v1.0
# simple program to guess at frame offsets and produce a cddb query string
# 
# 		       Meng Weng Wong
# 		  http://www.mengwong.com/
# 
# the original author disclaims all responsibility for this
# program.  mail about it will be IGNORED. - wmw 19990226
# 
# $Id: mp3tocddb.PL,v 1.2 2000/07/08 19:49:06 pudge Exp $
# 
# usage: mp3tocddb [-askcddb] [-textamp] [-dir=~/playlists] u2-achtung_baby*.mp3
# 
#  -askcddb will connect to the cddb to get full info
#  -dir=XXX specifies a directory for album information to go into
#  -textamp will write out album information into the specified dir
# 
# SEE ALSO mp3tools: http://www.zevils.com/linux/mp3tools/
# ----------------------------------------------------------

# ----------------------------------------------------------
# 	 no user-serviceable parts below this line
# ----------------------------------------------------------

use strict;
use vars qw($VERSION $debug $askcddb $textamp $dir);
use MP3::Info;
use CDDB;

($VERSION) = q$Id: mp3tocddb.PL,v 1.2 2000/07/08 19:49:06 pudge Exp $ =~ /([\d.]{3,})/;

$dir =~ s/~/$ENV{'HOME'}/ if (defined($dir));

# ----------------------------------------------------------
#			    main
# ----------------------------------------------------------

if (! @ARGV) { die "usage: mp3tocddb albumname-*.mp3\n" }

$askcddb ||= 1 if $textamp;

# 
# build the table of contents for each album.
# 
my %cdtoc = ();
my %cddb_query = ();
my %tracks_in;

if (@ARGV) {
    my $lastalbum = "";
    my $album     = "";
    foreach my $file (@ARGV) {
	next if $file !~ /\d\d.*mp3$/i;
	   $album =  $file;
	   $album =~ s/\-?\d+\.mp3$//i; # my naming convention is artist-albumtitle-NN.mp3

	use File::Basename;
	$album = basename($album);

	my $info  = get_mp3info($file);

	push (@{$cdtoc{$album}}, $info );
	push (@{$tracks_in{$album}}, basename($file));

	if ($lastalbum and $lastalbum ne $album) {
	    printf "%-20s", "$lastalbum: " unless $textamp;
	    $cddb_query{$lastalbum} = [&build_cddb_query($cdtoc{$lastalbum})];
	}
	$lastalbum = $album;
    }
    printf "%-20s", "$album: " unless $textamp;
    $cddb_query{$lastalbum} = [&build_cddb_query($cdtoc{$lastalbum})];
}

exit if not $askcddb;

my $cddb = new CDDB (Debug=>0) or die "unable to connect to CDDB: $!"; # defaults to www.cddb.com:8880.

# on #freeperl 19981126
# <freeside> i don't really care about those genres, do i?
# <dngor> if you're not using them, you don't need to query them.
# my @genres = $cddb->get_genres();  print "genres: ", join(', ', @genres), "\n";

my %disc_info;

ALBUM: foreach my $album (sort keys %cddb_query) {

    my ($my_disc_id,
	$my_total_tracks,
	$my_total_time,
	@my_frames) = @{$cddb_query{$album}};

    if ($my_total_tracks == 1) {
	print "$album: only one track.  skipping.\n" if $debug;
	next;
    }

    print "\nasking cddb about $album ...\n" if $debug;

    my @discs = ();
       @discs = $cddb->get_discs($my_disc_id, [@my_frames], $my_total_time);

    if (grep ! defined($_), @discs) { warn "get_discs didn't return anything!  skipping $album.\n"; next }

    foreach my $disc (@discs) {
       my ($genre, $cddb_id, $title) = @$disc;

       print "Found: $genre \t $cddb_id \t $title\n";

       # > ooh, big news!  i just found occasion to legitimately use $hash{$foo,$bar} syntax.
       # <q[merlyn]> where free?
       # > see, the cddb returns fuzzy matches of disc id + genre; discs are uniquely identified as a
       # > composite of discid and genre. so the keys in my %disc_info are {$disc_id, $genre}.
       # <q[merlyn]> why not just use two level hash?
       # <q[merlyn]> then you could iterate over all $disc_id's easily
       # > i started that way, but now i need to rank all the discs together, and i throw away the disc id anyway.
       # <q[merlyn]> oh... ok good
       # <q[merlyn]> well you could still use $disc_info{"$disc_id $genre"}
       # <q[merlyn]> and then still not need it. :)
       # <q[merlyn]> rather than relying on the secret value of $;
       # > yeah, but i just wanted to use {,}, okay?  geez, man, can't a girl have any fun?       
       # 
       # feh.

       $disc_info{$album}{"$cddb_id ($genre)"}              = $cddb->get_disc_details($genre, $cddb_id);
       $disc_info{$album}{"$cddb_id ($genre)"}->{'genre'} ||= $genre;
    }

    print "heh, CDDB doesn't seem to know about this one.  skipping.\n" and next ALBUM if (! @discs);
    
    push (@my_frames, $my_total_time * 75);
    my %distance;
    foreach my $cddb_id (sort keys %{$disc_info{$album}}) {

	my $disc_info = $disc_info{$album}{$cddb_id};

	my $disc_time	   = ($disc_info->{'disc length'} =~ /(\d+)/)[0];
	my $disc_id	           =  $disc_info->{'discid'};
	my $disc_title	   =  $disc_info->{'dtitle'};
	my @track_offsets = @{$disc_info->{'offsets'}};
	my @track_titles  = @{$disc_info->{'ttitles'}};

#	print "got keys: @{[keys %$disc_info]}\n";

	# give user a choice if multiple matches.
	# then write out to textamp format.

	# identify least-squares difference from what we actually have.
	# <dngor> treat each array as a coordinate in N-dimensional space, where N is the number of tracks
	# <Skrewtape> dngor - That's equivalent to least-squares.
	# <dngor> neat!

	push (@track_offsets, $disc_time * 75 + $track_offsets[0]);

	my @track_lengths = &offsets_to_seconds (@track_offsets);
	my @my_lengths    = &offsets_to_seconds (@my_frames);

#	for (0 .. $#track_titles) { print &ss_to_mmss($track_lengths[$_]), "  $track_titles[$_]\n"; }
#	print "their offsets: @track_offsets\n";
#	print "  our offsets: @my_frames\n";
#	print "$disc_title: lengths: @{[(map { &ss_to_mmss($_) } @track_lengths)]}\n";
#	print "$album: my lengths: @{[(map { &ss_to_mmss($_) } @my_lengths)]}\n";

	my $distance = &sqr_distance(\@track_lengths, \@my_lengths);
#	print "distance is $distance\n";

	$distance{$album}{$cddb_id} = $distance;
    }

    # now we rank the returned discs by their distance.
    my @ranking = sort { $distance{$album}{$a} <=> $distance{$album}{$b} } keys %{$distance{$album}};
    foreach my $cddb_id (@ranking) {
	printf "%s: %-02d: %s\n", ($album,
				   $distance{$album}{$cddb_id}, $
				   disc_info{$album}{$cddb_id}->{'dtitle'});
    }
    print "\n";

    if ($textamp) { # dump output to playlist files

	my $outfile = (defined($dir)?"$dir/":"") . "$album.txt";
	print "mp3tocddb: writing textamp playlist file $outfile\n";
	if (! open (OUT, ">$outfile")) {
	    warn "mp3tocddb: unable to open $outfile: $!\n";
	    if (! defined ($dir)) {
		warn "mp3tocddb: maybe you want to run with   mp3tocddb -dir=/some/dir\n";
	    }
	    next;
	}
	
	print OUT "# \n";
	print OUT "# generated by mp3tocddb at " . (localtime) . "\n";
	print OUT "# \n";
	print OUT "\n";

	print OUT map {   "$_\n" } &textamp_info($album, shift @ranking); # first one out is uncommented
	print OUT "\n" and
	print OUT map { "# $_\n" } &textamp_info($album, shift @ranking) while @ranking;

	close OUT or warn "mp3tocddb: unable to close $outfile: $!\n";
    }
}

# ----------------------------------------------------------
# 			 functions
# ----------------------------------------------------------

sub textamp_info {
    my ($album, $cddb_id) = @_;
    my @toreturn = ();

    my $disc_info          =  $disc_info{$album}{$cddb_id};
    my $disc_time	   = ($disc_info->{'disc length'} =~ /(\d+)/)[0];
    my $disc_id	           =  $disc_info->{'discid'};
    my $disc_title	   =  $disc_info->{'dtitle'};
    my $genre	   	   =  $disc_info->{'genre'};
    my @track_offsets = @{$disc_info->{'offsets'}};

    my ($artist, $real_title) = &split_title($disc_info->{'dtitle'});
    push (@toreturn,
	  "# ------------------------------------------------------------",
	  "cddb_id:      $disc_id",
	  "cddb_genre:   $genre",
	  "cddb_offsets: @track_offsets",
	  "cddb_time:    $disc_time",
	  "",
	  "artist: $artist",
	  "album:  $real_title",
	  "",
	  );
    
    my @track_titles  = @{$disc_info->{'ttitles'}};

    foreach my $track_number (0 .. $#{$tracks_in{$album}}) {
	my ($artist, $title) = &split_title($track_titles[$track_number]);
	
	if ($artist eq $title) { undef $artist }

	push (@toreturn, "url:    $tracks_in{$album}->[$track_number]");
	push (@toreturn, "artist: $artist") if defined $artist;
	push (@toreturn, "title:  $title");
	push (@toreturn, "");
    }

    return @toreturn;
}

sub split_title {
    # this is a toughy: the cddb has no separate fields for artist vs actual album title, so we're left guessing.
    
    local $_ = shift;
    
    my ($artist, $title);

       if (/(.*?)\s*\/\s*(.*)/)  { ($artist, $title) = ($1, $2) }
    elsif (/(.*?)\s+-+\s+(.*)/)  { ($artist, $title) = ($2, $1) }
    else                         { ($artist, $title) = ($_, $_) }

    for ($artist, $title) { s/^\s*//; s/\s*$// }

    return ($artist, $title);
}

sub sqr_distance {
    my @vector1 = @{+shift};
    my @vector2 = @{+shift};
    my $total = 0;

    foreach my $dimension (0 .. ($#vector1 < $#vector2 ? $#vector1 : $#vector2)) { # too much paranoia never hurt anyone
	my $difference = abs($vector1[$dimension] - $vector2[$dimension]);
	my $square     = $difference ** 2;
	$total        += $square;
    }
    
    return $total;
}

sub frames_to_ss {
    my $frames = shift;
    my $ss = int($frames / 75);
    return $ss;
}

sub ss_to_mmss {
    my $ss = shift;
    my $mm = $ss / 60;
       $ss = $ss % 60;
    return sprintf ("%02d:%02d", $mm, $ss);
}

sub offsets_to_seconds { # convert a list of offsets back into length in frseconds
    my @offsets = @_;
    my @track_lengths = ();
    while (@offsets > 1) {
	unshift(@track_lengths, pop (@offsets) - $offsets[-1]);
    }
    return map { &frames_to_ss ($_) } @track_lengths;
}

sub build_cddb_query {
    my @cdtoc = @{+shift};
    my $count = 1;

    foreach (@cdtoc) {
	my ($mm, $ss) = ($_->{MM}, $_->{SS});
#	printf "track %d lasts %d:%02d.\n", $count++, $mm, $ss;
    }

    my $discid = cddb_discid(@cdtoc);

    my @frames         = &invent_frame_numbers(@cdtoc);
    my $total_time     = &total_time(@cdtoc);
    my $total_tracks   = @cdtoc;

    my $login          = $ENV{USER};
    my $hostname       = &hostname; use Sys::Hostname; $hostname = `hostname` if $hostname !~ /\./; # macperl bug?
    my $client_name    = "mp3tocddb";
    my $client_version = "v0.1-freeside"; # for credit, grow yourself into this.

#    print "the projected discid is $discid.  that's probably almost, but not quite, right.\n";
#    print "here are some plausible frame numbers.  try a fuzzy match with them and see what comes out!\n";
#    print "after telnetting to a cddb server such as www.cddb.com 8880, you will need to say:\n";
#    print "cddb hello $login $hostname $client_name $client_version\n";

    print <<EOBLURB if (not $askcddb and $textamp);
the projected discid is $discid.  that's probably almost, but not quite, right.
here are some plausible frame numbers.  try a fuzzy match with them and see what comes out!
after telnetting to a cddb server such as www.cddb.com 8880, you will need to say:
cddb hello $login $hostname $client_name $client_version
EOBLURB

    print "cddb query $discid $total_tracks @frames $total_time\n" if not $textamp;

    return ( $discid,
	     $total_tracks,
	     $total_time,
	     @frames );
}

sub cddb_sum {
    my ($n, $ret) = (shift, 0);
    for (split //, $n) { $ret += $_ }
    return $ret;
}

sub total_time {
    my @cdtoc      = @_;
    my $total_time = 0;

    foreach my $track (@cdtoc) {
	my $track_time = $track->{MM} * 60 + $track->{SS};
	$total_time +=           $track_time;
    }

    return $total_time;
}


sub cddb_discid {
    my @cdtoc      = @_;
    my $n          = 0;
    my $total_time = 0;

    foreach my $track (@cdtoc) {
	my $track_time = $track->{MM} * 60 + $track->{SS};

	# the starting offset of each track is usually, but not always, the total time up until now.
	$n          += &cddb_sum($total_time);
	# suppose:
	# track 4 begins at 14:49.55. it lasts 03:51.25.
	# track 5 begins at 18:41.05.  hm.
	# this isn't good enough.  we're going to have to fake it. -- freeside 19981006

	$total_time +=           $track_time;
    }

#                    print "($n % 255) << 24 | $total_time << 8 | @{[scalar @cdtoc]}\n";
    return sprintf("%08x", ($n % 0xFF) << 24 | $total_time << 8 | @cdtoc);
}

sub invent_frame_numbers {

    # >>> cddb query 450b5018 24 150 13425 30325 38475 43650 53400 64600 74575 77400 85525 95650 102400 113550 123050 133800 136125 147850 153050 162525 164400 181423 183375 200750 216325 2896

    # hokay, let's make up some frame numbers.
    
    my @cdtoc      = @_;
    my $n          = 0;
    my $total_time = 0;

    foreach my $track (@cdtoc) {

	# there are 75 frames in a second.
	$track->{FRAME_OFFSET} = $total_time * 75;

	my $track_time  = $track->{MM} * 60 + $track->{SS};
	$total_time    += $track_time;

    }

    return map { $_->{FRAME_OFFSET} } @cdtoc;
}

# ----------------------------------------------------------
# 		     format statements
# ----------------------------------------------------------
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

