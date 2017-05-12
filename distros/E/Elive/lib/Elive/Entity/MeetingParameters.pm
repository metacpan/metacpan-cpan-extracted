package Elive::Entity::MeetingParameters;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

__PACKAGE__->entity_name('MeetingParameters');
__PACKAGE__->_isa('Meeting');

coerce 'Elive::Entity::MeetingParameters' => from 'HashRef'
          => via {Elive::Entity::MeetingParameters->new($_) };

has 'meetingId' => (is => 'rw', isa => 'Int', required => 1,
    documentation => 'associated meeting');
__PACKAGE__->primary_key('meetingId');

has 'costCenter' => (is => 'rw', isa => 'Str',
    documentation => 'user defined cost center');
__PACKAGE__->_alias('cost_center' => 'costCenter');

has 'moderatorNotes' => (is => 'rw', isa => 'Str',
    documentation => 'meeting instructions for moderator(s)');
__PACKAGE__->_alias('moderator_notes' => 'moderatorNotes');

has 'userNotes' => (is => 'rw', isa => 'Str',
    documentation => 'meeting instructions for all participants');
__PACKAGE__->_alias('user_notes' => 'userNotes');

enum enumRecordingStates => '', qw(on off remote);
has 'recordingStatus' => (is => 'rw', isa => 'enumRecordingStates',
    documentation => 'recording status; on, off or remote (start/stopped by moderator)');
__PACKAGE__->_alias('recording' => 'recordingStatus');

has 'raiseHandOnEnter' => (is => 'rw', isa => 'Bool',
    documentation => 'raise hands automatically when users join');
__PACKAGE__->_alias('raise_hands' => 'raiseHandOnEnter');

has 'maxTalkers' => (is => 'rw', isa => 'Int',
    documentation => 'maximum number of simultaneous talkers');
__PACKAGE__->_alias('max_talkers' => 'maxTalkers');

has 'inSessionInvitation'  => (is => 'rw', isa => 'Bool',
			       documentation => 'Can moderators invite other individuals from within the online session');
# v9.5
__PACKAGE__->_alias('inSessionInvitations' => 'inSessionInvitation');
__PACKAGE__->_alias('invites' => 'inSessionInvitation');

has 'followModerator'  => (is => 'rw', isa => 'Bool',
			   documentation => 'Whiteboard slides are locked to moderator view');
__PACKAGE__->_alias('follow_moderator' => 'followModerator');

has 'videoWindow'  => (is => 'rw', isa => 'Int',
		       documentation => 'Max simultaneous cameras');
__PACKAGE__->_alias('max_cameras' => 'videoWindow');

has 'recordingObfuscation'  => (is => 'rw', isa => 'Bool');
has 'recordingResolution'  => (is => 'rw', isa => 'Str',
    documentation => 'CG:course gray, CC:course color, MG:medium gray, MC:medium color, FG:fine gray, FC:fine color');
__PACKAGE__->_alias('recording_resolution' => 'recordingResolution');

has 'profile'  => (is => 'rw', isa => 'Str',
		   documentation => "Which user profiles are displayed: 'none', 'mod' or 'all'");

=head1 NAME

Elive::Entity::MeetingParameters - Meeting parameters entity class

=head1 SYNOPSIS

Note: the C<insert()> and C<update()> methods are depreciated. For alternatives,
please see L<Elive::Entity::Session>.

    use Elive::Entity::MeetingParameters;

    my $meeting_params
        = Elive::Entity::MeetingParameters->retrieve($meeting_id);

    $meeting_params->update({
           maxTalkers => 3,
           costCenter => 'acme',
           moderatorNotes => 'be there early!',
           userNotes => "don't be late!",
           recordingStatus => 'on',
           raiseHandsOnEnter => 1,
           inSessionInvitation => 1,
           followModerator => 0,
           videoWindow => 0,
         });

=head1 DESCRIPTION

This class contains a range of options for a previously created meeting.

=cut

=head1 METHODS

=cut

=head2 retrieve

    my $paremeters = Elive::Entity::MeetingParameters->retrieve($meeting_id);

Retrieves the meeting parameters for a meeting.

=cut

=head2 insert

The insert method is not applicable. The meeting parameters table is
automatically created when you create a table.

=cut

sub insert {return shift->_not_available}

=head2 delete

The delete method is not applicable. meeting parameters are deleted
when the meeting itself is deleted.

=cut

sub delete {return shift->_not_available}

=head2 list

The list method is not available for meeting parameters.

=cut

sub list {return shift->_not_available}

sub _thaw {
    my ($class, $db_data, @args) = @_;

    my $data = $class->SUPER::_thaw($db_data, @args);

    for (grep {defined} $data->{recordingStatus}) {

	$_ = lc($_);

	unless (m{^(on|off|remote)$}x || $_ eq '') {
	    warn "ignoring unknown recording status: $_\n";
	    delete  $data->{recordingStatus};
	}
    }

    return $data;
}

=head1 See Also

L<Elive::Entity::Session>

=cut

1;
