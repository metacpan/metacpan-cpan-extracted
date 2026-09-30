use strict;
use warnings;
use Test::More;

require_ok('Dist::Zilla::Plugin::GatherAgentContext');
ok( Dist::Zilla::Plugin::GatherAgentContext->can('gather_files'),
    'plugin provides gather_files (FileGatherer)' );

done_testing;
