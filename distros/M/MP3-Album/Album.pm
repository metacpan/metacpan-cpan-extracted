package MP3::Album;

use strict;
use MP3::Info;
use MP3::Album::Track;
use MP3::Album::Layout::Fetcher;
use MP3::Album::Layout;
use File::Basename;

our $VERSION = '0.14';

sub new {
   my $c = shift;
   my %a = @_;
   my $s = { };

   $s = bless $s, $c; 
   
   $s->{tracks} = [];

   if ($a{files}) {
   	$a{files} = [ $a{files} ] if (  ref($a{files}) ne 'ARRAY' );
	foreach my $f (@{$a{files}}) {
	    my $tr = MP3::Album::Track->new(filename => $f);
	    unless ($tr) { return undef; }
	    push @{$s->{tracks}}, $tr; 
	}
   }

   $s->{current_layout}    = undef;

   return $s;
}

sub rename_files {
   my $s = shift;
   my %a = @_;

   # %t track title;
   # %a album name
   # %n track number
   # %p artist name

   $a{format}     = '%p - %a - %n - %t.mp3' unless $a{format};
   $a{keep_copy}  |= 0;
   
   my $layout = $s->layout();
   my $li     = $layout->info();

   for (my $i = 0; $i < scalar(@{$s->{tracks}}); $i++) {
	next unless $s->{tracks}->[$i];

	my $track_number = sprintf("%02d",$i+1);

	my $fn = $a{format};

	$fn =~ s/\%p/$li->{tracks}->[$i]->{artist}/g;
	$fn =~ s/\%a/$li->{title}/g;
	$fn =~ s/\%n/$track_number/g;
	$fn =~ s/\%t/$li->{tracks}->[$i]->{title}/g;

	$fn =~ s/\//_/g;

	my $dirname = $a{out_dir} ? $a{out_dir} : dirname($s->{tracks}->[$i]->filename());

	my $r = $s->{tracks}->[$i]->rename(filename=>"$dirname/$fn", keep_copy => $a{keep_copy});

	return undef unless $r;
   };

   return 1;
}

sub generate_tags {
   my $s = shift;
   $s->_init unless $s->{_init_done};

   my $layout = $s->layout();
   my $li     = $layout->info();

   for (my $i = 0; $i < scalar(@{$s->{tracks}}); $i++) {
   	next unless $s->{tracks}->[$i];

	my $track_number = sprintf("%02d",$i+1);
	
	my $r = $s->{tracks}->[$i]->set_tag(
		title  		=> $li->{tracks}->[$i]->{title},
		artist 		=> $li->{tracks}->[$i]->{artist},
		album  		=> $li->{title},
		year   		=> $li->{year},
		genre           => $li->{genre},
		comment		=> $li->{comment},
		track_number	=> $track_number
	);

	return undef unless $r;
   }

   return 1;

}

sub info {
   my $s = shift;
   $s->_init unless $s->{_init_done};
   
   my %info = ( 
   		number_oF_tracks  => scalar(@{$s->{tracks}}),
		bitrates          => [ $s->_album_bitrate() ],
		uniform_bitrate   => scalar($s->_album_bitrate()) == 1 ? 1 : 0,
		frequencies       => [ $s->_album_frequencies() ],
		uniform_frequency => scalar($s->_album_frequency()) == 1 ? 1 : 0,
		cddb_disc_id      => $s->{cddb_query}->{discid}
   	      );
   return wantarray ? %info : \%info;
}

sub frequency_check {
   my $s = shift;
   $s->_init unless $s->{_init_done};

   return scalar($s->_album_frequencies()) == 1 ? 1 : 0;
}

sub bitrate_check{
   my $s = shift;
   $s->_init unless $s->{_init_done};

   return scalar($s->_album_bitrate()) == 1 ? 1 : 0;
}

sub tracks {
  my $s = shift;

  return @{$s->{tracks}};
}

