#! perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;
use Data::Dumper;
use JSON;

# An empty interpreter
{
    my $lisp = Language::LispPerl::Evaler->new();
    my $packed = $lisp->to_hash();
    # This makes sure it can be turned into json (in other words, it doesnt contain any objects)
    ok( my $json = JSON::to_json($packed));

    my $other_lisp = Language::LispPerl::Evaler->from_hash( $packed );
    is_deeply( $packed, $other_lisp->to_hash() );
}

{
    package PerlBindings;
    sub about{ return "This is bound"; }
}


# Define some stuff
{
    my $lisp = Language::LispPerl::Evaler->new();
    $lisp->eval(q|(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defn square [a] ( * a a ))

(def somename 5)

(defn somename-square [] ( let [somename 6] ( square somename ) ) )

(. require "PerlBindings" )
(defn perl-about []
  (.PerlBindings about ^{:return "scalar"}))

(defmacro sum-of-numbers []
  `( + 10 11 ))

|);
    {
        my $res = $lisp->eval(q|( type defn )|);
        is( $res->value(),  'macro' );
    }
    {
        my $res = $lisp->eval(q|( type square )|);
        is( $res->value(),  'function' );
    }
    {
        my $res = $lisp->eval(q|( type somename )|);
        is( $res->value(),  'number' );
    }
    {
        my $res = $lisp->eval(q|( type sum-of-numbers )|);
        is( $res->value(),  'macro' );
    }

    my $pack = $lisp->to_hash();
    ok( my $json = JSON::to_json( $pack ));
    my $other_lisp = Language::LispPerl::Evaler->from_hash( $pack );
    is_deeply( $pack, $other_lisp->to_hash() );
    {
        my $res = $other_lisp->eval(q|( type defn )|);
        is( $res->value(),  'macro' );
    }
    {
        my $res = $other_lisp->eval(q|( type square)|);
        is( $res->value(),  'function' );
    }
    {
        my $res = $other_lisp->eval(q|( type somename )|);
        is( $res->value(),  'number' );
    }
    {
        my $res = $other_lisp->eval(q|( type perl-about)|);
        is( $res->value(),  'function' );
    }
    {
        my $res = $other_lisp->eval(q|( type sum-of-numbers )|);
        is( $res->value(),  'macro' );
    }

    # Now it is time to use the persisted functions.
    {
        my $res = $other_lisp->eval(q|( square 3 )|);
        is( $res->value(), 9);
    }
    {
        my $res = $other_lisp->eval(q|( somename-square )|);
        is( $res->value(), 36);
    }
    {
        my $res = $other_lisp->eval(q|( perl-about )|);
        is( $res->value(), "This is bound");
    }
    # And the persisted macros
    {
        my $res = $other_lisp->eval(q|( sum-of-numbers )|);
        is( $res->value(), 21);
    }

}

done_testing();
