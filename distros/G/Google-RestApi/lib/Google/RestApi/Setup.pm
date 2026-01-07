package Google::RestApi::Setup;

use strict;
use warnings;

our $VERSION = '1.1.0';

use parent 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');
ToolSet->use_pragma(qw( feature state ));

ToolSet->no_pragma('autovivification');

ToolSet->export(
  'autodie'                            =>  [],
  'Log::Log4perl'                      => ':easy',
  'namespace::autoclean'               =>  [],
  'Type::Params'                       => 'compile compile_named multisig validate',
  'Types::Standard'                    => 'Undef Defined Value Bool Str StrMatch Int Num ArrayRef HashRef Dict CodeRef Object HasMethods slurpy Any Maybe Optional',
  'Types::Common::Numeric'             => 'PositiveNum PositiveOrZeroNum PositiveInt PositiveOrZeroInt',
  'YAML::Any'                          => 'Dump',
  'Google::RestApi::Utils'             => ':all',
  'Google::RestApi::Types'             => ':all',
  'Google::RestApi::SheetsApi4::Types' => ':all',  # TODO: really should only be used for spreadsheet code. leave for now.
);

1;

__END__

=head1 NAME

Google::RestApi::Setup.pm - Common set of perl dependencies and imports.
