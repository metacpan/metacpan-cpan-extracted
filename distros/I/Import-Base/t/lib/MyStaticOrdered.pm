package
    MyStaticOrdered;

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    # If we put '<strict', this will still apply
    '-strict' => [qw( vars )],
    # Make sure things added with < are still added
    '<File::Spec::Functions' => [qw( catdir )],
    # Make sure things added with > are still added
    '>File::Spec::Functions' => [qw( splitdir )],
);

our %IMPORT_BUNDLES = (
    Early => [
        '<strict',
        '<warnings',
    ],
    Strict => [
        'strict', 'warnings',
    ],
    # Lax will always be lax, no matter what
    Lax => [
        '>-strict',
        '>-warnings',
    ],
);

1;
