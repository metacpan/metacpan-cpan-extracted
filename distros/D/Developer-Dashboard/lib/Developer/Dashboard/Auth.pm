package Developer::Dashboard::Auth;

use strict;
use warnings;

our $VERSION = '4.26';

use Fcntl qw(:mode);
use Digest::SHA qw(sha256_hex hmac_sha256);
use File::Spec;
use POSIX qw(strftime);
use Socket qw(AF_INET AF_INET6 SOCK_STREAM getaddrinfo inet_ntoa inet_ntop unpack_sockaddr_in unpack_sockaddr_in6);

use Developer::Dashboard::JSON qw(json_encode json_decode);

# Work factor for the PBKDF2-HMAC-SHA256 helper-password scheme. This is the
# iteration count new helper passwords are stretched with; it is also recorded
# per-record so each stored hash is always verified with its own work factor.
my $PBKDF2_ITERATIONS = 210_000;

# Scheme label stored in a helper-user record so verify_user knows which
# derivation to reproduce. Records without this key are legacy single-round
# SHA-256 hashes and are still accepted for backward compatibility.
my $PBKDF2_SCHEME = 'pbkdf2-hmac-sha256';

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
# Input: remote_addr and host values from the current request, plus optional
# extra_loopback_hosts array reference for configured local-only alias hosts.
# Output: tier string, currently 'admin' or 'helper'.
sub trust_tier {
    my ( $self, %args ) = @_;
    my $remote_addr = $self->_canonical_ip( $args{remote_addr} );
    my $host = $self->_canonical_host( $args{host} );
    # Behind the SSL front-proxy every backend connection arrives from the
    # proxy's loopback socket, so remote_addr is ALWAYS loopback and can no
    # longer prove the real client is local. Never grant the loopback-admin
    # shortcut in that mode -- require an explicit helper login instead.
    return 'helper' if $args{ssl_proxied};
    return 'admin' if $self->_request_is_loopback_admin(
        remote_addr          => $remote_addr,
        host                 => $host,
        extra_loopback_hosts => $args{extra_loopback_hosts},
    );
    return 'helper';
}

# add_user(%args)
# Creates or replaces a file-backed helper user record.
# Input: username, password, and optional role.
# Output: saved user hash reference; the stored password is stretched with
# PBKDF2-HMAC-SHA256 and the scheme/iteration work factor is recorded alongside
# it so verification can reproduce the exact derivation later.
sub add_user {
    my ( $self, %args ) = @_;
    my $username = $args{username} || die 'Missing username';
    my $password = $args{password} || die 'Missing password';
    my $role     = $args{role}     || 'helper';
    die 'Username contains unsupported characters'
      if $username !~ /\A[A-Za-z0-9_.-]{1,64}\z/;
    die 'Password must be at least 8 characters long'
      if length($password) < 8;
    my $salt       = sha256_hex( join ':', $$, time, rand(), $username );
    my $iterations = $PBKDF2_ITERATIONS;
    my $record     = {
        username        => $username,
        role            => $role,
        salt            => $salt,
        password_scheme => $PBKDF2_SCHEME,
        iterations      => $iterations,
        password_hash   => _pbkdf2_hmac_sha256_hex( $password, $salt, $iterations ),
        updated_at      => _now_iso8601(),
    };
    my $file = $self->_user_file($username);
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode($record);
    close $fh;
    chmod 0600, $file;
    return $record;
}

# verify_user(%args)
# Verifies a username/password pair against stored auth data.
# Input: username and password.
# Output: user hash reference on success or undef on failure. New records are
# verified with PBKDF2-HMAC-SHA256; pre-existing single-round SHA-256 records
# stay verifiable so upgrading the scheme never locks out established users.
sub verify_user {
    my ( $self, %args ) = @_;
    my $username = $args{username} || return;
    my $password = $args{password} || return;
    my $user = $self->get_user($username) or return;
    my $expected = $self->_expected_password_hash( $user, $username, $password );
    return if !_secure_compare( $expected, $user->{password_hash} );
    return $user;
}

