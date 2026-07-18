#!perl
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN
{
    use_ok('Google::Auth::Exceptions') || print "Bail out!\n";
}

note("Testing Google::Auth::Exceptions $Google::Auth::Exceptions::VERSION, Perl $], $^X");

throws_ok { Google::Auth::Error->throw("generic Google Auth Error"); }
qr/generic/;

done_testing(2);
