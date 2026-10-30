package Langertha::Raider::PermissionChannel;
# ABSTRACT: Internal client of the hall's permission channel: asks a call over a Unix socket, never answers yes by accident
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use IO::Select;
use IO::Socket::UNIX;
use JSON::MaybeXS;
use Time::HiRes ();


has path => ( is => 'ro', isa => 'Str', required => 1 );


has timeout => ( is => 'ro', isa => 'Num', default => 300 );


has cancelled => ( is => 'ro', isa => 'Maybe[CodeRef]' );


has _socket => ( is => 'rw', init_arg => undef, clearer => '_drop_socket' );
has _buffer => ( is => 'rw', isa => 'Str', default => '', init_arg => undef );
has _next_id => ( is => 'rw', isa => 'Int', default => 0, init_arg => undef );

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 );

sub callback {
  my ( $self ) = @_;
  return sub { $self->request(@_) };
}


sub request {
  my ( $self, $req ) = @_;
  my $answer = eval { $self->_ask($req) };  return { answer => 'no', reason => 'permission channel: '.( $@ =~ s/ at .*//sr =~ s/\s+\z//r ) }
    unless ref $answer eq 'HASH';
  return $answer;
}


sub _ask {
  my ( $self, $req ) = @_;
  local $SIG{PIPE} = 'IGNORE';    # a closed hall is an answer (no), not a signal
  my $sock = $self->_socket || $self->_connect;
  my $id   = $self->_next_id( $self->_next_id + 1 );
  my $line = $JSON->encode({ id => $id, map { $_ => $req->{$_} } grep { defined $req->{$_} } qw( tool source arguments reason rule ) })."\n";
  unless ( defined syswrite( $sock, $line ) ) {
    $self->_close;
    return { answer => 'no', reason => 'the permission channel is closed' };
  }
  my $deadline = Time::HiRes::time() + $self->timeout;
  my $select   = IO::Select->new($sock);
  while (1) {
    if ( $self->cancelled && $self->cancelled->() ) {
      $self->_close;
      return { answer => 'no', reason => 'the run was cancelled' };
    }
    my $buffer = $self->_buffer;
    if ( $buffer =~ s/\A([^\n]*)\n// ) {
      my $text = $1;
      $self->_buffer($buffer);
      my $msg = eval { $JSON->decode($text) };
      next unless ref $msg eq 'HASH' && defined $msg->{id} && $msg->{id} eq $id;   # a late answer of an earlier question
      my $answer = $msg->{answer} // '';
      return { answer => 'no', reason => $msg->{reason} // 'the answer was not once, session or no' }
        unless $answer eq 'once' || $answer eq 'session';
      return { answer => $answer, ( defined $msg->{reason} ? ( reason => $msg->{reason} ) : () ) };
    }
    if ( Time::HiRes::time() >= $deadline ) {
      $self->_close;
      return { answer => 'no', reason => 'no answer within '.$self->timeout.' seconds' };
    }
    next unless $select->can_read(0.25);
    my $got = sysread( $sock, my $chunk, 65536 );
    unless ($got) {
      $self->_close;
      return { answer => 'no', reason => 'the permission channel closed' };
    }
    $self->_buffer( $self->_buffer.$chunk );
  }
}

sub _connect {
  my ( $self ) = @_;
  my $sock = IO::Socket::UNIX->new( Peer => $self->path, Type => SOCK_STREAM )
    or die 'cannot connect to '.$self->path.': '.$!."\n";
  $self->_buffer('');
  return $self->_socket($sock);
}

sub _close {
  my ( $self ) = @_;
  if ( my $sock = $self->_socket ) { close $sock }
  $self->_drop_socket;
  $self->_buffer('');
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::PermissionChannel - Internal client of the hall's permission channel: asks a call over a Unix socket, never answers yes by accident

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $channel = Langertha::Raider::PermissionChannel->new(
      path      => $path,                          # --permission-channel PATH
      cancelled => sub { $app->run_cancelled },    # optional
    );
    $app->on_permission_request( $channel->callback );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The raider's end of the channel the hall opens for a run that belongs to an
ACP session (ADR 0021, Nachtrag P2). The hall starts the raider with the
hidden option C<--permission-channel PATH>; the application then sets
L</callback> as its C<on_permission_request>, so a tool call the policy asks
about is put to the ACP client instead of being refused.

The wire is JSON Lines over the Unix socket at C<path>. The raider sends
C<< { id, tool, source, arguments, reason, rule } >> and blocks, like the
REPL does for its question, until the hall answers
C<< { id, answer => 'once' | 'session' | 'no', reason } >>.

B<Deny by default.> Every failure is the answer C<no>, never C<once>: the
socket cannot be reached, it closes, the line is not JSON, the answer is
none of the three words, nothing comes within L</timeout>, or the run is
cancelled while the question is open (C<cancelled> returns true: C<SIGINT>
of the hall's cancel). The hall answers within its own
C<permission_timeout> (default 120 s), so L</timeout> is only the raider's
last resort.

=head2 path

The Unix socket of the channel. Required.

=head2 timeout

Seconds after which the raider stops waiting and answers C<no> (default 300).
The hall's own timeout is shorter.

=head2 cancelled

Optional code that returns true when the run was cancelled; asked every
quarter of a second while a question is open.

=head2 callback

    $app->on_permission_request( $channel->callback );

A code reference for C<on_permission_request> of
L<Langertha::Raider::Application>.

=head2 request

    my $answer = $channel->request({ tool => 'bash', arguments => {...}, reason => '...', rule => 'Bash(make)' });
    # { answer => 'once' | 'session' | 'no', reason => ... }

Asks the hall and waits. Never dies, never returns anything but one of the
three answers.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Hall::PermissionChannel>

=item * L<Langertha::Raider::Application/on_permission_request>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
