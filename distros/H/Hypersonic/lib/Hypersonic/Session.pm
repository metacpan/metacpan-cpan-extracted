package Hypersonic::Session;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.03';

# Session management for Hypersonic
# Uses signed cookies for session ID, memory store for data
# Digest::SHA provides fast C-based HMAC-SHA256
# Only activated when session_config() is called

use Digest::SHA qw(hmac_sha256_hex);

# Session slot constants (used in Request object)
use constant {
    SLOT_SESSION          => 12,
    SLOT_SESSION_ID       => 13,
    SLOT_SESSION_MODIFIED => 14,
};

# Export slot constants
use Exporter 'import';
our @EXPORT_OK = qw(
    SLOT_SESSION SLOT_SESSION_ID SLOT_SESSION_MODIFIED
);

# Global session store - memory-based (survives across requests)
my %SESSION_STORE;
my $SESSION_CONFIG;

# JIT compilation state
my $COMPILED = 0;
my $MODULE_ID = 0;

# ============================================================
# JIT Compilation of Cryptographic Operations
# ============================================================

sub compile_session_ops {
    my ($class, %opts) = @_;

    return 1 if $COMPILED;

    # Check if OpenSSL is available (via TLS module)
    eval { require Hypersonic::TLS };
    if ($@) {
        warn "Hypersonic::Session: Cannot load TLS module, using pure Perl crypto: $@\n"
            if $ENV{HYPERSONIC_DEBUG};
        return 0;
    }

    my $has_openssl = Hypersonic::TLS::check_openssl();
    unless ($has_openssl) {
        warn "Hypersonic::Session: OpenSSL not available, using pure Perl crypto\n"
            if $ENV{HYPERSONIC_DEBUG};
        return 0;
    }

    # Get OpenSSL flags - must be non-empty for compilation to work
    my $extra_cflags = Hypersonic::TLS::get_extra_cflags() // '';
    my $extra_ldflags = Hypersonic::TLS::get_extra_ldflags() // '';

    unless ($extra_cflags =~ /-I/) {
        warn "Hypersonic::Session: OpenSSL headers not found, using pure Perl crypto\n"
            if $ENV{HYPERSONIC_DEBUG};
        return 0;
    }

    my $cache_dir = $opts{cache_dir} // '_hypersonic_session_cache';
    my $module_name = 'Hypersonic::Session::Ops_' . $MODULE_ID++;

    my $builder = XS::JIT::Builder->new;

    # Add required includes
    $builder->line('#include <openssl/hmac.h>')
            ->line('#include <openssl/evp.h>')
            ->line('#include <openssl/rand.h>')
            ->line('#include <fcntl.h>')
            ->line('#include <unistd.h>')
            ->line('#include <string.h>')
            ->blank;

    # --------------------------------------------------------
    # jit_hmac_sha256_hex: Generate HMAC-SHA256 signature
    # Input: data (SV*), key (SV*), output_len (IV, optional, default 32)
    # Output: hex-encoded signature (SV*)
    # --------------------------------------------------------
    $builder->xs_function('jit_hmac_sha256_hex')
      ->xs_preamble
      ->line('if (items < 2) croak("Usage: _jit_hmac_sha256_hex(data, key, [output_len])");')
      ->line('STRLEN data_len, key_len;')
      ->line('const unsigned char* data = (const unsigned char*)SvPV(ST(0), data_len);')
      ->line('const unsigned char* key = (const unsigned char*)SvPV(ST(1), key_len);')
      ->line('IV out_len = items > 2 ? SvIV(ST(2)) : 32;')
      ->line('if (out_len > 64) out_len = 64;')
      ->line('if (out_len < 1) out_len = 1;')
      ->blank
      ->line('unsigned char digest[EVP_MAX_MD_SIZE];')
      ->line('unsigned int digest_len = 0;')
      ->line('HMAC(EVP_sha256(), key, (int)key_len, data, data_len, digest, &digest_len);')
      ->blank
      ->line('char hex[129];')
      ->line('int hex_bytes = (int)(out_len / 2);')
      ->line('if (hex_bytes > 32) hex_bytes = 32;')
      ->line('for (int i = 0; i < hex_bytes; i++) {')
      ->line('    sprintf(hex + i*2, "%02x", digest[i]);')
      ->line('}')
      ->line('hex[out_len] = \'\\0\';')
      ->blank
      ->line('ST(0) = sv_2mortal(newSVpv(hex, out_len));')
      ->xs_return('1')
      ->xs_end;

    # --------------------------------------------------------
    # jit_constant_time_compare: Timing-attack resistant compare
    # Input: s1 (SV*), s2 (SV*)
    # Output: 1 if equal, 0 if not (IV)
    # --------------------------------------------------------
    $builder->xs_function('jit_constant_time_compare')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: _jit_constant_time_compare(s1, s2)");')
      ->line('STRLEN len1, len2;')
      ->line('const unsigned char* s1 = (const unsigned char*)SvPV(ST(0), len1);')
      ->line('const unsigned char* s2 = (const unsigned char*)SvPV(ST(1), len2);')
      ->blank
      ->comment('Length mismatch - still do constant-time work')
      ->line('STRLEN max_len = len1 > len2 ? len1 : len2;')
      ->line('unsigned char diff = (len1 != len2) ? 1 : 0;')
      ->blank
      ->line('for (STRLEN i = 0; i < max_len; i++) {')
      ->line('    unsigned char c1 = (i < len1) ? s1[i] : 0;')
      ->line('    unsigned char c2 = (i < len2) ? s2[i] : 0;')
      ->line('    diff |= c1 ^ c2;')
      ->line('}')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(diff == 0 ? 1 : 0));')
      ->xs_return('1')
      ->xs_end;

    # --------------------------------------------------------
    # jit_generate_session_id: Generate secure random session ID
    # Input: (none)
    # Output: 32-char hex string (SV*)
    # --------------------------------------------------------
    $builder->xs_function('jit_generate_session_id')
      ->xs_preamble
      ->line('unsigned char bytes[16];')
      ->blank
      ->comment('Try /dev/urandom first (most portable)')
      ->line('int fd = open("/dev/urandom", O_RDONLY);')
      ->if('fd >= 0')
        ->line('ssize_t n = read(fd, bytes, 16);')
        ->line('close(fd);')
        ->if('n != 16')
          ->line('croak("Failed to read 16 bytes from /dev/urandom");')
        ->endif
      ->else
        ->comment('Fallback to OpenSSL RAND_bytes')
        ->if('RAND_bytes(bytes, 16) != 1')
          ->line('croak("Failed to generate random bytes");')
        ->endif
      ->endif
      ->blank
      ->comment('Convert to hex')
      ->line('char hex[33];')
      ->line('for (int i = 0; i < 16; i++) {')
      ->line('    sprintf(hex + i*2, "%02x", bytes[i]);')
      ->line('}')
      ->line('hex[32] = \'\\0\';')
      ->blank
      ->line('ST(0) = sv_2mortal(newSVpv(hex, 32));')
      ->xs_return('1')
      ->xs_end;

    # --------------------------------------------------------
    # jit_verify_signature: Combined verify operation
    # Input: signed_cookie (SV*), secret (SV*)
    # Output: session_id if valid (SV*), undef if invalid
    # Format: 32-char-hex-id.16-char-hex-sig (49 chars total)
    # --------------------------------------------------------
    $builder->xs_function('jit_verify_signature')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: _jit_verify_signature(signed_cookie, secret)");')
      ->line('STRLEN cookie_len, secret_len;')
      ->line('const char* cookie = SvPV(ST(0), cookie_len);')
      ->line('const char* secret = SvPV(ST(1), secret_len);')
      ->blank
      ->comment('Validate format: 32-char-hex-id.16-char-hex-sig')
      ->if('cookie_len != 49 || cookie[32] != \'.\'')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Validate hex characters in session_id')
      ->line('for (int i = 0; i < 32; i++) {')
      ->line('    char c = cookie[i];')
      ->line('    if (!((c >= \'0\' && c <= \'9\') || (c >= \'a\' && c <= \'f\'))) {')
      ->line('        ST(0) = &PL_sv_undef;')
      ->line('        XSRETURN(1);')
      ->line('    }')
      ->line('}')
      ->blank
      ->comment('Extract session_id')
      ->line('char session_id[33];')
      ->line('memcpy(session_id, cookie, 32);')
      ->line('session_id[32] = \'\\0\';')
      ->blank
      ->comment('Get provided signature')
      ->line('const char* provided_sig = cookie + 33;')
      ->blank
      ->comment('Compute expected HMAC signature')
      ->line('unsigned char digest[EVP_MAX_MD_SIZE];')
      ->line('unsigned int digest_len = 0;')
      ->line('HMAC(EVP_sha256(), secret, (int)secret_len, (unsigned char*)session_id, 32, digest, &digest_len);')
      ->blank
      ->comment('Convert first 8 bytes to hex (16 chars)')
      ->line('char expected[17];')
      ->line('for (int i = 0; i < 8; i++) {')
      ->line('    sprintf(expected + i*2, "%02x", digest[i]);')
      ->line('}')
      ->line('expected[16] = \'\\0\';')
      ->blank
      ->comment('Constant-time comparison')
      ->line('unsigned char diff = 0;')
      ->line('for (int i = 0; i < 16; i++) {')
      ->line('    diff |= expected[i] ^ provided_sig[i];')
      ->line('}')
      ->blank
      ->if('diff != 0')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newSVpv(session_id, 32));')
      ->xs_return('1')
      ->xs_end;

    # Compile via XS::JIT
    eval {
        XS::JIT->compile(
            code          => $builder->code,
            name          => $module_name,
            cache_dir     => $cache_dir,
            extra_cflags  => $extra_cflags,
            extra_ldflags => $extra_ldflags,
            functions     => {
                'Hypersonic::Session::_jit_hmac_sha256_hex'      => { source => 'jit_hmac_sha256_hex', is_xs_native => 1 },
                'Hypersonic::Session::_jit_constant_time_compare' => { source => 'jit_constant_time_compare', is_xs_native => 1 },
                'Hypersonic::Session::_jit_generate_session_id'   => { source => 'jit_generate_session_id', is_xs_native => 1 },
                'Hypersonic::Session::_jit_verify_signature'      => { source => 'jit_verify_signature', is_xs_native => 1 },
            },
        );
        $COMPILED = 1;
    };
    if ($@) {
        warn "Hypersonic::Session: JIT compilation failed, using pure Perl: $@\n"
            if $ENV{HYPERSONIC_DEBUG};
    }

    return $COMPILED;
}

