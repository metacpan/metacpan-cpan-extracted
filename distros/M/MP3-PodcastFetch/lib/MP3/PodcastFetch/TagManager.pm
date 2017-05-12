package MP3::PodcastFetch::TagManager;
# $Id: TagManager.pm,v 1.4 2007/01/02 00:56:55 lstein Exp $

# Handle various differences between ID3 tag libraries

=head1 NAME

MP3::PodcastFetch::TagManager -- Handle differences among ID3 tag libraries

=head1 SYNOPSIS

 use MP3::PodcastFetch::TagManager;
 my $manager = MP3::PodcastFetch::TagManager->new();
 $manager->fix_tags('/tmp/podcasts/mypodcast.mp3',
                    { genre  => 'Podcast',
                      album  => 'My album',
                      artist => 'Lincoln Stein',
                      title  => 'Podcast #18' 
                    },
                    'auto');
  my $duration = $manager->get_duration('/tmp/podcasts/mypodcast.mp3');

=head1 DESCRIPTION

This is a utility class written for MP3::PodcastFetch. It papers over
the differences between three Perl ID3 tagging modules, MP3::Info,
MP3::Tag and Audio::TagLib. No other tagging libraries are currently
supported.

=head2 Main Methods

The following methods are intended for public consumption.

=over 4

=cut

my $MANAGER; # singleton

use strict;

=item $manager = MP3::PodcastFetch::TagManager->new();

Create a new manager object. At any time there can only be one such
object. Attempts to create new objects will retrieve the original
object.

=cut

sub new {
  my $class = shift;
  return $MANAGER ||= bless {},ref $class || $class;
}

=item $manager->fix_tags($filename,$tag_hash,$upgrade_type)

Attempt to write the tags from the keys and values contained in
$tag_hash. $filename is a path to a valid MP3 file. $tag_hash is a
hash reference containing one or more of the keys:

 genre
 title
 album
 artist
 comment
 year

$upgrade_type indicates what type of tag to write, and must be one of:

 id3v1
 id3v2.3
 id3v2.4
 auto

These will attempt to write ID3 tags at the indicated level. "auto"
attempts to write tags at the highest possible leve. Whether the
manager will be able to comply depends on which tagging modules are
present. For example, MP3::Tag can write ID3v2.3 and ID3v1 tags, but
not ID3v2.4.

You should place this method in an eval {}, as errors are indicated by
raising a die() exception.

=cut

sub fix_tags {
  my $self = shift;
  my ($filename,$tags,$upgrade_type) = @_;
  return unless $upgrade_type;
  $self->{$upgrade_type} ||= $self->load_tag_fixer_code($upgrade_type) 
    or die "Couldn't load appropriate tagging library: $@";
  $self->{$upgrade_type}->($filename,$tags);
}

=item $duration = $manager->get_duration($filename)

Get the duration of the indicated MP3 file using whatever library is
available. Returns undef if no tag library is available.

=back

=cut

sub get_duration {
  my $self     = shift;
  my $filename = shift;
  # try various ways of getting the duration

  unless ($self->{duration_getter}) {

    if (eval {require Audio::TagLib; 1}) {
      $self->{duration_getter} = \&get_duration_from_audiotaglib;
    }
    elsif (eval {require MP3::Info; 1}) {
      $self->{duration_getter} = \&get_duration_from_mp3info;
    }
    elsif (eval {require MP3::Tag; 1}) {
      $self->{duration_getter} = \&get_duration_from_mp3tag;
    }
    else {
      return;
    }
  }
  return $self->{duration_getter}->($filename);
}

=head2 Internal Methods & Functions.

The following methods are used internally, and may be overridden for
further functionality.

=over 4

=item $seconds = MP3::PodcastFetch::TagManager::get_duration_from_mp3info($filename)

Get the duration using MP3::Info. Note that this is a function, not a method.

=cut

sub get_duration_from_mp3info {
  my $filename = shift;
  my $info = MP3::Info::get_mp3info($filename) or return 0;
  return $info->{SS}
}

=over 4

=item $seconds = MP3::PodcastFetch::TagManager::get_duration_from_audiotaglib($filename)

Get the duration using Audio::Taglib. Note that this is a function, not a method.

=cut

sub get_duration_from_audiotaglib {
  my $filename = shift;
  my $file     = Audio::TagLib::MPEG::File->new($filename);
  defined $file or return 0;
  my $props    = $file->audioProperties;
  return $props->length;
}

=over 4

=item $seconds = MP3::PodcastFetch::TagManager::get_duration_from_mp3tag($filename)

Get the duration using MP3::Tag. Note that this is a function, not a method.

=cut

sub get_duration_from_mp3tag {
  my $filename = shift;
  open OLDOUT,     ">&", \*STDOUT or die "Can't dup STDOUT: $!";
  open OLDERR,     ">&", \*STDERR or die "Can't dup STDERR: $!";
  open STDOUT, ">","/dev/null";
  open STDERR, ">","/dev/null";
  my $file     = MP3::Tag->new($filename) or return 0;
  open STDOUT, ">&",\*OLDOUT;
  open STDERR, ">&",\*OLDERR;
  return $file->total_secs_int;
}

=item $coderef = $manager->load_tag_fixer_code($upgrade_type)

Return a coderef to the appropriate function for updating the tag.

=cut

