package MP3::M3U;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

sub new {
  my ($class, $file, $root) = @_;

  die "$file doesn't exist" unless -e $file;

  my $self = {};
  $self->{_file} = $file;
  $self->{_root} = substr $file, 0, (index $file, '/', 1);

  bless $self, $class;

  return $self;
}

sub parse {
# parse playlist and return arrayref of mp3 filenames
#  my $path = substring $playlist, 0, (rindex $playlist, "/");
  my ($self, $search, $replace) = @_;

  my @files = ();
  open M3U, $self->{_file} or die "Cannnot open $self->{_file}. $!";
  while(<M3U>) {
    next if /^#/;
    chomp;
    s/\r//g;
    s|\\|/|g; # convert "\" to "/"
    my $file = $_;
    if ( $search and $replace ) {
      $search =~ s|\\|/|g; # convert "\" to "/"
      $replace =~ s|\\|/|g; # convert "\" to "/"
      $file =~ s/$search/$replace/;
    }
    if ( !-e $file ) {
      $file = $self->{_root} . $file;
    }
    push @files, $file;
  }
  close M3U;
  return \@files;
}

1;

__END__

=head1 NAME

MP3::M3U - m3u playlist parser

=head1 SYNOPSIS

  use MP3::M3U;

  my $m3u = new MP3::M3U '/path/to/playlist.m3u';
  my $files = $m3u->parse();
  print foreach @$files;

=head1 DESCRIPTION

The parser engine tries to be smart in that it tests the existence of each file in the playlist with fallbacks.
That is, if a file in the playlist doesn't exist, the engine will prepend the root path of the playlist to the filename. This is useful when the m3u is in the format of:
  \song1.mp3
  \song2.mp3

The second fallback is specified via the parse method. See below.

=head1 INTERFACE 

=head2 new (M3U)

First argument is the absolute path to the playlist filename.

=head2 parse ([search, replace])

The optional arguments specify the search and replace strings to be executed for each filename in the playlist.

eg.:

GIVEN: playlist.m3u:
  E:\song1.mp3
  E:\song2.mp3

WANTED:
  /mp3/songs/song1.mp3
  /mp3/songs/song2.mp3

SOLUTION:
  parse('E:', '/mp3/songs');

=head1 AUTHOR

Ilia Lobsanov <ilia@lobsanov.com>

=head1 COPYRIGHT

Copyright (c) 2001 Ilia Lobsanov, Nurey Networks Inc.

=head1 LICENSE

Licensed under GPL.
