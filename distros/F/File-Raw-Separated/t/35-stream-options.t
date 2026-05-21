use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);
use File::Temp qw(tempfile);

# Custom separator
{
    my ($fh, $path) = tempfile(SUFFIX => '.dat', UNLINK => 1);
    print $fh "a;b;c\n";
    close $fh;

    my @rows;
    file_csv_parse_stream($path, sub { push @rows, [@{$_[0]}] }, { sep => ';' });
    is_deeply(\@rows, [['a','b','c']], 'stream with sep => ";"');
}

# TSV via opts
{
    my ($fh, $path) = tempfile(SUFFIX => '.dat', UNLINK => 1);
    print $fh "a\tb\tc\n";
    close $fh;

    my @rows;
    file_csv_parse_stream(
        $path,
        sub { push @rows, [@{$_[0]}] },
        { sep => "\t", quote => undef },
    );
    is_deeply(\@rows, [['a','b','c']], 'stream with TSV-style opts');
}

# Strict mode + malformed input → croak
{
    my ($fh, $path) = tempfile(SUFFIX => '.dat', UNLINK => 1);
    print $fh qq(a"b,c\n);
    close $fh;

    my $rc = eval {
        file_csv_parse_stream($path, sub { }, { strict => 1 });
        1;
    };
    ok(!$rc, 'strict + malformed croaks');
    like($@, qr/quot/i, 'error mentions quoting');
    like($@, qr/byte offset/i, 'error includes byte offset');
    like($@, qr/\Q$path\E/, 'error includes path');
}

# Bad code-ref arg
{
    my $rc = eval {
        file_csv_parse_stream('/tmp/whatever', 'not a code ref');
        1;
    };
    ok(!$rc, 'non-code-ref second arg croaks');
    like($@, qr/CODE/, 'error mentions CODE ref requirement');
}

# Bad opts arg
{
    my ($fh, $path) = tempfile(SUFFIX => '.dat', UNLINK => 1);
    print $fh "x\n";
    close $fh;

    my $rc = eval {
        file_csv_parse_stream($path, sub { }, "not a hashref");
        1;
    };
    ok(!$rc, 'non-hashref third arg croaks');
    like($@, qr/hashref/i, 'error mentions hashref requirement');
}

done_testing;
