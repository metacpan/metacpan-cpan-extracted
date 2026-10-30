package Langertha::Raider::Plugin::Events;
our $VERSION = '0.504';
# ABSTRACT: Report a raid's tool calls and results as machine-output events

use Moose;
use namespace::autoclean;
use Future::AsyncAwait;
use JSON::MaybeXS ();
use Langertha::Usage;

extends 'Langertha::Plugin';


has on_event => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);

has _calls => ( is => 'rw', init_arg => undef, default => 0 );

async sub plugin_before_raid {
  my ( $self, $messages ) = @_;
  $self->_calls(0);
  return $messages;
}

# The tokens of every model call of the raid (ADR 0026). Not reported when
# the response carries no usage.
async sub plugin_after_llm_response {
  my ( $self, $data, $iteration ) = @_;
  my $usage = Langertha::Usage->from_raw($data);
  if ($usage) {
    my $raider = $self->raider;
    my $model = ref $data eq 'HASH' && defined $data->{model} && length $data->{model} ? $data->{model}
      : $raider && $raider->engine->can('chat_model') ? $raider->engine->chat_model : undef;
    $self->on_event->('model.usage',
      purpose       => 'chat',
      defined $model ? ( model => $model ) : (),
      input_tokens  => $usage->input_tokens,
      output_tokens => $usage->output_tokens,
      defined $usage->cached_tokens      ? ( cache_read_tokens  => $usage->cached_tokens )      : (),
      defined $usage->cache_write_tokens ? ( cache_write_tokens => $usage->cache_write_tokens ) : (),
    );
  }
  return $data;
}

async sub plugin_before_tool_call {
  my ( $self, $name, $input, $ctx ) = @_;
  $self->_calls($self->_calls + 1);
  # Recorded in the call's context (Langertha::Raider/plugins), so the result
  # of a call that ran beside others gets its own id, and an async tool's
  # handler knows it (the agent call id of ADR 0027).
  $ctx->{call} = $self->_call_id if ref $ctx eq 'HASH';
  $self->on_event->('tool.call', call => $self->_call_id, name => $name, arguments => $input // {},
    status => 'dispatched');
  return ( $name, $input );
}

# The id of the last call. A host that passes no call context runs its tool
# calls one after another, so a result belongs to the last call.
sub _call_id { 'c'.$_[0]->_calls }

async sub plugin_after_tool_call {
  my ( $self, $name, $input, $result, $ctx ) = @_;
  my $call = ref $ctx eq 'HASH' && defined $ctx->{call} ? $ctx->{call} : $self->_call_id;
  my ( $text, $ok ) = ref $result eq 'HASH'
    ? ( join('', map { $_->{text} // '' } grep { ref $_ eq 'HASH' }
        ref $result->{content} eq 'ARRAY' ? @{ $result->{content} } : ()),
        !$result->{isError} )
    : ( $result // '', 1 );
  $self->on_event->('tool.result',
    call    => $call,
    name    => $name,
    status  => ref $result eq 'HASH' && $result->{cancelled} ? 'cancelled' : $ok ? 'succeeded' : 'failed',
    ok      => $ok ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    size    => length $text,
    content => $text,
  );
  $self->on_event->('message', role => 'user', content => $_) for $self->_result_messages($result);
  return $result;
}

# The user messages a result hands the raider (the _meta key of
# Langertha::Raider, ADR 0026): the raid adds them after the tool results,
# so they are reported -- and journalled -- as messages right after the
# tool.result.
sub _result_messages {
  my ( $self, $result ) = @_;
  my $meta = ref $result eq 'HASH' ? $result->{_meta} : undef;
  my $list = ref $meta eq 'HASH' ? $meta->{'raider/messages'} : undef;
  return ref $list eq 'ARRAY' ? grep { defined && !ref && length } @$list : ();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Plugin::Events - Report a raid's tool calls and results as machine-output events

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        plugins => [ '+Langertha::Raider::Plugin::Events' => {
          on_event => sub { my ( $type, %payload ) = @_; ... },
        } ],
    );

=head1 DESCRIPTION

The source of the C<tool.call> and C<tool.result> events of a raid: the
output of C<raider --stream-json> and its siblings (ADR 0013) and the
session journal (ADR 0015) are both fed from here. Every tool call the raid
makes is handed to L</on_event> twice: before it runs, with its name and
arguments, and after, with the outcome and the whole text of its result --
a consumer that shows less (the stream) cuts it itself.

Load it after any plugin that may skip or rewrite a tool call, so the
events describe the call that actually runs.

=head2 on_event

Code reference called as C<< $on_event->($type, %payload) >>. Required.

=over

=item C<tool.call> -- C<call> (the id of the call within the raid: C<c1>,
C<c2>, ...), C<name>, C<arguments> and C<status> (C<dispatched>). The id
is also recorded as C<call> in the call's context
(L<Langertha::Raider/plugins>), where an async tool's handler finds it.

=item C<tool.result> -- C<call> (the id of its C<tool.call>, also when
calls ran at the same time), C<name>,
C<status> (C<cancelled> for a call cut off by L<Langertha::Raider/cancel>,
C<failed> when the tool reported an error, else C<succeeded>),
C<ok> (the same as a boolean), C<size> (characters of the text) and
C<content> (the whole text).

=item C<message> -- C<role> (C<user>) and C<content>, right after the
C<tool.result> of a call whose result hands the raid a user message (the
body of a skill, L<Langertha::Raider/TOOL RESULTS THAT ADD MESSAGES>).

=item C<model.usage> -- after every model call of the raid that reports
tokens: C<purpose> (C<chat>), C<model>, C<input_tokens>, C<output_tokens> and,
when the provider reports them, C<cache_read_tokens> and
C<cache_write_tokens> (both part of C<input_tokens>; ADR 0026).

=back

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI::Machine>

=item * L<Langertha::Plugin>

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
