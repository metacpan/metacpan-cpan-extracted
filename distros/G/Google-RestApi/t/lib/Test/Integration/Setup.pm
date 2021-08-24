package Test::Integration::Setup;

use strict;
use warnings;

use base 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');

ToolSet->no_pragma('autovivification');

ToolSet->export(
  'autodie'                  =>  [],
  'Log::Log4perl'            => ':easy',
  'Types::Standard'          => 'Undef Defined Bool Str StrMatch Int ArrayRef HashRef Dict Object InstanceOf slurpy',
  'Types::Common::Numeric'   => 'PositiveInt PositiveOrZeroInt',
  'YAML::Any'                => 'Dump',
  'Test::Most'               =>  '',
  'Test::Utils'              => ':all',
  'Test::Integration::Utils' => ':all',
);

1;
