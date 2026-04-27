package Langertha::Knarr::Response;
# ABSTRACT: Normalized chat response shared across all Knarr handlers and protocol formatters
our $VERSION = '1.100';
use Moose;
use Scalar::Util qw( blessed );


has content => (
  is => 'ro',
  isa => 'Str',
  default => '',
);

has model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has usage => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

has tool_calls => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);

has finish_reason => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has raw => (
  is => 'ro',
  default => sub { undef },
);


sub coerce {
  my ($class, $thing) = @_;
  return $class->new() unless defined $thing;
  if (blessed $thing) {
    return $thing if $thing->isa($class);
    return $class->from_langertha_response($thing) if $thing->isa('Langertha::Response');
    return $class->new( content => "$thing" );
  }
  if (ref $thing eq 'HASH') {
    return $class->new( %$thing );
  }
  return $class->new( content => "$thing" );
}


sub from_langertha_response {
  my ($class, $r) = @_;
  return $class->new(
    content       => "$r",
    model         => ( $r->can('model')         ? $r->model         : undef ),
    usage         => ( $r->can('usage')         ? $r->usage         : undef ),
    tool_calls    => ( $r->can('tool_calls')    ? ( $r->tool_calls // [] ) : [] ),
    finish_reason => ( $r->can('finish_reason') ? $r->finish_reason : undef ),
    raw           => ( $r->can('raw')           ? $r->raw           : undef ),
  );
}


sub has_tool_calls {
  my ($self) = @_;
  return scalar @{ $self->tool_calls } > 0;
}


sub clone_with {
  my ($self, %override) = @_;
  return ref($self)->new(
    content       => $self->content,
    model         => $self->model,
    usage         => $self->usage,
    tool_calls    => $self->tool_calls,
    finish_reason => $self->finish_reason,
    raw           => $self->raw,
    %override,
  );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Response - Normalized chat response shared across all Knarr handlers and protocol formatters

=head1 VERSION

version 1.100

=head1 DESCRIPTION

The single shape every L<Langertha::Knarr::Handler> returns and every
L<Langertha::Knarr::Protocol> formatter consumes. Mirrors
L<Langertha::Response> but is decoupled from it so non-engine handlers
(L<Langertha::Knarr::Handler::Code>, L<Langertha::Knarr::Handler::A2AClient>,
L<Langertha::Knarr::Handler::ACPClient>) can produce a Knarr response
without going through Langertha first.

C<BUILDARGS> upgrades all the legacy shapes Knarr handlers used to
return — a bare string, a C<{ content =E<gt> ..., model =E<gt> ... }>
hashref, or a stringifiable L<Langertha::Response> — into a
proper value object. So existing call sites can pass anything they
already had and downstream code can rely on a single API.

=head2 content

Plain assistant text. Defaults to empty string.

=head2 model

The model id that produced the response, if known.

=head2 usage

A L<Langertha::Usage> object with token counts, if the engine reported
them. C<undef> for handlers that have no usage data (Code, Passthrough).

=head2 tool_calls

ArrayRef of L<Langertha::ToolCall> objects produced by the engine.
Empty arrayref when the response is plain text.

=head2 finish_reason

Provider-agnostic stop reason (C<stop>, C<tool_calls>, C<length>, ...).
Optional; the protocol formatters fall back to C<stop> / C<end_turn>
when undef.

=head2 raw

Optional. The provider-native response body, kept around for handlers
(passthrough-style) that want to preserve every byte upstream returned.

=head2 coerce

    my $r = Langertha::Knarr::Response->coerce( $whatever );

Class method. Accepts:

=over

=item * an existing C<Langertha::Knarr::Response> — returned as-is.

=item * a L<Langertha::Response> — fields lifted via
C<from_langertha_response>.

=item * any other blessed object that stringifies — used as C<content>.

=item * a HashRef — fed to C<new> after key normalization.

=item * a plain scalar — used as C<content>.

=item * C<undef> — produces an empty response.

=back

This is the single normalization entry point. Handlers can return
whatever shape is convenient and the dispatcher coerces once at the
boundary.

=head2 from_langertha_response

    my $r = Langertha::Knarr::Response->from_langertha_response($lresp);

Builds a Knarr response from a L<Langertha::Response>. Carries
C<content>, C<model>, C<usage>, C<tool_calls>, C<finish_reason>, and
C<raw> across.

=head2 has_tool_calls

True when C<tool_calls> contains at least one entry.

=head2 clone_with

    my $r2 = $r->clone_with( model => 'override' );

Returns a new response with the given fields overridden. All other
attributes carry through from C<$self>.

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
