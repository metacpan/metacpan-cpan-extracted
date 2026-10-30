package Langertha::Raider::Plugin::ClaudeHooks;
our $VERSION = '0.504';
# ABSTRACT: Internal plugin that runs the Claude Code PostToolUse and PostToolUseFailure hooks on tool results

use Moose;
use namespace::autoclean;
use Future::AsyncAwait;
use JSON::MaybeXS ();

extends 'Langertha::Plugin';


has app => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

has on_event => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_on_event',
);

has input => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_input',
);

has on_stop => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_on_stop',
);

async sub plugin_after_tool_call {
  my ( $self, $name, $input, $result, $ctx ) = @_;
  my $app = $self->app or return $result;
  return $result unless ref $result eq 'HASH';
  $ctx = {} unless ref $ctx eq 'HASH';
  my @blocks;
  if (defined( my $pre = $app->_take_tool_hook_context($input) )) {
    push @blocks, $pre;
  }
  my $hooks = $app->hooks;
  my $failed = $result->{isError} || $result->{cancelled};
  my $event = $failed ? 'PostToolUseFailure' : 'PostToolUse';
  if ($hooks && $hooks->has_hooks($event)) {
    my $r = await $hooks->run_f( $event => $app->_hook_input(
      ( $self->has_input ? $self->input->() : () ),
      tool_name  => $name,
      tool_input => ref $input eq 'HASH' ? $input : {},
      $failed ? (
        ( defined $ctx->{id} ? ( tool_use_id => $ctx->{id} ) : () ),
        error        => $self->_result_text($result),
        is_interrupt => $result->{cancelled} ? JSON::MaybeXS->true : JSON::MaybeXS->false,
      ) : (
        tool_response => { content => $result->{content} // [] },
      ),
    ) );
    $app->_report_hooks($r, $self->has_on_event ? $self->on_event : undef, call => $ctx->{call});
    $app->_hook_stopped($self->has_on_stop ? $self->on_stop : undef) if $r->stopped;
    my $tag = $app->_hook_tag($event, $name);
    push @blocks, map { $tag.' hook feedback: '.$_ } @{ $r->reasons } ? @{ $r->reasons } : '(no reason given)'
      if $r->blocked;
    push @blocks, $tag.' hook additional context: '.$r->context if defined $r->context;
  }
  return $result unless @blocks;
  return {
    %$result,
    content => [
      ( ref $result->{content} eq 'ARRAY' ? @{ $result->{content} } : () ),
      map { { type => 'text', text => "<system-reminder>\n".$_."\n</system-reminder>" } } @blocks,
    ],
  };
}

# The text blocks of a result, one per line: the error of a failed call.
sub _result_text {
  my ( $self, $result ) = @_;
  my $content = ref $result->{content} eq 'ARRAY' ? $result->{content} : [];
  return join "\n", map { $_->{text} } grep { ref $_ eq 'HASH' && defined $_->{text} } @$content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Plugin::ClaudeHooks - Internal plugin that runs the Claude Code PostToolUse and PostToolUseFailure hooks on tool results

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $raider = Langertha::Raider->new(
        engine  => $engine,
        plugins => [ '+Langertha::Raider::Plugin::ClaudeHooks' => { app => $app } ],
    );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The tool-result side of Claude Code's hooks (ADR 0022) in the Claude
layout. After every tool call it

=over

=item * appends the C<additionalContext> a C<PreToolUse> hook gave for
this call (L<Langertha::Raider::Application/tool_hook> keeps it),

=item * runs the C<PostToolUse> hooks of
L<Langertha::Raider::Application/hooks> on a result that is not an error
and was not cut off by a cancel, with C<tool_name> and C<tool_input> in
Claude Code's form and C<tool_response> as raider's result (an MCP
C<content> list, not Claude Code's per-tool shape), and appends their
C<additionalContext> and the reason of a C<decision: "block"> (or the
stderr of exit 2) -- the tool already ran, so this is feedback for the
model,

=item * runs the C<PostToolUseFailure> hooks instead on a result that is
an error (C<isError>: the tool failed, the gate or a C<PreToolUse> hook
refused the call, its arguments did not fit the schema) or was cut off by
a cancel (ADR 0034), with C<tool_name>, C<tool_input>, C<tool_use_id> (the
model's id of the call, when it gave one), C<error> (the result's text)
and C<is_interrupt> (true for a cancel), and appends their feedback the
same way. Claude Code fires it for neither a refused call nor a schema
error; raider does, as ADR 0034 decides,

=back

each as one more text block wrapped in C<< <system-reminder> >>, the way
L<Langertha::Raider::Plugin::NestedMemory> appends. It sits after
NestedMemory and before the Events plugin, so C<tool.result> in the
journal is the result as the model gets it. The hook runs are reported by
the application (C<hook.ran>, C<hook.message>) to L</on_event>; a
C<continue: false> calls L</on_stop> (default: the run is cancelled). The
C<hook.ran> of these tool hooks carry the call's id (C<call>, ADR 0034).

=head2 app

The L<Langertha::Raider::Application>. Required; held weakly.

=head2 on_event

Where the hook runs are reported, called as C<< ->($type, %payload) >>:
the Events consumer of the raider (a subagent's journal). Default: the
application's L<Langertha::Raider::Application/event>.

=head2 input

Optional code ref whose pairs go into every hook input -- a subagent's
C<agent_id>, C<agent_type> and C<permission_mode>.

=head2 on_stop

Optional code ref called on a C<continue: false>; default
L<Langertha::Raider::Application/cancel_run>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Hooks>

=item * L<Langertha::Raider::Plugin::NestedMemory>

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
