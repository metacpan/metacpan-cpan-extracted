#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Java::Release::Obj;

my $obj = Java::Release::Obj->new(
        arch => 'i386',
        os => 'linux',
        release => 1,
);

p $obj;

# Output like:
# Java::Release::Obj  {
#     Parents       Mo::Object
#     public methods (0)
#     private methods (0)
#     internals: {
#         arch      "i386",
#         os        "linux",
#         release   1
#     }
# }