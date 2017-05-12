# Copyright (c) 2008 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use Test::More;
use IO::CaptureOutput 1.08 qw/qxx/;

plan tests => 1;

$ENV{PERL5OPT} = '-MDevel::Autoflush';

my ( $stdout, $stderr ) = qxx( $^X, '-we', 'print $| ? 1 : 0,  "\n"' );
chomp($stdout);
is( $stdout, 1, "autoflush was set" ) or diag "STDERR: $stderr";

