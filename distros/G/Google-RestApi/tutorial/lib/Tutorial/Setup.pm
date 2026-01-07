package Tutorial::Setup;

use strict;
use warnings;

use parent 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');

ToolSet->no_pragma('autovivification');

ToolSet->export(
  'autodie'         =>  [],
  'Log::Log4perl'   => ':easy',
  'Try::Tiny'       =>  [],
  'YAML::Any'       => 'Dump',

  'Tutorial::Utils' => ':all',
  'Test::Utils'     => ':all',
);

1;
