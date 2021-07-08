package Google::RestApi::Setup;

use strict;
use warnings;

our $VERSION = '0.7';

use base 'ToolSet';

ToolSet->use_pragma( 'strict' );
ToolSet->use_pragma( 'warnings' );

ToolSet->no_pragma( 'autovivification' );

ToolSet->use_pragma( 'feature', 'state' );

ToolSet->export(
  'autodie'                =>  [],
  'Log::Log4perl'          => ':easy',
  'Type::Params'           => 'compile compile_named multisig',
  'Types::Standard'        => 'Undef Defined Value Bool Str StrMatch Int ArrayRef HashRef CodeRef HasMethods slurpy Any Maybe',
  'YAML::Any'              => 'Dump',
  'Google::RestApi::Utils' => 'named_extra config_file resolve_config_file strip bool dim dims dims_all cl_black cl_white',
);

1;

__END__

=head1 NAME

Google::RestApi::ToolSet.pm - Common set of perl dependencies.
