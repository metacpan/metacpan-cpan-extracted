#!/usr/bin/env perl

use v5.8;
use warnings;
use utf8;

use Test2::V0;

# Set up in-memory capture via a typeglob filehandle.
our $buf;
open *TESTOUT, '>', \$buf or die "Cannot open capture buffer: $!";

sub reset_capture {
    close *TESTOUT;
    $buf = '';
    open *TESTOUT, '>', \$buf or die "Cannot reopen capture buffer: $!";
}

require Devel::Bug;
Devel::Bug->import(out => *TESTOUT);

sub bug :lvalue;  # forward declaration: tells parser bug() is an lvalue sub

# ---------------------------------------------------------------------------
# 1. Scalar integer passes through; label and value appear in output
# ---------------------------------------------------------------------------

{
    reset_capture();
    my $in;
    ($in = bug('num') = 42);
    is   $in,  42,      'scalar integer passes through';
    like $buf, qr/num=/, 'label in scalar output';
    like $buf, qr/42/,   'value in scalar output';
}

# ---------------------------------------------------------------------------
# 2. Scalar string passes through
# ---------------------------------------------------------------------------

{
    reset_capture();
    my $in;
    ($in = bug('str') = 'hello');
    is   $in,  'hello', 'scalar string passes through';
    like $buf, qr/hello/, 'string in output';
}

# ---------------------------------------------------------------------------
# 3. undef passes through; UNDEF shown in output
# ---------------------------------------------------------------------------

{
    reset_capture();
    my $in;
    ($in = bug('undef_test') = undef);
    ok   !defined($in),   'undef passes through';
    like $buf, qr/UNDEF/, 'UNDEF shown in output';
}

# ---------------------------------------------------------------------------
# 4. Label "0" is preserved (not treated as false)
# ---------------------------------------------------------------------------

{
    reset_capture();
    my $in;
    ($in = bug('0') = 1);
    like $buf, qr/^0=/, 'label "0" not treated as false';
}

# ---------------------------------------------------------------------------
# 5. Plain list passes through grouped in a single output
# ---------------------------------------------------------------------------

{
    reset_capture();
    my @result = (bug 'nums') = (10, 20, 30);
    is   \@result, [10, 20, 30], 'plain list passes through';
    like $buf,     qr/nums=/,    'label in list output';
    like $buf,     qr/10/,       'first value in output';
    like $buf,     qr/30/,       'last value in output';
}

# ---------------------------------------------------------------------------
# 6. Empty list fires output
# ---------------------------------------------------------------------------

{
    reset_capture();
    my @result = (bug 'empty') = ();
    is   \@result, [],              'empty list passes through';
    like $buf,     qr/empty=\(\)/, 'empty list output fires';
}

# ---------------------------------------------------------------------------
# 7. Indices flag (:@) adds [N] prefixes
# ---------------------------------------------------------------------------

{
    reset_capture();
    my @result = (bug 'indexed:@') = ('a', 'b', 'c');
    is   \@result, ['a', 'b', 'c'], 'list passes through with indices flag';
    like $buf,     qr/0: /,          'index 0 in output';
    like $buf,     qr/2: /,          'index 2 in output';
}

# ---------------------------------------------------------------------------
# 8. Keyval flag (:%) formats as key => value pairs
# ---------------------------------------------------------------------------

{
    reset_capture();
    my %result = (bug 'pairs:%') = (a => 1, b => 2);
    is   \%result, {a => 1, b => 2}, 'key-value pairs pass through';
    like $buf,     qr/a =>/,         'key-value format in output';
}

# ---------------------------------------------------------------------------
# 9. Indexed keyval (:@%) combines index and key => value
# ---------------------------------------------------------------------------

{
    reset_capture();
    my %result = (bug 'ipairs:@%') = (x => 10, y => 20);
    is   \%result, {x => 10, y => 20}, 'indexed key-value pairs pass through';
    like $buf,     qr/0: /,             'index in indexed key-value output';
    like $buf,     qr/x =>/,           'key-value format in indexed output';
}

# ---------------------------------------------------------------------------
# 10. Multiline flag (:m) indents values on separate lines
# ---------------------------------------------------------------------------

{
    reset_capture();
    my @result = (bug 'ml:m') = (1, 2, 3);
    is   \@result, [1, 2, 3],  'list passes through with multiline flag';
    like $buf,     qr/\n  /,   'values indented in multiline output';
}

# ---------------------------------------------------------------------------
# 11. val override: actual value passes through; override shown in output
# ---------------------------------------------------------------------------

{
    reset_capture();
    my $in;
    ($in = bug('secret', val => '[REDACTED]') = 'password');
    is     $in,  'password',      'actual value passes through with val override';
    like   $buf, qr/\[REDACTED\]/, 'override shown in output';
    unlike $buf, qr/password/,    'actual value not shown when overridden';
}

# ---------------------------------------------------------------------------
# 12. 'override' alias for val
# ---------------------------------------------------------------------------

{
    reset_capture();
    my $in;
    ($in = bug('secret2', override => '[HIDDEN]') = 'classified');
    like   $buf, qr/\[HIDDEN\]/,   "'override' alias for val works";
    unlike $buf, qr/classified/,   'actual value suppressed via override alias';
}

# ---------------------------------------------------------------------------
# 13. Per-call color options accepted without error
# ---------------------------------------------------------------------------

{
    reset_capture();
    my $in;
    ok lives { ($in = bug('colored', ic => 'bold', lc => 'underline', vc => 'cyan') = 42) },
        'per-call color options accepted without error';
    is $in, 42, 'value passes through with per-call color options';
}

# ---------------------------------------------------------------------------
# 14. lineno option includes line number in output
# ---------------------------------------------------------------------------

{
    Devel::Bug->import(out => *TESTOUT, lineno => 1);
    reset_capture();
    my $in;
    ($in = bug('lined') = 1);
    like $buf, qr/line \d+/, 'line number in output when lineno => 1';
}

# ---------------------------------------------------------------------------
# 15. package option includes caller package in output
# ---------------------------------------------------------------------------

{
    Devel::Bug->import(out => *TESTOUT, package => 1);
    reset_capture();
    my $in;
    ($in = bug('pkgd') = 1);
    like $buf, qr/main/, 'caller package in output when package => 1';
}

# ---------------------------------------------------------------------------
# 16. filename option includes source filename in output
# ---------------------------------------------------------------------------

{
    Devel::Bug->import(out => *TESTOUT, filename => 1);
    reset_capture();
    my $in;
    ($in = bug('fnd') = 1);
    like $buf, qr/bug\.t/, 'source filename in output when filename => 1';
}

# ---------------------------------------------------------------------------
# 17. Lexical filehandle works as output handle
# ---------------------------------------------------------------------------

{
    my $lex_buf;
    open my $fh, '>', \$lex_buf or die "Cannot open: $!";
    Devel::Bug->import(out => $fh);
    my $in;
    ($in = bug('lex_fh') = 77);
    is   $in,  77,              'value passes through with lexical filehandle';
    like $lex_buf, qr/lex_fh/, 'output goes to lexical filehandle';
    like $lex_buf, qr/77/,     'value appears in lexical filehandle output';
}

done_testing;
