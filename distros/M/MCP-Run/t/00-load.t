use strict;
use warnings;
use Test::More;

use_ok('MCP::Run');
use_ok('MCP::Run::Bash');

# MCP::Run::format_result calls MCP::Run::Compress->new, so MCP::Run must
# bring the class in itself. Deliberately asserted here, where nothing has
# loaded Compress directly: a lazy require would push the failure out to the
# first compressed tools/call instead of server startup.
ok $INC{'MCP/Run/Compress.pm'}, 'MCP::Run loads MCP::Run::Compress';

done_testing;
