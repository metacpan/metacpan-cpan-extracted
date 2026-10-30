package Langertha::Raider::PlanTools;
# ABSTRACT: Internal plan-mode tools of raider: enter_plan_mode and exit_plan_mode
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use MCP::Server;


has handler => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);


has enter_handler => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_enter_handler',
);


has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);


has enter_server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_enter_server',
  init_arg => undef,
);


sub _build_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-plan', version => '1.0' );
  $server->tool(
    name         => 'exit_plan_mode',
    description  => 'In plan mode: present your finished plan to the user for approval. Call it when you have read '
      .'enough and know what you would change and how; the user approves it (then you may edit files and run commands) '
      .'or tells you what to change. Only for plans of work that changes something, not for research questions.',
    input_schema => {
      type       => 'object',
      properties => {
        plan => { type => 'string', description => 'The plan, concise, in Markdown' },
      },
      required => ['plan'],
    },
    code => sub {
      my ( $tool, $in ) = @_;
      my ( $text, $is_error ) = $self->handler->( $in->{plan} );
      return $tool->text_result( $text, $is_error ? 1 : 0 );
    },
  );
  return $server;
}

sub _build_enter_server {
  my ( $self ) = @_;
  croak __PACKAGE__.'->enter_server needs an enter_handler' unless $self->has_enter_handler;
  my $server = MCP::Server->new( name => 'raider-plan-enter', version => '1.0' );
  $server->tool(
    name         => 'enter_plan_mode',
    description  => 'Ask to switch to plan mode before a non-trivial implementation: a new feature, a change across '
      .'several files, a choice between approaches, unclear requirements. In plan mode you explore the code and design '
      .'the approach without changing anything, then present the plan with exit_plan_mode for the user to approve. '
      .'The user has to agree to enter plan mode. Skip it for small, obvious changes and for research questions.',
    input_schema => { type => 'object', properties => {} },
    code         => sub {
      my ( $tool ) = @_;
      my ( $text, $is_error ) = $self->enter_handler->();
      return $tool->text_result( $text, $is_error ? 1 : 0 );
    },
  );
  return $server;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::PlanTools - Internal plan-mode tools of raider: enter_plan_mode and exit_plan_mode

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $plan = Langertha::Raider::PlanTools->new(
      handler       => sub { my ( $plan ) = @_; ...; return ( $text, $is_error ) },
      enter_handler => sub { ...; return ( $text, $is_error ) },
    );
    my $exit  = $plan->server;         # MCP::Server with the tool exit_plan_mode
    my $enter = $plan->enter_server;   # MCP::Server with the tool enter_plan_mode

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The plan-mode tools, shaped after Claude Code's C<EnterPlanMode> and
C<ExitPlanMode> (L<Langertha::Raider::ToolNames>). In the C<plan> permission
mode (ADR 0021) the model reads and plans; with C<enter_plan_mode> (no
arguments) it asks to go there before a larger change, with
C<exit_plan_mode> it presents the plan to leave the mode. The tools decide
nothing themselves: L</enter_handler> and L</handler> -- the application --
switch the mode or say why it stays, and return the text the model gets.
Whether the person is asked before plan mode is entered is the permission
gate's business (ADR 0025): the call reaches the handler only when it may
run.

The application mounts C<enter_plan_mode> always and C<exit_plan_mode> once
its run has been in plan mode.

=head2 handler

Required. The handler of C<exit_plan_mode>: called as
C<< $handler->($plan) >> on every call; returns the result text and whether
it is an error.

=head2 enter_handler

The handler of C<enter_plan_mode>: called as C<< $enter_handler->() >> on
every call; returns the result text and whether it is an error. Needed for
L</enter_server>.

=head2 server

The L<MCP::Server> with the tool C<exit_plan_mode>, built once.

=head2 enter_server

The L<MCP::Server> with the tool C<enter_plan_mode>, built once. Croaks
without L</enter_handler>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::Permissions>

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
