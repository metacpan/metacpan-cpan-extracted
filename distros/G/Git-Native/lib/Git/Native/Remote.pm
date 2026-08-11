# ABSTRACT: A libgit2 remote (fetch / push)

package Git::Native::Remote;
use Moo;
use Carp ();
use Scalar::Util ();
use Git::Libgit2::FFI ();
use Git::Libgit2 qw(
  oid_to_hex GIT_PASSTHROUGH GIT_DIRECTION_FETCH GIT_DIRECTION_PUSH
);
use Git::Native::Error qw( check_rc );
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use FFI::Platypus::Memory qw( memcpy malloc free );
use Git::Native::Credential ();
use Git::Native::Remote::Result ();
use MIME::Base64 qw( encode_base64 decode_base64 );
use Digest::SHA qw( sha1 sha256 hmac_sha1 );

# Register the per-ref callback types on the shared FFI instance. The types
# libgit2 ships (git_credential_acquire_cb, git_transport_certificate_check_cb)
# are declared in Git::Libgit2::FFI at module load; these two are new and only
# used here, so we register them locally. `->type` errors on duplicate names —
# guard with eval so re-entry (test isolation, re-require) is safe.
{
  my $ffi = Git::Libgit2::FFI::ffi();
  # git_remote_callbacks.update_tips:
  #   int (*)(const char *refname, const git_oid *a, const git_oid *b, void *data)
  eval {
    $ffi->type(
      '(string, opaque, opaque, opaque)->int' => 'git_remote_update_tips_cb',
    );
  };
  # git_remote_callbacks.push_update_reference:
  #   int (*)(const char *refname, const char *status, void *data)
  eval {
    $ffi->type(
      '(string, string, opaque)->int' => 'git_push_update_reference_cb',
    );
  };
}

# libgit2 1.5.x struct layouts (probed). 1.9.x add fields at the end of
# git_remote_callbacks but the offsets up through `payload` are stable.
# Allocate buffers a bit larger than the C struct for forward-compat.
use constant {
  GIT_REMOTE_CALLBACKS_VERSION => 1,
  GIT_FETCH_OPTIONS_VERSION    => 1,
  GIT_PUSH_OPTIONS_VERSION     => 1,

  CALLBACKS_SIZE      => 256,   # actual 1.5: 120; 1.9: ~152
  FETCH_OPTIONS_SIZE  => 384,   # actual 1.5: 208
  PUSH_OPTIONS_SIZE   => 384,   # actual 1.5: 192

  # git_remote_callbacks field offsets (1.5.x layout, probed). Fields are
  # 8-byte fn pointers; the only non-pointer field is `version` (uint32 at
  # offset 0, padded 4 bytes to align the pointers at offset 8). `update_tips`
  # and `push_update_reference` are at offsets 48 and 72 respectively; both
  # sit well before payload (104) so the 256-byte allocation has plenty of
  # headroom for newer libgit2 that adds more fields after payload.
  CALLBACKS_CRED_OFFSET              => 24,   # credentials cb pointer
  CALLBACKS_CERTCHECK_OFFSET         => 32,   # certificate_check cb pointer
  CALLBACKS_UPDATE_TIPS_OFFSET       => 48,   # update_tips cb pointer
  CALLBACKS_PUSH_UPDATE_REF_OFFSET   => 72,   # push_update_reference cb pointer
  CALLBACKS_PAYLOAD_OFFSET           => 104,  # payload void*

  # git_cert_t (cert.cert_type @ offset 0)
  GIT_CERT_X509            => 1,
  GIT_CERT_HOSTKEY_LIBSSH2 => 2,

  # git_cert_hostkey field offsets + git_cert_ssh_t bits (1.5.x layout)
  CERT_HOSTKEY_TYPE_OFFSET   => 4,    # git_cert_ssh_t bitmask (which hashes set)
  CERT_HOSTKEY_SHA1_OFFSET   => 24,   # hash_sha1[20]
  CERT_HOSTKEY_SHA256_OFFSET => 44,   # hash_sha256[32]
  GIT_CERT_SSH_SHA1   => 2,
  GIT_CERT_SSH_SHA256 => 4,

  FETCH_OPTS_CALLBACKS_OFFSET => 8,    # callbacks struct (embedded)
  FETCH_OPTS_PRUNE_OFFSET     => 128,  # int (8 + 120)

  PUSH_OPTS_CALLBACKS_OFFSET  => 8,

  REMOTE_HEAD_NAME_OFFSET => 48,
  REMOTE_HEAD_SIZE        => 64,
  PTR_SIZE                => 8,
};

has _handle => ( is => 'rw', required => 1 );
has _owner  => ( is => 'ro', required => 1 );  # Repository

sub url  { Git::Libgit2::FFI::git_remote_url(  $_[0]->_handle ) }
sub name { Git::Libgit2::FFI::git_remote_name( $_[0]->_handle ) }

# ---------- fetch / push ----------

