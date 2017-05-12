package Elive::Entity::Preload;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

use Elive::Util;

use SOAP::Lite;  # contains SOAP::Data package
use MIME::Types;
use File::Basename qw{};

use Carp;

__PACKAGE__->entity_name('Preload');
__PACKAGE__->collection_name('Preloads');

has 'preloadId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->primary_key('preloadId');
__PACKAGE__->params(
    meetingId => 'Str',
    fileName => 'Str',
    length => 'Int',
    );
__PACKAGE__->_alias(key => 'preloadId');

enum enumPreloadTypes => qw(media whiteboard plan);
has 'type' => (is => 'rw', isa => 'enumPreloadTypes', required => 1,
	       documentation => 'preload type. media, whiteboard or plan',
    );

has 'name' => (is => 'rw', isa => 'Str', required => 1,
	       documentation => 'preload name, e.g. "intro.wbd"',
    );

has 'mimeType' => (is => 'rw', isa => 'Str', required => 1,
		   documentation => 'The mimetype of the preload (e.g., video/quicktime).');

has 'ownerId' => (is => 'rw', isa => 'Str', required => 1,
		 documentation => 'preload owner (userId)',
    );

has 'size' => (is => 'rw', isa => 'Int', required => 1,
	       documentation => 'The length of the preload in bytes',
    );

has 'data' => (is => 'rw', isa => 'Str',
	       documentation => 'The contents of the preload.');

has 'isProtected' => (is => 'rw', isa => 'Bool');
has 'isDataAvailable' => (is => 'rw', isa => 'Bool');

sub BUILDARGS {
    my $class = shift;
    my $spec = shift;

    my %args;

    if ($spec && ! ref($spec) ) {
	#
	# Assume a single string arguments represents the local path of a file
	# to be uploaded.
	#
	my $preload_path = $spec;

	open ( my $fh, '<', $preload_path)
	    or die "unable to open preload file $preload_path";

	binmode $fh;
	my $content = do {local $/; <$fh>};

	close $fh;

	die "upload file is empty: $preload_path"
	    unless length $content;

	%args = (
	    fileName => $preload_path,
	    data => $content,
	);
    }
    elsif (Elive::Util::_reftype($spec) eq 'HASH') {
	%args = %$spec;
    }
    else {
	croak 'usage: '.$class.'->new( filepath | {name => $filename, data => $binary_data, ...} )';
    }

    if ($args{data}) {
	$args{size} ||= length( $args{data} )
    }

    if (defined $args{fileName} && length $args{fileName}) {
	$args{name} ||= File::Basename::basename( $args{fileName} );
	croak "unable to determine a basename for preload path: $args{fileName}"
	    unless length $args{name};
    }

    die "unable to determine file name"
	unless defined $args{name} && length $args{name};

    $args{mimeType} ||= $class->_guess_mimetype($args{name});
    $args{type} ||= ($args{name} =~ m{\.wb[pd]$}ix  ? 'whiteboard'
		     : $args{name} =~ m{\.elpx?$}ix ? 'plan'
		     : 'media');

    return \%args;
}

=head1 NAME

Elive::Entity::Preload - Elluminate Preload instance class

=head2 DESCRIPTION

This is the entity class for meeting preloads.

    my $preloads = Elive::Entity::Preload->list(
                        filter =>  'mimeType=application/x-shockwave-flash',
                    );

    my $preload = Elive::Entity::Preload->retrieve($preload_id);

    my $type = $preload->type;

There are three possible types of preloads: media, plan and whiteboard.

=cut

=head1 METHODS

=cut

=head2 upload

    #
    # upload from a file
    #
    my $preload1 = Elive::Entity::Preload->upload('mypreloads/intro.wbd');

    #
    # upload in-memory data
    #
    my $preload2 = Elive::Entity::Preload->upload(
             {
		    type => 'whiteboard',
		    name => 'introduction.wbd',
		    ownerId => 357147617360,
                    data => $binary_data,
	     },
         );

Upload data from a client and create a preload.  If a C<mimeType> is not
supplied, it will be guessed from the C<name> extension, using
L<MIME::Types>.

=cut

sub upload {
    my ($class, $spec, %opt) = @_;

    my $connection = $opt{connection} || $class->connection
	or die "not connected";

    my $insert_data = $class->BUILDARGS( $spec );
    my $content = delete $insert_data->{data};
    $insert_data->{ownerId} ||= $connection->login->userId;
    #
    # 1. create initial record
    #
    my $self = $class->insert($insert_data, %opt);

    if ($self->size && $content) {
	#
	# 2. Now upload data to it
	#
	my $som = $connection->call('streamPreload',
				    %{ $self->_freeze(
					   {preloadId => $self->preloadId,
					    length => $self->size,
					   })},
				    stream => (SOAP::Data
					       ->type('hexBinary')
					       ->value($content)),
	    );

	$connection->_check_for_errors($som);
    }

    return $self;
}

