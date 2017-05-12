#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::JSON::Advance qw(err);

# Additional parameters.
%Error::Pure::JSON::Advance::ERR_PARAMETERS = (
        'status' => 1,
        'message' => 'Foo bar',
);

# Error.
err '1';

# Output like:
# {"status":1,"error-pure":[{"msg":["1"],"stack":[{"sub":"err","prog":"example1.pl","args":"(1)","class":"main","line":17}]}],"message":"Foo bar"}