# Check if JIT is compiled
sub is_jit_compiled { $COMPILED }

# ============================================================
# Core Cryptographic Functions (JIT or Perl fallback)
# ============================================================

# Session ID generation using secure random
sub _generate_session_id {
    # Use JIT-compiled version if available and actually defined
    if ($COMPILED && defined &_jit_generate_session_id) {
        return _jit_generate_session_id();
    }

    # Perl fallback
    my $bytes;

    # Try /dev/urandom first (Unix)
    if (-r '/dev/urandom') {
        open my $fh, '<:raw', '/dev/urandom' or die "Cannot open /dev/urandom: $!";
        read($fh, $bytes, 16);
        close $fh;
    } else {
        # Fallback to Perl's rand (less secure, but works everywhere)
        $bytes = pack('L*', map { int(rand(2**32)) } 1..4);
    }

    return unpack('H*', $bytes);
}

# Sign a session ID with HMAC-SHA256
sub _sign {
    my ($session_id, $secret) = @_;

    # Use JIT-compiled HMAC if available and actually defined
    if ($COMPILED && defined &_jit_hmac_sha256_hex) {
        my $sig = _jit_hmac_sha256_hex($session_id, $secret, 16);
        return "$session_id.$sig";
    }

    # Perl fallback
    my $sig = substr(hmac_sha256_hex($session_id, $secret), 0, 16);
    return "$session_id.$sig";
}

