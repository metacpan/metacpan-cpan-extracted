# $Id: iPhoto.pm,v 1.4 2003/12/04 04:16:42 dk99034 Exp $
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# 
package Mac::iPhoto;
#
use Mac::PropertyList;
use FileHandle;
use strict;

use vars qw /$VERSION/;

$VERSION = "0.1";

=head1 NAME

iPhoto - reads in photo albums plist files of iPhoto.app on MacOS X
         and presents them as perl data structure.

=head1 SYNOPSIS

use Mac::iPhoto;

my $a = new Mac::iPhoto("./AlbumData.xml");

$a->parse;

=head1 DESCRIPTION

Reads in photo albums plist files of iPhoto.app on MacOS X and
presents them as perl data structure.

=head1 FUNCTIONS

=head2 &new();

    my $AlbumData = Mac::iPhoto->new( "/Users/Shared/Photo/AlbumData.xml" );

    Creates new data object. Takes one parameter - UNIX path to
    AlbumData.xml file.


=head2 &parse()

    $AlbumData->&parse();

    Parses XML file and populates data structure $AlbumData->{'Data'}.

=head1 Structure of the data format of iPhoto.pm

Mac::iPhoto->parse() populates a hash iPhoto->{Data} that has following
structure:

    {
     Properties => \%Properties,
     Albums     => \@Albums,
     Images     => \@Images
    }

=head2 %Properties is hash of the top-level properties in the AlbumData.xml file.

%Properties has following structure:

    {
     'Application Version' => string,
     'Archive Path'        => string,
     'Major Version'       => string,
     'Minor Version'       => string,
    }

=head2 @Albums - array describing all albums in parsed XML file.

@Albums has following structure:

    {
      'AlbumName'          => string,
      'BookDesignName'     => string,
      'RepeatSlideShow'    => string,
      'SecondsPerSlide'    => string,
      'SongPath'           => string,
      'KeyList'            => \@KeyList,
    }

=head2 @Images - array describing all images in the AlbumData.xml file.

@Images has following structure:

      (
       'ImagePath'        => string,
       'Caption'          => string,
       'Comment'          => string,
       'Date'             => string,
       'ThumbPath'        => string,
       'ModificationDate' => string,
      );

=head1 CHANGES

Nov 19, 2003 - 1st actually working version of module.

=head1 EXAMPLE

use Mac::iPhoto;

my $a = new Mac::iPhoto("./AlbumData.xml");

$a->parse;

printf "Created by iTunes v. %s / maj.%s / min.%s\n",
     $a->{'Properties'}->{'Application Version'},
     $a->{Properties}->{'Major Version'},
     $a->{Properties}->{'Minor Version'};

printf "Album path: %s\n", $a->{Properties}->{'Archive Path'};

for my $album (@{$a->{Data}->{Albums}}) {

  printf "Name: %s \n", $album->{'AlbumName'};
  printf "BookDesignName: %s \n", $album->{'BookDesignName'};
  for my $key ( @{$album->{'KeyList'}}) {
    print $key, ": \n";
    printf "\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
      $a->{Data}->{Images}->[$key]->{'Date'},
      $a->{Data}->{Images}->[$key]->{'ImagePath'},
      $a->{Data}->{Images}->[$key]->{'ThumbPath'},
      $a->{Data}->{Images}->[$key]->{'Caption'},
      $a->{Data}->{Images}->[$key]->{'Comment'},
      $a->{Data}->{Images}->[$key]->{'ModificationDate'};
  }
}

=head1 CREDITS

Mac::iPhoto relies on Mac::PropertyList module for actual parsing of
XML file. Thanks for Brian D Foy, <bdfoy@cpan.org> for developing it.

=head1 AUTHOR

Dmytro Kovalov, 2003. kov at tokyo dot email dot ne dot jp.

       http://yarylo.sytes.net/
       http://www.asahi-net.or.jp/~as9d-kvlv/

=head1 SEE ALSO

https://sourceforge.net/projects/brian-d-foy/

