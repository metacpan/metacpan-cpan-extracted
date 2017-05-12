package Elive::Entity::Meeting;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

use Elive::Util;
use Elive::Entity::Preload;
use Elive::Entity::Preloads;
use Elive::Entity::Recording;
use Elive::Entity::MeetingParameters;
use Elive::Entity::ServerParameters;
use Elive::Entity::ParticipantList;

use YAML::Syck;

=head1 NAME

Elive::Entity::Meeting - Elluminate Meeting instance class

=head1 DESCRIPTION

This is the main entity class for meetings.

=cut

__PACKAGE__->entity_name('Meeting');
__PACKAGE__->collection_name('Meetings');
__PACKAGE__->params(
    displayName => 'Str',
    endDate => 'HiResDate',
    preloadId => 'Int',
    recurrenceCount => 'Int',
    recurrenceDays => 'Int',
    seats => 'Int',
    startDate => 'HiResDate',
    timeZone => 'Str',
    sessionRole => 'Int',
    version => 'Str',
    userId => 'Str',
    userName => 'Str',
    );

coerce 'Elive::Entity::Meeting' => from 'HashRef'
          => via {Elive::Entity::Meeting->new($_) };

# help out elive_query; expansion of 'select ** from meeting...'
__PACKAGE__->derivable(
    recordings => 'list_recordings',
    preloads => 'list_preloads',
    url => 'web_url');

has 'meetingId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->primary_key('meetingId');

has 'name' => (is => 'rw', isa => 'Str', required => 1,
	       documentation => 'meeting name',
    );

has 'start' => (is => 'rw', isa => 'HiResDate', required => 1,
		documentation => 'meeting start date and time');

has 'end' => (is => 'rw', isa => 'HiResDate', required => 1,
	      documentation => 'meeting end date and time');

has 'password' => (is => 'rw', isa => 'Str',
		   documentation => 'meeting password');

has 'deleted' => (is => 'rw', isa => 'Bool',
                  documentation => 'whether meeting has been deleted');

has 'facilitatorId' => (is => 'rw', isa => 'Str',
			documentation => 'userId of facilitator');
__PACKAGE__->_alias(facilitator => 'facilitatorId', freeze => 1);

has 'privateMeeting' => (is => 'rw', isa => 'Bool',
			 documentation => "don't display meeting in public schedule");
__PACKAGE__->_alias(private => 'privateMeeting', freeze => 1);

has  'allModerators' => (is => 'rw', isa => 'Bool',
			 documentation => "all participants can moderate");
__PACKAGE__->_alias(all_moderators => 'allModerators');

has  'restrictedMeeting' => (is => 'rw', isa => 'Bool',
			     documentation => "all participants must login");
__PACKAGE__->_alias(restricted => 'restrictedMeeting');

has 'adapter' => (is => 'rw', isa => 'Str',
		  documentation => 'adapter used to create the meeting/session. E.g.: "default", "standardv2"');

=head1 METHODS

=cut

=head2 insert

Note: the C<insert()> and C<update()> methods are depreciated. For alternatives,
please see L<Elive::Entity::Session>.

    my $start = time() + 15 * 60; # starts in 15 minutes
    my $end   = $start + 30 * 60; # runs for half an hour

    my $meeting = Elive::Entity::Meeting->insert({
	 name              => 'Test Meeting',
	 facilitatorId     => Elive->login,
	 start             => $start . '000',
	 end               => $end   . '000',
         password          => 'secret!',
         privateMeeting    => 1,
         restrictedMeeting => 1,
         seats             => 42,
	 });

    #
    # Set the meeting participants
    #
    my $participant_list = $meeting->participant_list;
    $participant_list->participants([$smith->userId, $jones->userId]);
    $participant_list->update;

A series of meetings can be created using the C<recurrenceCount> and
C<recurrenceDays> parameters.

    #
    # create three weekly meetings
    #
    my @meetings = Elive::Entity::Meeting->insert({
                            ...,
                            recurrenceCount => 3,
                            recurrenceDays  => 7,
                        });
=cut

=head2 update

    my $meeting = Elive::Entity::Meeting->update({
        start             => hires-date,
        end               => hires-date,
        name              => string,
        password          => string,
        seats             => int,
        privateMeeting    => 0|1,
        restrictedMeeting => 0|1,
        timeZone          => string
       });

=cut

=head2 delete

    my $meeting = Elive::Entity::Meeting->retrieve($meeting_id);
    $meeting->delete