=head2 download

    my $preload = Elive::Entity::Preload->retrieve($preload_id);
    my $binary_data = $preload->download;

Download preload data.

=cut

sub download {
    my ($self, %opt) = @_;

    my $preload_id = $opt{preload_id} ||= $self->preloadId;

    die "unable to get a preload_id"
	unless $preload_id;

    my $connection = $opt{connection} || $self->connection
	or die "not connected";

    my $som = $connection->call('getPreloadStream',
				%{$self->_freeze({preloadId => $preload_id})}
	);

    my $results = $self->_get_results($som, $connection);

    return  Elive::Util::_hex_decode($results->[0])
	if $results->[0];

    return;
}

=head2 import_from_server

    my $preload1 = Elive::Entity::Preload->import_from_server(
             {
		    type => 'whiteboard',
		    name => 'introduction.wbd',
		    ownerId => 357147617360,
                    fileName => $path_on_server
	     },
         );

Create a preload from a file that is already present on the server's
file-system. If a C<mimeType> is not supplied, it will be guessed from
the C<name> or C<fileName> extension using L<MIME::Types>.

=cut

sub import_from_server {
    my ($class, $spec, %opt) = @_;

    $spec = {fileName => $spec} if defined $spec && !ref $spec;

    my $insert_data = $class->BUILDARGS($spec);

    die "missing required parameter: fileName"
	unless $insert_data->{fileName};

    $insert_data->{ownerId} ||= do {
	my $connection = $opt{connection} || $class->connection
	    or die "not connected";

	$connection->login->userId;
    };

    $opt{command} ||= 'importPreload';

    return $class->insert($insert_data, %opt);
}

=head2 list_meeting_preloads

my $preloads = Elive::Entity::Preload->list_meeting_preloads($meeting_id);

Returns a list of preloads associated with the given meeting-Id or meeting
object.

=cut

sub list_meeting_preloads {
    my ($self, $meeting_id, %opt) = @_;

    die 'usage: $preload_obj->list_meeting_preloads($meeting)'
	unless $meeting_id;

    $opt{command} ||= 'listMeetingPreloads';

    return $self->_fetch({meetingId => $meeting_id}, %opt);
}

=head2 list

   my $all_preloads = Elive::Entity::Preload->list();

Lists all known preloads.

=cut

sub _thaw {
    my ($class, $db_data, %opt) = @_;

    my $db_thawed = $class->SUPER::_thaw($db_data, %opt);

    for (grep {defined} $db_thawed->{type}) {
	#
	# Just to pass type constraints
	#
	$_ = lc($_);

	unless (m{^media|whiteboard|plan$}x) {
	    Carp::carp "ignoring unknown media type: $_";
	    delete $db_thawed->{type};
	}
    }

    return $db_thawed;
}

=head2 update

The update method is not available for preloads.

=cut

sub update {return shift->_not_available}

sub _guess_mimetype {
    my ($class, $filename) = @_;

    my $mime_type;
    my $guess;

    unless ($filename =~ m{\.elpx?}x) { # plan
	our $mime_types ||= MIME::Types->new;
	$mime_type = $mime_types->mimeTypeOf($filename);

	$guess = $mime_type->type
	    if $mime_type;
    }

    $guess ||= 'application/octet-stream';

    # untaint
    $guess = $1
	if $guess =~ /([[:print:]]+)/;

    return $guess;
}

sub _readback_check {
    my ($class, $update_ref, $rows, @args) = @_;

    #
    # Elluminate 10.0 discards the file extension for whiteboard preloads;
    # bypass check on 'name'.
    #

    my %updates = %{ $update_ref };
    delete $updates{name};

    return $class->SUPER::_readback_check(\%updates, $rows, @args, case_insensitive => 1);
}

=head1 BUGS AND LIMITATIONS

=over 4

=item * Under Elluminate 9.6.0 and LDAP, you may need to arbitrarily add a 'DomN:'
prefix to the owner ID, when creating or updating a meeting.

    $preload->ownerId('Dom1:freddy');

=item * Elluminate 10.0 strips the file extension from the filename when
whiteboard files are saved or uploaded (C<introduction.wbd> => C<introduction>).
However, if the file lacks an extension to begin with, the request crashes with
the confusing error message: C<"string index out of range: -1">.

=item * As of ELM 3.3.5, The C<filter> option appears to have no affect when passed to the C<list()> method.

=back

=cut

1;
