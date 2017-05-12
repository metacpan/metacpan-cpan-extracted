use Test::More tests => 7;

use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use warnings;

require_ok('Digest::MD5');
require_ok('Scalar::Util');
require_ok('Exporter');

use_ok 'Hash::MD5';
use_ok 'Digest::MD5';
use_ok 'Scalar::Util';
use_ok 'Exporter';