# Verify and extract session ID from signed cookie
sub _verify {
    my ($signed_cookie, $secret) = @_;

    # Use JIT-compiled combined verify if available and actually defined
    if ($COMPILED && defined &_jit_verify_signature) {
        return _jit_verify_signature($signed_cookie, $secret);
    }

    # Perl fallback
    return unless $signed_cookie && $signed_cookie =~ /^([a-f0-9]{32})\.([a-f0-9]{16})$/;

    my ($session_id, $sig) = ($1, $2);
    my $expected = substr(hmac_sha256_hex($session_id, $secret), 0, 16);

    # Constant-time comparison to prevent timing attacks
    return unless length($sig) == length($expected);
    my $diff = 0;
    $diff |= ord(substr($sig, $_, 1)) ^ ord(substr($expected, $_, 1)) for 0 .. length($sig) - 1;

    return $diff == 0 ? $session_id : undef;
}

# Constant-time string comparison
sub _constant_time_compare {
    my ($s1, $s2) = @_;

    # Use JIT-compiled version if available and actually defined
    if ($COMPILED && defined &_jit_constant_time_compare) {
        return _jit_constant_time_compare($s1, $s2);
    }

    # Perl fallback
    return 0 unless defined $s1 && defined $s2;
    return 0 unless length($s1) == length($s2);

    my $diff = 0;
    $diff |= ord(substr($s1, $_, 1)) ^ ord(substr($s2, $_, 1)) for 0 .. length($s1) - 1;

    return $diff == 0 ? 1 : 0;
}

