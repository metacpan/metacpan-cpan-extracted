use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── begin/rescue/ensure/end ───────────────────────────────────────

{
    my $src = <<'END';
begin
risky_op
rescue RuntimeError => e
puts e.message
ensure
cleanup
end
END
    my $out = r($src);
    like($out, qr/^begin$/m,                    'begin at depth 0');
    like($out, qr/^  risky_op$/m,               'begin body at depth 1');
    like($out, qr/^rescue RuntimeError => e$/m, 'rescue at depth 0');
    like($out, qr/^  puts e\.message$/m,         'rescue body at depth 1');
    like($out, qr/^ensure$/m,                    'ensure at depth 0');
    like($out, qr/^  cleanup$/m,                 'ensure body at depth 1');
    like($out, qr/^end$/m,                       'end at depth 0');
}

# ── def with rescue inside ────────────────────────────────────────

{
    my $src = <<'END';
def safe_divide(a, b)
begin
a / b
rescue ZeroDivisionError
0
end
end
END
    my $out = r($src);
    like($out, qr/^def safe_divide/m,        'def at depth 0');
    like($out, qr/^  begin$/m,               'begin at depth 1');
    like($out, qr/^    a \/ b$/m,            'begin body at depth 2');
    like($out, qr/^  rescue ZeroDivisionError$/m, 'rescue at depth 1');
    like($out, qr/^    0$/m,                 'rescue body at depth 2');
    like($out, qr/^  end$/m,                 'inner end at depth 1');
    like($out, qr/^end$/m,                   'outer end at depth 0');
}

# ── multiple rescue clauses ───────────────────────────────────────

{
    my $src = <<'END';
begin
op
rescue TypeError => e
handle_type(e)
rescue ArgumentError => e
handle_arg(e)
rescue => e
handle_other(e)
end
END
    my $out = r($src);
    like($out, qr/^begin$/m,              'begin');
    like($out, qr/^  op$/m,              'body at depth 1');
    like($out, qr/^rescue TypeError/m,    'first rescue at depth 0');
    like($out, qr/^  handle_type\(e\)/m, 'first rescue body at depth 1');
    like($out, qr/^rescue ArgumentError/m,'second rescue at depth 0');
    like($out, qr/^rescue => e$/m,        'bare rescue at depth 0');
    like($out, qr/^end$/m,               'end at depth 0');
}

done_testing;
