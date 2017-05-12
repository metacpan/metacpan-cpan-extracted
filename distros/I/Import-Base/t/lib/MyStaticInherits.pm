package
    MyStaticInherits;

use strict;
use warnings;
use base 'MyStatic';

our @IMPORT_MODULES = (
    '-strict' => [qw( vars )],
);

our %IMPORT_BUNDLES = (
    'Spec' => [
        'File::Spec::Functions' => [qw( catfile )],
    ],
    Lax => [
        '-strict',
        '-warnings',
    ],
);

1;