# ============================================================
# Session Configuration and Middleware
# ============================================================

# Configure session handling
sub configure {
    my ($class, %opts) = @_;

    die "Session secret is required" unless $opts{secret} && length($opts{secret}) >= 16;

    # Try to compile JIT ops on first configuration
    $class->compile_session_ops(cache_dir => $opts{cache_dir}) unless $COMPILED;

    $SESSION_CONFIG = {
        secret      => $opts{secret},
        cookie_name => $opts{cookie_name} // 'hsid',
        max_age     => $opts{max_age} // 86400,  # 1 day default
        path        => $opts{path} // '/',
        httponly    => $opts{httponly} // 1,
        secure      => $opts{secure} // 0,
        samesite    => $opts{samesite} // 'Lax',
    };

    return $SESSION_CONFIG;
}

# Get session config
sub config { $SESSION_CONFIG }

# Generate before middleware for session loading
sub before_middleware {
    return sub {
        my ($req) = @_;

        my $config = $SESSION_CONFIG or return;

        # Get session cookie
        my $signed_cookie = $req->cookie($config->{cookie_name});

        my ($session_id, $data);

        if ($signed_cookie) {
            # Verify signature and get session ID
            $session_id = _verify($signed_cookie, $config->{secret});

            if ($session_id && exists $SESSION_STORE{$session_id}) {
                $data = $SESSION_STORE{$session_id};
            }
        }

        # Create new session if needed
        unless ($session_id && $data) {
            $session_id = _generate_session_id();
            $data = { _created => time(), _new => 1 };
            $SESSION_STORE{$session_id} = $data;
        }

        # Store in request (use the session slot)
        $req->[SLOT_SESSION] = $data;
        $req->[SLOT_SESSION_ID] = $session_id;
        $req->[SLOT_SESSION_MODIFIED] = 0;

        return;  # Continue to handler
    };
}

# Generate after middleware for session saving
sub after_middleware {
    return sub {
        my ($req, $res) = @_;

        my $config = $SESSION_CONFIG or return $res;

        my $session_id = $req->[SLOT_SESSION_ID];
        my $data = $req->[SLOT_SESSION];
        my $modified = $req->[SLOT_SESSION_MODIFIED];
        my $is_new = $data && $data->{_new};

        # Only set cookie if session is new or modified
        if ($session_id && ($is_new || $modified)) {
            delete $data->{_new} if $data;

            # Sign the session ID
            my $signed = _sign($session_id, $config->{secret});

            # Set cookie on response
            $res->cookie($config->{cookie_name}, $signed,
                path     => $config->{path},
                max_age  => $config->{max_age},
                httponly => $config->{httponly},
                secure   => $config->{secure},
                samesite => $config->{samesite},
            );

            # Save session data
            $SESSION_STORE{$session_id} = $data if $data;
        }

        return $res;
    };
}

# ============================================================
# Session Data Access Methods
# ============================================================

# Session accessor - get or set session values
# Called as: $req->session('key') or $req->session('key', $value)
sub get_set {
    my ($req, $key, $value) = @_;

    my $data = $req->[SLOT_SESSION];
    return unless $data;

    if (@_ == 2) {
        # Getter
        return $data->{$key};
    } else {
        # Setter
        $data->{$key} = $value;
        $req->[SLOT_SESSION_MODIFIED] = 1;
        return $value;
    }
}

# Get all session data
sub get_all {
    my ($req) = @_;
    return $req->[SLOT_SESSION];
}

# Clear session
sub clear {
    my ($req) = @_;

    my $session_id = $req->[SLOT_SESSION_ID];
    delete $SESSION_STORE{$session_id} if $session_id;

    $req->[SLOT_SESSION] = {};
    $req->[SLOT_SESSION_MODIFIED] = 1;
}