sub load_tag_fixer_code {
  my $self         = shift;
  my $upgrade_type = shift;
  $self->upgrade_tags($upgrade_type);
  return $self->load_mp3_tag_lib   if lc $upgrade_type eq 'id3v1' or lc $upgrade_type eq 'id3v2.3';
  return $self->load_audio_tag_lib if lc $upgrade_type eq 'id3v2.4';
  return $self->load_audio_tag_lib || $self->load_mp3_tag_lib 
    || $self->load_mp3_info_lib if lc $upgrade_type eq 'auto';
  return;
}

=item $result = $manager->load_mp3_tag_lib
=item $result = $manager->load_audio_tag_lib
=item $result = $manager->load_mp3_info_lib;

These methods attempt to load the corresponding tagging libraries,
returning true if successful.

=cut

sub load_mp3_tag_lib {
  my $self   = shift;
  my $loaded = eval {require MP3::Tag; 1; };
  return unless $loaded;
  return lc $self->upgrade_tags eq 'id3v1' ? \&upgrade_to_ID3v1 : \&upgrade_to_ID3v23;
}

sub load_audio_tag_lib {
  my $self = shift;
  my $loaded = eval {require Audio::TagLib; 1; };
  return unless $loaded;
  return \&upgrade_to_ID3v24;
}

sub load_mp3_info_lib {
  my $self   = shift;
  my $loaded = eval {require MP3::Info; 1; };
  return unless $loaded;
  return \&upgrade_to_ID3v1_with_info;
}

=item MP3::PodcastFetch::TagManager::upgrade_to_ID3v24($filename,$tags)
=item MP3::PodcastFetch::TagManager::upgrade_to_ID3v23($filename,$tags)
=item MP3::PodcastFetch::TagManager::upgrade_to_ID3v1($filename,$tags)

These functions (not methods) update the tags of $filename to the
requested level.

=back

=cut

sub upgrade_tags {
    my $self = shift;
    my $d    = $self->{upgrade_type};
    $self->{upgrade_type} = shift if @_;
    $d;
}

sub upgrade_to_ID3v24 {
  my ($filename,$tags) = @_;
  my $mp3   = Audio::TagLib::FileRef->new($filename);
  defined $mp3 or die "Audio::TabLib::FileRef->new: $!";
  $mp3->save;    # this seems to upgrade the tag to v2.4
  undef $mp3;
  $mp3   = Audio::TagLib::FileRef->new($filename);
  my $tag   = $mp3->tag;
  $tag->setGenre(Audio::TagLib::String->new($tags->{genre}))     if defined $tags->{genre};
  $tag->setTitle(Audio::TagLib::String->new($tags->{title}))     if defined $tags->{title};
  $tag->setAlbum(Audio::TagLib::String->new($tags->{album}))     if defined $tags->{album};
  $tag->setArtist(Audio::TagLib::String->new($tags->{artist}))   if defined $tags->{artist};
  $tag->setComment(Audio::TagLib::String->new($tags->{comment})) if defined $tags->{comment};
  $tag->setYear($tags->{year})                                   if defined $tags->{year};
  $mp3->save;
}

sub upgrade_to_ID3v1 {
  my ($filename,$tags,) = @_;
  upgrade_to_ID3v1_or_23($filename,$tags,0);
}

sub upgrade_to_ID3v23 {
  my ($filename,$tags,) = @_;
  upgrade_to_ID3v1_or_23($filename,$tags,1);
}

sub upgrade_to_ID3v1_or_23 {
  my ($filename,$tags,$v2) = @_;
  # quench warnings from MP3::Tag
  open OLDOUT,     ">&", \*STDOUT or die "Can't dup STDOUT: $!";
  open OLDERR,     ">&", \*STDERR or die "Can't dup STDERR: $!";
  open STDOUT, ">","/dev/null";
  open STDERR, ">","/dev/null";
  MP3::Tag->config(autoinfo=> $v2 ? ('ID3v1','ID3v1') : ('ID3v2','ID3v1'));
  my $mp3   = MP3::Tag->new($filename) or die "MP3::Tag->new($filename): $!";
  my $data = $mp3->autoinfo;
  do { $data->{$_} = $tags->{$_} if defined $tags->{$_} } foreach qw(genre title album artist comment year);
  $mp3->update_tags($data,$v2);
  $mp3->close;
  open STDOUT, ">&",\*OLDOUT;
  open STDERR, ">&",\*OLDERR;
}

sub upgrade_to_ID3v1_with_info {
  my ($filename,$tags) = @_;
  my $mp3 = MP3::Info->new($filename) or die;
  $mp3->title($tags->{title}) if defined $tags->{title};
  $mp3->genre($tags->{genre}) if defined $tags->{genre};
  $mp3->album($tags->{album}) if defined $tags->{album};
  $mp3->artist($tags->{artist})   if defined $tags->{artist};
  $mp3->comment($tags->{comment}) if defined $tags->{comment};
  $mp3->year($tags->{year})       if defined $tags->{year};
}

1;

__END__

=head1 BUGS

The architecture of this module was poorly thought out. It is
currently difficult to extend. There should be a single virtual base
class which autoloads implementors dynamically.

=head1 SEE ALSO

L<podcast_fetch.pl>,
L<MP3::PodcastFetch>,
L<MP3::PodcastFetch::Feed::Channel>,
L<MP3::PodcastFetch::Feed::Item>,
L<MP3::PodcastFetch::XML::SimpleParser>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2006 Lincoln Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
