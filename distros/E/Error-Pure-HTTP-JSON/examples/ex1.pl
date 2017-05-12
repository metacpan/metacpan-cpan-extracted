#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::JSON qw(err);

# Error.
err '1';

# Output like:
# Content-type: application/json
#
# [{"msg":["1"],"stack":[{"sub":"err","prog":"example1.pl","args":"(1)","class":"main","line":11}]}]