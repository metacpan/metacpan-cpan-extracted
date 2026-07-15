use strict;
use warnings;
use Test::More;
use Eshu;

# ── indent_string dispatching ────────────────────────────────────

{
    my $src = "function foo() {\necho 1;\n}\n";
    my $out = Eshu->indent_string($src, lang => 'php');
    like($out, qr/^function foo\(\) \{$/m,  'indent_string php: function');
    like($out, qr/^    echo 1;$/m,           'indent_string php: body at 4 spaces');
    like($out, qr/^\}$/m,                    'indent_string php: closing brace');
}

# ── highlight_string dispatching ─────────────────────────────────

{
    my $out = Eshu->highlight_string('<?php echo "hello"; ?>', lang => 'php');
    like($out, qr/esh-k.*echo/,    'highlight_string php: echo keyword');
    like($out, qr/esh-s.*hello/,   'highlight_string php: string highlighted');
}

# ── indent_php with tabs ─────────────────────────────────────────

{
    my $src = "if (\$x) {\necho \$x;\n}\n";
    my $out = Eshu->indent_php($src, indent_char => "\t");
    like($out, qr/^\techo \$x;$/m, 'indent_php with tabs: body gets one tab');
    like($out, qr/^\}$/m,           'closing brace at depth 0');
}

# ── detect_lang for php variants ─────────────────────────────────

{
    is(Eshu->detect_lang('index.php'),    'php',  '.php detected');
    is(Eshu->detect_lang('index.phtml'),  'php',  '.phtml detected');
    is(Eshu->detect_lang('index.PHP'),    'php',  '.PHP detected (case insensitive)');
    is(Eshu->detect_lang('index.php3'),   'php',  '.php3 detected');
    is(Eshu->detect_lang('index.php4'),   'php',  '.php4 detected');
    is(Eshu->detect_lang('index.php5'),   'php',  '.php5 detected');
}

done_testing;
