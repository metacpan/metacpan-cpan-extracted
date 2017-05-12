#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;
use Test::Exception;

BEGIN {
    {

        package Export::Stuff;
        use Exporter::Declare;

        sub bar($) { my $x = shift; "bar $x" }

        {
            no strict 'refs';
            *{'baz'} = sub($) { my $x = shift; "baz $x" };
        }

        default_export foo => sub($) { my $x = shift; "foo $x" };
        default_export 'bar';
        default_export 'baz';

        sub before_import {
            my $class = shift;
            my ( $caller, $specs ) = @_;
            $specs->add_export( '&whoosh' => sub { 'whoosh' } );
        }
    }

    Export::Stuff->import();
}

tests before_import => sub {
    can_ok( __PACKAGE__, qw/ whoosh / );
};

tests prototypes => sub {
    can_ok( __PACKAGE__, qw/foo bar baz/ );
    is( prototype( \&foo ), '$', "foo prototype" );
    is( prototype( \&bar ), '$', "bar prototype" );
    is( prototype( \&baz ), '$', "baz prototype" );

    is( foo('a'), "foo a", "foo prototype" );
    is( bar('a'), "bar a", "bar prototype" );
    is( baz('a'), "baz a", "baz prototype" );

    # Even in throws ok we need to eval this, prototypes are a compile-time error
    throws_ok { eval 'foo()' || die $@ } qr/Not enough arguments for main::foo/, "Prototype takes effect (foo)";
    throws_ok { eval 'bar()' || die $@ } qr/Not enough arguments for .*bar/,     "Prototype takes effect (bar)";
    throws_ok { eval 'baz()' || die $@ } qr/Not enough arguments for main::baz/, "Prototype takes effect (baz)";
};

tests proto_no_begin => sub {

    package Something;
    use Test::More;
    Export::Stuff->import();

    is( foo( "A", "b" ), "foo A", "Prototype is bypassed by lack of BEGIN" );
};

run_tests;
done_testing;