# fetch(refspecs => [...], credentials => sub { ... }, prune => 0|1,
#       reflog_message => '...')
#
# Returns a Git::Native::Remote::Result describing the per-ref outcomes.
# libgit2 returns 0 even when refs were skipped as non-fast-forward — the
# only way to learn about it is via the update_tips callback we install.
sub fetch {
  my ( $self, %args ) = @_;
  my $refspecs_ref = $args{refspecs};

  # The update_tips callback records each accepted local ref update.
  my @updated;
  my ( $tips_thunk, $tips_keep ) = _make_update_tips_thunk( \@updated );

  my ( $sa_ptr, $sa_keep ) = _build_strarray( $refspecs_ref );

  my ( $opts_ptr, $opts_keep ) = _build_fetch_options(
    $args{credentials}, $args{prune}, $tips_thunk,
  );

  my $rc = Git::Libgit2::FFI::git_remote_fetch(
    $self->_handle, $sa_ptr, $opts_ptr,
    $args{reflog_message} // 'fetch',
  );
  check_rc $rc;

  return Git::Native::Remote::Result->new( updated => \@updated );
}

# push(refspecs => [...], credentials => sub { ... }, prune => 0|1)
#
# Returns a Git::Native::Remote::Result. libgit2 returns 0 even when the
# server rejected refs (pre-receive hook, protected ref, non-ff on a
# non-forced refspec); the push_update_reference callback carries the
# per-ref status the server sent.
sub push {
  my ( $self, %args ) = @_;
  my $original_refspecs = $args{refspecs} // [];
  my $refspecs_ref = $self->_expand_push_refspecs($original_refspecs);

  # --prune: connect, list remote refs in our refspec's destination
  # namespace, emit delete refspecs for the ones we don't have locally.
  # Pass ORIGINAL refspecs (still containing wildcards) so we can
  # recover the namespace pattern.
  if ( $args{prune} && @$original_refspecs ) {
    my @delete = $self->_compute_prune_deletes(
      $original_refspecs, $args{credentials},
    );
    CORE::push @$refspecs_ref, @delete;
  }

  # Per-ref outcomes from push_update_reference. status == NULL is success,
  # status == "" is server-reported success with no message, status != ""
  # is a rejection message. The callback only names the ref, so pair the
  # expanded refspecs with the local oids they carry first — that is where
  # an accepted entry's `to` comes from.
  my @rejected;
  my @updated;
  my ( $push_thunk, $push_keep ) = _make_push_update_thunk(
    \@rejected, \@updated, $self->_push_update_targets($refspecs_ref),
  );

  my ( $sa_ptr, $sa_keep ) = _build_strarray( $refspecs_ref );

  my ( $opts_ptr, $opts_keep ) = _build_push_options(
    $args{credentials}, $push_thunk,
  );

  my $rc = Git::Libgit2::FFI::git_remote_push(
    $self->_handle, $sa_ptr, $opts_ptr,
  );
  check_rc $rc;

  return Git::Native::Remote::Result->new(
    updated  => \@updated,
    rejected => \@rejected,
  );
}

# List the remote-side refs (requires connecting first). Returns an
# arrayref of names. Caller passes credentials cb so private remotes work.
sub list_refs {
  my ( $self, %args ) = @_;
  $self->_connect( GIT_DIRECTION_FETCH, $args{credentials} );
  my @names;
  eval {
    check_rc Git::Libgit2::FFI::git_remote_ls(
      \my $heads_arr, \my $count, $self->_handle,
    );
    # heads_arr is git_remote_head**: an array of $count pointers,
    # each pointing to a git_remote_head whose .name (char*) lives at
    # offset REMOTE_HEAD_NAME_OFFSET.
    my $ffi = Git::Libgit2::FFI::ffi();
    for ( my $i = 0; $i < $count; $i++ ) {
      my $head_ptr = unpack 'J',
        _peek_bytes( $heads_arr + $i * PTR_SIZE, PTR_SIZE );
      my $name_ptr = unpack 'J',
        _peek_bytes( $head_ptr + REMOTE_HEAD_NAME_OFFSET, PTR_SIZE );
      my $name = $ffi->cast( 'opaque' => 'string', $name_ptr );
      CORE::push @names, $name;
    }
  };
  my $err = $@;
  Git::Libgit2::FFI::git_remote_disconnect( $self->_handle );
  die $err if $err;
  return \@names;
}

sub _connect {
  my ( $self, $direction, $cred_cb ) = @_;
  # Build a callbacks struct on the stack-ish (Perl-owned buffer).
  my $cb = "\0" x CALLBACKS_SIZE;
  my ($cb_ptr) = scalar_to_buffer($cb);
  check_rc Git::Libgit2::FFI::git_remote_init_callbacks(
    $cb_ptr, GIT_REMOTE_CALLBACKS_VERSION,
  );
  my @keep = ( \$cb );
  if ($cred_cb) {
    my ( $thunk, $thunk_keep ) = _make_credential_thunk($cred_cb);
    CORE::push @keep, $thunk_keep;
    my $ptr_val = Git::Libgit2::FFI::ffi->cast(
      'git_credential_acquire_cb' => 'opaque', $thunk,
    );
    my $pkt = pack 'J', $ptr_val;
    my ($pkt_p) = scalar_to_buffer($pkt);
    memcpy( $cb_ptr + CALLBACKS_CRED_OFFSET, $pkt_p, 8 );
    CORE::push @keep, \$pkt;
  }
  _install_certcheck( $cb_ptr, 0, \@keep );
  check_rc Git::Libgit2::FFI::git_remote_connect(
    $self->_handle, $direction, $cb_ptr, 0, 0,
  );
  # Hold keepalive on $self so it survives until the next call frees it.
  $self->{_connect_keep} = \@keep;
  return $self;
}

