package MVC::Neaf::X::Session::File;

use strict;
use warnings;
our $VERSION = 0.1901;

=head1 NAME

MVC::Neaf::X::Session::File - File-based sessions for Not Even A Framework.

=head1 DESCRIPTION

This module implements session storage, as described in
L<MVC::Neaf::X::Session>.

It will store session data inside a single directory.
The file format is JSON but MAY change in the future.

Uses flock() to avoid collisions.

If session_ttl was specified, old session files will be deleted.

B<NOTE> The file-locking MAY be prone to race conditions. If you want real secure
expiration, please specify expiration INSIDE the session, or use a database.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use MVC::Neaf;
    use MVC::Neaf::X::Session::File;

    MVC::Neaf->set_session_engine(
        engine => MVC::Neaf::X::Session::File->new( dir => $mydir )
    );
    # ... define your application here

=head1 METHODS

=cut

use Fcntl qw(:flock :seek);
use JSON;
use URI::Escape qw(uri_escape);

use parent qw(MVC::Neaf::X::Session);

=head2 new( %options )

Constructor. %options may include:

=over

=item * session_ttl - how long to store session data.

=item * dir (required) - where to store files.

=back

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );

    $self->my_croak( "dir option is mandatory" )
        unless $self->{dir} and -d $self->{dir};

    return $self;
};

=head2 save_session( $id, \%data )

Save session data to a file.

=cut

sub save_session {
    my ($self, $id, $data) = @_;

    my $raw = $self->encode_content( $data );
    my $expire = $self->atomic_write( $id, $raw );
    $expire = $self->{session_ttl} ? $self->{session_ttl}+$expire : undef;

    return {
        id => $id,
        expire => $expire,
    };
};

=head2 load_session( $id )

Load session data from file.
Will DELETE session if session_ttl was specified and exceeded.

=cut

sub load_session {
    my ($self, $id) = @_;

    my ($raw, $expire) = $self->atomic_read( $id );
    return $raw
        ? { data => $self->decode_content( $raw ) }
        : $raw;
};

=head2 delete_session( $id )

Remove a session, if such session is stored at all.

=cut

sub delete_session {
    my ($self, $id) = @_;

    if (!unlink $self->get_file_name( $id )) {
        return 0 if $!{ENOENT} or $!{EPERM} && $^O eq 'MSWin32'; # missing = ok, locked+mswin = ok
        $self->my_croak( "Failed to delete file ".($self->get_file_name( $id ))
            .": $!" );
    };
    return 1;
};

=head2 atomic_read( $id )

Internal mechanism beyond load_file.

=cut

sub atomic_read {
    my ($self, $id) = @_;

    my $fname = $self->get_file_name( $id );
    my $ok = open (my $fd, "<", $fname);
    if (!$ok) {
        $!{ENOENT} and return; # file missing = OK
        $self->my_croak( "Failed to open(r) $fname: $!" );
    };

    flock $fd, LOCK_SH
        or $self->my_croak( "Failed to lock(r) $fname: $!" );

    # Remove stale sessions
    my $ttl = $self->session_ttl;
    my $expire = $ttl && [stat $fd]->[9] + $ttl;
    if ($expire && $expire < time) {
        close $fd if $^O eq 'MSWin32'; # won't delete under windows
        $self->delete_session( $id );
        return;
    };

    local $/;
    my $raw = <$fd>;
    defined $raw
        or $self->my_croak( "Failed to read from $fname: $!" );

    close $fd; # ignore errors
    return ($raw, $expire);
};

=head2 atomic_write( $id, $content )

Internal mechanism beyond save_session.

=cut

sub atomic_write {
    my ($self, $id, $raw) = @_;

    my $fname = $self->get_file_name( $id );
    open (my $fd, ">>", $fname)
        or $self->my_croak( "Failed to open(w) $fname: $!" );

    flock $fd, LOCK_EX
        or $self->my_croak( "Failed to lock(w) $fname: $!" );

    # Have exclusive permissions of fname, truncate & print
    truncate $fd, 0;
    seek $fd, 0, SEEK_SET;
    print $fd $raw
        or $self->my_croak( "Failed to write to $fname: $!" );

    close $fd
        or $self->my_croak( "Failed to sync(w) $fname: $!" );

    return time;
};

=head2 get_file_name( $id )

Convert id into filename.

=cut

sub get_file_name {
    my ($self, $id) = @_;

    $self->my_croak("Storage directory not set")
        unless $self->{dir};
    return join '/', $self->{dir}, uri_escape( $id );
};

=head2 encode_content( $data )

=head2 decode_content( $raw )

Currently JSON is used.

=cut

sub encode_content {
    my ($self, $data) = @_;

    return encode_json( $data );
};

sub decode_content {
    my ($self, $raw) = @_;

    return decode_json( $raw );
};

1;
