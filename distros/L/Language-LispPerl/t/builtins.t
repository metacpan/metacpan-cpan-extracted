#! perl

use strict;
use warnings;

use File::Temp;

use Test::More;
use Test::Exception;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;

use Data::Dumper;

ok( my $lisp = Language::LispPerl::Evaler->new() );


{
    # eval
    my $res = $lisp->eval(q|( eval "( + 1 2 )" )| );
    is( $res->value() , 3 );
    throws_ok { $lisp->eval(q|( eval 1 2 3 )|); } qr/expects 1/ ;
}

{
    # syntax
    my $res = $lisp->eval(q|( syntax true )| );
    is( $res->type() , 'bool' );
    is( $res->value() , 'true' );
}

{
    # Exception
    throws_ok{ $lisp->eval(q|( throw wtf "This is exceptional")|) }  qr/This is exceptional/ ;
    ok( $lisp->exception() );
    is( $lisp->exception()->{label} , 'wtf' );

    {
        ok( my $res = $lisp->eval(q|(catch (throw aaa "bbb") (fn [e] ( syntax e )))|) );
        ok( $res->type() , 'exception' );
        ok( $res->value(), 'bbb' );
    }

    {
        ok( my $res = $lisp->eval(q|(catch (throw aaa "bbb") (fn [e] ( exception-label  e )))|) );
        ok( $res->type() , 'string' );
        ok( $res->value(), 'aaa' );
    }

    {
        ok( my $res = $lisp->eval(q|(catch (throw aaa "bbb") (fn [e] ( exception-message  e )))|) );
        ok( $res->type() , 'string' );
        ok( $res->value(), 'bbb' );
    }
}

{
    # Def, set
    ok( $lisp->eval(q|(def somename true)|) );
    is( $lisp->var('somename')->name(), '#somename' );
    is( $lisp->var('somename')->value()->type(), 'bool');
    is( $lisp->var('somename')->value()->value(), 'true');

    ok( $lisp->eval(q|(def ^{:k "v"} foo "bar")|) );
    is( $lisp->var('foo')->name(), '#foo' );
    is( $lisp->var('foo')->value()->type(), 'string');
    is( $lisp->var('foo')->value()->value(), 'bar');
    is( $lisp->var('foo')->value()->meta_data()->type() , "meta");
    is( $lisp->var('foo')->value()->meta_data()->type() , "meta");
    is( $lisp->var('foo')->value()->meta_data()->value()->{k}->type , "string");
    is( $lisp->var('foo')->value()->meta_data()->value()->{k}->value , "v");

    ok( $lisp->eval(q|(set! foo "baz")|) );
    is( $lisp->var('foo')->name(), '#foo' );
    is( $lisp->var('foo')->value()->type(), 'string');
    is( $lisp->var('foo')->value()->value(), 'baz');
}

{
    # let
    ok( my $res = $lisp->eval(q|( let [ a 1 b 2 ] ( - a b ) ( + a b ) )|) );
    is( $res->type() , 'number' );
    is( $res->value() , 3 );
}

{
    # fn
    ok( my $res = $lisp->eval(q|( (fn [a  b] ( + a b ) ) 1 2 )|) );
    is( $res->type() , 'number' );
    is( $res->value() , 3 );
}

{
    # defmacro
    ok( my $res = $lisp->eval(q|(defmacro addition [a b] ( + a b ) )|) );
    is( $res->type() , 'macro' );
    ok( $res->value()->isa('Language::LispPerl::Seq') );
    ok( $res = $lisp->eval(q|( addition 1 2 )| ) );
    is( $res->type() , 'number' );
    is( $res->value() , 3 );
}

{
    # gen-sym
    ok( my $res = $lisp->eval(q|( gen-sym "bacon" )|) );
    is( $res->type() , 'symbol');
    like( $res->value() , qr/^baconatom/ );
}

{
    # require
    ok( my $res = $lisp->eval(q|(require "core.clp")|) );
    is( $res->type() , 'macro');
    ok( $res->value()->isa('Language::LispPerl::Seq') );
}

{
    # read
    my ($fh, $filename) = File::Temp::tempfile();
    print $fh q|(+ 1 2) (+ 3 4)|;
    close($fh);
    ok( my $res = $lisp->eval('(read "'.$filename.'")') );
    is( $res->type() , 'number' );
    is( $res->value() , 7 );
}

