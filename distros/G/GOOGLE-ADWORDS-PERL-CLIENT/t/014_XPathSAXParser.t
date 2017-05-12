#!/usr/bin/perl
#
# Copyright 2011, Google Inc. All Rights Reserved.
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
#
# Unit tests for the Google::Ads::AdWords::Deserializer module.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib qw(t/util);

use File::Basename;
use File::Spec;
use Test::More (tests => 6);
use TestUtils qw(read_test_properties);

use_ok("Google::Ads::Common::XPathSAXParser");

my $properties = read_test_properties();

my $parser = Google::Ads::Common::XPathSAXParser->new({
  xpath_expression => "//soap:Body/*",
  handlers => {
    Start => sub {
      my $parser = shift;
      my $name = shift;
      my $attribs = shift;
      my $node = shift;
      is($attribs->{"att1"}, "att1value", "checking element attributes");
      is($name, "element", "check element tag start");
    },
    End => sub {
      my $parser = shift;
      my $name = shift;
      my $attribs = shift;
      my $node = shift;
      is($name, "element", "check element tag end");
    },
    Char => sub {
      my $parser = shift;
      my $value = shift;
      my $node = shift;
      is($value, "char data", "check text tag");
    },
    Comment => sub {
      my $parser = shift;
      my $value = shift;
      my $node = shift;
      is($value, " comment ", "check comment tag");
    }
  }
});

$parser->parse($properties->getProperty("sax_parser_input"));