# Compute delete refspecs for `--prune`: for each `[+]src:dst` with `*`,
# list remote refs matching the dst pattern, and emit a delete for each
# one whose local counterpart no longer exists.
sub _compute_prune_deletes {
  my ( $self, $refspecs, $cred_cb ) = @_;
  my $remote_names = $self->list_refs( credentials => $cred_cb );
  my %local;
  $local{$_} = 1 for @{ $self->_owner->reference_names };

  my @deletes;
  my %seen;
  # Walk *original* user refspecs to figure out the dst-pattern namespace.
  # We can't recover the dst-pattern from already-expanded specs.
  for my $rs (@$refspecs) {
    my ( $force, $src, $dst ) = $rs =~ /\A(\+?)([^:]+):(.+)\z/;
    next unless defined $src && $dst =~ /\*/;
    # Map remote ref → expected local name using dst→src.
    my $dst_re = quotemeta($dst); $dst_re =~ s/\\\*/(.*)/;
    $dst_re = qr/\A${dst_re}\z/;
    my $src_template = $src;
    for my $rname (@$remote_names) {
      my ($cap) = $rname =~ $dst_re;
      next unless defined $cap;
      my $expected_local = $src_template;
      $expected_local =~ s/\*/$cap/;
      next if $local{$expected_local};
      next if $seen{$rname}++;
      CORE::push @deletes, ":${rname}";
    }
  }
  return @deletes;
}

# Read N bytes from a raw C address into a Perl scalar.
sub _peek_bytes {
  my ( $addr, $len ) = @_;
  my $buf = "\0" x $len;
  my ($bp) = scalar_to_buffer($buf);
  memcpy( $bp, $addr, $len );
  return $buf;
}

# libgit2 git_remote_push does NOT expand wildcard refspecs (unlike CLI
# git). We do it here: for each `+?src:dst` refspec containing `*`,
# enumerate matching local refs and emit one explicit refspec per ref.
sub _expand_push_refspecs {
  my ( $self, $refspecs ) = @_;
  $refspecs //= [];
  my @out;
  for my $rs (@$refspecs) {
    my ( $force, $src, $dst ) = $rs =~ /\A(\+?)([^:]+):(.+)\z/;
    if ( !defined $src || ( index( $src, '*' ) < 0 && index( $dst, '*' ) < 0 ) ) {
      CORE::push @out, $rs;
      next;
    }
    my $src_re = quotemeta($src);
    $src_re =~ s/\\\*/(.*)/;
    $src_re = qr/\A${src_re}\z/;

    my $names = $self->_owner->reference_names( glob => $src );
    for my $name (@$names) {
      my ($cap) = $name =~ $src_re;
      next unless defined $cap;
      my $expanded_dst = $dst;
      $expanded_dst =~ s/\*/$cap/;
      CORE::push @out, "${force}${name}:${expanded_dst}";
    }
  }
  return \@out;
}

# ---------- internals ----------

# Build a git_strarray pointing into Perl-owned memory. Returns
# ($strarray_ptr, $keepalive_scalars_ref). Caller must hold
# $keepalive_scalars_ref alive across the C call.
sub _build_strarray {
  my ($refspecs) = @_;
  $refspecs //= [];
  Carp::croak "_build_strarray: refspecs must be an arrayref"
    if ref $refspecs ne 'ARRAY';
  # Empty list → NULL strarray pointer, which libgit2 reads as
  # "use configured refspecs from .git/config".
  return ( 0, [] ) unless @$refspecs;

  # Copy each string so we have stable storage we control.
  my @copies = map { "$_" } @$refspecs;
  my @ptrs;
  for my $s (@copies) {
    my ($p) = scalar_to_buffer($s);
    CORE::push @ptrs, $p;
  }
  my $strings_buf = pack 'J*', @ptrs;
  my ($strings_ptr) = scalar_to_buffer($strings_buf);

  my $strarray = pack 'JJ', $strings_ptr, scalar(@copies);
  my ($sa_ptr) = scalar_to_buffer($strarray);

  # Keep refs to every buffer that owns memory referenced from $strarray.
  return ( $sa_ptr, [ \@copies, \$strings_buf, \$strarray ] );
}

sub _build_fetch_options {
  my ( $cred_cb, $prune, $update_tips_thunk ) = @_;

  my $opts = "\0" x FETCH_OPTIONS_SIZE;
  my ($opts_ptr) = scalar_to_buffer($opts);
  check_rc Git::Libgit2::FFI::git_fetch_options_init(
    $opts_ptr, GIT_FETCH_OPTIONS_VERSION,
  );

  my @keep = ( \$opts );

  if ($cred_cb) {
    my ( $cb_thunk, $cb_keep ) = _make_credential_thunk($cred_cb);
    CORE::push @keep, $cb_keep;

    # Write the closure's C pointer into callbacks.credentials.
    my $cb_ptr_val = Git::Libgit2::FFI::ffi->cast(
      'git_credential_acquire_cb' => 'opaque', $cb_thunk,
    );
    my $cb_buf = pack 'J', $cb_ptr_val;
    my ($cb_buf_ptr) = scalar_to_buffer($cb_buf);
    memcpy( $opts_ptr + FETCH_OPTS_CALLBACKS_OFFSET + CALLBACKS_CRED_OFFSET,
            $cb_buf_ptr, 8 );
    CORE::push @keep, \$cb_buf;
  }

  _install_certcheck( $opts_ptr, FETCH_OPTS_CALLBACKS_OFFSET, \@keep );

  if ($update_tips_thunk) {
    my $ptr_val = Git::Libgit2::FFI::ffi->cast(
      'git_remote_update_tips_cb' => 'opaque', $update_tips_thunk,
    );
    my $buf = pack 'J', $ptr_val;
    my ($bp) = scalar_to_buffer($buf);
    memcpy( $opts_ptr + FETCH_OPTS_CALLBACKS_OFFSET
            + CALLBACKS_UPDATE_TIPS_OFFSET, $bp, 8 );
    CORE::push @keep, \$buf;
  }

  if ( defined $prune ) {
    my $val = $prune ? 1 : 2;   # 1 = PRUNE, 2 = NO_PRUNE
    my $pb  = pack 'l', $val;
    my ($pbp) = scalar_to_buffer($pb);
    memcpy( $opts_ptr + FETCH_OPTS_PRUNE_OFFSET, $pbp, 4 );
    CORE::push @keep, \$pb;
  }

  return ( $opts_ptr, \@keep );
}

