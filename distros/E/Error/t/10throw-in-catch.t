#!/usr/bin/perl

use strict;
use warnings;

use Error qw(:try);
use Test::More tests => 2;

my ($error);

eval
{
try {
    throw Error::Simple( "message" );
}
catch Error::Simple with {
    die "A-Lovely-Day";
};
};
$error = $@;

# TEST
ok (scalar($error =~ /^A-Lovely-Day/), 
    "Error thrown in the catch clause is registered"
);

eval {
try {
    throw Error::Simple( "message" );
}
otherwise {
    die "Had-the-ancient-greeks";
};
};
$error = $@;

# TEST
ok (scalar($error =~ /^Had-the-ancient/), 
    "Error thrown in the otherwise clause is registered"
);

