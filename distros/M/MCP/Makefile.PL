use 5.020;

use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'MCP',
  VERSION_FROM => 'lib/MCP.pm',
  ABSTRACT     => 'Connect Perl with AI using MCP (Model Context Protocol)',
  AUTHOR       => 'Sebastian Riedel <sri@cpan.org>',
  LICENSE      => 'mit',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime   => {requires => {perl => '5.020'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/mojolicious/mojo-mcp/issues'},
      homepage   => 'https://mojolicious.org',
      license    => ['http://www.opensource.org/licenses/mit'],
      repository => {
        type => 'git',
        url  => 'https://github.com/mojolicious/mojo-mcp.git',
        web  => 'https://github.com/mojolicious/mojo-mcp',
      },
      x_IRC => {url => 'irc://irc.libera.chat/#mojo', web => 'https://web.libera.chat/#mojo'}
    },
  },
  PREREQ_PM => {'CryptX' => '0.087', 'IPC::Run' => '20231003.0', 'JSON::Validator' => '5.15', Mojolicious => '9.41'},
  test      => {TESTS    => 't/*.t t/*/*.t'}
);
