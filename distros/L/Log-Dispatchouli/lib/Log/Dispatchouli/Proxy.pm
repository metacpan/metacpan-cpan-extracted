use v5.20;
use warnings;
package Log::Dispatchouli::Proxy 3.002;
# ABSTRACT: a simple wrapper around Log::Dispatch

use experimental 'postderef'; # Not dangerous.  Is accepted without changed.

use Log::Fmt ();
use Params::Util qw(_ARRAY0 _HASH0);

#pod =head1 DESCRIPTION
#pod
#pod A Log::Dispatchouli::Proxy object is the child of a L<Log::Dispatchouli> logger
#pod (or another proxy) and relays log messages to its parent.  It behaves almost
#pod identically to a Log::Dispatchouli logger, and you should refer there for more
#pod of its documentation.
#pod
#pod Here are the differences:
#pod
#pod =begin :list
#pod
#pod * You can't create a proxy with C<< ->new >>, only by calling C<< ->proxy >> on an existing logger or proxy.
#pod
#pod * C<set_debug> will set a value for the proxy; if none is set, C<get_debug> will check the parent's setting; C<clear_debug> will clear any set value on this proxy
#pod
#pod * C<log_debug> messages will be redispatched to C<log> (to the 'debug' logging level) to prevent parent loggers from dropping them due to C<debug> setting differences
#pod
#pod =end :list
#pod
#pod =cut

sub _new {
  my ($class, $arg) = @_;

  my $guts = {
    parent => $arg->{parent},
    logger => $arg->{logger},
    debug  => $arg->{debug},
    proxy_prefix => $arg->{proxy_prefix},
    proxy_ctx    => $arg->{proxy_ctx},
  };

  bless $guts => $class;
}

sub proxy  {
  my ($self, $arg) = @_;
  $arg ||= {};

  my @proxy_ctx;

  if (my $ctx = $arg->{proxy_ctx}) {
    @proxy_ctx = _ARRAY0($ctx)
               ? (@proxy_ctx, @$ctx)
               : (@proxy_ctx, $ctx->%{ sort keys %$ctx });
  }

  my $prox = (ref $self)->_new({
    parent => $self,
    logger => $self->logger,
    debug  => $arg->{debug},
    muted  => $arg->{muted},
    proxy_prefix => $arg->{proxy_prefix},
    proxy_ctx    => \@proxy_ctx,
  });
}

sub parent { $_[0]{parent} }
sub logger { $_[0]{logger} }

sub ident     { $_[0]{logger}->ident }
sub config_id { $_[0]{logger}->config_id }

sub set_prefix   { $_[0]{prefix} = $_[1] }
sub get_prefix   { $_[0]{prefix} }
sub clear_prefix { undef $_[0]{prefix} }
sub unset_prefix { $_[0]->clear_prefix }

sub set_debug    { $_[0]{debug} = $_[1] ? 1 : 0 }
sub clear_debug  { undef $_[0]{debug} }

sub get_debug {
  return $_[0]{debug} if defined $_[0]{debug};
  return $_[0]->parent->get_debug;
}

sub mute   { $_[0]{muted} = 1 }
sub unmute { $_[0]{muted} = 0 }

sub set_muted    { $_[0]{muted} = $_[1] ? 1 : 0 }
sub clear_muted  { undef $_[0]{muted} }

sub _get_local_muted { $_[0]{muted} }

sub get_muted {
  return $_[0]{muted} if defined $_[0]{muted};
  return $_[0]->parent->get_muted;
}

sub _get_all_prefix {
  my ($self, $arg) = @_;

  return [
    $self->{proxy_prefix},
    $self->get_prefix,
    _ARRAY0($arg->{prefix}) ? @{ $arg->{prefix} } : $arg->{prefix}
  ];
}

sub log {
  my ($self, @rest) = @_;
  my $arg = _HASH0($rest[0]) ? shift(@rest) : {};

  return if $self->_get_local_muted and ! $arg->{fatal};

  local $arg->{prefix} = $self->_get_all_prefix($arg);

  $self->parent->log($arg, @rest);
}

sub log_fatal {
  my ($self, @rest) = @_;

  my $arg = _HASH0($rest[0]) ? shift(@rest) : {};
  local $arg->{fatal}  = 1;

  $self->log($arg, @rest);
}

sub log_debug {
  my ($self, @rest) = @_;

  my $debug = $self->get_debug;
  return if defined $debug and ! $debug;

  my $arg = _HASH0($rest[0]) ? shift(@rest) : {};
  local $arg->{level} = 'debug';

  $self->log($arg, @rest);
}

sub _compute_proxy_ctx_kvstr_aref {
  my ($self) = @_;

  return $self->{proxy_ctx_kvstr} //= do {
    my @kvstr = $self->parent->_compute_proxy_ctx_kvstr_aref->@*;

    if ($self->{proxy_ctx}) {
      my $our_kv = Log::Fmt->_pairs_to_kvstr_aref($self->{proxy_ctx});
      push @kvstr, @$our_kv;
    }

    \@kvstr;
  };
}

sub log_event {
  my ($self, $event, $data) = @_;

  return if $self->get_muted;


  my $message = $self->logger->_log_event($event,
    $self->_compute_proxy_ctx_kvstr_aref,
    [ _ARRAY0($data) ? @$data : $data->%{ sort keys %$data } ]
  );
}

sub log_debug_event {
  my ($self, $event, $data) = @_;

  return unless $self->get_debug;

  return $self->log_event($event, $data);
}

sub info  { shift()->log(@_); }
sub fatal { shift()->log_fatal(@_); }
sub debug { shift()->log_debug(@_); }

use overload
  '&{}'    => sub { my ($self) = @_; sub { $self->log(@_) } },
  fallback => 1,
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatchouli::Proxy - a simple wrapper around Log::Dispatch

=head1 VERSION

version 3.002

=head1 DESCRIPTION

A Log::Dispatchouli::Proxy object is the child of a L<Log::Dispatchouli> logger
(or another proxy) and relays log messages to its parent.  It behaves almost
identically to a Log::Dispatchouli logger, and you should refer there for more
of its documentation.

Here are the differences:

=over 4

=item *

You can't create a proxy with C<< ->new >>, only by calling C<< ->proxy >> on an existing logger or proxy.

=item *

C<set_debug> will set a value for the proxy; if none is set, C<get_debug> will check the parent's setting; C<clear_debug> will clear any set value on this proxy

=item *

C<log_debug> messages will be redispatched to C<log> (to the 'debug' logging level) to prevent parent loggers from dropping them due to C<debug> setting differences

=back

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
