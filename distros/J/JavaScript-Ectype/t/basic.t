#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;
use JavaScript::Ectype;

my $TEST_PATH = './t/js/ectype/';


# minify test

*minify = \&JavaScript::Ectype::_minify_javascript;
{

    is( JavaScript::Ectype->convert(
            target   => 'minify.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            (function(){
                var Test=Class.create({initialize:function(name){this.name=name;}})
                ;;;;new Test("<TMPL_VAR NAME=text>");
            })();
        |),
        'no-package-declared'
    );
}
{
    is( JavaScript::Ectype->convert(
            target   => 'package.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            "package".namespace().using(function(_namespace_){
                var Test=Class.create({initialize:function(name){this.name=name;}});
                new Test("<TMPL_VAR NAME=text>");
            });
        |),
        'package-declared'
    );
}
{
    is( JavaScript::Ectype->convert(
            target   => 'depends.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            "package".namespace().depends();
            "package2".namespace().depends();
            (function(){
                var Test=Class.create({initialize:function(name){this.name=name;}});
                new Test("<TMPL_VAR NAME=text>");
            })();
        |),
        'depends'
    );
}
{
    is( JavaScript::Ectype->convert(
            target   => 'import_normal.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            "package".namespace().depends(["Fuga","Hoge"]);
            "package2".namespace().depends();
            with( "package".namespace().stash() ){
                with( "package2".namespace().stash() ){
                    (function(){
                        var Test=Class.create({initialize:function(name){this.name=name:}});
                        new Test("<TMPL_VAR NAME=text>");
                    })();
                }
            }|),
        'within_all'
    );
}
{
    is( JavaScript::Ectype->convert(
            target   => 'import_byname.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            "package".namespace().depends();
            "package2".namespace().depends();
            "package".namespace().within(["Test2","Test1"],function(Test2,Test1){
               "package2".namespace().within(["Test2","Test1"],function(Test22,Test21){
                    (function(){
                        var Test=Class.create({initialize:function(name){this.name=name:}});
                        new Test("<TMPL_VAR NAME=text>");
                    })();
                });
            });
        |),
        'within_by_component'
    );
}
{
    is( JavaScript::Ectype->convert(
            target   => 'package_own.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            "package_own.fuga".namespace().depends();
            "package_own.hoge".namespace().depends();
            "package_own.fuga.package".namespace().within(["Load"],function(Load){
                "package_own.hoge.package".namespace().within(["Ext"],function(Ext){
                    "package_own".namespace().using(function(_namespace_){
                        var Test=Class.create({initialize:function(name){this.name=name:}});
                        new Test("<TMPL_VAR NAME=text>");
                    });
                });
            });
        |),
        'package-relative-path',
    );
}

{
    is( JavaScript::Ectype->convert(
            target   => 'require.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            "Test".namespace().depends();
            "very.deep".namespace().using(function(_namespace_){
                function Hoge(){"HE!!!!!!!!!!!!!!!!!!11";}
            });
            "very.deep.namespace".namespace().within(["Class"],function(Class){
                "require".namespace().using(function(_namespace_){
                    package.Ex=Class;
                });
            });
        |),
        'require'
    );
}



{
    my $x = JavaScript::Ectype->load(
        target   => 'require2.ectype.js',
        path     => $TEST_PATH,
    );
    is( $x->converted_data ,
        minify(q|
           "Test".namespace().depends();
            "very.deep".namespace().using(function(_namespace_){
                function Hoge(){"HE!!!!!!!!!!!!!!!!!!11";}
            });
            "very.deep.namespace".namespace().within(["Class"],function(Class){
                "require".namespace().using(function(_namespace_){
                    package.Ex=Class;
                });
            });
            (function(){
                var Hello="World";
            })();
        |),
        'require-tree'
    );
    is_deeply(
        [ $x->related_files ],
        [   './t/js/ectype/require2.ectype.js',
            './t/js/ectype/require.ectype.js',
            './t/js/ectype/very/deep/namespace/class.js'
        ],
        'check-related-files'
    );

}

{
    is( JavaScript::Ectype->convert(
            target   => 'include.ectype.js',
            path     => $TEST_PATH,
        ),
        minify(q|
            "include".namespace().using(function(_namespace_){
                function hello(){return"world"}
                expose({hello:hello});
            });
        |),
        'include'
    );
}
1;
