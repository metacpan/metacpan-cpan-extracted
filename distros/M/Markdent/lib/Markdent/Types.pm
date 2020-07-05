package Markdent::Types;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Markdent::Types::Internal -reexport;
use Specio::Library::Builtins -reexport;
use Specio::Library::Numeric -reexport;

our $VERSION = '0.37';

1;
