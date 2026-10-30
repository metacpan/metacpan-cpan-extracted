package Langertha::Raider::Hall::PermissionChannel;
# ABSTRACT: Internal per-run Unix socket on which a hall raider asks the ACP client for permission
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Future;
use IO::Async::Listener;
use IO::Async::Stream;
use IO::Socket::UNIX;
use JSON::MaybeXS;
use Path::Tiny;


has loop => ( is => 'ro', required => 1 );


has handler => ( is => 'ro', isa => 'CodeRef', required => 1 );


has timeout => ( is => 'ro', isa => 'Num', default => 120 );


has path => ( is => 'ro', isa => 'Str', writer => '_set_path', init_arg => undef );


has _dir      => ( is => 'rw', init_arg => undef );
has _listener => ( is => 'rw', init_arg => undef );
has _streams  => ( is => 'ro', default => sub { [] }, init_arg => undef );
has _pending  => ( is => 'ro', default => sub { {} }, init_arg => undef );
has _closed   => ( is => 'rw', default => 0, init_arg => undef );

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 );

sub start {
  my ( $self ) = @_;
  my $dir = Path::Tiny->tempdir( TEMPLATE => 'raider-perm-XXXXXX', CLEANUP => 0 );
  chmod 0700, "$dir";
  $self->_dir($dir);
  my $path = $dir->child('p.sock')->stringify;
  my $sock = IO::Socket::UNIX->new( Local => $path, Listen => 5, Type => SOCK_STREAM )
    or die 'permission channel: cannot listen on '.$path.': '.$!."\n";
  my $listener = IO::Async::Listener->new( on_stream => sub { $self->_accept( $_[1] ) } );
  $self->loop->add($listener);
  $listener->listen( handle => $sock );
  $self->_listener($listener);
  $self->_set_path($path);
  return $path;
}


sub _accept {
  my ( $self, $stream ) = @_;
  $stream->configure(
    on_read => sub {
      my ( $s, $buf ) = @_;
      while ( $$buf =~ s/\A([^\n]*)\n// ) { $self->_question( $s, $1 ) }
      return 0;
    },
    on_closed => sub { },
  );
  push @{ $self->_streams }, $stream;
  $self->loop->add($stream);
  return;
}

sub _question {
  my ( $self, $stream, $line ) = @_;
  return unless length $line;
  my $req = eval { $JSON->decode($line) };
  return unless ref $req eq 'HASH' && defined $req->{id};
  my $id = $req->{id};
  my $answered = 0;
  my $reply = sub {
    my ( $answer ) = @_;
    return if $answered++ || $self->_closed;
    delete $self->_pending->{$id};
    my $word = ref $answer eq 'HASH' ? $answer->{answer} // '' : '';
    $answer = { answer => 'no', reason => $word eq 'no' && defined $answer->{reason} ? $answer->{reason} : 'no valid answer' }
      unless $word eq 'once' || $word eq 'session';
    $stream->write( $JSON->encode({ id => $id, answer => $answer->{answer},
      ( defined $answer->{reason} ? ( reason => $answer->{reason} ) : () ) })."\n" );
  };
  my $f = eval { $self->handler->($req) };
  $f = Future->fail( $@ || 'handler failed' ) unless eval { $f->isa('Future') };
  my $timer = $self->loop->delay_future( after => $self->timeout )->on_done( sub {
    $reply->({ answer => 'no', reason => 'no answer from the client within '.$self->timeout.' seconds' });
    $f->cancel unless $f->is_ready;    # lets the asker forget the question
  });
  # Held until answered: a Future nobody holds is destroyed mid-flight.
  $self->_pending->{$id} = [ $f, $timer ];
  $f->on_done( sub { $timer->cancel; $reply->( $_[0] ) } )
    ->on_fail( sub { $timer->cancel; $reply->({ answer => 'no', reason => 'the client could not be asked' }) } )
    ->on_cancel( sub { $timer->cancel; $reply->({ answer => 'no', reason => 'the question was cancelled' }) } );
  return;
}

sub close {
  my ( $self ) = @_;
  return if $self->_closed;
  $self->_closed(1);
  for my $p ( values %{ $self->_pending } ) {
    $_->cancel for grep { !$_->is_ready } @$p;
  }
  %{ $self->_pending } = ();
  for my $s ( @{ $self->_streams } ) {
    eval { $s->close_now };
  }
  @{ $self->_streams } = ();
  if ( my $l = $self->_listener ) {
    eval { $self->loop->remove($l) };
    $self->_listener(undef);
  }
  if ( my $dir = $self->_dir ) {
    eval { $dir->remove_tree };
    $self->_dir(undef);
  }
  return;
}


sub DEMOLISH { $_[0]->close }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::PermissionChannel - Internal per-run Unix socket on which a hall raider asks the ACP client for permission

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $channel = Langertha::Raider::Hall::PermissionChannel->new(
      loop    => $loop,
      timeout => 120,
      handler => sub { my ($request) = @_; return $future_of_answer },
    );
    my $path = $channel->start;     # for --permission-channel
    ...
    $channel->close;

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The hall's end of the channel of one run (ADR 0021, Nachtrag P2): the hall
creates it for a run bound to an ACP session, passes the socket path to the
raider as C<--permission-channel PATH>, and closes it when the run ends. The
socket lives in a directory of its own (mode 0700) under the temporary
directory, so only the hall's user can connect.

Each line the raider writes is a question
C<< { id, tool, source, arguments, reason, rule } >>; L</handler> returns a
L<Future> of C<< { answer => 'once' | 'session' | 'no', reason } >>, which is
written back as C<< { id, answer, reason } >>. B<Deny by default>: a handler
that dies, fails, answers anything else, or does not answer within
L</timeout> seconds gives C<no>. The raider is never killed for waiting.

=head2 loop

The L<IO::Async::Loop>. Required.

=head2 handler

Called with the question (a hash); returns a Future of the answer. Required.

=head2 timeout

Seconds the handler gets before the answer is C<no> (default 120).

=head2 path

The socket path, after L</start>.

=head2 start

    my $path = $channel->start;

Creates the socket and starts listening. Returns the path.

=head2 close

Ends the channel: open questions are dropped (the raider is gone or going),
the socket and its directory are removed. Safe to call twice.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::PermissionChannel>

=item * L<Langertha::Raider::Hall::ACP>

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