sub _build_push_options {
  my ( $cred_cb, $push_update_thunk ) = @_;

  my $opts = "\0" x PUSH_OPTIONS_SIZE;
  my ($opts_ptr) = scalar_to_buffer($opts);
  check_rc Git::Libgit2::FFI::git_push_options_init(
    $opts_ptr, GIT_PUSH_OPTIONS_VERSION,
  );

  my @keep = ( \$opts );

  if ($cred_cb) {
    my ( $cb_thunk, $cb_keep ) = _make_credential_thunk($cred_cb);
    CORE::push @keep, $cb_keep;

    my $cb_ptr_val = Git::Libgit2::FFI::ffi->cast(
      'git_credential_acquire_cb' => 'opaque', $cb_thunk,
    );
    my $cb_buf = pack 'J', $cb_ptr_val;
    my ($cb_buf_ptr) = scalar_to_buffer($cb_buf);
    memcpy( $opts_ptr + PUSH_OPTS_CALLBACKS_OFFSET + CALLBACKS_CRED_OFFSET,
            $cb_buf_ptr, 8 );
    CORE::push @keep, \$cb_buf;
  }

  _install_certcheck( $opts_ptr, PUSH_OPTS_CALLBACKS_OFFSET, \@keep );

  if ($push_update_thunk) {
    my $ptr_val = Git::Libgit2::FFI::ffi->cast(
      'git_push_update_reference_cb' => 'opaque', $push_update_thunk,
    );
    my $buf = pack 'J', $ptr_val;
    my ($bp) = scalar_to_buffer($buf);
    memcpy( $opts_ptr + PUSH_OPTS_CALLBACKS_OFFSET
            + CALLBACKS_PUSH_UPDATE_REF_OFFSET, $bp, 8 );
    CORE::push @keep, \$buf;
  }

  return ( $opts_ptr, \@keep );
}

# Wrap a user coderef so it conforms to git_credential_acquire_cb.
# Returns ($closure, $keepalive). The closure must outlive the C call —
# the keepalive bundle is what the Remote method holds onto.
#
# NOTHING in here may die: the closure is called from libgit2's C frames,
# and a Perl exception unwinding across them is undefined behaviour. Every
# failure mode reports via warn and returns a negative rc, which libgit2
# propagates out of git_remote_fetch/push for check_rc to throw properly.
sub _make_credential_thunk {
  my ($user_cb) = @_;
  my $ffi = Git::Libgit2::FFI::ffi();

  my $closure = $ffi->closure(sub {
    my ( $out_ptr, $url, $username_from_url, $allowed_types, $payload ) = @_;
    my $cred = eval {
      $user_cb->(
        url                => $url,
        username_from_url  => $username_from_url,
        allowed_types      => $allowed_types,
      );
    };
    if ($@) {
      warn "credential callback died: $@";
      return -1;
    }
    return GIT_PASSTHROUGH unless defined $cred;
    unless ( Scalar::Util::blessed($cred)
             && $cred->isa('Git::Native::Credential') ) {
      warn "credentials callback must return a Git::Native::Credential "
         . "or undef, got " . _describe_value($cred) . "\n";
      return -1;
    }

    # Disown the wrapper — libgit2 takes ownership on return 0.
    my $cred_handle = $cred->_disown;

    # *out_ptr = cred_handle  (write 8 bytes of pointer to the address
    # the caller gave us)
    my $pkt = pack 'J', $cred_handle;
    my ($pkt_p) = scalar_to_buffer($pkt);
    memcpy( $out_ptr, $pkt_p, 8 );

    return 0;
  });

  # `sticky` would survive process-lifetime; we only need until the C
  # call returns, so just hand the closure to the caller's keepalive.
  return ( $closure, [ \$closure ] );
}

# Name a value for a diagnostic without ever dying on it — a blessed object
# may carry an overloaded (and throwing) stringifier, so report its class
# instead of interpolating it. Only used from inside FFI closures, where a
# die is not survivable.
sub _describe_value {
  my ($v) = @_;
  if ( my $class = Scalar::Util::blessed($v) ) { return "a $class object" }
  if ( my $type  = ref $v )                    { return "a $type reference" }
  my $str = "$v";
  $str = substr( $str, 0, 60 ) . '...' if length($str) > 63;
  return "the non-reference value '$str'";
}

