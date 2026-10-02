#!/usr/bin/env perl
# ABSTRACT: The prompt's tool description derives from the mounted tool servers (ADR 0005)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use IO::Socket::UNIX;
use MCP::Server;
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Application;

clear_engine_env();
delete @ENV{ grep { /^RAIDER_HALL_/ } keys %ENV };

# An application that mounts one more tool server than the stock set.
{
  package Test::Raider::ProbeApp;
  use Moose;
  extends 'Langertha::Raider::Application';
  around _build_tool_servers => sub {
    my ( $orig, $self ) = @_;
    my $probe = MCP::Server->new(name => 'probe', version => '1.0');
    $probe->tool(
      name         => 'zz_probe',
      description  => 'A tool only this test mounts',
      input_schema => {
        type       => 'object',
        properties => { b => {}, a => {}, y => {}, x => {} },
        required   => [qw( b a )],
      },
      code => sub { $_[0]->text_result('ok') },
    );
    return [ @{ $self->$orig }, $probe ];
  };
  __PACKAGE__->meta->make_immutable;
}

sub app {
  my ( %args ) = @_;
  my $class = delete $args{class} // 'Langertha::Raider::Application';
  return $class->new(
    root    => tempdir(CLEANUP => 1),
    engine  => 'openai',
    api_key => 'test',
    detect  => 0,
    %args,
  );
}

# The tool lines of the tool description, in order.
sub tool_lines {
  my ( $app ) = @_;
  my ($block) = $app->mission =~ /^Tools \(MCP\):\n((?:  - .*\n)+)/m
    or return [];
  return [ map { s/^  - //r } split /\n/, $block ];
}

subtest 'stock set: exactly the mounted tools, with their parameters' => sub {
  my $app = app();
  is(tool_lines($app), [
    'list_files(path)',
    'read_file(path)',
    'write_file(path, content)',
    'edit_file(path, old_string, new_string)',
    'bash(command, [compress], [timeout], [working_directory])',
    'web_search(query, [limit])',
    'web_fetch(url, [as_html])',
  ], 'tool description lists the stock tool servers');
  unlike($app->mission, qr/perl_eval/, 'Perl tools not mounted, not described');
  unlike($app->mission, qr/telegram_reply|hall_status/, 'Hall tools not mounted, not described');
};

subtest 'the prompt names the same tools the engine is given' => sub {
  my $app = app(perl => 1);
  my @listed;
  for my $mcp (@{ $app->_mcps }) {
    $app->loop->await($mcp->initialize);
    push @listed, map { $_->{name} } @{ $app->loop->await($mcp->list_tools)->get };
  }
  my @described = map { /^(\w+)\(/ ? $1 : () } @{ tool_lines($app) };
  is(\@described, \@listed, 'one tool set for prompt and catalogue');
};

subtest 'Perl tools: described once mounted' => sub {
  my $app = app(perl => 1);
  my $lines = tool_lines($app);
  ok((grep { $_ eq 'perl_eval(code, [stdin], [timeout])' } @$lines), 'perl_eval with its parameters');
  ok((grep { /^perl_check\(/ } @$lines), 'perl_check');
  ok((grep { /^perl_cpanm\(/ } @$lines), 'perl_cpanm');
};

subtest 'Hall tools: described when the hall socket mounts them' => sub {
  my $dir  = tempdir(CLEANUP => 1);
  my $path = path($dir)->child('hall.sock')->stringify;
  my $sock = IO::Socket::UNIX->new(Type => SOCK_STREAM(), Local => $path, Listen => 1)
    or skip_all('no unix socket: '.$!);
  local $ENV{RAIDER_HALL_SOCKET} = $path;
  my $lines = tool_lines(app());
  ok((grep { $_ eq 'telegram_reply(bot, chat_id, text, [message_thread_id])' } @$lines),
    'telegram_reply with its parameters');
  ok((grep { $_ eq 'hall_status()' } @$lines), 'hall_status, no parameters');
  ok((grep { $_ eq 'hall_spawn(name, mission)' } @$lines), 'hall_spawn with its parameters');
};

subtest 'an additionally mounted tool shows up; required first, optional sorted' => sub {
  my $app = app(class => 'Test::Raider::ProbeApp');
  my $lines = tool_lines($app);
  is($lines->[-1], 'zz_probe(b, a, [x], [y])', 'extra tool described from its input schema');
  unlike(app()->mission, qr/zz_probe/, 'the stock application does not describe it');
};

subtest '-M and --bare keep the derived description' => sub {
  for my $args ([ mission => 'You are the flag mission.' ], [ bare => 1 ],
    [ mission => 'Only this.', bare => 1 ]) {
    my $app = app(perl => 1, @$args);
    ok((grep { /^perl_eval\(/ } @{ tool_lines($app) }), "perl_eval described (@$args)");
  }
};

done_testing;
