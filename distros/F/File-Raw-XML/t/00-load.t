#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The three modules load, one version, and the provider config that
# ExtUtils::Depends writes for consumers is in the built tree.

use_ok('File::Raw::XML')           or BAIL_OUT('File::Raw::XML does not load');
use_ok('File::Raw::XML::Document');
use_ok('File::Raw::XML::Node');

ok(defined $File::Raw::XML::VERSION, 'File::Raw::XML has a version');
like($File::Raw::XML::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

ok(eval { require File::Raw::XML::Install::Files; 1 },
   'File::Raw::XML::Install::Files exists (the provider config)')
    or diag $@;
{
    no warnings 'once';
    my $inc = $File::Raw::XML::Install::Files::inc;
    ok(defined $inc && $inc =~ /-I\S*include/,
       'and it records an include path, so a consumer finds frx_abi.h')
        or diag "inc: " . (defined $inc ? $inc : 'undef');
}

done_testing;
