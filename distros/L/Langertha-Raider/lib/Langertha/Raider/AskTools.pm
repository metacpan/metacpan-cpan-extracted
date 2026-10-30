package Langertha::Raider::AskTools;
# ABSTRACT: Internal question tool of raider: ask_user
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use MCP::Server;


has answerer => (
  is  => 'ro',
  isa => 'CodeRef',
);


has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);



sub unavailable {
  return 'ask_user is not available: this run is not interactive, nobody can answer. '
    .'Decide yourself with the information you have and state your assumption in your answer.';
}

sub _build_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-ask', version => '1.0' );
  $server->tool(
    name         => 'ask_user',
    description  => 'Ask the user a question and wait for the answer. Use it when a decision or a fact you cannot find out '
      .'yourself blocks the work; do not ask what you can read or try. Give options when the answer is a choice. '
      .'In a run nobody can answer, the call is refused: decide yourself and say what you assumed.',
    input_schema => {
      type       => 'object',
      properties => {
        question => { type => 'string', description => 'The question' },
        options  => { type => 'array', items => { type => 'string' }, description => 'Choices to offer (optional)' },
      },
      required => ['question'],
    },
    code => sub {
      my ( $tool, $in ) = @_;
      my $ask = $self->answerer ? $self->answerer->() : undef;
      return $tool->text_result( $self->unavailable, 1 ) unless $ask;
      my $answer = $ask->( $in->{question}, $in->{options} // [] );
      return $tool->text_result( 'The user gave no answer (input closed). Decide yourself and state your assumption.', 1 )
        unless defined $answer && length $answer;
      return $tool->text_result( 'User answered: '.$answer );
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

Langertha::Raider::AskTools - Internal question tool of raider: ask_user

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $ask    = Langertha::Raider::AskTools->new( answerer => sub { $have_person ? sub { my ( $question, $options ) = @_; ... } : undef } );
    my $server = $ask->server;      # MCP::Server with the tool ask_user

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The C<ask_user> tool, shaped after Claude Code's C<AskUserQuestion>
(L<Langertha::Raider::ToolNames>): the model asks the person at the
keyboard a question, with optional choices, and gets the answer as the
tool result.

The tool asks nobody itself. L</answerer> yields the surface's way to put the
question to a person (the REPL reads a line, see
L<Langertha::Raider::Application/on_ask_user>). A run nobody can answer --
a one-shot C<raider "..."> run, the Hall, a cron job, ACP -- has no such
way, and the tool refuses plainly: an error result that tells the model to
decide for itself and say what it assumed. It never blocks a run that no
one watches.

C<ask_user> is the tool the model sees. The self-tool C<raider_ask_user> of
L<Langertha::Raider> (C<raider_mcp>) is the library's own variant, which
ends the raid with a C<question> result; the application does not turn it
on.

=head2 answerer

Called on every call, without arguments. Returns the code to put the
question to a person -- called as C<< $ask->($question, \@options) >> (C<@options>
empty without choices), returning the answer as text or undef when the
person gave none -- or undef when nobody can answer. Asked per call because
the surface may register its way after the tools are mounted. Without it
every call is refused.

=head2 server

The L<MCP::Server> with the tool C<ask_user>, built once.

=head2 unavailable

The text of the refusal.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::ToolNames>

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
