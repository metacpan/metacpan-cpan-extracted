#!/usr/bin/perl
package TEST::LayerErrors;
use strict;
use warnings;

use Fennec;

tests foo => sub {
    throws_ok {
        tests not_here => sub { 1 }
    }
    qr/tests\(\) can only be used within a describe or case block, or at the package level\./, "Layer error";
};

describe bar => sub {
    tests inner => sub {
        throws_ok {
            tests not_here => sub { 1 }
        }
        qr/tests\(\) can only be used within a describe or case block, or at the package level\./, "Layer error";
    };
};

done_testing;
