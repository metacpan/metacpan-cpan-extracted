#! perl

use strict;
use warnings;

use File::Temp;

use Test::More;
use Test::Exception;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;
use Data::Dumper;


my $lisp = Language::LispPerl::Evaler->new();


package PerlBindings;

sub about{ return "This is bound"; }
sub about_you{ my ($who) = @_; return "This is about $who";}
sub perl_func{
    my ($function) = @_;
    return $lisp->eval( $function );
}

1;
package main;

$lisp->eval('(require "core.clp")');
$lisp->eval(q|(. require "PerlBindings" )|);

{
    ok( my $res = $lisp->eval(q|
    (defn perl-about []
      (.PerlBindings about ^{:return "scalar"}))
    (defn perl-about-you [who]
      (.PerlBindings about_you ^{:return "scalar"} who))
    (defmacro perl-func [ & body]
      `(.PerlBindings perl_func ^{:return "raw"} (clj->string (quote ~@body ))))

|) );

    # is( $res->type(),  'function' );
}
{
    ok( my $res = $lisp->eval(q|( perl-about )| ) );
    is( $res->type() , 'perlobject' );
    is( $res->value() , "This is bound" );
}
{
    ok( my $res = $lisp->eval(q|( perl-about-you "marcel" )| ) );
    is( $res->type() , 'perlobject' );
    is( $res->value() , "This is about marcel" );
}
{
    ok( my $res = $lisp->eval(q|( perl-func ( let [variable "marcel"] ( perl-about-you ( perl-about-you variable ) ) ))| ) );
    is( $res->type() , 'perlobject' );
    is( $res->value() , "This is about This is about marcel" );
}

done_testing();
