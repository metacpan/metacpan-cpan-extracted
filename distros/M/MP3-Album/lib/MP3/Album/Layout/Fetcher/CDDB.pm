package MP3::Album::Layout::Fetcher::CDDB;

use strict;
use MP3::Album::Layout;
use CDDB;
use Data::Dumper;

sub fetch {
	   my $c = shift;
	   my %a = @_;

	   my @results = ();

	   $a{cddb_host}  = $a{cddb_host}  || 'freedb.freedb.org';
	   $a{cddb_port}  = $a{cddb_port}  || 8880;
	   $a{cddb_login} = $a{cddb_login} || $ENV{USER};


           my $cddb  = new CDDB( Host  => $a{cddb_host},
                                 Port  => $a{cddb_port},
                                 Login => $a{cddb_login});
           if (!$cddb) {
                $@ = "error connecting to cddb";
                return undef;
           }

	   return [] unless ($a{album}->{cddb_query}->{discid} && $a{album}->{cddb_query}->{frames} && $a{album}->{cddb_query}->{disctime});

           my @cddb_discs = $cddb->get_discs( $a{album}->{cddb_query}->{discid},
                                           $a{album}->{cddb_query}->{frames},
                                           $a{album}->{cddb_query}->{disctime}
                                         );
           foreach my $disc (@cddb_discs) {
                my $disc_info = $cddb->get_disc_details($disc->[0], $disc->[1]);
		last unless $disc_info;
                my ($artist,$title) = split(/\s*\/\s*/, $disc->[2]);
                my $layout = MP3::Album::Layout->new();
                $layout->artist($artist);
                $layout->title($title);
                $layout->genre($disc->[0]);

                my $k = 0;
                foreach my $t (@{$disc_info->{ttitles}}) {
                  $layout->add_track( title => $t, artist => $artist, lenght=> $disc_info->{seconds}->[$k]);
		  $k++;
                }
                push @results, $layout;
	  }
	
	  return \@results;
}

1;
