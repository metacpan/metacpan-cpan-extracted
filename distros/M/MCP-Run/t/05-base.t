use strict;
use warnings;
use Test::More;

use MCP::Run;

# A runner that answers everything with a successful exit, and records that it
# was asked. This is exactly the shape of the bug in karr #15: bash -c "" also
# returns exit 0, so a request that reaches execute() at all is already lost.
{
  package MCP::Run::Test::Recorder;
  use Mojo::Base 'MCP::Run', -signatures;

  has calls => sub { [] };

  sub execute ($self, $command, $working_directory, $timeout) {
    push @{$self->calls}, {command => $command, timeout => $timeout};
    return {exit_code => 0, stdout => '', stderr => ''};
  }
}

subtest 'base class execute dies' => sub {
  my $server = MCP::Run->new(name => 'TestServer');
  eval { $server->execute('echo hi', undef, 10) };
  like $@, qr/must be implemented by a subclass/, 'base class execute dies';
};

subtest 'default attributes' => sub {
  my $server = MCP::Run->new(name => 'TestServer');
  is $server->timeout, 30, 'default timeout is 30';
  is $server->tool_name, 'run', 'default tool_name is run';
  is $server->allowed_commands, undef, 'default allowed_commands is undef';
  is $server->working_directory, undef, 'default working_directory is undef';
};

# karr #15: 'command' is required by the input schema and nothing enforced it,
# so an incomplete request ran through both gates into execute() and came back
# as 'Exit code: 0'. The client cannot tell that from a real run and sees no
# reason to fix its request. The check belongs in the base class, so every
# future runner subclass inherits it.
subtest 'empty command is rejected before execute' => sub {
  my @cases = (
    ['missing key',     undef, 'no_key'],
    ['undef command',   undef],
    ['empty string',    ''],
    ['whitespace only', "  \t "],
  );

  for my $case (@cases) {
    my ($label, $command, $omit) = @$case;
    my $args = $omit ? {} : {command => $command};

    my $server = MCP::Run::Test::Recorder->new(name => 'TestServer');
    my $result = $server->tools->[0]->call($args, {});

    ok $result->{isError}, "$label: isError set";
    like $result->{content}[0]{text}, qr/No command given/,
      "$label: rejected with a message that names the missing parameter";
    unlike $result->{content}[0]{text}, qr/Exit code: 0/,
      "$label: not answered as a successful run";
    is scalar @{$server->calls}, 0,
      "$label: execute never reached, so nothing was started for an empty command";
  }
};

# Whitespace-only is treated as empty above. The allowlist gate has always
# agreed (/^\s*(\S+)/ finds no first word in it), and this pins the two paths
# to the same answer so a later change cannot make them diverge.
subtest 'whitespace-only command is empty on the allowlist path too' => sub {
  my $server = MCP::Run::Test::Recorder->new(name => 'TestServer', allowed_commands => ['ls']);
  my $result = $server->tools->[0]->call({command => "  \t "}, {});

  like $result->{content}[0]{text}, qr/No command given/,
    'the emptiness check answers first, before the allowlist';
  is scalar @{$server->calls}, 0, 'execute never reached';
};

# The emptiness check must not swallow real commands on its way past.
subtest 'a non-empty command still reaches execute' => sub {
  my $server = MCP::Run::Test::Recorder->new(name => 'TestServer');
  my $result = $server->tools->[0]->call({command => '  echo hi  '}, {});

  ok !$result->{isError}, 'no error result';
  is $server->calls->[0]{command}, '  echo hi  ',
    'execute got the command verbatim, surrounding whitespace included';
};

# karr #10 (F4): a non-positive per-call timeout is normalised by the runner,
# not rejected by the schema. MCP validates input_schema for real, so adding
# `minimum => 1` would answer `timeout: 0` with a hard -32602 "Invalid
# arguments" -- a fixed string that names no parameter -- and nothing would
# run, while the same 0 arriving via MCP_RUN_TIMEOUT has no schema in front of
# it and would still fall back to the default. This pins the base class's half
# of that decision: 0 survives validation and reaches execute, which is what
# gives the runner the chance to normalise it.
subtest 'a non-positive timeout reaches the runner instead of failing the schema' => sub {
  my $server = MCP::Run::Test::Recorder->new(name => 'TestServer');
  my $tool   = $server->tools->[0];

  is $tool->input_schema->{properties}{timeout}{minimum}, undef,
    'no minimum on timeout, so the runner fallback decides and not the validator';

  for my $value (0, -1) {
    ok !$tool->validate_input({command => 'true', timeout => $value}),
      "timeout $value passes schema validation";
  }

  $tool->call({command => 'true', timeout => 0}, {});
  is $server->calls->[0]{timeout}, 0,
    'the raw 0 is handed to execute untouched, for the runner to normalise';
};

done_testing;
