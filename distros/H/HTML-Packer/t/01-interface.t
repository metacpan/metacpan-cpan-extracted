#!perl -T

use Test::More;

my $not = 39;

SKIP: {
    eval { use HTML::Packer; };

    skip( 'HTML::Packer not installed!', $not ) if ( $@ );

    plan tests => $not;

    my $packer = HTML::Packer->init();

    ok( ! $packer->remove_comments(), 'Default value for remove_comments.' );
    ok( ! $packer->remove_newlines(), 'Default value for remove_newlines.' );
    ok( ! $packer->no_compress_comment(), 'Default value for no_compress_comment.' );
    ok( ! $packer->html5(), 'Default value for no_cdata.' );
    ok( ! $packer->do_javascript(), 'Default value for do_javascript.' );
    ok( ! $packer->do_stylesheet(), 'Default value for do_stylesheet.' );

    $packer->remove_comments( 1 );
    ok( $packer->remove_comments(), 'Set remove_comments.' );
    $packer->remove_comments( 0 );
    ok( ! $packer->remove_comments(), 'Unset remove_comments.' );

    $packer->remove_newlines( 1 );
    ok( $packer->remove_newlines(), 'Set remove_newlines.' );
    $packer->remove_newlines( 0 );
    ok( ! $packer->remove_newlines(), 'Unset remove_newlines.' );

    $packer->no_compress_comment( 1 );
    ok( $packer->no_compress_comment(), 'Set no_compress_comment.' );
    $packer->no_compress_comment( 0 );
    ok( ! $packer->no_compress_comment(), 'Unset no_compress_comment.' );

    $packer->html5( 1 );
    ok( $packer->html5(), 'Set html5.' );
    $packer->html5( 0 );
    ok( ! $packer->html5(), 'Unset html5.' );

    $packer->do_javascript( 'clean' );
    is( $packer->do_javascript(), 'clean', 'Set do_javascript to "clean".' );
    $packer->do_javascript( 'shrink' );
    is( $packer->do_javascript(), 'shrink', 'Set do_javascript to "shrink".' );
    $packer->do_javascript( 'obfuscate' );
    is( $packer->do_javascript(), 'obfuscate', 'Set do_javascript to "obfuscate".' );
    $packer->do_javascript( 'foo' );
    is( $packer->do_javascript(), 'obfuscate', 'Setting do_javascript to "foo" failed.' );
    $packer->do_javascript( '' );
    ok( ! $packer->do_javascript(), 'Unset do_javascript.' );
    $packer->do_javascript( 'bar' );
    ok( ! $packer->do_javascript(), 'Setting do_javascript to "bar" failed.' );

    $packer->do_stylesheet( 'minify' );
    is( $packer->do_stylesheet(), 'minify', 'Set do_stylesheet to "minify".' );
    $packer->do_stylesheet( 'pretty' );
    is( $packer->do_stylesheet(), 'pretty', 'Set do_stylesheet to "pretty".' );
    $packer->do_stylesheet( 'foo' );
    is( $packer->do_stylesheet(), 'pretty', 'Setting do_stylesheet to "foo" failed.' );
    $packer->do_stylesheet( '' );
    ok( ! $packer->do_stylesheet(), 'Unset do_stylesheet.' );
    $packer->do_stylesheet( 'bar' );
    ok( ! $packer->do_stylesheet(), 'Setting do_stylesheet to "bar" failed.' );

    eval "use JavaScript::Packer $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER;";
    if ( $@ ) {
        ok( ! $packer->javascript_packer(), 'JavaScript::Packer >= ' . $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER . ' not installed.' );
    }
    else {
        isa_ok( $packer->javascript_packer(), 'JavaScript::Packer', 'JavaScript::Packer installed.' );
    }

    eval "use CSS::Packer $HTML::Packer::REQUIRED_CSS_PACKER;";
    if ( $@ ) {
        ok( ! $packer->css_packer(), 'CSS::Packer >= ' . $HTML::Packer::REQUIRED_CSS_PACKER . ' not installed.' );
    }
    else {
        isa_ok( $packer->css_packer(), 'CSS::Packer', 'CSS::Packer installed.' );
    }

    my $str = '';

    $packer->minify( \$str, {} );

    ok( ! $packer->remove_comments(), 'Default value for remove_comments is still set.' );
    ok( ! $packer->remove_newlines(), 'Default value for remove_newlines is still set.' );
    ok( ! $packer->no_compress_comment(), 'Default value for no_compress_comment is still set.' );
    ok( ! $packer->html5(), 'Default value for html5 is still set.' );
    ok( ! $packer->do_javascript(), 'Default value for do_javascript is still set.' );
    ok( ! $packer->do_stylesheet(), 'Default value for do_stylesheet is still set.' );

    $packer->minify(
        \$str,
        {
            remove_comments     => 1,
            remove_newlines     => 1,
            no_compress_comment => 1,
            html5               => 1,
            do_javascript       => 'clean',
            do_stylesheet       => 'minify'
        }
    );

    ok( $packer->remove_comments(), 'Set remove_comments again.' );
    ok( $packer->remove_newlines(), 'Set remove_newlines again.' );
    ok( $packer->no_compress_comment(), 'Set no_compress_comment again.' );
    ok( $packer->html5(), 'Set html5 again.' );
    ok( $packer->do_javascript(), 'Set do_javascript to "clean" again.' );
    ok( $packer->do_stylesheet(), 'Set do_stylesheet to "minify" again.' );

}