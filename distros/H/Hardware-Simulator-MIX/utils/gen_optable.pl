
my $optab = {

5 => "misc",
0 => "nop",
8 => "lda",
15 => "ldx",
"9_14" => "ldi",
16 => "ldan",
23 => "ldxn",
"17_22" => "ldin",
24 => "sta",
"25_30" => "sti",
31 => "stx",
32 => "stj",
33 => "stz",
1 => "add",
2 => "sub",
3 => "mul",
4 => "div",
"48_55" => "addr_transfer",
"56_63" => "cmp",
39 => "jmp_cond",
"40_47" => "jmp_reg",
7 => "move",
6 => "shift",
36 => "input",
37 => "output",
35 => "ioc",
34 => "jbus",
38 => "jred"

};

my $optab2 = {};
my @opfunc = ();

for (keys %{$optab})
{

    my $val = $optab->{$_};
    printf( "$_ => $val\n");
    push @opfunc, $val;
    if (m/(\d+)_(\d+)/)
    {
	for (my $i = $1; $i <= $2; $i++)
	{
	    add_optab2($i, $val);
	}
    }
    else
    {
	add_optab2($_, $val);
    }
}

foreach ( sort { $a <=> $b } keys %{$optab2})
{
    printf("    &X_%-16s #%02d\n", uc($optab2->{$_}) . ",", $_);
}

foreach ( sort @opfunc )
{
    printf("sub X_%s() {\n", uc($_));
    print '    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;' . "\n";
    print "    return 1;\n";
    print "}\n\n";
}

sub add_optab2
{
    my ($c, $val) = @_;

    if (exists $optab2->{$c})
    {
	print STDERR "$c exists already!\n";
	exit;
    }
    $optab2->{$c} = $val;
}