Delete the meeting.

Note:

=over 4

=item Meeting recordings are not deleted.

If you also want to remove the associated recordings, you'll need to delete
them yourself, E.g.:

    my $recordings = $meeting->list_recordings;

    foreach my $recording (@$recordings) {
        $recording->delete;
    }

    $meeting->delete;

=item Recently deleted meetings may remain retrievable, but with the I<deleted> property to true.

Meetings, Meeting Parameters, Server Parameters and recordings may remain
accessible via the SOAP interface for a short period of time until they
are garbage collected by ELM.

You'll may need to check for deleted meetings:

    my $meeting =  Elive::Entity::Meeting->retrieve($meeting_id);
    if ($meeting && ! $meeting->deleted) {
        # ...
    }

or filter them out when listing meetings:

    my $live_meetings =  Elive::Entity::Meeting->list(filter => 'deleted = false');

=back

=cut

sub delete {
    my $self = shift;

    $self->SUPER::delete(@_);

    # update the object as well
    if (my $db_data = $self->_db_data) {
	$db_data->{deleted} = 1;
    }

    return $self->deleted(1);
}

=head2 list_user_meetings_by_date

Lists all meetings for which this user is a participant, over a given
date range.

For example, to list all meetings for a particular user over the next week:

   my $now = DateTime->now;
   my $next_week = $now->clone->add(days => 7);

   my $meetings = Elive::Entity::Meeting->list_user_meetings_by_date(
        {userId => $user_id,
         startDate => $now->epoch.'000',
         endDate => $next_week->epoch.'000'}
       );

=cut

sub list_user_meetings_by_date {
    my ($class, $params, %opt) = @_;

    my %fetch_params;
    my $reftype = Elive::Util::_reftype($params);

    if ($reftype eq 'HASH') {
	%fetch_params = %$params;
    }
    elsif ($reftype eq 'ARRAY'
	   && $params->[0] && @$params <= 3) {
	# older usage
	@fetch_params{qw{userId startDate endDate}} = @$params;
    }
    else {
	die 'usage: $class->user_meetings_by_date({userId=>$user, startDate=>$start_date, endDate=>$end_date})'
    }

    return $class->_fetch($class->_freeze(\%fetch_params),
			  command => 'listUserMeetingsByDate',
			  %opt,
	);
}

=head2 add_preload

    my $preload = Elive::Entity::Preload->upload( 'c:\tmp\intro.wbd');
    my $meeting = Elive::Entity::Meeting->retrieve($meeting_id);
    $meeting->add_preload($preload);

Associates a preload with the given meeting-Id, or meeting object.

=cut

sub add_preload {
    my ($self, $preload_id, %opt) = @_;

    die 'usage: $meeting_obj->add_preload($preload)'
	unless $preload_id;

    my %params = %{ $opt{param} || {} };

    my $meeting_id = $opt{meeting_id} || $self->meetingId;
    die "unable to determine meeting_id"
	unless $meeting_id;

    $params{meetingId} ||= $meeting_id;
    $params{preloadId} = $preload_id;

    my $connection = $self->connection
	or die "not connected";

    my $som = $connection->call('addMeetingPreload',
				%{ $self->_freeze( \%params ) });

    return $connection->_check_for_errors($som);
}

=head2 check_preload

    my $ok = $meeting_obj->check_preload($preload);

Checks that the preload is associated with this meeting.

=cut

sub check_preload {
    my ($self, $preload_id, %opt) = @_;

    die 'usage: $meeting_obj->check_preload($preload || $preload_id)'
	unless $preload_id;

    my $meeting_id = $opt{meeting_id} || $self->meetingId;

    die "unable to determine meeting_id"
	unless $meeting_id;

    my $connection = $self->connection
	or die "not connected";

    my $som = $connection
	->call('checkMeetingPreload',
	       %{ $self->_freeze({ preloadId => $preload_id,
				   meetingId => $meeting_id,
				 });
	       }
	);

    $connection->_check_for_errors($som);

    my $results = $self->_unpack_as_list($som->result);

    return @$results && Elive::Util::_thaw($results->[0], 'Bool');
}

=head2 is_participant

    my $ok = $meeting_obj->is_participant($user);

Checks that the user is a meeting participant.

=cut