# Build the update_tips closure (git_remote_callbacks.update_tips).
# Records each accepted ref update into the caller's $updated arrayref.
#
#   int cb(const char *refname, const git_oid *a, const git_oid *b, void *data)
#
# a is the old local tip; libgit2 passes a non-NULL pointer even when the
# ref didn't exist locally (the bytes are zero-filled — a zero SHA-1).
# We translate the all-zero "no previous ref" case to from => undef so
# callers can tell new-ref from same-oid updates without a magic constant.
# b is the new local tip, and is the all-zero oid when the ref was DELETED
# rather than moved — that is how a `prune => 1` fetch reports the refs it
# dropped (probed against a file:// remote). Same treatment: to => undef,
# which is also what the push side reports for a delete refspec, so
# `!defined $_->{to}` means "this ref is gone" on both operations.
#
# `reason` is always the empty string here: update_tips only fires for
# updates libgit2 accepted, and there is no server verdict on a fetch at all.
# It exists so a fetch entry and a push entry carry the identical key set —
# see Git::Native::Remote::Result.
#
# Returns 0 on success — returning non-zero aborts the fetch, which is what
# we want if libgit2 handed us something we cannot record (a NULL new tip),
# because the Result would otherwise lie by omission. Like every FFI closure
# here it must not let a die escape into libgit2's C frames, so the body runs
# under eval and reports via warn.
sub _make_update_tips_thunk {
  my ($updated) = @_;
  my $ffi = Git::Libgit2::FFI::ffi();
  my $closure = $ffi->closure(sub {
    my ( $refname, $a_ptr, $b_ptr, $payload ) = @_;

    my $ok = eval {
      die "update_tips callback got NULL b oid for ref '$refname'\n"
        unless $b_ptr;
      my $from = $a_ptr ? _oid_hex_if_nonzero($a_ptr) : undef;
      my $to   = _oid_hex_if_nonzero($b_ptr);
      CORE::push @$updated, {
        ref    => $refname,
        from   => $from,
        to     => $to,
        reason => '',
      };
      1;
    };
    if ( !$ok ) {
      warn "Git::Native update_tips callback failed: $@";
      return -1;
    }
    return 0;
  });
  return ( $closure, [ \$closure ] );
}

# Read a 20-byte git_oid out of a raw pointer and return its hex form, or
# undef when the 20 raw bytes are all zero. libgit2 uses the zero oid as a
# sentinel on both sides of update_tips: as the old tip it means "the ref did
# not exist here before", as the new tip it means "the ref was deleted".
sub _oid_hex_if_nonzero {
  my ($ptr) = @_;
  my $raw = _peek_bytes($ptr, 20);
  return undef if $raw eq "\0" x 20;
  return oid_to_hex($ptr);
}

# Build the push_update_reference closure (git_remote_callbacks.push_update_reference).
# Records each ref the server accepted (status NULL or "") into $updated and
# each rejected ref (status != NULL) into $rejected. status is the literal
# message from the server (e.g. "non-fast-forward", "pre-receive hook declined").
#
#   int cb(const char *refname, const char *status, void *data)
#
# $targets is the destination-refname => oid-hex map from
# _push_update_targets, so an accepted push entry carries the same
# { ref, from, to, reason } key set a fetch entry does. `from` is always
# undef: the previous remote-side oid is only knowable through a
# git_remote_ls snapshot taken before the push, and paying for that extra
# round trip on every push would be worse than an honest undef.
sub _make_push_update_thunk {
  my ( $rejected, $updated, $targets ) = @_;
  $targets //= {};
  my $ffi = Git::Libgit2::FFI::ffi();
  my $closure = $ffi->closure(sub {
    my ( $refname, $status, $payload ) = @_;
    # libgit2 normalises "no rejection" to NULL on the way in; a server that
    # sent an empty status string means the same thing.
    if ( !defined $status || $status eq '' ) {
      CORE::push @$updated, {
        ref    => $refname,
        from   => undef,
        to     => $targets->{$refname},
        reason => '',
      };
    }
    else {
      CORE::push @$rejected, { ref => $refname, reason => $status };
    }
    return 0;
  });
  return ( $closure, [ \$closure ] );
}

# Map each expanded push refspec's destination refname to the oid the push
# puts there, so a push update can report `to` the way a fetch update does.
# push_update_reference only hands us a per-ref verdict, but the source side
# of the refspec is a local ref we can just look up — no extra network.
#
# The value is undef for a delete refspec (`:refs/x`, which is what
# `prune => 1` emits) — matching the deleted-ref convention on the fetch
# side — and also undef for a source that is not a local reference (a raw
# oid, a shorthand, a ref that vanished between expansion and push).
sub _push_update_targets {
  my ( $self, $refspecs ) = @_;
  my %target;
  for my $rs (@$refspecs) {
    my ( $src, $dst );
    if ( index( $rs, ':' ) >= 0 ) {
      ( $src, $dst ) = $rs =~ /\A\+?([^:]*):(.*)\z/;
    }
    else {
      # A refspec without a colon pushes the source to the same name.
      ($src) = $rs =~ /\A\+?(.*)\z/;
      $dst = $src;
    }
    next unless defined $dst && length $dst;
    $target{$dst} = ( defined $src && length $src )
      ? $self->_local_oid_hex($src)
      : undef;
  }
  return \%target;
}

# Hex oid a local refname points at, or undef if it does not resolve to
# one. Goes through resolve so a symbolic source (`HEAD:refs/heads/main`)
# reports the oid it points at rather than nothing. Never dies: an
# unresolvable push source is a missing `to`, not a failed push.
sub _local_oid_hex {
  my ( $self, $refname ) = @_;
  my $oid = eval { $self->_owner->reference($refname)->resolve->target };
  return undef unless $oid;
  return $oid->hex;
}

