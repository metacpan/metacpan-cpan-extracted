#!/usr/bin/env perl

# Original authors: don
# $Revision: $


use strict;
use warnings;

use Test::More tests => 1;

use JSON::DWIW;

my $str = '[ { "foo": "bar", "cat": 1 }, { "concat": 1, "lambda" : [ "one", 2, 3 ] } ]';


my $foo = { foo => [ ] };
my $handler = sub { push @{$foo->{foo}}, $_[0]; return 1; };

my $data = JSON::DWIW::deserialize($str, { start_depth => 1,
                                           start_depth_handler => $handler });
my $expected = {
                'foo' => [
                          {
                           'cat' => 1,
                           'foo' => 'bar'
                          },
                          {
                           'lambda' => [
                                        'one',
                                        2,
                                        3
                                       ],
                           'concat' => 1
                          }
                         ]
               };

is_deeply($foo, $expected, "start_depth_handler");

