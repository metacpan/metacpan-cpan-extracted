# ABSTRACT: A libgit2 remote (fetch / push)

package Git::Native::Remote;
use Moo;
use Carp ();
use Git::Libgit2 qw( check_rc );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use FFI::Platypus::Memory qw( memcpy malloc free );
use Git::Native::Credential ();

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

  CALLBACKS_CRED_OFFSET    => 24,   # credentials cb pointer
  CALLBACKS_PAYLOAD_OFFSET => 104,  # payload void*

  FETCH_OPTS_CALLBACKS_OFFSET => 8,    # callbacks struct (embedded)
  FETCH_OPTS_PRUNE_OFFSET     => 128,  # int (8 + 120)

  PUSH_OPTS_CALLBACKS_OFFSET  => 8,

  GIT_PASSTHROUGH => -30,

  GIT_DIRECTION_FETCH => 0,
  GIT_DIRECTION_PUSH  => 1,

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
sub fetch {
  my ( $self, %args ) = @_;
  my $refspecs_ref = $args{refspecs};
  my ( $sa_ptr, $sa_keep ) = _build_strarray( $refspecs_ref );

  my ( $opts_ptr, $opts_keep )
    = _build_fetch_options( $args{credentials}, $args{prune} );

  my $rc = Git::Libgit2::FFI::git_remote_fetch(
    $self->_handle, $sa_ptr, $opts_ptr,
    $args{reflog_message} // 'fetch',
  );
  check_rc $rc;
  return $self;
}

# push(refspecs => [...], credentials => sub { ... }, prune => 0|1)
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

  my ( $sa_ptr, $sa_keep ) = _build_strarray( $refspecs_ref );

  my ( $opts_ptr, $opts_keep )
    = _build_push_options( $args{credentials} );

  my $rc = Git::Libgit2::FFI::git_remote_push(
    $self->_handle, $sa_ptr, $opts_ptr,
  );
  check_rc $rc;
  return $self;
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
  my ( $cred_cb, $prune ) = @_;

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
  my ($cred_cb) = @_;

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

  return ( $opts_ptr, \@keep );
}

# Wrap a user coderef so it conforms to git_credential_acquire_cb.
# Returns ($closure, $keepalive). The closure must outlive the C call —
# the keepalive bundle is what the Remote method holds onto.
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
    Carp::croak "credentials callback must return a Git::Native::Credential"
      unless ref $cred && $cred->isa('Git::Native::Credential');

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

version 0.003

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

The C<credentials> coderef is invoked by libgit2 each time an auth
attempt is needed. It receives C<url>, C<username_from_url>, and
C<allowed_types> as named args, and must return either a
L<Git::Native::Credential> or C<undef> (to fall through to the next
auth type).

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