# ---------- host-key verification (certificate_check callback) ----------

# Write a certificate_check closure into a callbacks struct. $cb_base is the
# offset of the embedded git_remote_callbacks within $struct_ptr (0 for a
# bare callbacks struct, 8 for fetch/push options). Pushes keepalives.
#
# libgit2 1.5.x + libssh2 has NO built-in known_hosts checking (that landed in
# 1.7). Without a certificate_check callback the ssh transport rejects every
# host with GIT_ECERTIFICATE (-17) "invalid or unknown remote ssh hostkey".
# So we always install one and verify the hostkey against ~/.ssh/known_hosts
# ourselves, mirroring what the `git` CLI does via OpenSSH.
sub _install_certcheck {
  my ( $struct_ptr, $cb_base, $keep ) = @_;
  my ( $thunk, $thunk_keep ) = _make_certcheck_thunk();
  CORE::push @$keep, @$thunk_keep;
  my $ptr_val = Git::Libgit2::FFI::ffi->cast(
    'git_transport_certificate_check_cb' => 'opaque', $thunk,
  );
  my $buf = pack 'J', $ptr_val;
  my ($bp) = scalar_to_buffer($buf);
  memcpy( $struct_ptr + $cb_base + CALLBACKS_CERTCHECK_OFFSET, $bp, 8 );
  CORE::push @$keep, \$buf;
  return;
}

# Build the certificate_check closure. Returns ($closure, $keepalive).
#
#   int cb(git_cert *cert, int valid, const char *host, void *payload)
#
# Return 0 to accept, <0 to reject (libgit2 aborts the connection with that
# code). For TLS (git_cert_x509) we honour libgit2's own `valid` flag so HTTPS
# remotes keep their normal CA validation. For SSH (git_cert_hostkey) we verify
# against known_hosts unless GIT_NATIVE_SSH_INSECURE is set (accept-all).
sub _make_certcheck_thunk {
  my $ffi = Git::Libgit2::FFI::ffi();
  my $closure = $ffi->closure(sub {
    my ( $cert_ptr, $valid, $host, $payload ) = @_;
    my $ok = eval {
      my $cert_type = unpack 'l', _peek_bytes( $cert_ptr, 4 );
      return $valid ? 1 : 0 if $cert_type == GIT_CERT_X509;
      if ( $cert_type == GIT_CERT_HOSTKEY_LIBSSH2 ) {
        return 1 if $ENV{GIT_NATIVE_SSH_INSECURE};
        return _verify_known_host( $cert_ptr, $host );
      }
      # Unknown cert kind — fall back to libgit2's own verdict.
      return $valid ? 1 : 0;
    };
    if ($@) {
      warn "Git::Native certificate check died: $@";
      return -1;
    }
    return $ok ? 0 : -1;
  });
  return ( $closure, [ \$closure ] );
}

# Verify an ssh hostkey against known_hosts using the SHA256 (preferred) or
# SHA1 fingerprint libssh2 computed for the negotiated key. Returns 1 on a
# match, 0 otherwise (with an actionable warning).
sub _verify_known_host {
  my ( $cert_ptr, $host ) = @_;
  my $bits = unpack 'l', _peek_bytes( $cert_ptr + CERT_HOSTKEY_TYPE_OFFSET, 4 );

  my ( $digest, $want );
  if ( $bits & GIT_CERT_SSH_SHA256 ) {
    $digest = 'sha256';
    $want   = _peek_bytes( $cert_ptr + CERT_HOSTKEY_SHA256_OFFSET, 32 );
  }
  elsif ( $bits & GIT_CERT_SSH_SHA1 ) {
    $digest = 'sha1';
    $want   = _peek_bytes( $cert_ptr + CERT_HOSTKEY_SHA1_OFFSET, 20 );
  }
  else {
    warn "Git::Native: ssh hostkey for '$host' offers no SHA1/SHA256 "
       . "fingerprint to verify; rejecting\n";
    return 0;
  }

  my ( $matched, $host_seen ) = _known_hosts_match( $host, $digest, $want );
  return 1 if $matched;

  if ($host_seen) {
    warn "Git::Native: ssh hostkey for '$host' did NOT match the "
       . "$host_seen known_hosts entr" . ( $host_seen == 1 ? 'y' : 'ies' )
       . " for it — server offered a key type you have not cached, or the "
       . "key changed. Run `ssh-keyscan $host >> ~/.ssh/known_hosts`, or set "
       . "GIT_NATIVE_SSH_INSECURE=1 to bypass.\n";
  }
  else {
    warn "Git::Native: ssh host '$host' is not in known_hosts. Run "
       . "`ssh-keyscan $host >> ~/.ssh/known_hosts`, or set "
       . "GIT_NATIVE_SSH_INSECURE=1 to bypass.\n";
  }
  return 0;
}

