#!perl
use strict;
use warnings FATAL => 'all';
no warnings 'once';

use Test::More;

{
    package Foo;

    use Keyword::Pluggable;

    sub import {
        Keyword::Pluggable::define(
	    keyword => 'class',
	    code    => "package",
        );
    }

    sub unimport {
        Keyword::Pluggable::undefine(keyword => 'peek');
    }

    BEGIN { $INC{"Foo.pm"} = 1; }
}

use Foo;

{ class Gpkg0; our $v = __PACKAGE__; }
is $Gpkg0::v, 'Gpkg0';

eval q{ class Gpkg1; our $v = __PACKAGE__ };
is $@, '';
is $Gpkg1::v, 'Gpkg1';

SKIP: {
    skip "evalbytes() requires v5.16", 3
        if $^V lt v5.16;
    my $err;
    eval q{
        use v5.16;
        evalbytes q{ class Gpkg2; our $v = __PACKAGE__ };
        $err = $@;
    };
    is $@, '';
    is $err, '';
    is $Gpkg2::v, 'Gpkg2';
}

TODO: {
    local $TODO = 's//.../e handling is broken';
    my $str = '';
    eval q{ $str =~ s/^/ class Gpkg3; our $v = __PACKAGE__ /e };
    is $@, '';
    is $str, 'Gpkg3';
    is $Gpkg3::v, 'Gpkg3';
}

done_testing;
