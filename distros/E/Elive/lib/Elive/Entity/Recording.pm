package Elive::Entity::Recording;
use warnings; use strict;
use Mouse;

extends 'Elive::Entity';

use Elive::Util;

__PACKAGE__->entity_name('Recording');
__PACKAGE__->collection_name('Recordings');
__PACKAGE__->derivable(url => 'web_url');

has 'recordingId' => (is => 'rw', isa => 'Str', required => 1);
__PACKAGE__->primary_key('recordingId');

__PACKAGE__->params(
    userId => 'Str',
    userIP => 'Str',
    length => 'Int',
    );

has 'creationDate' => (is => 'rw', isa => 'HiResDate', required => 1,
		       documentation => 'creation date and time of the recording');

has 'data' => (is => 'rw', isa => 'Str',
	       documentation => 'recording byte-stream');

has 'facilitator' => (is => 'rw', isa => 'Str',
		      documentation => 'the creator of the meeting');

has 'keywords' => (is => 'rw', isa => 'Str',
		   documentation => 'keywords for this recording');

has 'meetingId' => (is => 'rw', isa => 'Int',
		    documentation => 'id of the meeting that created this recording');
__PACKAGE__->_alias(meetingRoomId => 'meetingId', freeze => 1);

has 'sessionInstanceId' => (is => 'rw', isa => 'Int',
		    documentation => 'id of the session instance that created this recording');

has 'open' => (is => 'rw', isa => 'Bool',
	       documentation => 'whether to display this recording on the public page');
has 'roomName' => (is => 'rw', isa => 'Str',
		   documentation => 'name of the meeting that created this recording');
has 'size' => (is => 'rw', isa => 'Int',
	       documentation => 'recording file size (bytes');
has 'version' => (is => 'rw', isa => 'Str',
		  documentation => 'version of Elluminate Live! that created this recording');

has  'sasId' => (is => 'rw', isa => 'Int');

has 'startDate' => (is => 'rw', isa => 'HiResDate',
		    documentation => 'start date/time of the recording');

has 'endDate' => (is => 'rw', isa => 'HiResDate',
		  documentation => 'end date/time of the recording');

=head1 NAME

Elive::Entity::Recording - Elluminate Recording Entity class

=cut

sub BUILDARGS {
    my $class = shift;
    my $spec = shift;

    die "usage $class->new({ ... }, ...)"
	unless Elive::Util::_reftype($spec) eq 'HASH';

    my %args = %{ $spec };

    if (defined $args{data}) {
	$args{size} ||= length( $args{data} );
    }

    return \%args;
}

=head1 METHODS

=cut

=head2 web_url

Utility method to return various website links for the recording. This is
available as both object and class level methods.

    #
    # Object level.
    #
    my $recording = Elive::Entity::Recording->retrieve($recording_id);
    my $url = recording->web_url(action => 'play');

    #
    # Class level access.
    #
    my $url = $recording->web_url(
                     action => 'play',
                     recording_id => $recording_id,
                     connection => $my_connection);  # optional


=cut

sub web_url {
    my ($self, %opt) = @_;

    my $recording_id = $opt{recording_id} || $self->recordingId;
    $recording_id = Elive::Util::_freeze($recording_id, 'Str');

    die "no recording_id given"
	unless $recording_id;

    my $connection = $self->connection || $opt{connection}
	or die "not connected";

    my $url = $connection->url;

    my %Actions = (
	'play'   => '%s/play_recording.html?recordingId=%s',
	);

    my $action = $opt{action} || 'play';

    die "unrecognised action: $action"
	unless exists $Actions{$action};

    return sprintf($Actions{$action},
		   $url, $recording_id);
}

=head2 buildJNLP 

    my $jnlp = $recording_entity->buildJNLP(version => version,
					    userId => $user->userId,
					    userIP => $ENV{REMOTE_ADDR});

Builds a JNLP for the recording.

JNLP is the 'Java Network Launch Protocol', also commonly known as Java
WebStart. You can, for example, render this as a web page with mime type
C<application/x-java-jnlp-file>.

The C<userIP> is required for elm 9.0+ when C<recordingJNLPIPCheck> has
been set to C<true> in C<configuration.xml> (or set interactively via:
Preferences E<gt>E<gt> Session Access E<gt>E<gt> Lock Recording Playback to Client IP)

It represents a fixed client IP address for launching the recording playback.

See also L<http://wikipedia.org/wiki/JNLP>.

=cut

sub buildJNLP {
    my ($self, %opt) = @_;

    my $connection = $self->connection || $opt{connection}
	or die "not connected";

    my $recording_id = $opt{recording_id} || $self->recordingId;

    die "unable to determine recording_id"
	unless $recording_id;

    my %soap_params = (recordingId => $recording_id);

    $soap_params{'userIP'} = $opt{userIP} if $opt{userIP}; # elm 9.1+ compat
    $soap_params{'userId'} = $opt{userId} || $connection->login->userId;

    my $som = $connection->call('buildRecordingJNLP', %{$self->_freeze(\%soap_params)});

    my $results = $self->_get_results($som, $connection);

    return @$results && $results->[0];
}

