use Mac::iPod::DB;

my $base = shift() || '/Volumes/peapod'; # where your iPod is mounted

my $db = new Mac::iPod::DB('./Path/To/iPod_Control/iTunes/iTunesDB');


foreach my $pl ($db->playlists) {

    printf "playlist: %s\n", $pl->name;

    foreach my $sid ($pl->songs) {

	( my $path = $db->song($sid)->path() ) =~ s/\:/\//g;

	printf "Artist: %s title: %s path: %s%s\n", 
	$db->song($sid)->artist(), $db->song($sid)->title(), $base, $path;

	
    }

}
