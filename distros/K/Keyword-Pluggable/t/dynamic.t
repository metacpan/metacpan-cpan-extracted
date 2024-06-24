#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 2;

{
    package Foo;

    use Keyword::Pluggable;

    sub import {
        Keyword::Pluggable::define
		keyword        => 'mysub',
		code           => sub {
			my $named = ${$_[0]} =~ /^\s*\p{XIDS}\p{XIDC}*/s;
                        substr ${$_[0]}, 0, 0, "sub";
			!$named;
		},
		expression => 'dynamic',
	;
    }

    sub unimport {
        Keyword::Pluggable::undefine keyword => 'mysub';
    }

    BEGIN { $INC{"Foo.pm"} = 1; }
}

use Foo;

is do { mysub blah { 42 } blah() }, 42, "statement";
is mysub { 42 }->(), 42, "expression";