=head2 download

    my $recording = Elive::Entity::Recording->retrieve($recording_id);
    my $binary_data = $recording->download;

Download data for a recording.

=cut

sub download {
    my ($self, %opt) = @_;

    my $recording_id = $opt{recording_id} || $self->recordingId;

    die "unable to get a recording_id"
	unless $recording_id;

    my $connection = $self->connection || $opt{connection}
	or die "not connected";

    my $som = $connection->call('getRecordingStream',
				%{ $self->_freeze({
				       recordingId => $recording_id,
				       })},
	);

    my $results = $self->_get_results($som, $connection);

    return  Elive::Util::_hex_decode($results->[0])
	if $results->[0];

    return;
}

=head2 upload

This method lets you import recordings to an Elluminate Server.

You'll need supply binary data, a generated recording-Id and, optionally,
an associated meeting: 

    use Elive;
    use Elive::Entity::Recording;

    sub example_upload {
	#
	# demo subroutine to upload a recording file to an Elluminate server
	# - assumes that we are already connected to the server
	#
	my $recording_file = shift;   # path to recording file
	my %opt = @_;

	# get the binary data from somewhere

	open (my $fh, '<', $recording_file)
	    or die "unable to open $recording_file: $!";
	$fh->binmode;

	my $binary_data = do {local $/ = undef; <$fh>};
	die "no recording data: $recording_file"
	    unless ($binary_data && length($binary_data));

	# somehow generate a unique key for the recordingId.

	use Time::HiRes();
	my ($seconds, $microseconds) = Time::HiRes::gettimeofday();
	my $recordingId = sprintf("%d%04d_upload", $seconds, $microseconds/1000);

	my %recording_data = (
	    data => $binary_data,
	    recordingId => $recordingId,
	    version => $opt{version},
	    );

	if (my $meeting = $opt{meeting}) {
	    #
	    # associate the recording with this meeting
	    #
	    $recording_data{meetingId} = $meeting->meetingId;
	    $recording_data{roomName}  = $meeting->name;
	    $recording_data{facilitator} = $meeting->facilitatorId;
	}

	$recording_data{version} ||= Elive->server_details->version;
	$recording_data{facilitator} ||= Elive->login;

	my $recording = Elive::Entity::Recording->upload( \%recording_data );

	return $recording;
    }

Note: the C<facilitator>, when supplied must match the facilitator for the given C<meetingId>.

=cut

sub upload {
    my ($class, $spec, %opt) = @_;

    my $insert_data = $class->BUILDARGS( $spec );

    my $binary_data = delete $insert_data->{data};

    my $self = $class->insert($insert_data, %opt);

    my $size = $self->size;

    if ($size && $binary_data) {

	my $connection = $self->connection
	    or die "not connected";

	my $som = $connection->call('streamRecording',
				    %{ $class->_freeze({
					   recordingId => $self->recordingId,
					   length => $size}) },
				    stream => (SOAP::Data
					       ->type('hexBinary')
					       ->value($binary_data)),
	    );

	$connection->_check_for_errors($som);
    }

    return $self;
}

=head2 insert

The C<insert()> method is typically used to describe files that are
present in the site's recording directory.

You'll may need to insert recordings yourself if you are importing large
volumes of recording files or to recover recordings that have
not been closed cleanly.

    sub demo_recording_insert {
        my $import_filename = shift;
        my $meeting = shift;

	my $recordingId = $meeting->meetingId.'_import';
	my $import_filename = sprintf("%s_recordingData.bin", $recordingId);

	#
	# Somehow upload the file to the server and work-out the byte-size.
	# This needs to be uploaded to:
	#        ${instancesRoot}/${instanceName}/WEB-INF/resources/recordings
	# where $instanceRoot is typically /opt/ElluminateLive/manager/tomcat
	#
	my $bytes = import_recording($import_filename); # implementation dependant

	my $recording = Elive::Entity::Recording->insert({
	    recordingId => $recordingId,
	    creationDate => time().'000',
	    meetingId => $meeting->meetingId,
	    facilitator => $meeting->facilitator,
	    roomName => $meeting->name,
	    version => Elive->server_details->version,
	    size => $bytes,
       });
    }

The Recording C<insert> method, unlike other entities, requires that you supply
a primary key. This is then used to determine the name of the file to look for
in the recording directory, as in the above example.

The C<meetingId> is optional. Recordings do not have to be associated with a
particular meetings. They will still be searchable and are available for
playback.

=cut

1;