{
    # Lists
    ok( my $res = $lisp->eval('( list 1 2 3 4 )') );
    is( $res->type() , 'list' );
    is( ref( $res->value() ) , 'ARRAY' );
    is( ref( $res->value()->[0] ) , 'Language::LispPerl::Atom' );

    ok( $res = $lisp->eval('( car ( list 3 2 1 ) )') );
    is( $res->type(), 'number' );
    is( $res->value() , 3 );

    ok( $res = $lisp->eval('( cdr ( list  3 2 1 ) )') );
    is( ref( $res->value() ) , 'ARRAY' );
    is( scalar( @{$res->value()} ) , 2 );

    ok( $res = $lisp->eval('( cons 1 (list 2 3) )') );
    is( ref($res->value() ) , 'ARRAY' );
    is( scalar( @{$res->value()} ) , 3 );
}

{
    # Flow control
    ok( my $res = $lisp->eval(q|( if (> 1 2 ) (syntax "ya") (syntax "nie"))|) );
    is( $res->value() , "nie");
    ok( $res = $lisp->eval(q|( if (> 1 2 ) (syntax "ya"))|) );
    is( $res->value() , "nil");
    ok( $res = $lisp->eval(q|( if (< 1 2 ) (syntax "ya") (syntax "nie"))|) );
    is( $res->value() , "ya");

    ok( $res = $lisp->eval(q|
(set! foo 5 )
(while (< foo 10) ( set! foo (+ foo 1 ) ) )
|));
    is( $res->value() , 10 );

    ok( $res = $lisp->eval(q|( begin ( + 1 2 ) ( + 3 4 ) )|) );
    is( $res->value(), 7 );
}

{
    # String tests
    ok( my $res = $lisp->eval(q|( if ( eq "bla" "bla") "yes")|) );
    is( $res->value() , 'yes' );
    ok( $res = $lisp->eval(q|( if ( ne "bla" "blad") "yes")|) );
    is( $res->value() , 'yes' );
    ok( $res = $lisp->eval(q|( if ( gt "aaa" "bbb") "yes" "no")|) );
    is( $res->value() , 'no' );
    ok( $res = $lisp->eval(q|( if ( lt "aaa" "bbb") "yes" "no")|) );
    is( $res->value() , 'yes' );
}

{
    # General purpose equal
    {
        ok( my $res = $lisp->eval(q|(equal "bla" "bla")|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(equal "1" 1)|) );
        is( $res->value(), 'false' );
    }
    {
        ok( my $res = $lisp->eval(q|(equal 1 1)|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(equal true true)|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(equal true false)|) );
        is( $res->value(), 'false' );
    }

}

{
    # Logic
    {
        ok( my $res = $lisp->eval(q|(not false)|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(! true)|) );
        is( $res->value(), 'false' );
    }
    {
        ok( my $res = $lisp->eval(q|(and true true)|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(and true false)|) );
        is( $res->value(), 'false' );
    }
    {
        ok( my $res = $lisp->eval(q|(and false true)|) );
        is( $res->value(), 'false' );
    }
    {
        ok( my $res = $lisp->eval(q|(or false true)|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(or true true)|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(or true false)|) );
        is( $res->value(), 'true' );
    }
    {
        ok( my $res = $lisp->eval(q|(or false false)|) );
        is( $res->value(), 'false' );
    }
}

