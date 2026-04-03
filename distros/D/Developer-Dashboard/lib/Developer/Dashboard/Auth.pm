package Developer::Dashboard::Auth;

use strict;
use warnings;

our $VERSION = '1.33';

use Fcntl qw(:mode);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use POSIX qw(strftime);

use Developer::Dashboard::JSON qw(json_encode json_decode);

# new(%args)
# Constructs an auth manager bound to file and path registries.
# Input: files and paths objects.
# Output: Developer::Dashboard::Auth object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $files = $args{files} || die 'Missing file registry';
    return bless {
        paths => $paths,
        files => $files,
    }, $class;
}

# trust_tier(%args)
# Classifies a request as trusted admin or helper tier.
# Input: remote_addr and host values from the current request.
# Output: tier string, currently 'admin' or 'helper'.
sub trust_tier {
    my ( $self, %args ) = @_;
    my $remote_addr = defined $args{remote_addr} ? $args{remote_addr} : '';
    my $host = $self->_canonical_host( $args{host} );
    return 'admin' if $remote_addr eq '127.0.0.1' && ( !defined $host || $host eq '' || $host eq '127.0.0.1' );
    return 'helper';
}

# add_user(%args)
# Creates or replaces a file-backed helper user record.
# Input: username, password, and optional role.
# Output: saved user hash reference.
sub add_user {
    my ( $self, %args ) = @_;
    my $username = $args{username} || die 'Missing username';
    my $password = $args{password} || die 'Missing password';
    my $role     = $args{role}     || 'helper';
    die 'Username contains unsupported characters'
      if $username !~ /\A[A-Za-z0-9_.-]{1,64}\z/;
    die 'Password must be at least 8 characters long'
      if length($password) < 8;
    my $salt     = sha256_hex( join ':', $$, time, rand(), $username );
    my $record   = {
        username      => $username,
        role          => $role,
        salt          => $salt,
        password_hash => $self->_password_hash( $username, $password, $salt ),
        updated_at    => _now_iso8601(),
    };
    my $file = $self->_user_file($username);
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} json_encode($record);
    close $fh;
    chmod 0600, $file;
    return $record;
}

# verify_user(%args)
# Verifies a username/password pair against stored auth data.
# Input: username and password.
# Output: user hash reference on success or undef on failure.
sub verify_user {
    my ( $self, %args ) = @_;
    my $username = $args{username} || return;
    my $password = $args{password} || return;
    my $user = $self->get_user($username) or return;
    my $expected = $self->_password_hash( $username, $password, $user->{salt} );
    return if $expected ne $user->{password_hash};
    return $user;
}

# get_user($username)
# Loads a single stored user record by username.
# Input: username string.
# Output: user hash reference or undef when missing.
sub get_user {
    my ( $self, $username ) = @_;
    for my $file ( $self->_user_file_candidates($username) ) {
        next if !-f $file;
        open my $fh, '<', $file or die "Unable to read $file: $!";
        local $/;
        return json_decode( scalar <$fh> );
    }
    return;
}

# list_users()
# Lists all valid stored user records.
# Input: none.
# Output: sorted list of user hash references.
sub list_users {
    my ($self) = @_;
    my %users;
    for my $root ( reverse $self->{paths}->users_roots ) {
        opendir my $dh, $root or next;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            next if $entry !~ /(.*)\.json$/;
            my $user = eval { $self->get_user($1) };
            $users{$1} = $user if $user;
        }
        closedir $dh;
    }
    return sort { $a->{username} cmp $b->{username} } values %users;
}

# remove_user($username)
# Removes a stored user record by username.
# Input: username string.
# Output: true value.
sub remove_user {
    my ( $self, $username ) = @_;
    unlink $_ for grep { -f $_ } $self->_user_file_candidates($username);
    return 1;
}

