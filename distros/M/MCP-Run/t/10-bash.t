use strict;
use warnings;
use Test::More;

use MCP::Run::Bash;

subtest 'constructor registers run tool' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $tools  = $server->tools;
  is scalar(@$tools), 1, 'one tool registered';
  is $tools->[0]->name, 'run', 'tool name is run';

  my $schema = $tools->[0]->input_schema;
  is $schema->{type}, 'object', 'schema type is object';
  ok exists $schema->{properties}{command}, 'schema has command property';
  ok exists $schema->{properties}{working_directory}, 'schema has working_directory property';
  ok exists $schema->{properties}{timeout}, 'schema has timeout property';
  is_deeply $schema->{required}, ['command'], 'command is required';
};

subtest 'custom tool_name' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', tool_name => 'exec');
  is $server->tools->[0]->name, 'exec', 'custom tool name';
};

subtest 'custom tool_description' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', tool_description => 'Run stuff');
  is $server->tool_description, 'Run stuff', 'custom tool description';
};

subtest 'simple command execution' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('echo hello', undef, 10);
  is $result->{exit_code}, 0, 'exit code 0';
  is $result->{stdout}, 'hello', 'stdout captured';
  is $result->{stderr}, '', 'no stderr';
};

subtest 'stderr capture' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('echo err >&2', undef, 10);
  is $result->{exit_code}, 0, 'exit code 0';
  is $result->{stdout}, '', 'no stdout';
  is $result->{stderr}, 'err', 'stderr captured';
};

subtest 'non-zero exit code' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('exit 42', undef, 10);
  is $result->{exit_code}, 42, 'exit code 42';
};

subtest 'working_directory' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('pwd', '/tmp', 10);
  is $result->{exit_code}, 0, 'exit code 0';
  like $result->{stdout}, qr{^/tmp/?$}, 'ran in /tmp';
};

subtest 'server default working_directory' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer', working_directory => '/tmp');
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'pwd'}, {});
  like $result->{content}[0]{text}, qr{/tmp}, 'uses server default working_directory';
};

subtest 'timeout' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $result = $server->execute('sleep 60', undef, 1);
  is $result->{exit_code}, 124, 'exit code 124 on timeout';
  ok defined $result->{error}, 'error message set';
  like $result->{error}, qr/timed out/i, 'error mentions timeout';
};

subtest 'allowed_commands: allowed' => sub {
  my $server = MCP::Run::Bash->new(
    name             => 'TestServer',
    allowed_commands => ['echo', 'pwd'],
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'echo ok'}, {});
  like $result->{content}[0]{text}, qr/Exit code: 0/, 'allowed command runs';
};

subtest 'allowed_commands: blocked' => sub {
  my $server = MCP::Run::Bash->new(
    name             => 'TestServer',
    allowed_commands => ['echo'],
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'rm -rf /'}, {});
  like $result->{content}[0]{text}, qr/Command not allowed: rm/, 'blocked command rejected';
  ok $result->{isError}, 'isError set for blocked command';
};

subtest 'format_result: success' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $tool   = $server->tools->[0];
  my $result = $server->format_result($tool, { exit_code => 0, stdout => 'hello', stderr => '' });
  like $result->{content}[0]{text}, qr/Exit code: 0/, 'contains exit code';
  like $result->{content}[0]{text}, qr/hello/, 'contains stdout';
  ok !$result->{isError}, 'isError is false for success';
};

subtest 'format_result: error' => sub {
  my $server = MCP::Run::Bash->new(name => 'TestServer');
  my $tool   = $server->tools->[0];
  my $result = $server->format_result($tool, { exit_code => 1, stdout => '', stderr => 'fail', error => 'boom' });
  like $result->{content}[0]{text}, qr/Exit code: 1/, 'contains exit code';
  like $result->{content}[0]{text}, qr/fail/, 'contains stderr';
  like $result->{content}[0]{text}, qr/boom/, 'contains error';
  ok $result->{isError}, 'isError is true for failure';
};

subtest 'validator: allowed' => sub {
  my $server = MCP::Run::Bash->new(
    name      => 'TestServer',
    validator => sub {
      my ($cmd, $dir) = @_;
      return 1 if $cmd =~ /^echo|^pwd/;
      return "blocked: $cmd";
    },
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'echo ok'}, {});
  like $result->{content}[0]{text}, qr/Exit code: 0/, 'allowed command runs';
};

subtest 'validator: denied with reason' => sub {
  my $server = MCP::Run::Bash->new(
    name      => 'TestServer',
    validator => sub {
      my ($cmd, $dir) = @_;
      return 1 if $cmd =~ /^echo|^pwd/;
      return "security policy forbids this";
    },
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'rm -rf /'}, {});
  like $result->{content}[0]{text}, qr/Command security policy forbids this/, 'blocked with reason';
  ok $result->{isError}, 'isError set for blocked command';
};

subtest 'validator: denied without reason' => sub {
  my $server = MCP::Run::Bash->new(
    name      => 'TestServer',
    validator => sub {
      my ($cmd, $dir) = @_;
      return 1 if $cmd =~ /^echo/;
      return;
    },
  );
  my $tool   = $server->tools->[0];
  my $result = $tool->call({command => 'rm -rf /'}, {});
  like $result->{content}[0]{text}, qr/Command denied/, 'blocked without reason';
  ok $result->{isError}, 'isError set for blocked command';
};

done_testing;
