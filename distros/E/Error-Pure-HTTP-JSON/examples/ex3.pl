#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Output::JSON;
use Error::Pure::HTTP::JSON qw(err);

# Pretty print.
$Error::Pure::Output::JSON::PRETTY = 1;

# Error.
err '1';

# Output like:
# Content-type: application/json
#
# [
#    {
#       "msg" : [
#          "1"
#       ],
#       "stack" : [
#          {
#             "sub" : "err",
#             "prog" : "example3.pl",
#             "args" : "(1)",
#             "class" : "main",
#             "line" : 15
#          }
#       ]
#    }
# ]