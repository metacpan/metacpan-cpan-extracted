package Langertha::Raider::ToolEffects;
# ABSTRACT: Internal static table of what each built-in tool can do (effect classes)
our $VERSION = '0.503';
use strict;
use warnings;
use Carp qw( croak );


my %EFFECTS = (
  # files
  list_files             => [qw( read )],
  read_file              => [qw( read )],
  write_file             => [qw( write )],
  edit_file              => [qw( write )],
  # shell
  bash                   => [qw( code )],
  # web
  web_search             => [qw( network )],
  web_fetch              => [qw( network )],
  # perl
  perl_eval              => [qw( code )],
  perl_check             => [qw( code )],
  perl_cpanm             => [qw( network code )],
  # hall
  telegram_reply         => [qw( message )],
  hall_status            => [qw( read )],
  hall_spawn             => [qw( message code )],
  # raider self-tools
  raider_ask_user        => [qw( message )],
  raider_wait            => [],
  raider_wait_for        => [qw( code )],
  raider_pause           => [],
  raider_abort           => [],
  raider_session_history => [qw( read )],
  raider_manage_mcps     => [qw( code )],
  raider_switch_engine   => [qw( network )],
);

my @CLASSES = qw( read write network code message );


sub classes { my ($self) = @_; return @CLASSES }

sub tool_names { my ($self) = @_; return sort keys %EFFECTS }

sub effects_for {
  my ( $self, $name ) = @_;
  croak __PACKAGE__.'->effects_for needs a tool name' unless defined $name && length $name;
  my $effects = $EFFECTS{$name} or return;
  return [ @$effects ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::ToolEffects - Internal static table of what each built-in tool can do (effect classes)

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

One place that says what each built-in tool of raider can do to the world,
in five effect classes (ADR 0005, information only -- nothing here allows or
refuses a call):

=over

=item C<read> -- reads local files or state

=item C<write> -- changes local files

=item C<network> -- talks to the internet

=item C<code> -- runs arbitrary code; it can do anything the other classes do

=item C<message> -- sends something to a person or to another agent

=back

A tool with an empty list has no effect outside the run (pure control flow).
A tool that is not in the table has no answer: L</effects_for> returns undef
and reports say C<unknown>. The table is keyed by name, so ask it only about
tools the caller knows to be built-in -- an external MCP server may use any
name, and its C<read_file> is not ours. C<explain_config> asks about the tools
raider itself mounted; a later policy (the gate of ADR 0005) must combine it
with the tool's source.

C<perl_eval> and C<perl_check> are C<code>: C<perl -c> runs C<BEGIN> blocks and
C<use>. C<perl_cpanm> is C<network> and C<code>: it downloads and then runs
distribution build and test code. C<bash> is C<code> alone, as the class
covers the rest. C<hall_spawn> starts another raider with a mission, so it
is C<message> and C<code>. C<raider_wait_for> is C<code>: the host runs a
callback of its own for the condition and raider cannot say what it does, so
the table takes the cautious reading. C<raider_manage_mcps> is C<code>
(activating starts a tool server) and C<raider_switch_engine> is C<network>
(later prompts go to another provider).

=head2 classes

The effect classes, in display order.

=head2 tool_names

All built-in tool names of the table, sorted.

=head2 effects_for

    my $classes = Langertha::Raider::ToolEffects->effects_for('write_file');   # ['write']

A new array ref of effect classes (empty: no effect outside the run), or
undef for a tool that is not in the table.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
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

=cut
