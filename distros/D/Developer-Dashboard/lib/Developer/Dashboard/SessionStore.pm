package Developer::Dashboard::SessionStore;

use strict;
use warnings;

our $VERSION = '2.76';

use Digest::SHA qw(sha256_hex);
use File::Spec;
use POSIX qw(strftime);

use Developer::Dashboard::JSON qw(json_encode json_decode);

# new(%args)
# Constructs the file-backed session store.
# Input: paths object.
# Output: Developer::Dashboard::SessionStore object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    return bless { paths => $paths }, $class;
}

# create(%args)
# Creates and persists a new browser session record.
# Input: username, role, and optional remote address.
# Output: session hash reference.
sub create {
    my ( $self, %args ) = @_;
    my $username = $args{username} || die 'Missing username';
    my $role     = $args{role}     || 'helper';
    my $ttl      = $args{ttl_seconds} || 43_200;
    my $session_id = sha256_hex( join ':', $$, time, rand(), $username, $role );
    my $record = {
        session_id  => $session_id,
        username    => $username,
        role        => $role,
        remote_addr => $args{remote_addr} || '',
        created_at  => _now_iso8601(),
        expires_at  => _iso8601_after($ttl),
        updated_at  => _now_iso8601(),
    };
    my $file = $self->_session_file($session_id);
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode($record);
    close $fh;
    chmod 0600, $file;
    return $record;
}

# get($session_id)
# Loads a session record by session id.
# Input: session id string.
# Output: session hash reference or undef when missing.
sub get {
    my ( $self, $session_id ) = @_;
    return if !defined $session_id || $session_id eq '';
    for my $file ( $self->_session_file_candidates($session_id) ) {
        next if !-f $file;
        open my $fh, '<:raw', $file or die "Unable to read $file: $!";
        local $/;
        return json_decode( scalar <$fh> );
    }
    return;
}

# delete($session_id)
# Deletes a stored session record.
# Input: session id string.
# Output: true value.
sub delete {
    my ( $self, $session_id ) = @_;
    return if !defined $session_id || $session_id eq '';
    unlink $_ for grep { -f $_ } $self->_session_file_candidates($session_id);
    return 1;
}

# from_cookie($cookie, %args)
# Resolves a dashboard session from a Cookie header and validates it.
# Input: raw cookie header string plus optional remote address.
# Output: session hash reference or undef when not present/invalid.
sub from_cookie {
    my ( $self, $cookie, %args ) = @_;
    return if !defined $cookie || $cookie eq '';
    my %pairs;
    for my $part ( split /;\s*/, $cookie ) {
        my ( $k, $v ) = split /=/, $part, 2;
        next if !defined $k || $k eq '';
        $pairs{$k} = defined $v ? $v : '';
    }
    my $session = $self->get( $pairs{dashboard_session} ) or return;
    if ( $session->{expires_at} && _iso8601_to_epoch( $session->{expires_at} ) <= time ) {
        $self->delete( $session->{session_id} );
        return;
    }
    if ( defined $args{remote_addr} && defined $session->{remote_addr} && $session->{remote_addr} ne '' ) {
        return if $session->{remote_addr} ne $args{remote_addr};
    }
    return $session;
}

# _session_file($session_id)
# Resolves the session storage file path.
# Input: session id string.
# Output: file path string.
sub _session_file {
    my ( $self, $session_id ) = @_;
    return File::Spec->catfile( $self->{paths}->sessions_root, "$session_id.json" );
}

# _session_file_candidates($session_id)
# Returns all candidate session file paths in effective lookup order.
# Input: session id string.
# Output: ordered list of session file path strings.
sub _session_file_candidates {
    my ( $self, $session_id ) = @_;
    return map { File::Spec->catfile( $_, "$session_id.json" ) } $self->{paths}->sessions_roots;
}

# _now_iso8601()
# Returns the current UTC timestamp in ISO-8601 form.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = gmtime();
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @t );
}

# _iso8601_after($seconds)
# Returns an ISO-8601 timestamp that is the given number of seconds in the future.
# Input: ttl seconds integer.
# Output: timestamp string.
sub _iso8601_after {
    my ($seconds) = @_;
    my $epoch = time + ( $seconds || 0 );
    my @t = gmtime($epoch);
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @t );
}

# _iso8601_to_epoch($text)
# Converts an ISO-8601 UTC timestamp to epoch seconds.
# Input: timestamp string.
# Output: epoch integer.
sub _iso8601_to_epoch {
    my ($text) = @_;
    return 0 if !defined $text || $text !~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z\z/;
    require Time::Local;
    return Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 );
}

1;

__END__

=head1 NAME

Developer::Dashboard::SessionStore - file-backed browser sessions

=head1 SYNOPSIS

  my $sessions = Developer::Dashboard::SessionStore->new(paths => $paths);
  my $session  = $sessions->create(username => 'mvu');

=head1 DESCRIPTION

This module stores helper login sessions on disk so the web application can
persist authenticated helper access between requests.

=head1 METHODS

=head2 new, create, get, delete, from_cookie

Construct and manage session records.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module stores helper login sessions with remote-address binding and expiry metadata. It is the persistence layer behind helper login cookies and the helper-only browser access model.

=head1 WHY IT EXISTS

It exists because helper authentication needs durable session state with explicit security rules. By keeping that state in one store, login, logout, and request-auth checks all validate the same session contract.

=head1 WHEN TO USE

Use this file when changing helper session lifetime, binding rules, or the stored session record shape.

=head1 HOW TO USE

Construct it with the active path registry and use its session create/load/delete methods from the auth-aware web routes instead of reading session files directly.

=head1 WHAT USES IT

It is used by the web app login/logout flow, by auth tests that verify expiry and remote binding, and by helper-access integration smoke.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::SessionStore -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/03-web-app.t t/08-web-update-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
