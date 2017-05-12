package GBPVR::CDBI::RecordingSchedule;

use warnings;
use strict;

our $VERSION = '0.03';

use base 'GBPVR::CDBI';
use GBPVR::CDBI::PlaybackPosition;
use GBPVR::CDBI::VideoArchive::ArchiveTable;

__PACKAGE__->table('recording_schedule');
__PACKAGE__->columns(Primary => qw/oid/ );
__PACKAGE__->columns(All => qw/
	oid
	programme_oid
	capture_source_oid
	filename
	status 
	recording_type
	recording_group
	manual_start_time
	manual_end_time
	manual_channel_oid
	quality_level
	pre_pad_minutes
	post_pad_minutes
/, 
);

sub parse_manual_time {
  my $self = shift;
  my $time = shift;
  return unless $time =~ /^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/;
  return ($1, $2, $3, $4, $5, $6);  # (Y,M,D, H,M,S)
}

sub start_time {
  my $self = shift;
  my $time = $self->manual_start_time or return;
  return sprintf( "%02d:%02d", ($self->parse_manual_time($time))[3,4] );
}

sub end_time {
  my $self = shift;
  my $time = $self->manual_end_time or return;
  return sprintf( "%02d:%02d", ($self->parse_manual_time($time))[3,4] );
}

sub start_date {
  my $self = shift;
  my $time = $self->manual_start_time or return;
  return sprintf( "%04d-%02d-%02d", ($self->parse_manual_time($time))[0,1,2] );
}

sub end_date {
  my $self = shift;
  my $time = $self->manual_end_time or return;
  return sprintf( "%04d-%02d-%02d", ($self->parse_manual_time($time))[0,1,2] );
}

__PACKAGE__->has_a( programme_oid => 'GBPVR::CDBI::Programme');
__PACKAGE__->has_a( capture_source_oid => 'GBPVR::CDBI::CaptureSource');
__PACKAGE__->has_a( manual_channel_oid => 'GBPVR::CDBI::Channel');
__PACKAGE__->columns(Stringify => qw/ programme_oid / );

sub last_position {
  my $obj = shift;
  my ($pp) = GBPVR::CDBI::PlaybackPosition->search( filename => $obj->filename );
  if( @_ ){
    my $pos = shift;
    if( $pp ){
      $pp->last_position( $pos);
      $pp->update;
    }else{
      $pp = GBPVR::CDBI::PlaybackPosition->create({ filename => $obj->filename, last_position => $pos });
    }
  }
  return $pp ? $pp->last_position : undef;
}

sub archivetable {
  my $obj = shift;
  return unless $obj->programme_oid;
  my ($at) = GBPVR::CDBI::VideoArchive::ArchiveTable->search( UniqueID => $obj->programme_oid->unique_identifier );
  return $at;
}

sub status_string {
  my $obj = shift;
  my %mapping = (
	0	=> 'Pending',
	2	=> 'Completed',
	3	=> 'Number3',
	4	=> 'Number4',
  );
  return $mapping{ $obj->status };
}



1;
__END__

=head1 NAME

GBPVR::CDBI::RecordingSchedule - GBPVR.recording_schedule table

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

=head1 ATTRIBUTES

oid, programme_oid, capture_source_oid, filename, status, recording_type, recording_group, manual_start_time, manual_end_time, manual_channel_oid, quality_level, pre_pad_minutes, post_pad_minutes

manual_start_time and manual_end_time are 'YYYY-MM-DD HH:MM:SS' strings.

=head2 start_time

Read-only.  Returns manual_start_time as a 'HH:MM' string.

=head2 end_time

Read-only.  Returns manual_end_time as a 'HH:MM' string.

=head2 start_date

Read-only.  Returns manual_start_time as a 'YYYY-MM-DD' string.

=head2 end_date

Read-only.  Returns manual_end_time as a 'YYYY-MM-DD' string.

=head1 FOREIGN KEYS

        programme_oid => L<GBPVR::CDBI::Programme>
        capture_source_oid => L<GBPVR::CDBI::CaptureSource>
        manual_channel_oid => L<GBPVR::CDBI::Channel>

=head1 METHODS

=head2 last_position

Alias accessor/mutator for the corresponding (created if none exists) GBPVR::CDBI::PlaybackPosition->last_position attribute.

=head2 archivetable

Attempts to return the corresponding (via unique_identifier) GBPVR::CDBI::VA::ArchiveTable object.

=head2 status_string

Maps $obj->status to a human-readable string.

=head2 parse_manual_time

Takes a 'YYYY-MM-DD HH:MM:SS' string and returns a (YYYY,MM,DD,HH,MM,SS) array.

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

