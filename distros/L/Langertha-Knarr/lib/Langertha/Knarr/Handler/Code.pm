package Langertha::Knarr::Handler::Code;
# ABSTRACT: Coderef-backed Knarr handler for fakes, tests, and custom logic
our $VERSION = '1.001';
use Moose;
use Future;
use Future::AsyncAwait;
use Langertha::Knarr::Stream;

with 'Langertha::Knarr::Handler';


has code => (
  is => 'ro',
  isa => 'CodeRef',
  required => 1,
);

# Optional: separate generator for streaming. Returns a coderef that itself
# returns next-chunk strings (undef = done) when called.
has stream_code => (
  is => 'ro',
  isa => 'Maybe[CodeRef]',
  default => sub { undef },
);

has models => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [ { id => 'steerboard-code', object => 'model' } ] },
);

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my $out = $self->code->( $session, $request );
  return { content => "$out", model => $request->model // 'steerboard-code' };
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  if ( my $sc = $self->stream_code ) {
    my $gen = $sc->( $session, $request );
    return Langertha::Knarr::Stream->new( generator => $gen );
  }
  my $text = $self->code->( $session, $request );
  return Langertha::Knarr::Stream->from_list("$text");
}

sub list_models { $_[0]->models }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::Code - Coderef-backed Knarr handler for fakes, tests, and custom logic

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Langertha::Knarr::Handler::Code;

    my $handler = Langertha::Knarr::Handler::Code->new(
        code => sub {
            my ($session, $request) = @_;
            return 'echo: ' . $request->messages->[-1]{content};
        },
        stream_code => sub {
            my @parts = ('hel', 'lo');
            return sub { @parts ? shift @parts : undef };
        },
    );

=head1 DESCRIPTION

The simplest possible handler: pass coderefs that return strings (or
chunk generators for streaming) and you get a working Knarr handler.
Useful for tests, fakes, smoketests, and "fake LLM" demos.

=head2 code

Required. Coderef called as C<< $code->($session, $request) >> for
non-streaming requests; must return a scalar string.

=head2 stream_code

Optional. Coderef returning another coderef that yields the next chunk
per call, C<undef> to signal end.

=head2 models

Optional. Arrayref of model descriptors. Defaults to a single
C<steerboard-code> entry.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

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

=cut
