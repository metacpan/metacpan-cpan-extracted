use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── basic try/except ─────────────────────────────────────────────

{
    my $src = <<'SRC';
try:
    x = int(s)
except ValueError:
    x = 0
SRC
    my $out = py($src);
    like($out, qr/^try:$/m,              'try at depth 0');
    like($out, qr/^    x = int\(s\)$/m, 'try body at depth 1');
    like($out, qr/^except ValueError:$/m,'except at depth 0');
    like($out, qr/^    x = 0$/m,         'except body at depth 1');
}

# ── try/except/else ──────────────────────────────────────────────

{
    my $src = <<'SRC';
try:
    result = compute()
except RuntimeError:
    result = None
else:
    log(result)
SRC
    my $out = py($src);
    like($out, qr/^    result = compute\(\)$/m, 'try body at depth 1');
    like($out, qr/^except RuntimeError:$/m,     'except at depth 0');
    like($out, qr/^    result = None$/m,         'except body at depth 1');
    like($out, qr/^else:$/m,                     'else at depth 0');
    like($out, qr/^    log\(result\)$/m,          'else body at depth 1');
}

# ── try/except/finally ───────────────────────────────────────────

{
    my $src = <<'SRC';
try:
    f = open(path)
    data = f.read()
except OSError:
    data = ''
finally:
    f.close()
SRC
    my $out = py($src);
    like($out, qr/^    f = open\(path\)$/m, 'try body line 1 at depth 1');
    like($out, qr/^    data = f\.read\(\)$/m,'try body line 2 at depth 1');
    like($out, qr/^except OSError:$/m,       'except at depth 0');
    like($out, qr/^    data = ''$/m,          'except body at depth 1');
    like($out, qr/^finally:$/m,              'finally at depth 0');
    like($out, qr/^    f\.close\(\)$/m,       'finally body at depth 1');
}

# ── multiple except clauses ──────────────────────────────────────

{
    my $src = <<'SRC';
try:
    op()
except TypeError:
    handle_type()
except ValueError:
    handle_value()
except (OSError, IOError):
    handle_io()
SRC
    my $out = py($src);
    like($out, qr/^except TypeError:$/m,         'first except at depth 0');
    like($out, qr/^except ValueError:$/m,        'second except at depth 0');
    like($out, qr/^except \(OSError, IOError\):$/m, 'tuple except at depth 0');
    like($out, qr/^    handle_io\(\)$/m,         'tuple except body at depth 1');
}

# ── except as e ──────────────────────────────────────────────────

{
    my $src = "try:\n    x()\nexcept Exception as e:\n    log(e)\n";
    my $out = py($src);
    like($out, qr/^except Exception as e:$/m, 'except as e at depth 0');
    like($out, qr/^    log\(e\)$/m,            'except body at depth 1');
}

# ── nested try/except ────────────────────────────────────────────

{
    my $src = <<'SRC';
def safe_parse(s):
    try:
        try:
            return int(s)
        except ValueError:
            return float(s)
    except (ValueError, TypeError):
        return None
SRC
    my $out = py($src);
    like($out, qr/^    try:$/m,                  'outer try at depth 1');
    like($out, qr/^        try:$/m,              'inner try at depth 2');
    like($out, qr/^            return int\(s\)$/m, 'inner try body at depth 3');
    like($out, qr/^        except ValueError:$/m,'inner except at depth 2');
    like($out, qr/^    except \(ValueError/m,    'outer except at depth 1');
    like($out, qr/^        return None$/m,       'outer except body at depth 2');
}

# ── try inside loop ───────────────────────────────────────────────

{
    my $src = <<'SRC';
for item in items:
    try:
        process(item)
    except Exception:
        skip(item)
SRC
    my $out = py($src);
    like($out, qr/^    try:$/m,             'try inside for at depth 1');
    like($out, qr/^        process\(item\)$/m,'try body at depth 2');
    like($out, qr/^    except Exception:$/m, 'except inside for at depth 1');
    like($out, qr/^        skip\(item\)$/m,  'except body at depth 2');
}

done_testing;
