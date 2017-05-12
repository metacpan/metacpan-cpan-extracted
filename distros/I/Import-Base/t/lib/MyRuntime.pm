package
    MyRuntime;

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
    'dies' => [
        sub { die "GOODBYE" },
    ],
);

1;
