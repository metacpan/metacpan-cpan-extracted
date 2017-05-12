package
    MyStaticVersion;

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    "strict",
    "warnings",
);

our %IMPORT_BUNDLES = (
    'Bad' => [
        { 'MyVersioned' => 9999 },
    ],
    'BadArgs' => [
        { 'MyVersionedExporter' => 9999 } => [qw( foo )],
    ],
    'Good' => [
        { 'MyVersioned' => 1.4 },
    ],
    'GoodArgs' => [
        { 'MyVersionedExporter' => 1.4 } => [qw( foo )],
    ],
);

1;
