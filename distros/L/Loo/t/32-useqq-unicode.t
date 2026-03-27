use strict;
use warnings;
use utf8;
use Test::More;
use Loo qw(ncDump);

# Unicode scalar
{
    my $dd = Loo->new(["snowman \x{2603}"]);
    $dd->{use_colour} = 0;
    $dd->Useqq(1);
    my $out = $dd->Dump;
    like($out, qr/"snowman /, 'useqq unicode emits double-quoted string');
}

# Embedded NUL byte
{
    my $s = "a\0b";
    my $dd = Loo->new([$s]);
    $dd->{use_colour} = 0;
    $dd->Useqq(1);
    my $out = $dd->Dump;
    like($out, qr/"a\\x\{00\}b"|"a\\0b"/, 'useqq escapes NUL byte');
}

# High byte string
{
    my $s = "\x{00E9}"; # e-acute
    my $dd = Loo->new([$s]);
    $dd->{use_colour} = 0;
    $dd->Useqq(1);
    my $out = $dd->Dump;
    like($out, qr/"/, 'high-byte value still quoted');
}

# Control characters
{
    my $s = "line1\nline2\tend\r";
    my $dd = Loo->new([$s]);
    $dd->{use_colour} = 0;
    $dd->Useqq(1);
    my $out = $dd->Dump;
    like($out, qr/\\n/, 'newline escaped');
    like($out, qr/\\t/, 'tab escaped');
    like($out, qr/\\r/, 'carriage return escaped');
}

done_testing;