# login_page(%args)
# Builds the helper login page HTML.
# Input: optional message text and optional redirect_to path/query string.
# Output: HTML string.
sub login_page {
    my ( $self, %args ) = @_;
    my $message = $args{message} || 'Helper access requires login.';
    my $redirect_to = defined $args{redirect_to} ? $args{redirect_to} : '';
    $message =~ s/&/&amp;/g;
    $message =~ s/</&lt;/g;
    $message =~ s/>/&gt;/g;
    $redirect_to =~ s/&/&amp;/g;
    $redirect_to =~ s/</&lt;/g;
    $redirect_to =~ s/>/&gt;/g;
    $redirect_to =~ s/"/&quot;/g;
    return <<"HTML";
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Developer Dashboard Login</title>
  <style>
    body { margin: 0; font-family: Georgia, serif; background: #f6efe4; color: #1f2a2e; }
    main { max-width: 520px; margin: 60px auto; background: #fffdf8; border: 1px solid #ddd3c2; padding: 28px; }
    label { display: block; margin: 14px 0 6px; }
    input { width: 100%; box-sizing: border-box; padding: 10px; font-size: 16px; }
    button { margin-top: 18px; padding: 10px 18px; font-size: 16px; }
  </style>
</head>
<body>
<main>
  <h1>Developer Dashboard</h1>
  <p>$message</p>
  <form method="post" action="/login">
    <input name="redirect_to" type="hidden" value="$redirect_to">
    <label for="username">Username</label>
    <input id="username" name="username" type="text" autocomplete="username">
    <label for="password">Password</label>
    <input id="password" name="password" type="password" autocomplete="current-password">
    <button type="submit">Login</button>
  </form>
</main>
</body>
</html>
HTML
}

# _user_file($username)
# Resolves the on-disk file path for a username.
# Input: username string.
# Output: user record file path string.
sub _user_file {
    my ( $self, $username ) = @_;
    my $safe = $username;
    $safe =~ s/[^A-Za-z0-9_.-]+/_/g;
    return File::Spec->catfile( $self->{paths}->users_root, "$safe.json" );
}

# _user_file_candidates($username)
# Returns all candidate user-record file paths in effective lookup order.
# Input: username string.
# Output: ordered list of user record file path strings.
sub _user_file_candidates {
    my ( $self, $username ) = @_;
    my $safe = $username;
    $safe =~ s/[^A-Za-z0-9_.-]+/_/g;
    return map { File::Spec->catfile( $_, "$safe.json" ) } $self->{paths}->users_roots;
}

# _canonical_host($host)
# Normalizes a host header for trust checks.
# Input: host header string, optionally with port.
# Output: normalized lowercase host string or undef.
sub _canonical_host {
    my ( $self, $host ) = @_;
    return if !defined $host;
    $host =~ s/:\d+$//;
    return lc $host;
}

# _password_hash($username, $password, $salt)
# Derives the stored password hash for a user.
# Input: username string, password string, salt string.
# Output: hash string.
sub _password_hash {
    my ( $self, $username, $password, $salt ) = @_;
    return sha256_hex( join ':', $salt, $username, $password );
}

# _now_iso8601()
# Returns the current UTC timestamp in ISO-8601 form.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = gmtime();
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @t );
}

1;

__END__

=head1 NAME

Developer::Dashboard::Auth - local auth and trust-tier handling

=head1 SYNOPSIS

  my $auth = Developer::Dashboard::Auth->new(files => $files, paths => $paths);
  my $user = $auth->verify_user(username => 'mvu', password => 'example-pass-123');

=head1 DESCRIPTION

This module implements the local-first trust model for Developer Dashboard.
Exact loopback requests are treated as trusted admin access, while other
requests authenticate through file-backed helper user records.

=head1 METHODS

=head2 new

Construct an auth manager.

=head2 trust_tier, add_user, verify_user, get_user, list_users, remove_user, login_page

Manage trust decisions, helper users, and login UI.

=cut