=cut

sub new {
    my($class) = shift;
    my $self = {};
    bless($self, $class);
    $self->{AlbumDataFile} = shift;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->{AlbumDataFile}->close();
}


sub parse () {
  my $self = shift;
  my $AlbumData_file = $self->{AlbumDataFile};
  my $AlbumData = new FileHandle ;
  die "Can not open file $AlbumData_file for reading: $!\n" unless $AlbumData->open("< $AlbumData_file");
  my @Albums;
  my $save_SLASH = $/;  undef $/;
  my $txt = <$AlbumData>;
  my $data  = Mac::PropertyList::parse_plist( $txt );
  my %Properties =
    (
     'Application Version' => $data->{value}->{'Application Version'}->{value},
     'Archive Path' => $data->{value}->{'Archive Path'}->{value},
     'Major Version' =>  $data->{value}->{'Major Version'}->{value},
     'Minor Version' =>  $data->{value}->{'Minor Version'}->{value},
    );
  #
  # all albums
  #
  my @data_albums = $data->{value}->{'List of Albums'}->{value};
  #
  # rotate trhough albums
  #
  for my $l (@data_albums) {
    for my $data_album (@{$l}) {
      # Album properties:
      # $album->{type}  : dict
      #
      # Keys:
      # ~~~~~
      # $album->{value}->{'KeyList'}->{'value'}
      # array values: $album->{value}->{'KeyList'}->{'value'}->{'value'}
      my @KeyList = ();
      for my $key (my @keys = $data_album->{value}->{'KeyList'}->{'value'}) {
	for my $key2 ( @{$key}) {
	  #	push @albumKeys, $key2->{'value'};
	  #	push $albumsHash{$AlbumName}->{Photos} = \@albumKeys;
	  push @KeyList, $key2->{'value'};
	}
      }
      ;
      my %album =
	(
	 'AlbumName'          => $data_album->{value}->{'AlbumName'}->{value},
	 'BookDesignName'     => $data_album->{value}->{'BookDesignName'}->{value},
	 'RepeatSlideShow'    => $data_album->{value}->{'RepeatSlideShow'}->{value},
	 'SecondsPerSlide'    => $data_album->{value}->{'SecondsPerSlide'}->{value},
	 'SongPath'           => $data_album->{value}->{'SongPath'}->{value},
	 'KeyList'            => \@KeyList,
	);
      push @Albums, \%album;
    }
  }
  #
  # Images:
  # ~~~~~~~
  my @Images = ();
  for my $image (sort keys %{$data->{value}->{'Master Image List'}->{'value'}}) {
    #
    # Caption Comment Date ImagePath ModificationDate ThumbPath
    #
    my %image =
      (
       'ImagePath'        => %{$data->{value}->{'Master Image List'}->{'value'}}->{$image}->{'value'}->{'ImagePath'}->{'value'},
       'Caption'          => %{$data->{value}->{'Master Image List'}->{'value'}}->{$image}->{'value'}->{'Caption'}->{'value'},
       'Comment'          => %{$data->{value}->{'Master Image List'}->{'value'}}->{$image}->{'value'}->{'Comment'}->{'value'},
       'Date'             => %{$data->{value}->{'Master Image List'}->{'value'}}->{$image}->{'value'}->{'Date'}->{'value'},
       'ThumbPath'        => %{$data->{value}->{'Master Image List'}->{'value'}}->{$image}->{'value'}->{'ThumbPath'}->{'value'},
       'ModificationDate' => %{$data->{value}->{'Master Image List'}->{'value'}}->{$image}->{'value'}->{'ModificationDate'}->{'value'},
      );
    @Images[$image] = \%image;
  }
  $/ = $save_SLASH;		# restore $/
  my %AlbumData =
    (
     Albums     => \@Albums,
     Images     => \@Images,
    );

  $self->{Data} = \%AlbumData;
  $self->{Properties} = \%Properties;
}

# ============================================================
# END
#
1;
