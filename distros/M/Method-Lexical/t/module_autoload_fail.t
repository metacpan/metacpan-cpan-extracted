#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

eval "use Method::Lexical foo => '+Method::Lexical::Test::No::Such::Package::foo';";
like $@, qr{Can't load Method::Lexical::Test::No::Such::Package}, 'error loading nonexistent package (autoloaded)';

eval "use Method::Lexical foo => 'Method::Lexical::Test::No::Such::Package::foo', -autoload => 1";
like $@, qr{Can't load Method::Lexical::Test::No::Such::Package}, 'error loading nonexistent package (-autoload => 1)';
