# NAME

Language::LispPerl - A lisp in pure Perl with perl bindings.

# SYNOPSIS

    use Language::LispPerl::Evaler;

    my $lisp = Language::LispPerl::Evaler->new();

    # Load core functions and macros
    $lisp->load("core.clp");

    my $res = $lisp->eval(q|
          (defmacro defn [name args & body]
            `(def ~name
               (fn ~args ~@body)))

          (defn foo [arg]
            (println arg))

          (foo "hello world!") ;comment here
        |);

    # $res is the last lisp object evaluated.

# DESCRIPTION

Language::LispPerl is a pure Perl lisp interpreter.
It is a fork of [CljPerl](https://metacpan.org/pod/CljPerl) that focuses on making embedding
lisp code in your Perl written software straightforward.

# INCOMPATIBILITIES

- From version 0.004

    This uses [Moose](https://metacpan.org/pod/Moose) instead of [Moo](https://metacpan.org/pod/Moo). This should not have any impact on your code,
    except if you have written your own role for 'Language::LispPerl::BuiltIns'. It will need to be a [Moose::Role](https://metacpan.org/pod/Moose::Role)
    instead of a [Moo::Role](https://metacpan.org/pod/Moo::Role).

## BINDING Perl functions to Lisp

### Lisp <-> Perl

Here is how to bind to your own Perl functions from lisp.

This assumes that your perl functions live in My::App::LispFunctions

#### PURE Perlfunctions in My::App::LispFunctions:

        package My::App::LispFunctions;

        sub do_stuff {
       my ($x , $y ) = @_;
       ..
       return;
        }

    sub say_stuff {
       my ($x , $y ) = @_;
       ..
       return $string_or_number;
    }

        sub is_stuff {
       ..
       # Note that here we return a raw lisp object.
       return Language::LispPerl->true();
        }

#### Binding to these functions in myapp.clp (living in share/lisp for instance):

     ;; These lisp binding functions will live
     ;; in the namespace 'myapp'

     ;; Note that you need core.clp to be loaded in the Evaler.

     (ns myapp
       (. require My::App::LispFunctions)

       (defn do-stuff [x y]
              (.My::App::LispFunctions do_stuff  ^{:return "nil"}  x y ))

       (defn say-stuff [x y]
            (.My::App::LispFunctions say_stuff ^{:return "scalar"} x y ))

           (defn is-stuff [x y]
            (.My::App::LispFunctions is_stuff ^{:return "raw"} x y)))

#### Usage in lisp space:

     ( require "myapp.clp" ) ;; Or in Perl $lisp->load("myapp.clp");
     ( myapp#do-stuff .. .. ) ;; Note the myapp# namespace marker.

### Importing and using any Perl package (without prior binding)

#### An example which creates a timer with AnyEvent.

        (. require AnyEvent)

        (def cv (->AnyEvent condvar))

        (def count 0)

        (def t (->AnyEvent timer
          {:after 1
           :interval 1
           :cb (fn [ & args]
                 (println count)
                 (set! count (+ count 1))
                 (if (>= count 10)
                   (set! t nil)))}))

        (.AnyEvent::CondVar::Base recv cv)

### Implemeting your own native Lisp functions

.TBC.

### This lisp implementation

#### Atoms

    * Reader forms

      * Symbols :

           foo, foo#bar

      * Literals

      * Strings :

           "foo", "\"foo\tbar\n\""

      * Numbers :

           1, -2, 2.5

      * Booleans :

           true, false . Or from Perl: Language::LispPerl->true() and Language::LispPerl->false()

      * Nil :

           nil . Or from Perl: Language::LispPerl->nil();

      * Keywords :

           :foo

    * Lists :

           (foo bar)

    * Vectors :

           [foo bar]

    * Maps :

           {:key1 value1 :key2 value2 "key3" value3}

#### Macro charaters

    * Quote ('). :

           '(foo bar)

    * Comment (;) :

           ; comment

    *  Dispatch (#) :

      * Accessor (:) :

           #:0 ; index accessor
           #:"key" ; key accessor
           #::key  ; key accessor

      * Sender (!) :

           #!"foo"

      * XML ([) :

           #[body ^{:attr "value"}]

    * Metadata (^) :

           ^{:key value}

    * Syntax-quote (`) :

           `(foo bar)

    * Unquote (~) :

           `(foo ~bar)

    * Unquote-slicing (~@) :

           `(foo ~@bar)

#### Builtin  lisp Functions

    * list :

           (list 'a 'b 'c) ;=> '(a b c)

    * car :

           (car '(a b c))  ;=> 'a

    * cdr :

           (cdr '(a b c))  ;=> '(b c)

    * cons :

           (cons 'a '(b c)) ;=> '(a b c)

    * key accessor :

           (#::a {:a 'a :b 'a}) ;=> 'a

    * keys :

           (keys {:a 'a :b 'b}) ;=> (:a :b)

    * index accessor :

           (#:1 ['a 'b 'c]) ;=> 'b

    * sender :

           (#:"foo" ['a 'b 'c]) ;=> (foo ['a 'b 'c])

    * xml :

           #[html ^{:class "markdown"} #[body "helleworld"]]

    * length :

           (length '(a b c)) ;=> 3
           (length ['a 'b 'c]) ;=> 3
           (length "abc") ;=> 3

    * append :

           (append '(a b) '(c d)) ;=> '(a b c d)
           (append ['a 'b] ['c 'd]) ;=> ['a 'b 'c 'd]
           (append "ab" "cd") ;=> "abcd"

    * type :

           (type "abc") ;=> "string"
           (type :abc)  ;=> "keyword"
           (type {})    ;=> "map"

    * meta :

           (meta foo ^{:m 'b})
           (meta foo) ;=> {:m 'b}

    * fn :

           (fn [arg & args]
             (println 'a))

    * apply :

           (apply list '(a b c)) ;=> '(a b c)

    * eval :

           (eval "(+ 1 2)")

    * require :

           (require "core")

    * def :

           (def foo "bar")
           (def ^{:k v} foo "bar")

    * set! :

           (set! foo "bar")

    * let :

           (let [a 1
                 b a]
             (println b)) 

    * defmacro :

           (defmacro foo [arg & args]
             `(println ~arg)
             `(list ~@args))

    * if :

           (if (> 1 0)
             (println true)
             (println false))

           (if true
             (println true))

    * while :

           (while true
             (println true))

    * begin :

           (begin
             (println 'foo)
             (println 'bar))

    * perl->clj :

    * ! not :

           (! true) ;=> false

    * + - * / % == != >= <= > < : only for number.

    * eq ne : only for string.

    * equal : for all objects.

    * . : (.[perl namespace] method [^meta] args ...)
           A meta can be specifed to control what type of value should be passed into perl function.
           type : "scalar" "array" "hash" "ref" "nil"
           ^{:return type
             :arguments [type ...]}

           (.Language::LispPerl print "foo")
           (.Language::LispPerl print ^{:return "nil" :arguments ["scalar"]} "foo") ; return nil and pass first argument as a scalar

    * -> : (->[perl namespace] method args ...)
      Like '.', but this will pass perl namespace as first argument to perl method.

    * println

           (println {:a 'a})

    * trace-vars : Trace the variables in current frame.

           (trace-vars)

    * quote : Returns the given list as is without evaluating it

       (quote (+ 1 2 )) -> (+ 1 2)

#### Core Functions (defined in core.clp)

    * use-lib : append path into Perl and Language::LispPerl files' searching paths.

           (use-lib "path")

    * ns : Language::LispPerl namespace.

           (ns "foo"
             (println "bar"))

    * defn :

           (defn foo [arg & args]
             (println arg))

    * defmulti :

    * defmethod :

    * reduce :

    * map :

    * file#open : open a file with a callback.

           (file#open ">file"
             (fn [fh]
               (file#>> fn "foo")))

    * file#<< : read a line from a file handler.

           (file#<< fh)

    * file#>> : write a string into a file handler.

           (file#>> fh "foo")

# PERSISTENCE

Since V0.007, you have the possibility to 'freeze' the evaler into a pure perl data structure,
and defrost it later on to execute some code in the same evaler state.

Usage:

    my $lisp = Language::LispPerl::Evaler->new();
    # Load core functions and macros
    $lisp->load("core.clp");
    $lisp->eval(q|(defn square [a] ( * a a ))|);

    my $perl_hash = $lisp->to_hash();
    # Store this pure perl hash somewhere in your favourite format.
    # Hint: compress its representation as it can be quite big.

    # Then later on:
    my $new_lisp = Language::LispPerl::Evaler->from_hash( $perl_hash );
    my $res = $new_lisp->eval(q|(square 2 )|);

# SEE ALSO

[CljPerl](https://metacpan.org/pod/CljPerl)

# AUTHOR

Current author: Jerome Eteve ( JETEVE )

Original author: Wei Hu, <huwei04@hotmail.com>

# COPYRIGHT

Copyright 2016-2017 Jerome Eteve. All rights Reserved.

Copyright 2013 Wei Hu. All Rights Reserved.

# ACKNOWLEDGEMENTS

This package as been released with the support of [http://broadbean.com](http://broadbean.com)

# LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
