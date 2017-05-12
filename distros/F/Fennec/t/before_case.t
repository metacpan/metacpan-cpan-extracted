#!/usr/bin/perl
use strict;
use warnings;

use Fennec;

describe set => sub {
    my $name = "";

    before_case init_name => sub {
        $name .= "Foo";
    };

    case bar => sub { $name .= "Bar" };
    case baz => sub { $name .= "Baz" };

    after_case finish_name => sub {
        $name .= "End";
    };

    tests them => sub {
        like( $name, qr/^Foo(Bar|Baz)End$/, "Parts in correct order" );
    };
};

done_testing;
