#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::HTTP::JSON::Advance qw(err);

# Additional parameters.
%Error::Pure::HTTP::JSON::Advance::ERR_PARAMETERS = (
        'status' => 1,
        'message' => 'Foo bar',
);

# Error.
err '1';

# Output like:
# Content-type: application/json
#
# {"status":1,"error-pure":[{"msg":["1"],"stack":[{"sub":"err","prog":"example1.pl","args":"(1)","class":"main","line":17}]}],"message":"Foo bar"}