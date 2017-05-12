
use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 8;

use lib './lib';

use File::Util;
use File::Util::Definitions;
use File::Util::Interface::Classic;
use File::Util::Interface::Modern;
use File::Util::Exception;
use File::Util::Exception::Standard;
use File::Util::Exception::Diagnostic;

is File::Util::DESTROY(),
   undef,
   'File::Util::DESTROY() returns as expected';

is File::Util::Definitions::DESTROY(),
   undef,
   'File::Util::Definitions::DESTROY() returns as expected';

is File::Util::Interface::Classic::DESTROY(),
   undef,
   'File::Util::Interface::Classic::DESTROY() returns as expected';

is File::Util::Interface::Modern::DESTROY(),
   undef,
   'File::Util::Interface::Modern::DESTROY() returns as expected';

is File::Util::Exception::DESTROY(),
   undef,
   'File::Util::Exception::DESTROY() returns as expected';

is File::Util::Exception::Standard::DESTROY(),
   undef,
   'File::Util::Exception::Standard::DESTROY() returns as expected';

is File::Util::Exception::Diagnostic::DESTROY(),
   undef,
   'File::Util::Exception::Diagnostic::DESTROY() returns as expected';

exit;