sub is_participant {
    my ($self, $user, %opt) = @_;

    die 'usage: $meeting_obj->is_preload($user || $user_id)'
	unless $user;

    my $meeting_id = $opt{meeting_id} || $self->meetingId;

    die "unable to determine meeting_id"
	unless $meeting_id;

    my $connection = $self->connection
        or die "not connected";

    my $command = $opt{command} || 'isParticipant';

    my $som = $connection
        ->call($command,
	       %{ $self->_freeze({ userId => $user,
				   meetingId => $meeting_id,
				})
	       }
	);

    $connection->_check_for_errors($som);

    my $results = $self->_unpack_as_list($som->result);

    return @$results && Elive::Util::_thaw($results->[0], 'Bool');
}

=head2 is_moderator

    my $ok = $meeting_obj->is_moderator($user);

Checks that the user is a meeting moderator.

=cut

sub is_moderator {
    my ($self, $user, %opt) = @_;

    return $self->is_participant($user, %opt, command => 'isModerator');
}

sub _readback_check {
    my ($class, $updates_ref, $rows, @args) = @_;
    my %updates = %$updates_ref;

    #
    # password not included in readback record - skip it
    #
    delete $updates{password};

    #
    # A series of recurring meetings can potentially be returned.
    # to do: check for correct sequence of start and end times.
    # for now, we just check the first meeting.
    #
    $rows = [$rows->[0]] if @$rows > 1;

    return $class->SUPER::_readback_check(\%updates, $rows, @args);
}

=head2 remove_preload

    $meeting_obj->remove_preload($preload_obj);
    $preload_obj->delete;  # if you don't want it to hang around

Disassociate a preload from a meeting.

=cut

sub remove_preload {
    my ($self, $preload_id, %opt) = @_;

    my $meeting_id = $opt{meeting_id} || $self->meetingId;

    die 'unable to get a meeting_id'
	unless $meeting_id;

    die 'unable to get a preload'
	unless $preload_id;

    my $connection = $self->connection
	or die "not connected";

    my $som = $connection->call('deleteMeetingPreload',
				 %{ $self->_freeze({ meetingId => $meeting_id,
						     preloadId => $preload_id,
						   })
				 }
				);

    return $connection->_check_for_errors($som);
}
    
=head2 buildJNLP 

Builds a JNLP for the meeting.

    # ...
    use Elive;
    use Elive::Entity::Role;
    use Elive::Entity::Meeting;

    use CGI;
    my $cgi = CGI->new;

    #
    # authentication, calls to Elive->connect,  etc goes here...
    #
    my $meeting_id = $cgi->param('meeting_id');
    my $meeting = Elive::Entity::Meeting->retrieve($meeting_id);

    my $login_name = $cgi->param('user');

    my $jnlp = $meeting->buildJNLP(
                                   userName => $login_name,
                                   sessionRole => ${Elive::Entity::Role::PARTICIPANT},
                                  );
    #
    # join this user to the meeting
    #

    print $cgi->header(-type       => 'application/x-java-jnlp-file',
                       -attachment => 'my-meeting.jnlp');

    print $jnlp;

Alternatively, you can pass a user object or user-id via C<userId>

    my $user = Elive::Entity::User->get_by_loginName($login_name);

    my $jnlp = $meeting->buildJNLP(userId => $user);

Or you can just conjure up a display name and role. The user does
not have to exist as in the ELM database, or in the meeting's participant list:

    my $jnlp = $meeting->buildJNLP(
                       displayName => 'Joe Bloggs',
                       sessionRole => ${Elive::Entity::Role::PARTICIPANT}
                     );

Guests will by default be given a C<sessionRole> of participant (3).

JNLP is the 'Java Network Launch Protocol', also commonly known as Java
WebStart. To launch the meeting you can, for example, render this as a web
page, or send email attachments  with mime type C<application/x-java-jnlp-file>.

Under Windows, and other desktops, files are usually saved  with extension
C<.jnlp>.

See also L<http://wikipedia.org/wiki/JNLP>.

=cut