# Scan the known_hosts files for $host and compare the cached key's digest to
# $want. Returns (matched, host_line_count): host_line_count distinguishes
# "host unknown" from "host known but key mismatch".
sub _known_hosts_match {
  my ( $host, $digest, $want ) = @_;
  my $host_seen = 0;
  for my $file (
    "$ENV{HOME}/.ssh/known_hosts",
    "$ENV{HOME}/.ssh/known_hosts2",
    '/etc/ssh/ssh_known_hosts',
  ) {
    next unless -r $file;
    open my $fh, '<', $file or next;
    while ( my $line = <$fh> ) {
      $line =~ s/\A\s+//;
      next if $line eq '' || $line =~ /\A[#\r\n]/;
      my @parts = split ' ', $line;
      my $marker = ( @parts && $parts[0] =~ /\A\@/ ) ? shift @parts : '';
      next if @parts < 3;
      next if $marker eq '@cert-authority' || $marker eq '@revoked';
      my ( $hosts, undef, $key64 ) = @parts;
      next unless _host_in_field( $host, $hosts );
      $host_seen++;
      my $blob = decode_base64($key64);
      next unless length $blob;
      my $got = $digest eq 'sha256' ? sha256($blob) : sha1($blob);
      return ( 1, $host_seen ) if $got eq $want;
    }
    close $fh;
  }
  return ( 0, $host_seen );
}

# Does $host match a known_hosts host field? Handles hashed (|1|salt|hash via
# HMAC-SHA1), plain comma lists, [host]:port, and * / ? wildcards.
sub _host_in_field {
  my ( $host, $field ) = @_;
  if ( $field =~ /\A\|1\|([^|]+)\|(.+)\z/ ) {
    my ( $salt64, $hash64 ) = ( $1, $2 );
    my $got = encode_base64( hmac_sha1( $host, decode_base64($salt64) ), '' );
    return $got eq $hash64;
  }
  for my $pat ( split /,/, $field ) {
    next if $pat eq '';
    $pat = $1 if $pat =~ /\A\[([^\]]+)\](?::\d+)?\z/;
    return 1 if lc $pat eq lc $host;
    if ( $pat =~ /[*?]/ ) {
      my $re = quotemeta $pat;
      $re =~ s/\\\*/.*/g;
      $re =~ s/\\\?/./g;
      return 1 if $host =~ /\A$re\z/i;
    }
  }
  return 0;
}

sub DEMOLISH {
  my $self = shift;
  if ( my $h = $self->{_handle} ) {
    Git::Libgit2::FFI::git_remote_free($h);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Remote - A libgit2 remote (fetch / push)

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $remote = $repo->remote('origin');
  say $remote->url;

  $remote->fetch(
    refspecs    => ['+refs/heads/*:refs/remotes/origin/*'],
    credentials => sub {
      my (%args) = @_;
      Git::Native::Credential->ssh_agent(
        username => $args{username_from_url} // 'git',
      );
    },
    prune => 1,
  );

  $remote->push(
    refspecs    => ['+refs/karr/*:refs/karr/*'],
    credentials => sub {
      Git::Native::Credential->userpass(
        username => 'git',
        password => $ENV{GITHUB_TOKEN},
      );
    },
  );

=head1 DESCRIPTION

Wraps C<git_remote*>. Supports the libgit2 credential acquire callback,
so SSH-agent / SSH-key / HTTPS-token auth all work without shelling out
to the C<git> binary.

The C<credentials> coderef accepted by C<fetch>, C<push> and C<list_refs>
is libgit2's credential-acquire callback. libgit2 invokes it only when the
transport actually issues an auth challenge — over C<file://> it is never
called at all — and it may invoke it more than once, once per auth type it
is prepared to try:

  credentials => sub {
    my (%args) = @_;
    # $args{url}                the URL libgit2 is authenticating against
    # $args{username_from_url}  user part of the URL, or undef
    # $args{allowed_types}      git_credential_t bitmask of the credential
    #                           kinds this transport will accept
    Git::Native::Credential->ssh_agent(
      username => $args{username_from_url} // 'git',
    );
  };

Return a L<Git::Native::Credential> to authenticate with it — libgit2 takes
ownership of it from that moment on. Return C<undef> to decline: that maps
to libgit2's C<GIT_PASSTHROUGH>, which makes it move on to the next auth
type instead of failing the operation outright. The credential you return
has to be of a kind listed in C<allowed_types>; libgit2 checks. The bitmask
values are libgit2's own (1 userpass-plaintext, 2 ssh-key, 8 default,
32 username, ...) — L<Git::Libgit2> exports no names for them yet.

Nothing may escape the callback: it runs inside libgit2's C frames, where a
Perl exception is undefined behaviour. The wrapper therefore contains every
failure — if your coderef dies, or returns anything other than a credential
or C<undef>, the reason is reported with C<warn> and an error code is
returned to libgit2, so the surrounding C<fetch> / C<push> fails with a
L<Git::Native::Error>. Catch what you can inside the callback if you want a
better message than that.

SSH host keys are verified against C<known_hosts> by this module (libgit2
1.5 has no built-in check and would otherwise reject every host). A host
that is unknown, or whose cached key does not match, fails the connection
with a warning naming the C<ssh-keyscan> command that would fix it; setting
C<GIT_NATIVE_SSH_INSECURE=1> accepts any host key instead. HTTPS keeps
libgit2's own CA validation.

=head2 url / name

  say $remote->url;    # file:///srv/git/karr.git
  say $remote->name;   # origin

C<url> is the remote's fetch URL (a separately configured
C<remote.E<lt>nameE<gt>.pushurl> is not exposed). C<name> is C<undef> for a
remote built with C<< $repo->remote_anonymous($url) >>, which exists only
in memory and is never written to the config.

=head2 fetch

  my $result = $remote->fetch(
    refspecs => ['+refs/heads/*:refs/remotes/origin/*'],
    prune    => 1,
  );
  say "$_->{ref}: ", $_->{from} // '(new)', ' -> ', $_->{to} // '(deleted)'
    for @{ $result->updated };

