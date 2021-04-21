#!/usr/bin/env perl

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# <@LICENSE>
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>
#

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

my $has_sha1 = eval { require Digest::SHA1; 1 };

plan tests => $has_sha1 ? 7 : 5;

use_ok('Mail::Pyzor::SHA');

if ($has_sha1) {
    my $path = `$^X -MDigest::SHA1 -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA.pm"} || q<>'`;
    is( $path, q<>, 'didn’t load Digest::SHA if Digest::SHA1 is already loaded.' );
    ok( !$?, '… and succeeded' );
}

my $path = `$^X -MDigest::SHA -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA1.pm"} || q<>'`;
is( $path, q<>, 'didn’t load Digest::SHA1 if Digest::SHA is already loaded.' );
ok( !$?, '… and succeeded' );

if ($has_sha1) {
    diag "== This install has Digest::SHA1.";

    my $path = `$^X -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA1.pm"} || q<>'`;
    like( $path, qr<SHA1>, 'loaded Digest::SHA1 if nothing is already loaded.' );
    ok( !$?, '… and succeeded' );
}
else {
    diag "== This install does not have Digest::SHA1.";

    my $path = `$^X -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA.pm"} || q<>'`;
    like( $path, qr<SHA>, 'loaded Digest::SHA if nothing is loaded and nothing else available.' );
    ok( !$?, '… and succeeded' );
}
