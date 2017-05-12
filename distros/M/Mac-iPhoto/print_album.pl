#!/usr/bin/perl
#
# Example program. Demonstrates usage of Mac::iPhoto.pm module.
#
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