# _expected_password_hash($user, $username, $password)
# Recomputes the stored password hash for a record using that record's own
# scheme so legacy and stretched records both verify against the right
# derivation.
# Input: stored user hash reference, username string, candidate password string.
# Output: expected password-hash hex string for the record's declared scheme.
sub _expected_password_hash {
    my ( $self, $user, $username, $password ) = @_;
    if ( ( $user->{password_scheme} || '' ) eq $PBKDF2_SCHEME ) {
        my $iterations = $user->{iterations} || $PBKDF2_ITERATIONS;    # uncoverable condition false
        return _pbkdf2_hmac_sha256_hex( $password, $user->{salt}, $iterations );
    }
    return $self->_password_hash( $username, $password, $user->{salt} );
}

# get_user($username)
# Loads a single stored user record by username.
# Input: username string.
# Output: user hash reference or undef when missing.
sub get_user {
    my ( $self, $username ) = @_;
    for my $file ( $self->_user_file_candidates($username) ) {
        next if !-f $file;
        open my $fh, '<:raw', $file or die "Unable to read $file: $!";
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
<html lang="en">
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

# helper_users_enabled()
# Reports whether at least one helper user exists for outsider logins.
# Input: none.
# Output: boolean true when helper login access is configured.
sub helper_users_enabled {
    my ($self) = @_;
    my @users = $self->list_users;
    return @users ? 1 : 0;
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
    $host =~ s/^\s+//;
    $host =~ s/\s+$//;
    return if $host eq '';
    if ( $host =~ /^\[([0-9A-Fa-f:.]+)\](?::\d+)?$/ ) {
        $host = $1;
    }
    elsif ( $host =~ /^([^:]+):\d+$/ ) {
        $host = $1;
    }
    return lc $host;
}

# _request_is_loopback_admin(%args)
# Reports whether one request should be treated as trusted local-admin traffic.
# Hostnames that are well-known local-machine aliases ('localhost',
# 'localhost.localdomain') are always accepted.  Hostnames that merely resolve
# to loopback via DNS are NOT trusted — that prevents DNS-rebinding attacks
# where an attacker hostname resolves to 127.0.0.1.
# Input: canonical remote_addr IP string and canonical host string.
# Output: boolean true when the request comes from loopback and the host
# belongs to an explicitly trusted local-only set.
sub _request_is_loopback_admin {
    my ( $self, %args ) = @_;
    my $remote_addr = $args{remote_addr} || '';
    my $host = $args{host};
    return 0 if !$self->_ip_is_loopback($remote_addr);
    return 1 if !defined $host || $host eq '';
    return $self->host_is_local_alias(
        host                 => $host,
        extra_loopback_hosts => $args{extra_loopback_hosts},
    );
}

# host_is_local_alias(%args)
# Reports whether one host value is an explicitly trusted name for this
# machine: a numeric loopback literal, a configured local-only alias from
# web.ssl_subject_alt_names, or a well-known localhost hostname. IPv6 brackets
# and any :port suffix are stripped before comparison, so the loopback-admin
# trust check and the web layer's cross-site Origin/Referer check apply one
# shared alias semantics. Hostnames that merely resolve to loopback via DNS
# are NOT accepted — that is the DNS-rebinding protection.
# Input: host string (optionally host:port or [v6]:port) plus optional
# extra_loopback_hosts array reference of configured local-only alias hosts.
# Output: boolean true when the host names this machine itself.
sub host_is_local_alias {
    my ( $self, %args ) = @_;
    my $host = $self->_canonical_host( $args{host} );
    # _canonical_host returns undef or a non-empty lowercased host, never an
    # empty string, so undef is the only not-a-host outcome to reject here.
    return 0 if !defined $host;
    my @extra_loopback_hosts = map { $self->_canonical_host($_) }
      grep { defined $_ && $_ ne '' }
      @{ ref( $args{extra_loopback_hosts} ) eq 'ARRAY' ? $args{extra_loopback_hosts} : [] };
    return 1 if $self->_ip_is_loopback( $self->_canonical_ip($host) );
    return 1 if grep { $_ eq $host } @extra_loopback_hosts;
    # Well-known system-local hostnames are implicitly trusted without
    # DNS resolution.  This list is intentionally small — arbitrary
    # hostnames that happen to resolve to loopback are NOT trusted,
    # preventing DNS-rebinding admin elevation.
    return 1 if $host eq 'localhost';
    return 1 if $host eq 'localhost.localdomain';
    return 1 if $host eq 'localhost6' || $host eq 'localhost6.localdomain6';
    return 0;    # Any other hostname is not local even when it resolves to loopback
}

# _host_resolves_only_to_loopback($host)
# Resolves one hostname and checks whether every resolved address is loopback-safe.
# Input: canonical host string.
# Output: boolean true when all resolved IPs are loopback addresses.
sub _host_resolves_only_to_loopback {
    my ( $self, $host ) = @_;
    return 0 if !defined $host || $host eq '';
    my @ips = $self->_resolve_host_ips($host);
    return 0 if !@ips;
    return !grep { !$self->_ip_is_loopback($_) } @ips;
}

# _resolve_host_ips($host)
# Resolves one hostname into canonical IPv4/IPv6 literal strings.
# Input: canonical host string.
# Output: list of canonical IP strings, possibly empty when resolution fails.
sub _resolve_host_ips {
    my ( $self, $host ) = @_;
    return () if !defined $host || $host eq '';
    my ( $err, @results ) = getaddrinfo( $host, undef, { socktype => SOCK_STREAM } );
    return () if $err;
    my @ips;
    my %seen;
    for my $result (@results) {
        next if ref($result) ne 'HASH';
        my $family = $result->{family};
        my $addr = $result->{addr};
        my $ip;
        if ( defined $family && $family == AF_INET ) {
            my ( undef, $packed_addr ) = unpack_sockaddr_in($addr);
            $ip = inet_ntoa($packed_addr);
        }
        elsif ( defined $family && $family == AF_INET6 ) {
            my ( undef, $packed_addr ) = unpack_sockaddr_in6($addr);
            $ip = inet_ntop( AF_INET6, $packed_addr );
        }
        $ip = $self->_canonical_ip($ip);
        next if $ip eq '';
        next if $seen{$ip}++;
        push @ips, $ip;
    }
    return @ips;
}

# _canonical_ip($value)
# Normalizes one IPv4/IPv6 literal into a comparable canonical string.
# Input: raw IP string.
# Output: canonical IP string or the original value when it is not an IP literal.
sub _canonical_ip {
    my ( $self, $value ) = @_;
    return '' if !defined $value;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return '' if $value eq '';
    if ( $value =~ /\A(?:\d{1,3}\.){3}\d{1,3}\z/ ) {
        return $value;
    }
    if ( $value =~ /:/ ) {
        my $packed = Socket::inet_pton( AF_INET6, $value );
        return defined $packed ? lc( inet_ntop( AF_INET6, $packed ) ) : lc $value;
    }
    return lc $value;
}

# _ip_is_loopback($ip)
# Reports whether one canonical IP literal is loopback-only.
# Input: canonical IPv4/IPv6 literal string.
# Output: boolean true for 127.0.0.0/8 with valid 0-255 octets or ::1; strings
# with out-of-range octets such as 127.0.0.999 are not treated as loopback.
sub _ip_is_loopback {
    my ( $self, $ip ) = @_;
    return 0 if !defined $ip || $ip eq '';
    return 1 if $ip =~ /\A127(?:\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}\z/;
    return 1 if $ip eq '::1' || $ip eq '0:0:0:0:0:0:0:1';
    return 0;
}

# _password_hash($username, $password, $salt)
# Derives the legacy single-round SHA-256 password hash for a user. Retained
# only so pre-existing helper records created before password stretching keep
# verifying; new records use the PBKDF2 scheme instead.
# Input: username string, password string, salt string.
# Output: hash string.
sub _password_hash {
    my ( $self, $username, $password, $salt ) = @_;
    return sha256_hex( join ':', $salt, $username, $password );
}

# _pbkdf2_hmac_sha256_hex($password, $salt, $iterations)
# Stretches a password with PBKDF2-HMAC-SHA256 (RFC 2898). The 32-byte SHA-256
# output equals the derived-key length, so exactly one output block is needed.
# Input: password string, salt string, positive iteration count.
# Output: 64-character lowercase hex string of the derived key.
sub _pbkdf2_hmac_sha256_hex {
    my ( $password, $salt, $iterations ) = @_;
    my $u      = hmac_sha256( $salt . pack( 'N', 1 ), $password );
    my $result = $u;
    for ( 2 .. $iterations ) {
        $u = hmac_sha256( $u, $password );
        $result ^= $u;
    }
    return unpack( 'H*', $result );
}

# _secure_compare($left, $right)
# Compares two strings in length-constant time so password-hash verification
# does not leak how many leading characters matched through timing.
# Input: two strings (either may be undef).
# Output: boolean true only when both are defined, equal length, and identical.
sub _secure_compare {
    my ( $left, $right ) = @_;
    return 0 if !defined $left || !defined $right;
    return 0 if length($left) != length($right);
    my $diff = 0;
    $diff |= ord( substr( $left, $_, 1 ) ) ^ ord( substr( $right, $_, 1 ) )
      for 0 .. length($left) - 1;
    return $diff == 0 ? 1 : 0;
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
Loopback requests using loopback-local IPs such as C<127.0.0.1> or C<::1>,
explicitly configured local alias names, or the well-known hostnames
C<localhost>, C<localhost.localdomain>, C<localhost6>, and
C<localhost6.localdomain6> can be treated as trusted admin access, while
all other requests authenticate through file-backed helper user records.

DNS-rebinding protection: hostnames that merely resolve to loopback addresses
via DNS are NOT granted admin trust.  Only the well-known local-machine
aliases listed above, configured C<extra_loopback_hosts>, and literal loopback
IPs are accepted.  This prevents an attacker-controlled hostname that resolves
to C<127.0.0.1> from gaining admin access over a loopback connection.

Helper passwords are stored stretched with PBKDF2-HMAC-SHA256 and each record
carries its own scheme label and iteration work factor. Helper records written
before stretching was introduced used a single-round salted SHA-256 hash and
are still accepted, so tightening the scheme never locks out an established
helper user.

=head1 METHODS

=head2 new

Construct an auth manager.

=head2 trust_tier, add_user, verify_user, get_user, list_users, remove_user, login_page, helper_users_enabled

Manage trust decisions, helper users, and login UI.

=head2 host_is_local_alias

Report whether one host value is an explicitly trusted local name for this
machine: a numeric loopback literal, a configured local-only alias, or a
well-known localhost hostname. The loopback-admin trust check and the web
layer's cross-site Origin/Referer defense share this method so both apply
identical alias semantics.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module owns helper-user authentication. It stores helper users in the runtime, verifies passwords, renders login-page state, and applies the access rules that distinguish local admin access from helper-user access for non-loopback clients.

=head1 WHY IT EXISTS

It exists because authentication policy should not be scattered across route code. Centralizing helper-user verification and login-page behavior keeps the auth boundary explicit and makes it possible to test the outsider-versus-helper rules directly.

=head1 WHEN TO USE

Use this file when changing helper password requirements, login-page messaging, user storage, or the verification logic that decides whether a submitted helper login is valid.

=head1 HOW TO USE

Construct it with the runtime file and path registries, then use methods such as C<add_user>, C<verify_user>, C<list_users>, and C<login_page>. Route handlers should call into this module instead of parsing auth data themselves.

=head1 WHAT USES IT

It is used by the web app login flow, by CLI helper-user administration commands, by session/bootstrap logic that decides whether outsider access should be challenged, and by focused auth regression tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Auth -e 1

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
