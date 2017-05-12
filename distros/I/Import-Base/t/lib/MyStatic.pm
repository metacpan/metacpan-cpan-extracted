package
    MyStatic;

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    "strict",
    "warnings",
);

our %IMPORT_BUNDLES = (
    'Spec' => [
        'File::Spec::Functions' => [qw( catdir )],
    ],
    'lax' => [
        '-warnings' => [qw( uninitialized )],
    ],
);

1;
