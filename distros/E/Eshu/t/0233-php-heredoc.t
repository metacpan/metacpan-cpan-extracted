use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── basic heredoc ────────────────────────────────────────────────

{
    my $src = <<'END';
$x = <<<EOT
Hello
World
EOT;
echo $x;
END
    my $out = p($src);
    like($out, qr/^\$x = <<<EOT$/m,  'heredoc opening at depth 0');
    like($out, qr/^Hello$/m,          'heredoc body line 1 verbatim');
    like($out, qr/^World$/m,          'heredoc body line 2 verbatim');
    like($out, qr/^EOT;$/m,           'heredoc end marker');
    like($out, qr/^echo \$x;$/m,      'code after heredoc at depth 0');
}

# ── nowdoc ───────────────────────────────────────────────────────

{
    my $src = <<'END';
$y = <<<'EOT'
no $interpolation here
EOT;
END
    my $out = p($src);
    like($out, qr/^\$y = <<<'EOT'$/m,           'nowdoc opening');
    like($out, qr/^no \$interpolation here$/m,   'nowdoc body verbatim');
    like($out, qr/^EOT;$/m,                      'nowdoc end marker');
}

# ── heredoc inside function ───────────────────────────────────────

{
    my $src = <<'END';
function foo() {
$msg = <<<EOT
  indented content
EOT;
return $msg;
}
END
    my $out = p($src);
    like($out, qr/^function foo\(\) \{$/m,    'function at depth 0');
    like($out, qr/^    \$msg = <<<EOT$/m,     'heredoc start at depth 1');
    like($out, qr/^  indented content$/m,     'heredoc body verbatim (2 spaces)');
    like($out, qr/^EOT;$/m,                   'end marker at depth 0 (traditional)');
    like($out, qr/^    return \$msg;$/m,       'code after heredoc at depth 1');
}

done_testing;
