#!perl -T

# =========================================================================== #
#
# Most of these tests are stolen from JavaScript::Minifier
#
# =========================================================================== #

use Test::More;

my $not = 39;

SKIP: {
    eval( 'use JavaScript::Packer' );

    skip( 'JavaScript::Packer not installed!', $not ) if ( $@ );

    plan tests => $not;

    fileTest( 's1',  'clean',     's1 compression level "clean"' );
    fileTest( 's2',  'shrink',    's2 compression level "shrink"' );
    fileTest( 's3',  'obfuscate', 's3 compression level "obfuscate"' );
    fileTest( 's4',  'best',      's4 compression level "best" whith short javascript' );
    fileTest( 's5',  'best',      's5 compression level "best" whith long javascript' );
    fileTest( 's7',  'clean',     's7 compression level "clean" function as argument' );
    fileTest( 's8',  'shrink',    's8 compression level "shrink" function as argument' );
    fileTest( 's9',  'shrink',    's9 compression level "shrink" with _no_shrink_ argument' );
    fileTest( 's10', 'shrink',    's10 compression level "shrink" with quoted args' );
    fileTest( 's11', 'best',      's11 compression level "best" with long javascript matching _encode62 ord match 57' );
    fileTest( 's12', 'best',      's12 compression level "best" with long javascript matching _encode62 ord match 65' );
    fileTest( "s$_", 'minify',    "s$_ compression level \"minify\" keep sourceMappingURL" )
		for 13 .. 19;

    my $packer = JavaScript::Packer->init();

    my $var = 'var x = 2;';
    $packer->minify( \$var );
    is( $var, 'var x=2;', 'string literal input and ouput' );

    $var = "var x = 2;\n;;;alert('hi');\nvar x = 2;";
    $packer->minify( \$var );
    is( $var, 'var x=2;var x=2;', 'scriptDebug option' );

    $var = "var x = 2;";
    $packer->copyright( 'BSD' );
    $packer->minify( \$var );
    is( $var, '/* BSD */' . "\n" . 'var x=2;', 'copyright option compression level "clean"' );
    $packer->compress( 'shrink' );
    $packer->minify( \$var );
    is( $var, '/* BSD */' . "\n" . 'var x=2;', 'copyright option compression level "shrink"' );
    $packer->compress( 'best' );
    $packer->minify( \$var );
    is( $var, '/* BSD */' . "\n" . 'var x=2;', 'copyright option compression level "best"' );
    $packer->compress( 'obfuscate' );
    $packer->minify( \$var );
    is(
        $var,
        '/* BSD */'
            . "\neval(function(p,a,c,k,e,r){e=String;if('0'.replace(0,e)==0){while(c--)r[e(c)]=k[c];k=[function(e){return r[e]||e}];e=function(){return'[01]'};c=1};while(c--)if(k[c])p=p.replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('1 0=2;',[],2,'x|var'.split('|'),0,{}))",
        'copyright option compression level "obfuscate"'
    );

    $packer = JavaScript::Packer->init();

    $var = "/* Copyright BSD */var x = 2;";
    $packer->minify( \$var, { remove_copyright => 1 } );
    is( $var, 'var x=2;', 'copyright comment with remove_copyright option' );

    $var = "/* Copyright BSD */var x = 2;";
    $packer->minify( \$var, { remove_copyright => 0 } );
    is( $var, '/* Copyright BSD */' . "\n" . 'var x=2;', 'copyright comment without remove_copyright option' );

    $packer = JavaScript::Packer->init();

    $var = "/* JavaScript::Packer _no_compress_ */\n\nvar x = 1;\n\n\nvar y = 2;";
    $packer->minify( \$var );
    is( $var, "/* JavaScript::Packer _no_compress_ */\n\nvar x = 1;\n\n\nvar y = 2;", '_no_compress_ comment' );

    $var = "/* JavaScript::Packer _no_compress_ */\n\nvar x = 1;\n\n\nvar y = 2;";
    $packer->minify( \$var, { no_compress_comment => 1 } );
    is( $var, "var x=1;var y=2;", '_no_compress_ comment with no_compress_comment option' );

    $var = "var foo = \"foo\" + \"bar\" + \"baz\" + 'foo' + 'bar' + 'baz' + \"foo\" + \"bar\" + \"baz\";";
    $packer->minify( \$var );
    is( $var, "var foo=\"foobarbaz\"+'foobarbaz'+\"foobarbaz\";", 'concat' );

    $var = "var foo = \" \"; var bar = \"+\";";
    JavaScript::Packer::minify( \$var );
    is( $var, "var foo=\" \";var bar=\"+\";", 'concat with plus' );

    $var = "var foo = \" \"; var bar = \"+\"; var baz = \"-\";";
    JavaScript::Packer::minify( \$var );
    is( $var, "var foo=\" \";var bar=\"+\";var baz=\"-\";", 'concat with plus and three strings' );

    $var = "!/foo/";
    $packer->minify( \$var );
    is( $var, "!/foo/", 'regexp preceeded by negation' );

    $var = "!/foo/";
    JavaScript::Packer::minify( \$var );
    is( $var, "!/foo/", 'regexp preceeded by negation, subroutine invocation' );

    $var = "!/foo/";
    $packer->minify( \$var, { compress => 'shrink', } );
    is( $var, "!/foo/", 'regexp preceeded by negation, with shrink' );

    $var = "!/foo/";
    JavaScript::Packer::minify( \$var, { compress => 'shrink', } );
    is( $var, "!/foo/", 'regexp preceeded by negation, with shrink, subroutine invocation' );

    $var = "var foo = /bar/;";
    JavaScript::Packer::minify( \$var );
    is( $var, "var foo=/bar/;", 'building Regexp object implictly' );

    $var = "var foo = /bar/;";
    JavaScript::Packer::minify( \$var, { compress => 'shrink', } );
    is( $var, "var foo=/bar/;", 'building Regexp object implictly with shrink' );

    $var = q~var foo = new RegExp("bar");~;
    JavaScript::Packer::minify( \$var );
    is( $var, q~var foo=new RegExp("bar");~, 'building Regexp object explictly' );

    $var = q~var foo = new RegExp("bar");~;
    JavaScript::Packer::minify( \$var );
    JavaScript::Packer::minify( \$var, { compress => 'shrink', } );
    is( $var, q~var foo=new RegExp("bar");~, 'building Regexp object explictly with shrink' );
}

