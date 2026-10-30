package Langertha::Raider::SkillTools;
our $VERSION = '0.504';
# ABSTRACT: Internal MCP::Server factory with the skill tool (load a skill on demand)

use strict;
use warnings;
use Carp qw( croak );
use MCP::Server;

use Exporter 'import';
our @EXPORT_OK = qw( build_skill_tools_server );


sub build_skill_tools_server {
  my %args = @_;
  my $skills = $args{skills}
    or croak __PACKAGE__.'::build_skill_tools_server needs skills';
  my $render = $args{render};

  my $server = MCP::Server->new(name => 'raider-skills', version => '1.0');

  $server->tool(
    name         => 'skill',
    description  => 'Execute a skill within the conversation. Skills are specialised '
      .'instructions and domain knowledge, loaded on demand; the available skills are '
      .'listed in the system prompt with their descriptions. When a task matches a '
      .'skill, call this tool with its name BEFORE acting on the task, then follow the '
      .'instructions it loads into the conversation. Only call skills that are listed, '
      .'and do not load a skill again whose instructions are already in the conversation.',
    input_schema => {
      type       => 'object',
      properties => {
        skill => {
          type        => 'string',
          description => 'The skill name, e.g. "pdf" or "plugin:skill"',
        },
        args => {
          type        => 'string',
          description => 'Optional arguments for the skill',
        },
      },
      required => ['skill'],
    },
    code => sub {
      my ( $tool, $in ) = @_;
      my $name = $in->{skill};
      $name = '' unless defined $name && !ref $name;
      $name =~ s/\A\s+|\s+\z//g;
      my $skill = length $name ? $skills->find($name) : undef;
      unless ($skill && $skills->is_listed($skill)) {
        my @listed = map { $_->{name} } $skills->listed;
        return $tool->text_result('<tool_use_error>Unknown skill: '.( length $name ? $name : '(none given)' )
          .'. '.( @listed ? 'Available skills: '.join(', ', @listed) : 'No skills are available.' )
          .'</tool_use_error>', 1);
      }
      my $args = $in->{args};
      $args = undef if ref $args;
      my $loaded = $render ? $render->($skill, $args) : { text => $skills->tool_text($skill->{name}, $args) };
      return $tool->text_result($loaded->{error}, 1) if defined $loaded->{error};
      # As Claude Code: the result only says so, the body is a user message
      # of its own after the tool results (Langertha::Raider, ADR 0026).
      my $result = $tool->text_result('Launching skill: '.$skill->{name});
      $result->{_meta} = { 'raider/messages' => [ $loaded->{text} ] };
      return $result;
    },
  );

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::SkillTools - Internal MCP::Server factory with the skill tool (load a skill on demand)

=head1 VERSION

version 0.504

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The C<skill> tool of ADR 0019 §4: an L<MCP::Server> with one tool,
C<skill(skill, args?)>, that loads a skill of a
L<Langertha::Raider::Context::Skills> catalogue the way Claude Code's Skill
tool does (ADR 0026): the result is C<Launching skill: NAME>, and the skill
-- C<Base directory for this skill: DIR>, then the body without
frontmatter, C<$ARGUMENTS> replaced (see
L<Langertha::Raider::Context::Skills/tool_text>) -- goes under the
C<raider/messages> key of the result's C<_meta>, so the raid adds it as a
user message of its own after the tool results
(L<Langertha::Raider/TOOL RESULTS THAT ADD MESSAGES>). The system prompt
lists the skills (L<Langertha::Raider::Context::Skills/prompt_text>); the
tool loads one. Mount it only when the catalogue lists at least one skill.

=head2 build_skill_tools_server

    my $server = Langertha::Raider::SkillTools::build_skill_tools_server(
        skills => $catalogue,   # Langertha::Raider::Context::Skills
        render => sub { my ( $entry, $args ) = @_; ...; return { text => $text } },  # optional
    );

Returns an L<MCP::Server> with the tool C<skill>. A name the catalogue does
not know, or a skill that is not model-invocable
(C<disable-model-invocation: true>), is the error result
C<< <tool_use_error>Unknown skill: NAME. Available skills: ...</tool_use_error> >>
-- Claude Code's words and frame, then the listed skills.
Croaks without C<skills>.

C<render> loads the entry's text: called with the catalogue entry and the
C<args>, it returns C<< { text => ... } >>, or C<< { error => ... } >> --
then the tool result is that error and nothing is loaded. The application
passes L<Langertha::Raider::Application/skill_tool_text>, which renders
through L<Langertha::Raider::SlashCommand> (ADR 0030 E<sect>2: placeholders
and C<!`cmd`>). Without it the text is
L<Langertha::Raider::Context::Skills/tool_text>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Context::Skills>

=item * L<Langertha::Raider::FileTools>

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
