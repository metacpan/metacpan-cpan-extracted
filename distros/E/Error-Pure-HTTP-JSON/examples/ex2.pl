#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::JSON qw(err);

# Error.
err '1', '2', '3';

# Output like:
# Content-type: application/json
#
# [{"msg":["1","2","3"],"stack":[{"sub":"err","prog":"example2.pl","args":"(1, 2, 3)","class":"main","line":11}]}]