sub buildJNLP {
    my ($self, %opt) = @_;

    my $connection = $self->connection || $opt{connection}
	or die "not connected";

    my $meeting_id = $opt{meeting_id} ||= $self->meetingId;

    die "unable to determine meeting_id"
	unless $meeting_id;

    my %soap_params = (meetingId => $meeting_id);

    foreach my $param (qw(displayName sessionRole userName userId)) {
	my $val = delete $opt{$param};
	$soap_params{$param} = $val
	    if defined $val;
    }

    my $user = delete $opt{user};

    if ($user) {
	if (ref($user) || $user =~ m{^\d+$}x) {
	    $soap_params{userId} ||= $user;
	}
	else {
	    $soap_params{userName} ||= $user;
	}
    }

    $soap_params{userId} ||= $connection->login
	unless $soap_params{userName} || $soap_params{displayName};

    my %params_frozen = %{$self->_freeze(\%soap_params)};
    my $som = $connection->call('buildMeetingJNLP' => %params_frozen);

    my $results = $self->_get_results($som, $connection);

    return @$results && $results->[0];
}

=head2 web_url

Utility method to return various website links for the meeting. This is
available as both class level and object level methods.

    #
    # Class level access.
    #
    my $url = Elive::Entity::Meeting->web_url(
                     meeting_id => $meeting_id,
                     action => 'join',    # join|edit|...
                     connection => $my_connection);  # optional

    #
    # Object level.
    #
    my $meeting = Elive::Entity::Meeting->retrieve($meeting_id);
    my $url = meeting->web_url(action => 'join');

=cut

sub web_url {
    my ($self, %opt) = @_;

    my $meeting_id = $opt{meeting_id} || $self->meetingId;

    die "no meeting_id given"
	unless $meeting_id;

    my $connection = $self->connection || $opt{connection}
	or die "not connected";

    my $url = $connection->url;

    my %Actions = (
	'join'   => '%s/join_meeting.html?meetingId=%s',
	'edit'   => '%s/modify_meeting.event?meetingId=%s',
	'delete' => '%s/delete_meeting?meetingId=%s',
	);

    my $action = $opt{action} || 'join';

    die "unrecognised action: $action"
	unless exists $Actions{$action};

    $meeting_id = Elive::Util::_freeze($meeting_id, 'Str');

    return sprintf($Actions{$action},
		   $url, $meeting_id);
}

=head2 parameters

    my $meeting = Elive::Entity::Meeting->retrieve($meeting_id);
    my $meeting_parameters = $meeting->parameters;

Utility method to return the meeting parameters associated with a meeting.
See also L<Elive::Entity::MeetingParameters>.

=cut

sub parameters {
    my ($self, @args) = @_;

    return Elive::Entity::MeetingParameters
	->retrieve($self->meetingId,
		   reuse => 1,
		   connection => $self->connection,
		   @args,
	);
}

=head2 server_parameters

    my $meeting = Elive::Entity::Meeting->retrieve($meeting_id);
    my $server_parameters = $meeting->server_parameters;

Utility method to return the server parameters associated with a meeting.
See also L<Elive::Entity::ServerParameters>.

=cut

sub server_parameters {
    my ($self, @args) = @_;

    return Elive::Entity::ServerParameters
	->retrieve($self->meetingId,
		   reuse => 1,
		   connection => $self->connection,
		   @args,
	);
}

=head2 participant_list

    my $meeting = Elive::Entity::Meeting->retrieve($meeting_id);
    my $participant_list = $meeting->participant_list;
    my $participants = $participant_list->participants;

Utility method to return the participant_list associated with a meeting.
See also L<Elive::Entity::ParticipantList>.

=cut

sub participant_list {
    my ($self, @args) = @_;

    return Elive::Entity::ParticipantList
	->retrieve($self->meetingId,
		   reuse => 1,
		   connection => $self->connection,
		   @args,
	);
}

=head2 list_preloads

    my $preloads = $meeting_obj->list_preloads;

Lists all preloads associated with the meeting. See also L<Elive::Entity::Preload>.

=cut

sub list_preloads {
    my ($self, @args) = @_;

    return Elive::Entity::Preload
        ->list_meeting_preloads($self->meetingId,
				connection => $self->connection,
				@args);
}

=head2 list_recordings

    my $recordings = $meeting_obj->list_recordings;

Lists all recordings associated with the meeting. See also
L<Elive::Entity::Recording>.

=cut

sub list_recordings {
    my ($self, @args) = shift;

    return Elive::Entity::Recording
	->list(filter => 'meetingId = '.$self->quote( $self->meetingId ),
	       connection => $self->connection,
	       @args);
}

=head1 SEE ALSO

L<Elive::Entity::Session>

L<Elive::Entity::Preload>

L<Elive::Entity::Recording>

L<Elive::Entity::MeetingParameters>

L<Elive::Entity::ServerParameters>

L<Elive::Entity::ParticipantList>

=cut

1;
