package Langertha::Raider::Hall::MCP;
our $VERSION = '0.503';
# ABSTRACT: Internal MCP tool adapter exposing the raider hall


use Moose;
use namespace::autoclean;
use JSON::MaybeXS;

has hall => (
  is => 'ro',
  isa => 'Langertha::Raider::Hall',
  required => 1,
  weak_ref => 1,
);

has socket_path => (
  is => 'ro',
  lazy => 1,
  builder => '_build_socket_path',
);

sub _build_socket_path {
  my ($self) = @_;
  $self->hall->root->child('.raider-hall.mcp')->stringify;
}

sub tools {
  my ($self) = @_;
  return {
    spawn_raider => {
      description => 'Spawn a raider in the hall',
      input => {
        type => 'object',
        properties => {
          name => { type => 'string' },
          mission => { type => 'string' },
        },
        required => [qw(name mission)],
      },
    },
    list_raiders => {
      description => 'List running raiders in the hall',
      input => { type => 'object', properties => {} },
    },
    schedule_raid => {
      description => 'Schedule a cron raid',
      input => {
        type => 'object',
        properties => {
          name => { type => 'string' },
          cron => { type => 'string' },
          mission => { type => 'string' },
          coalesce => { type => 'boolean' },
        },
        required => [qw(name cron mission)],
      },
    },
    cancel_job => {
      description => 'Cancel a scheduled job',
      input => {
        type => 'object',
        properties => { id => { type => 'string' } },
        required => [qw(id)],
      },
    },
    send_telegram => {
      description => 'Send a Telegram message',
      input => {
        type => 'object',
        properties => {
          bot => { type => 'string' },
          chat_id => { type => 'integer' },
          text => { type => 'string' },
        },
        required => [qw(bot chat_id text)],
      },
    },
    hall_status => {
      description => 'Get hall status',
      input => { type => 'object', properties => {} },
    },
  };
}

sub handle_tool_call {
  my ($self, $tool, $input) = @_;
  my $hall = $self->hall;

  if ($tool eq 'spawn_raider') {
    return $hall->spawn(name => $input->{name}, mission => $input->{mission});
  }
  if ($tool eq 'list_raiders') {
    return { raiders => [$hall->ps] };
  }
  if ($tool eq 'schedule_raid') {
    $hall->cron_scheduler->add_job(
      id => $input->{name},
      cron => $input->{cron},
      name => $input->{name},
      mission => $input->{mission},
      coalesce => $input->{coalesce} // 0,
    ) if $hall->can('cron_scheduler');
    return { scheduled => 1, name => $input->{name} };
  }
  if ($tool eq 'cancel_job') {
    $hall->cron_scheduler->cancel_job($input->{id}) if $hall->can('cron_scheduler');
    return { cancelled => 1, id => $input->{id} };
  }
  if ($tool eq 'send_telegram') {
    my $result = $hall->telegram->send_message(
      bot => $input->{bot},
      chat_id => $input->{chat_id},
      text => $input->{text},
    ) if $hall->can('telegram');
    delete $result->{future} if $result;
    return $result if $result;
    return { error => 'telegram not configured' };
  }
  if ($tool eq 'hall_status') {
    return {
      running => scalar(keys %{$hall->raiders}),
      root => $hall->root->stringify,
      slots => $hall->_running_slots,
    };
  }
  return { error => "unknown tool: $tool" };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::MCP - Internal MCP tool adapter exposing the raider hall

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Describes and dispatches the hall management tools (spawn, list, schedule,
cancel, Telegram, status) of a L<Langertha::Raider::Hall>.

No transport serves these tools yet: the hall opens no C<.raider-hall.mcp>
socket, so nothing outside the hall process can call them.

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