Fetch from the remote. Returns a L<Git::Native::Remote::Result>, not a
truth value: libgit2 returns 0 from C<git_remote_fetch> even when it
skipped individual refs (a non-fast-forward update on a refspec without
C<+>), so the list of refs that actually moved is the only trustworthy
report. C<< $result->updated >> holds one
C<< { ref => $refname, from => $oid_hex|undef, to => $oid_hex|undef,
reason => '' } >> per ref that changed locally — the same four keys a push
reports, see L<Git::Native::Remote::Result/updated>.

C<ref> is the local destination the refspec mapped to, not the remote's
name for it. C<from> is C<undef> for a ref that did not exist locally
before. C<to> is C<undef> when the ref was B<deleted> rather than moved,
which is how a C<< prune => 1 >> fetch reports the stale refs it dropped.
C<reason> is always the empty string on a fetch; it exists so fetch and
push entries have the same shape. Refs that were already up to date produce
no entry at all. C<< $result->rejected >> is always empty for a fetch —
libgit2's skip path does not route through the callback we install, so a
skipped ref shows up as a missing entry in C<updated>, not as a rejection.

Named arguments:

C<refspecs> — arrayref of refspecs. Omitted or empty means "use the
refspecs configured for this remote", the same as a bare C<git fetch>.

C<prune> — C<1> deletes local refs whose upstream counterpart is gone,
C<0> explicitly disables pruning even when the configuration asks for it,
and omitting it leaves the decision to
C<< remote.<name>.prune >> / C<< fetch.prune >>. This is libgit2's own
C<git_fetch_options.prune>, unlike the reimplemented push side.

C<credentials> — coderef, see above.

C<reflog_message> — reflog message written for the updated refs, default
C<fetch>.

=head2 push

  my $result = $remote->push(
    refspecs    => ['+refs/karr/*:refs/karr/*'],
    credentials => \&creds,
  );
  die join ', ', map { "$_->{ref}: $_->{reason}" } @{ $result->rejected }
    if @{ $result->rejected };

Push to the remote. Returns a L<Git::Native::Remote::Result>, and
C<< $result->rejected >> is the part that matters: libgit2 returns 0 from
C<git_remote_push> as long as the transfer itself worked, even if the
server refused every single ref (pre-receive hook declined, protected
branch, non-fast-forward on a refspec without C<+>). Code that only checks
that C<push> did not throw will report a wholly rejected push as a success.

Rejected entries are C<< { ref => $remote_refname, reason => $message } >>
with the status string the server sent (C<non-fast-forward>,
C<pre-receive hook declined>, ...). Accepted refs land in
C<< $result->updated >> with the same four keys a fetch reports,
C<< { ref => $remote_refname, from => undef, to => $oid_hex|undef,
reason => '' } >>.

C<ref> is the ref's name on the B<remote> side here, not a local one — the
server reports its own names, and no attempt is made to map them back
through the refspec. C<to> is the OID the push put there, recovered from
the local source side of the refspec rather than from the server, which
only sends a per-ref verdict; it is C<undef> for a ref the push B<deleted>
(the delete refspecs C<< prune => 1 >> generates, or an explicit
C<< :refs/... >>), and also C<undef> when the source is not a local
reference we can resolve. C<from> is always C<undef> on a push: the
previous remote-side OID is only knowable from a ref listing taken before
the push, and C<push> will not spend an extra network round trip on it —
use C<list_refs> beforehand if you need it.

Both lists come from the server's report-status, so they are only as
detailed as the transport. libgit2's local (C<file://>) transport neither
runs receive hooks nor reports status, so against a local bare repository
every pushed ref is reported as accepted.

Wildcard refspecs are expanded by this module, not by libgit2:
C<git_remote_push> rejects C<+refs/karr/*:refs/karr/*> outright as "not a
valid reference". C<push> enumerates the local refs matching the source
pattern and emits one concrete refspec per match, splicing the captured
tail into the destination, so C<refs/karr/*:refs/backup/*> works too. The
consequence for callers: a push wildcard covers exactly the refs that
exist locally at that moment, and a pattern matching nothing contributes
nothing to the push rather than being an error. Fetch is unaffected —
there the server side enumerates.

C<prune =E<gt> 1> is likewise reimplemented; libgit2 has no equivalent of
C<git push --prune>. It connects to the remote, lists its refs, and for
every remote ref in the destination namespace whose local counterpart no
longer exists adds a C<:refs/...> delete refspec to the push. It therefore
needs an explicit C<refspecs> list and only takes effect for wildcard
refspecs — a concrete C<a:b> refspec spans no namespace to diff. The extra
connection uses the same C<credentials> callback, and the deleted refs are
reported in C<< $result->updated >> alongside the refs that were written,
distinguishable by their C<< to => undef >>.

=head2 list_refs

  my $names = $remote->list_refs;
  # [ 'HEAD', 'refs/heads/main', 'refs/tags/v1.0' ]

Connect to the remote, read its ref advertisement, disconnect. Returns an
arrayref of the refnames as the B<remote> names them, C<HEAD> included: no
refspec mapping is applied and nothing is written to the local repository.
Takes an optional C<credentials> callback with the same contract as
C<fetch>. The connection is closed again even when the listing throws.

=head1 SEE ALSO

L<Git::Native::Credential>, L<Git::Native::Remote::Result>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-native/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