# Regenerate session ID (for security, e.g., after login)
sub regenerate {
    my ($req) = @_;

    my $old_id = $req->[SLOT_SESSION_ID];
    my $data = $req->[SLOT_SESSION] || {};

    # Delete old session
    delete $SESSION_STORE{$old_id} if $old_id;

    # Create new session ID
    my $new_id = _generate_session_id();
    $SESSION_STORE{$new_id} = $data;

    $req->[SLOT_SESSION_ID] = $new_id;
    $req->[SLOT_SESSION_MODIFIED] = 1;

    return $new_id;
}

# Cleanup expired sessions (call periodically)
sub cleanup {
    my ($max_age) = @_;
    $max_age //= $SESSION_CONFIG->{max_age} // 86400;

    my $cutoff = time() - $max_age;

    for my $id (keys %SESSION_STORE) {
        my $data = $SESSION_STORE{$id};
        if ($data && $data->{_created} && $data->{_created} < $cutoff) {
            delete $SESSION_STORE{$id};
        }
    }
}

# For testing - get store size
sub _store_size { scalar keys %SESSION_STORE }

# For testing - clear entire store
sub _clear_store { %SESSION_STORE = () }

# For testing - reset JIT state
sub _reset_jit { $COMPILED = 0; $MODULE_ID = 0; }

1;

__END__

=head1 NAME

Hypersonic::Session - JIT-compiled session management for Hypersonic

=head1 SYNOPSIS

    use Hypersonic;

    my $server = Hypersonic->new();

    # Enable sessions
    $server->session_config(
        secret      => 'your-secret-key-at-least-16-chars',
        cookie_name => 'sid',
        max_age     => 86400,      # 1 day
        httponly    => 1,
        secure      => 1,          # HTTPS only
        samesite    => 'Strict',
    );

    # Use sessions in handlers
    $server->get('/profile' => sub {
        my ($req) = @_;
        my $user = $req->session('user');
        return res->json({ user => $user });
    }, { dynamic => 1 });

    $server->post('/login' => sub {
        my ($req) = @_;
        my $data = $req->json;

        # Set session data
        $req->session(user => $data->{username});
        $req->session(logged_in => 1);

        return res->json({ success => 1 });
    }, { dynamic => 1, parse_json => 1 });

    $server->post('/logout' => sub {
        my ($req) = @_;
        $req->session_clear;
        return res->json({ logged_out => 1 });
    }, { dynamic => 1 });

=head1 DESCRIPTION

C<Hypersonic::Session> provides fast, secure session management using
signed cookies for session IDs and in-memory storage for session data.

=head2 JIT-Compiled Cryptography

When OpenSSL is available, cryptographic operations are JIT-compiled to
native C code for maximum performance:

=over 4

=item * B<HMAC-SHA256 signing> - Direct OpenSSL calls (~3-5x faster)

=item * B<Session ID generation> - Direct /dev/urandom read (~5-10x faster)

=item * B<Constant-time comparison> - C-level timing attack resistance

=item * B<Combined verification> - Single C function for parse+verify

=back

Falls back to pure Perl (Digest::SHA) when OpenSSL is unavailable.

=head2 Security Features

=over 4

=item * HMAC-SHA256 signed session IDs (tamper-proof)

=item * Secure random session ID generation

=item * Constant-time signature verification (timing attack resistant)

=item * HttpOnly and Secure cookie flags

=item * SameSite cookie attribute

=back

=head2 JIT Philosophy

Session middleware is only injected when C<session_config()> is called.
No session code runs for routes that don't use sessions.

=head1 CONFIGURATION OPTIONS

=over 4

=item secret (required)

Secret key for HMAC signing. Must be at least 16 characters.

=item cookie_name

Session cookie name. Default: C<hsid>

=item max_age

Session lifetime in seconds. Default: C<86400> (1 day)

=item path

Cookie path. Default: C</>

=item httponly

Set HttpOnly flag. Default: C<1>

=item secure

Set Secure flag (HTTPS only). Default: C<0>

=item samesite

SameSite attribute. Default: C<Lax>

=back

=head1 CLASS METHODS

=head2 compile_session_ops

    Hypersonic::Session->compile_session_ops(
        cache_dir => '_session_cache',
    );

Compile the JIT cryptographic operations. Called automatically when
C<configure()> is first called.

Returns true if JIT compilation succeeded, false otherwise.

=head2 is_jit_compiled

    if (Hypersonic::Session->is_jit_compiled) {
        # Using native C crypto
    }

Returns true if JIT compilation succeeded.

=head1 SEE ALSO

L<Hypersonic>, L<Hypersonic::Request>, L<Hypersonic::Response>,
L<Hypersonic::TLS>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