sub filesMatch {
    my $file1 = shift;
    my $file2 = shift;
    my $a;
    my $b;

    while ( 1 ) {
        $a = getc( $file1 );
        $b = getc( $file2 );

        if ( !defined( $a ) && !defined( $b ) ) {    # both files end at same place
            return 1;
        }
        elsif (
            !defined( $b ) ||                        # file2 ends first
            !defined( $a ) ||                        # file1 ends first
            $a ne $b
            )
        {                                            # a and b not the same
note( "[$a] [$b]" );
            return 0;
        }
    }
}

sub fileTest {
    my $filename = shift;
    my $compress = shift || 'minify';
    my $comment  = shift || '';

    open( INFILE,  't/scripts/' . $filename . '.js' )      or die( "couldn't open file" );
    open( GOTFILE, '>t/scripts/' . $filename . '-got.js' ) or die( "couldn't open file" );

    my $js = join( '', <INFILE> );

    my $packer = JavaScript::Packer->init();

    $packer->minify( \$js, { compress => $compress } );
    print GOTFILE $js;
    close( INFILE );
    close( GOTFILE );

    open( EXPECTEDFILE, 't/scripts/' . $filename . '-expected.js' ) ;#or die( "couldn't open file $filename-expected.js: $!" );
    open( GOTFILE,      't/scripts/' . $filename . '-got.js' )      ;#or die( "couldn't open file $filename-got.js: $!" );
    ok( filesMatch( GOTFILE, EXPECTEDFILE ), $comment )
;#		|| BAIL_OUT( "fail" );
    close( EXPECTEDFILE );
    close( GOTFILE );
}
