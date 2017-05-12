#!perl

use strict;
use warnings;

use Test::More;

eval 'use HTML::Packer;';
plan skip_all => 'HTML::Packer not installed!' if $@;

eval "use JavaScript::Packer $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER;";
plan skip_all => "JavaScript::Packer $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER not installed!" if $@;

plan tests => 20;

SKIP: {

    foreach my $content_type (
        'application/javascript',
        'application/ecmascript',
        'text/javascript',
        'text/ecmascript',
        'text/x-javascript',
        'application/x-javascript',
        'javascript',
        '',
        'text/template',
        'text/html',
    ) {
        foreach my $attr_def (
            " type=\"$content_type\"",
            " foo=\"bar\" type=\"$content_type\"",
        ) {
            $attr_def =~ s/ type=""//;

            my $js_input = <<EOT;

<script$attr_def>



  alert('test');</script>

<a href="/"  >link

1   < /a>


<!-- comment -->

    <  a href="/">   link 2
    < / a  >



EOT

            my $js_expected = "<script$attr_def>" . '/*<![CDATA[*/alert(\'test\');/*]]>*/</script> <a href="/">link 1 </a> <a href="/"> link 2 </a>';
            my $js_expected_no_js = "<script$attr_def>" . "\n\n\n\n" . '  alert(\'test\');</script> <a href="/">link 1 </a> <a href="/"> link 2 </a>';

            my $js_comp_input   = $js_input;
            my $packer = HTML::Packer->init();
            $packer->minify(
                \$js_comp_input,
                {
                    remove_comments => 1,
                    remove_newlines => 1,
                    do_javascript => 'clean'
                }
           );

            if ( $@ ) {
                is( $js_comp_input, $js_expected_no_js, 'Test do_javascript. JavaScript::Packer >= ' . $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER . ' not installed.' );
            } else {
                    ( !$content_type or $content_type !~ /script/ )
                        ? is( $js_comp_input,$js_expected_no_js,"DO NOT minifiy for $content_type" )
                        : is( $js_comp_input,$js_expected, "minify for $content_type" );
            }
        }
    }
}
