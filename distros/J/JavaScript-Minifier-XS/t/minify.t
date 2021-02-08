#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use JavaScript::Minifier::XS qw(minify);

###############################################################################
subtest 'leading whitespace can be removed' => sub {
  my $given  = qq{\n\n\r\t\n    \n    var leading="leading whitespace gets removed";};
  my $expect = qq{var leading="leading whitespace gets removed";};
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
subtest 'trailing whitespace can be removed' => sub {
  my $given  = qq{var trailing="trailing whitespace gets removed";  \t\n\r  \n};
  my $expect =qq{var trailing="trailing whitespace gets removed";};
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
subtest 'comments' => sub {;
  subtest 'block comments' => sub {
    my $given  = ";/* block comments get removed */;";
    my $expect = ";;";
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'line comments' => sub {
    my $given  = ";// line comments get removed\n;";
    my $expect = ";;";
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'copyright in block comment' => sub {
    my $given  = qq{/* comments containing the word "Copyright" are left in */};
    my $expect = qq{/* comments containing the word "Copyright" are left in */};
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'copyright in line comment' => sub {
    my $given  = qq{// line comments with "CoPyRiGhT", case in-sensitive};
    my $expect = qq{// line comments with "CoPyRiGhT", case in-sensitive};
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'preserved copyright line comment gets EOL' => sub { # GH#3
    my $given = q|
      function foo() {
        // copyright is preserved
      }
    |;
    my $expect = qq|function foo(){// copyright is preserved\n}|;
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'inline block comment' => sub {
    my $given  = 'var foo /* remove */ = /* me too */ 3;';
    my $expect = 'var foo=3;';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'inline block comment' => sub {
    my $given  = 'var bar = /* and me */ 4;';
    my $expect = 'var bar=4;';
    my $got    = minify($given);
    is $got, $expect;
  };


  subtest 'inline block comment' => sub {
    my $given  = 'var replaced_with_ws = foo + /* ws */ +bar;';
    my $expect = 'var replaced_with_ws=foo+ +bar;';
    my $got    = minify($given);
    is $got, $expect;
  };


  subtest 'inline block comment' => sub {
    my $given  = 'var also_replaced    = foo - /* ws */ -bar;';
    my $expect = 'var also_replaced=foo- -bar;';
    my $got    = minify($given);
    is $got, $expect;
  };


  subtest 'inline block comment' => sub {
    my $given  = 'var removed_outright = foo + /* me gone */ -bar;';
    my $expect = 'var removed_outright=foo+-bar;';
    my $got    = minify($given);
    is $got, $expect;
  };


  subtest 'inline block comment' => sub {
    my $given  = 'var also_removed     = foo - /* me gone */ +bar;';
    my $expect = 'var also_removed=foo-+bar;';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# Comments placed directly before a regex should be skipped, instead of being
# used to determine whether the leading '/' of the regexp is actually for
# division or not.
#
# When its not working correctly, the regexes are parsed as division and that
# causes the quote matching to get bungled up.
subtest 'comments before a regex' => sub {
  my $given = qq{
    var foo = [
        // trick the engine into thinking we end in an array[]
        /^'/,

        // this *should* be parsed as a comment, not a literal
        /^"/,

        // isn't this the line with the closing apostrophe in it?
        /foo/
        ];
  };
  my $expect = qq{var foo=[/^'/,/^"/,/foo/];};
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
subtest 'MSIE conditional compilation comments' => sub {
  my $given = q{
    /* comments get removed */
    /*@ except those that are "IE Conditional Compilation" comments @*/
    /*@ we'll remove those that start with the flag but don't end with it. */
    /* as well as those that end with it but didn't start with it @*/
  };
  my $expect = q{/*@ except those that are "IE Conditional Compilation" comments @*/};
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# whitespace after "prefix" sigils should get removed
subtest 'prefix sigils' => sub {
  my $given = q|
    function foo(   ){
        alert("foo!");
    }
  |;
  my $expect = q|function foo(){alert("foo!");}|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# whitespace before "postfix" sigils should get removed
subtest 'postfix sigils' => sub {
  my $given = q|
    function foo(   )

    {
        alert("foo!")
        ;

    }
  |;
  my $expect = qq|function foo()\n{alert("foo!");}|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
subtest 'simple' => sub {
  my $given = q|
    /* foo */

    var x  = 2;
  |;
  my $expect = q|var x=2;|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# quoted literals get preserved, in several forms
subtest 'literals' => sub {
  subtest 'single quoted literal' => sub {
    my $given  = q{var single_quoted=' single quoted strings // with line comments ';};
    my $expect = q{var single_quoted=' single quoted strings // with line comments ';};
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'double quoted literal' => sub {
    my $given  = q{var double_quoted=" double quoted strings /* with block comments */ ";};
    my $expect = q{var double_quoted=" double quoted strings /* with block comments */ ";};
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'regexp literal' => sub {
    my $given  = q{var regexes=/ regexes stay /;};
    my $expect = q{var regexes=/ regexes stay /;};
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# use of "/" for division should get compacted
subtest 'division' => sub {
  my $given  = "var foo = 10 / 2;";
  my $expect = "var foo=10/2;";
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# RT#80598; regexps containing an escaped "/" should not be treated as comments
subtest 'regexp escaped "/" is not a comment' => sub {
  my $given  = q|
    function foo(url) {
        return ( /\// ).test( url );
    }
  |;
  my $expect = q|function foo(url){return(/\//).test(url);}|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# GH#6; regexps can contain an unescaped slash inside a character set
subtest 'regexp with unescaped slash in character set' => sub {
  my $given  = q|var a = ""; var re = /[/"]/i; console.log(re.test(a));|;
  my $expect = q|var a="";var re=/[/"]/i;console.log(re.test(a));|;
  my $got    = minify($given);
  is $got, $expect;
};

subtest 'regexp with escaped slash in character set' => sub {
  my $given  = q|var a = ""; var re = /[\/"]/i; console.log(re.test(a));|;
  my $expect = q|var a="";var re=/[\/"]/i;console.log(re.test(a));|;
  my $got    = minify($given);
  is $got, $expect;
};

subtest 'regexp with not really a character set' => sub {
  my $given  = q|var a = ""; var re = /\[/i; console.log(re.test(a));|;
  my $expect = q|var a="";var re=/\[/i;console.log(re.test(a));|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# should be able to return a regex from a function
subtest 'return regex from function' => sub {
  my $given = q|
    function foo() {
        return /\d{1,2}/;
    }
  |;
  my $expect = q|function foo(){return/\d{1,2}/;}|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# Division of an array subscript should NOT be treated as opening a regexp, but
# should be treated as division.
subtest 'division of array subscript' => sub {
  my $given = q|
    function foo() {
        var bar = someArray[2]/2;
    }
    function bar() {
        foo(); // this / is not a regexp close, its just part of a line comment
    }
  |;
  my $expect = qq|function foo(){var bar=someArray[2]/2;}\nfunction bar(){foo();}|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
subtest 'ES6 templates' => sub {
  my $given = q|
let vat = $(`#items-${i}-vat_id :selected`);

let html  = `
<div class="foo">
  <span class="bar">
    <button>Baz</button>
  <span>
</div>
`;
|;
  my $expect = q|let vat=$(`#items-${i}-vat_id :selected`);let html=`
<div class="foo">
  <span class="bar">
    <button>Baz</button>
  <span>
</div>
`;|;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# JS that minifies to "nothing"
subtest 'minifies to nothing' => sub {
  subtest 'block comment' => sub {
    my $given  = '/* */';
    my $expect = undef;
    my $got    = minify($given);
    is $got, $expect
  };

  subtest 'line comment' => sub {
    my $given  = '// foo';
    my $expect = undef;
    my $got    = minify($given);
    is $got, $expect
  };

  subtest 'just whitespace' => sub {
    my $given  = "  \r\n \t ";
    my $expect = undef;
    my $got    = minify($given);
    is $got, $expect
  };

  subtest 'empty string' => sub {
    my $given  = '';
    my $expect = undef;
    my $got    = minify($given);
    is $got, $expect
  };
};

###############################################################################
# RT#58416; don't crash if attempting to minify something that isn't JS
# ... while there's no guarantee that what we get back is _sane_, we should at
#     least not blow up or segfault.
subtest "Minifying non-JS shouldn't crash" => sub {
  my $given  = 'not javascript';
  my $expect = 'not javascript';
  my $got    = minify($given);
  is $got, $expect
};

###############################################################################
done_testing();
