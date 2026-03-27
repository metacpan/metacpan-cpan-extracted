use strict;
use warnings;
use Test::More;
use Loo qw(Dump ncDump dDump);

# Functional Dump with no args
{
    my $out = Dump();
    is($out, '', 'Dump() with no args returns empty output');
}

# Many scalar values
{
    my @vals = (1..12);
    my $out = ncDump(@vals);
    like($out, qr/\$VAR1 = 1;/, 'multi: first value');
    like($out, qr/\$VAR12 = 12;/, 'multi: last value');
}

# Mixed values
{
    my $obj = bless {k => 1}, 'Mix::Obj';
    my $arr = [1, 2];
    my $h = {a => 1};
    my $out = ncDump($obj, $arr, $h, undef, qr/x/);
    like($out, qr/'Mix::Obj'/, 'mixed: blessed class');
    like($out, qr/\$VAR2 = \[/, 'mixed: second is array');
    like($out, qr/\$VAR3 = \{/, 'mixed: third is hash');
    like($out, qr/\$VAR4 = undef;/, 'mixed: fourth undef');
    like($out, qr/\$VAR5 = qr\//, 'mixed: fifth regex');
}

# dDump with multiple values including coderef
{
    my $out = dDump(sub { $_[0] + 1 }, 42);
    like($out, qr/sub \{/, 'dDump multi: deparsed coderef');
    like($out, qr/\$VAR2 = 42;/, 'dDump multi: second scalar');
}

done_testing;
