
use strict;
use warnings;
use Test::More;
use Test::NoWarnings;

use lib './lib';

use File::Util;

plan tests => ( scalar @File::Util::EXPORT_OK ) + 1;

map
{
   ok ref UNIVERSAL::can('File::Util', $_) eq 'CODE',
      "can do exported $_"
} @File::Util::EXPORT_OK;

exit;