{
    # Length
    {
        ok( my $res = $lisp->eval(q|(length "abcd")|) );
        is( $res->value() , 4 );
    }
    {
        ok( my $res = $lisp->eval(q|(length [ 1 2 3 ])|) );
        is( $res->value() , 3 );
    }
    {
        ok( my $res = $lisp->eval(q|(length (list `a `b `c `d `e))|) );
        is( $res->value() , 5 );
    }
    {
        ok( my $res = $lisp->eval(q|(length #[html ^{:class "markdown"} #[body #[p "helleworld"]]])|) );
        is( $res->value(), 1 );
    }
}

{
    # Reverse
    {
        ok( my $res = $lisp->eval(q|(reverse "abcd")|) );
        is( $res->value() , 'dcba' );
    }
    {
        ok( my $res = $lisp->eval(q|(reverse "")|) );
        is( $res->value() , '' );
    }
    {
        ok( my $res = $lisp->eval(q|(reverse (list 1 2))|) );
        is( $res->value()->[0]->value() , 2 );
    }
    {
        ok( my $res = $lisp->eval(q|( reverse [ 1 2 ] )|) );
        is( $res->value()->[0]->value(), 2 );
    }
    {
        ok( my $res = $lisp->eval(q|(reverse #[header #[p "P1"] #[p "P2"] ])|) );
        is( $res->value()->[0]->value()->[0]->value(), 'P2' );
    }
}

{
    # Append
    {
        ok( my $res = $lisp->eval(q|(append "abcd" "efgh")|) );
        is( $res->value() , 'abcdefgh' );
    }
    {
        ok( my $res = $lisp->eval(q|(append (list 1 2) (list 3 4))|) );
        is( $res->value()->[3]->value() , 4 );
    }
    {
        ok( my $res = $lisp->eval(q|(append [ 1 2 ] [3 4] )|) );
        is( $res->value()->[3]->value(), 4 );
    }
    {
        ok( my $res = $lisp->eval(q|(append  {:a `b} {:c `d})|) );
        is( $res->value()->{c}->value() , 'd' );
    }
}
{
    # keys
    ok( my $res = $lisp->eval(q|(keys {:a 1 :b 2})|) );
    my %got_key = map{ $_->value() => 1 }  @{ $res->value() };
    ok( $got_key{a} );
    ok( $got_key{b} );
}

{
    # xml-name
    ok( my $res = $lisp->eval(q|(xml-name #[header "bla"])|) );
    is( $res->value() , 'header' );
}

{
    # Namespace building
    ok( my $res = $lisp->eval(q|(namespace-begin "boudinblanc")|));
    is( $lisp->current_namespace() , 'boudinblanc');

    ok( $res = $lisp->eval(q|(namespace-end)|) );
    is( $lisp->current_namespace() , '');
}

{
    # object introspection
    {
        ok( my $res = $lisp->eval(q|(object-id 1)|) );
        is( $res->value() , 'atom792' );
    }

    {
        ok( my $res = $lisp->eval(q|(type 1)|) );
        is( $res->value() , 'number' );
    }
    {
        ok( my $res = $lisp->eval(q|(type "bla")|) );
        is( $res->value() , 'string' );
    }

    {
        ok( my $res = $lisp->eval(q|(meta 1 ^{:a 2})|) );
        is( $res->type() , 'meta' );
    }

    {
        ok( my $res = $lisp->eval(q|(meta #[html ^{:class "markdown"} #[body #[p "helleworld"]]])|) );
        is( $res->type() , 'meta' );
    }
}

{
    # Apply
    {
        ok( my $res = $lisp->eval(q|( apply + ( list 1 2 ) )|) );
        is( $res->value() , 3 );
    }
    {
        ok( my $res = $lisp->eval(q|( apply (fn [a  b] ( * a b ) ) ( list 2 3 ) )|) );
        is( $res->value() , 6 );
    }
}

{
    # Quoting
    {
        ok( my $res = $lisp->eval( q|(quote "marcel")|) );
        is( $res->type() , "string" );
        is( $res->value() , 'marcel');
    }
    {
        ok( my $res = $lisp->eval( q|(quote marcel)|) );
        is( $res->type() , "symbol" );
        is( $res->value() , 'marcel');
    }
    {
        ok( my $res = $lisp->eval( q|(quote ( apply + ( list 1 2 ) ))|) );
        is( $res->type() , "list" );
        is( $res->value()->[0]->type(), "symbol");
        is( $res->value()->[0]->value(), "apply");
        is( $res->value()->[1]->type(), "symbol");
        is( $res->value()->[1]->value(), "+");
        is( $res->value()->[2]->type(), "list");
        is( $res->value()->[2]->value()->[0]->type(), "symbol");
        is( $res->value()->[2]->value()->[0]->value(), "list");
    }
}

{
    # Stringification
    {
        ok( my $res = $lisp->eval( q|( clj->string "marcel" )|) );
        is( $res->value() , '"marcel"');
    }
    {
        ok( my $res = $lisp->eval( q|( clj->string "marce\"l" )|) );
        is( $res->value() , '"marce\"l"');
    }
    {
        ok( my $res = $lisp->eval( q|( clj->string  [ 1 2 3 ] )|) );
        is( $res->value() , '[1 2 3]');
    }
    {
        ok( my $res = $lisp->eval( q|( clj->string  (fn [a b] ( * a b ) ) )|) );
        is( $res->value() , '(fn [a b] (* a b))');
    }
}

{
    ok( my $res = $lisp->eval(q|( trace-vars )|) );
}

{
    # Perl
    {
        ok( my $res = $lisp->eval(q|(. require "Language::LispPerl" )|));
        is( $res->value(), 'true');
    }
    {
        ok( my $res = $lisp->eval(q|( def lisp nil ) ( set! lisp ( ->Language::LispPerl::Evaler new ) )|) );
        is( $res->type(),  'perlobject' );
    }
    {
        ok( my $res = $lisp->eval(q|( .Language::LispPerl::Evaler "eval" lisp "( + 1 2 )" )|) );
        is( $res->type() , 'perlobject');
        is( $res->value()->value() , 3 );
    }
}

done_testing();
