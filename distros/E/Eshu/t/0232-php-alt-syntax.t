use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── if(): endif; ─────────────────────────────────────────────────

{
    my $src = <<'END';
if ($x):
echo "yes";
endif;
END
    my $out = p($src);
    like($out, qr/^if \(\$x\):$/m,    'if(): at depth 0');
    like($out, qr/^    echo "yes";$/m, 'body at depth 1');
    like($out, qr/^endif;$/m,          'endif; at depth 0');
}

# ── if / elseif / else / endif ───────────────────────────────────

{
    my $src = <<'END';
if ($a):
echo "a";
elseif ($b):
echo "b";
else:
echo "c";
endif;
END
    my $out = p($src);
    like($out, qr/^if \(\$a\):$/m,      'if(): at depth 0');
    like($out, qr/^    echo "a";$/m,    'if body at depth 1');
    like($out, qr/^elseif \(\$b\):$/m,  'elseif at depth 0');
    like($out, qr/^    echo "b";$/m,    'elseif body at depth 1');
    like($out, qr/^else:$/m,             'else: at depth 0');
    like($out, qr/^    echo "c";$/m,    'else body at depth 1');
    like($out, qr/^endif;$/m,            'endif; at depth 0');
}

# ── foreach(): endforeach; ───────────────────────────────────────

{
    my $src = <<'END';
foreach ($arr as $v):
echo $v;
endforeach;
END
    my $out = p($src);
    like($out, qr/^foreach \(\$arr as \$v\):$/m, 'foreach(): at depth 0');
    like($out, qr/^    echo \$v;$/m,              'foreach body at depth 1');
    like($out, qr/^endforeach;$/m,                'endforeach; at depth 0');
}

# ── while(): endwhile; ───────────────────────────────────────────

{
    my $src = <<'END';
while ($x > 0):
$x--;
endwhile;
END
    my $out = p($src);
    like($out, qr/^while \(\$x > 0\):$/m,  'while(): at depth 0');
    like($out, qr/^    \$x--;$/m,            'while body at depth 1');
    like($out, qr/^endwhile;$/m,             'endwhile; at depth 0');
}

# ── for(): endfor; ───────────────────────────────────────────────

{
    my $src = <<'END';
for ($i = 0; $i < 5; $i++):
echo $i;
endfor;
END
    my $out = p($src);
    like($out, qr/^for \(\$i = 0;/m,  'for(): at depth 0');
    like($out, qr/^    echo \$i;$/m,   'for body at depth 1');
    like($out, qr/^endfor;$/m,          'endfor; at depth 0');
}

done_testing;
