#!perl -T

# =========================================================================== #

use Test::More;

my $js_input = <<EOT;

<script type="javascript">



  alert('test');</script>

<a href="/"  >link

1   < /a>


<!-- comment -->

    <  a href="/">   link 2
    < / a  >



EOT

my $js_expected             = '<script type="javascript">/*<![CDATA[*/alert(\'test\');/*]]>*/</script> <a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $js_expected_html5       = '<script>alert(\'test\');</script> <a href="/">link 1 </a> <a href="/"> link 2 </a>';

my $js_expected_html5_no_js = '<script>' . "\n\n\n\n" . '  alert(\'test\');</script> <a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $js_expected_no_js       = '<script type="javascript">' . "\n\n\n\n" . '  alert(\'test\');</script> <a href="/">link 1 </a> <a href="/"> link 2 </a>';

my $css_input = <<EOT;


  <style type="text/css">

  foo {
    asdf:asdf;
    ew:12;
  }
</style>

<a href="/"  >link

1   < /a>


<!-- comment -->

    <  a href="/">   link 2
    < / a  >


EOT

my $css_expected                = '<style type="text/css">' . "\nfoo{\nasdf:asdf;\new:12;\n}\n" . '</style> <a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $css_expected_no_css         = '<style type="text/css">' . "\n\n  foo {\n    asdf:asdf;\n    ew:12;\n  }\n" . '</style> <a href="/">link 1 </a> <a href="/"> link 2 </a>';

my $css_expected_html5          = '<style>' . "\nfoo{\nasdf:asdf;\new:12;\n}\n" . '</style> <a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $css_expected_html5_no_css   = '<style>' . "\n\n  foo {\n    asdf:asdf;\n    ew:12;\n  }\n" . '</style> <a href="/">link 1 </a> <a href="/"> link 2 </a>';

my $html_input = <<EOT;
<script type="javascript">/*<![CDATA[*/



  alert('test');/*]]>*/</script>
  <br />
  <img src="/bild.jpg" alt="hmpf" />
<a href="/"  >link

1   < /a>


<!-- comment -->

    <  a href="/">   link 2
    < / a  >

EOT

my $html_expected       = '<script>alert(\'test\');</script><br><img src="/bild.jpg" alt="hmpf"> <a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $html_expected_no_js = '<script>/*<![CDATA[*/' . "\n\n\n\n  " . 'alert(\'test\');/*]]>*/</script><br><img src="/bild.jpg" alt="hmpf"> <a href="/">link 1 </a> <a href="/"> link 2 </a>';

my $not = 11;

SKIP: {
    eval { use HTML::Packer; };

    skip( 'HTML::Packer not installed!', $not ) if ( $@ );

    plan tests => $not;

    minTest( 's1', undef, 'Test without opts.' );
    minTest( 's2', { remove_newlines => 1 }, 'Test remove_newlines.' );
    minTest( 's3', { remove_comments => 1 }, 'Test remove_comments.' );
    minTest( 's4', { remove_comments => 1, remove_newlines => 1 }, 'Test remove_newlines and remove_comments.' );
    minTest( 's5', { remove_comments => 1, remove_newlines => 1 }, 'Test _no_compress_ comment.' );
    minTest( 's6', { remove_comments => 1, remove_newlines => 1, no_compress_comment => 1 }, 'Test _no_compress_ comment with no_compress_comment option.' );

    my $packer = HTML::Packer->init();
    my $js_comp_input   = $js_input;
    my $js_html5_input  = $js_input;
    $packer->minify( \$js_comp_input, { remove_comments => 1, remove_newlines => 1, do_javascript => 'clean' } );
    $packer->minify( \$js_html5_input, { remove_comments => 1, remove_newlines => 1, do_javascript => 'clean', html5 => 1 } );
    $packer->minify( \$html_input, { remove_comments => 1, remove_newlines => 1, do_javascript => 'clean', html5 => 1 } );

    eval "use JavaScript::Packer $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER;";
    if ( $@ ) {
        is( $js_comp_input, $js_expected_no_js, 'Test do_javascript. JavaScript::Packer >= ' . $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER . ' not installed.' );
        is( $js_html5_input, $js_expected_html5_no_js, 'Test do_javascript 2. JavaScript::Packer >= ' . $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER . ' not installed.' );
        is( $html_input, $html_expected_no_js, 'Test do_javascript 3. JavaScript::Packer >= ' . $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER . ' not installed.' );
    }
    else {
        is( $js_comp_input, $js_expected, 'Test do_javascript. JavaScript::Packer installed.' );
        is( $js_html5_input, $js_expected_html5, 'Test do_javascript 2. JavaScript::Packer installed.' );
        is( $html_input, $html_expected, 'Test do_javascript 3. JavaScript::Packer installed.' );
    }

    my $css_comp_input  = $css_input;
    my $css_html5_input = $css_input;

    $packer->minify( \$css_comp_input, { remove_comments => 1, remove_newlines => 1, do_stylesheet => 'pretty', html5 => 0 } );
    $packer->minify( \$css_html5_input, { remove_comments => 1, remove_newlines => 1, do_stylesheet => 'pretty', html5 => 1 } );

    eval "use CSS::Packer $HTML::Packer::REQUIRED_CSS_PACKER;";
    if ( $@ ) {
        is( $css_comp_input, $css_expected_no_css, 'Test do_stylesheet. CSS::Packer >= ' . $HTML::Packer::REQUIRED_CSS_PACKER . ' not installed.' );
        is( $css_html5_input, $css_expected_html5_no_css, 'Test do_stylesheet 2. CSS::Packer >= ' . $HTML::Packer::REQUIRED_CSS_PACKER . ' not installed.' );
    }
    else {
        is( $css_comp_input, $css_expected, 'Test do_stylesheet. CSS::Packer installed.' );
        is( $css_html5_input, $css_expected_html5, 'Test do_stylesheet 2. CSS::Packer installed.' );
    }
}

sub filesMatch {
    my $file1 = shift;
    my $file2 = shift;
    my $a;
    my $b;

    while (1) {
        $a = getc($file1);
        $b = getc($file2);

        if (!defined($a) && !defined($b)) { # both files end at same place
            return 1;
        }
        elsif (
            !defined($b) || # file2 ends first
            !defined($a) || # file1 ends first
            $a ne $b
        ) {     # a and b not the same
            return 0;
        }
    }
}

sub minTest {
    my $filename = shift;
    my $opts = shift || {};
    my $message = shift || '';

    open(INFILE, 't/html/' . $filename . '.html') or die("couldn't open file");
    open(GOTFILE, '>t/html/' . $filename . '-got.html') or die("couldn't open file");

    my $html = join( '', <INFILE> );

    my $packer = HTML::Packer->init();

    $packer->minify( \$html, $opts );
    print GOTFILE $html;
    close(INFILE);
    close(GOTFILE);

    open(EXPECTEDFILE, 't/html/' . $filename . '-expected.html') or die("couldn't open file");
    open(GOTFILE, 't/html/' . $filename . '-got.html') or die("couldn't open file");
    ok(filesMatch(GOTFILE, EXPECTEDFILE), $message );
    close(EXPECTEDFILE);
    close(GOTFILE);
}