sub add {
 my $s = shift;
 my %a = @_;

 $s->_init unless $s->{_init_done};

 unless ( $a{track} ) {
     $@ = "missing param track";
     return undef;
 }

 my $tr = MP3::Album::Track->new(filename => $a{track});
 unless ($tr) { return undef }

 $a{position} = scalar(@{$s->{tracks}})+1 unless $a{position};

 if ( $a{position} > scalar(@{$s->{tracks}})+1 ) {
     $@ = "position must be between start and end of the album";
     return undef;
 }

 my @tracks = @{$s->{tracks}};

 my @f = splice(@tracks, 0, ($a{position}-1));

 $s->{tracks} = [@f, $tr, @tracks];

 delete $s->{_init_done};
 return 1;

};

sub layout {
  my $s = shift;
  $s->_init unless $s->{_init_done};

  if (@_) {
      unless ( $_[0] && (ref $_[0] eq 'MP3::Album::Layout') ) {
        $@ = "I need a MP3::Album::Layout to set up the album layout";
	return undef;
      }
      $s->{current_layout} = $_[0];
     
  } elsif (! $s->{current_layout} ) {
	my $l = $s->fetch_layout();
	return undef if (!$l); 
	$s->{current_layout} = $l->[0];
  }

  return $s->{current_layout};
}

sub fetch_layout {
  my $s = shift;
  my %a = @_;

  $s->_init unless $s->{_init_done};

  $a{method} = 'Tag' unless $a{method};

  my $layouts = MP3::Album::Layout::Fetcher->fetch(album=>$s, method=>$a{method});

  return undef unless $layouts;

  return wantarray ? @$layouts : $layouts;
};

sub available_fetchers {
  return MP3::Album::Layout::Fetcher->available_fetchers();
}

sub _album_frequencies {
  my $s = shift;

  my %freqs;
  
  foreach my $t (@{$s->{tracks}}) {
	$freqs{$t->bitrate()}=1 if $t->bitrate();	
  }

  return keys(%freqs);
}

sub _album_bitrate {
  my $s = shift;

  my %bitrates;
  
  foreach my $t (@{$s->{tracks}}) {
	$bitrates{$t->bitrate()}=1 if $t->bitrate();	
  }

  return keys(%bitrates);
}

sub _generate_toc {
  my $s = shift;
  my @toc;
  foreach my $f (@{$s->{tracks}}) {
       push @toc, $f->{info};
  }
  return @toc;
}

sub _cddb_query_builder {
  my $s = shift;
  my %a = @_;
  die "need a toc to build a query\n" unless $a{toc};

  my $discid       = $s->_disc_id(toc => $a{toc});
  my $disctime     = $s->_disc_time(toc => $a{toc});
  my $total_tracks = @{$a{toc}};
  my $frames       = $s->_get_frames(toc=> $a{toc});

  return { discid=> $discid, disctime=>$disctime, disctracks=>$total_tracks, frames=>$frames };
  
}

sub _get_frames {
   my $s = shift;
   my %a = @_;

   my @frames;
   my $t = 0;
   foreach my $track ( @{$a{toc}} ) {
      push @frames, $t * 75;
      $t += ( $track->{MM} * 60 + $track->{SS} );
   }
   return \@frames;
}

sub _disc_time {
   my $s = shift;
   my %a = @_;
   my $total_time = 0;

   foreach my $track (@{$a{toc}}) {
        my $track_time = $track->{MM} * 60 + $track->{SS};
        $total_time +=           $track_time;
   }

   return $total_time;
}

sub _disc_id {
   my $s = shift;
   my %a = @_;
   my $n          = 0;
   my $total_time = 0;

   foreach my $track ( @{$a{toc}} ) {
        my $track_time = $track->{MM} * 60 + $track->{SS};

        $n          += $s->_cddb_sum($total_time);
        $total_time += $track_time;
    }

    return sprintf("%08x", ($n % 0xFF) << 24 | $total_time << 8 | @{$a{toc}});
}

sub _cddb_sum {
    my $s = shift;
    my ($n, $ret) = (shift, 0);
    for (split //, $n) { $ret += $_ }
    return $ret;
}

sub _init {
    my $s = shift;

    @{$s->{toc}}       = $s->_generate_toc;
    $s->{cddb_query}   = $s->_cddb_query_builder(toc=>$s->{toc});

    $s->{_init_done} = 1;

    return 1;
}

1;
