package MP3::Album::Layout::Fetcher::Tag;
use strict;
use MP3::Album::Layout;

sub fetch {
	my $c = shift;
	my %a = @_;

        my @tracks     = $a{album}->tracks;
        my %artists    = ();
        my %album_name = ();
	my %genres     = ();
        my $artist     = 'Various Artists';
        my $album      = 'Unknown';
	my $genre      = 'Unknown';

        my $layout     = MP3::Album::Layout->new();

        foreach my $t (@tracks) {
                $artists{lc($t->{info}->{ARTIST})}++ if $t->{info}->{ARTIST};
                $album_name{lc($t->{info}->{ALBUM})}++ if $t->{info}->{ALBUM};
		$genres{lc($t->{info}->{GENRE})}++ if $t->{info}->{GENRE};
        }

        $artist = $tracks[0]->{info}->{ARTIST} if (scalar(keys(%artists)) == 1);
        $album  = $tracks[0]->{info}->{ALBUM} if (scalar(keys(%album_name)) == 1);
        $genre  = $tracks[0]->{info}->{GENRE} if (scalar(keys(%genres)) == 1);
        $layout->artist($artist);
        $layout->title($album);
        $layout->genre($genre);

        foreach my $t (@tracks) {
                my $t_artist = $artist;
                $t_artist = $t->{info}->{ARTIST} if $artist eq 'Various Artists';
                $layout->add_track( artist => $t_artist, title => $t->{info}->{TITLE} );
        }

	return wantarray ? ( $layout ) : [ $layout ];
}

1;

