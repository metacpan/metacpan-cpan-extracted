package Google::RestApi::Setup;

use strict;
use warnings;

our $VERSION = '0.8';

use base 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');
ToolSet->use_pragma('feature', 'state');

ToolSet->no_pragma('autovivification');

ToolSet->export(
  'autodie'                =>  [],
  'Log::Log4perl'          => ':easy',
  'Type::Params'           => 'compile compile_named multisig validate',
  'Types::Standard'        => 'Undef Defined Value Bool Str StrMatch Int ArrayRef HashRef Dict CodeRef Object HasMethods slurpy Any Maybe',
  'Types::Common::Numeric' => 'PositiveNum PositiveOrZeroNum PositiveInt PositiveOrZeroInt',
  'YAML::Any'              => 'Dump',
  'Google::RestApi::Types' => ':all',
  'Google::RestApi::Utils' => ':all',
);

1;

__END__

=head1 NAME

Google::RestApi::ToolSet.pm - Common set of perl dependencies and imports.
