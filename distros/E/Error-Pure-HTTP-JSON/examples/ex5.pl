#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::JSON::Advance qw(err);

# Additional parameters.
%Error::Pure::HTTP::JSON::Advance::ERR_PARAMETERS = (
        'status' => 1,
        'message' => 'Foo bar',
);

# Error.
err '1', '2', '3';

# Output like:
# Content-type: application/json
#
# {"status":1,"error-pure":[{"msg":["1","2","3"],"stack":[{"sub":"err","prog":"example2.pl","args":"(1, 2, 3)","class":"main","line":17}]}],"message":"Foo bar"}