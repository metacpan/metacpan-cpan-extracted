#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Eshu;

# Benchmark Eshu indentation engines
# Usage: perl bench/bench.pl [iterations]

my $iterations = $ARGV[0] || 100;

# Generate a sizeable C source
my $c_src = generate_c(500);
# Generate a sizeable Perl source
my $pl_src = generate_pl(500);
# Generate a sizeable XS source
my $xs_src = generate_xs(100);

printf "Benchmark: %d iterations each\n", $iterations;
printf "C source:    %d lines (%d bytes)\n", scalar(() = $c_src =~ /\n/g), length($c_src);
printf "Perl source: %d lines (%d bytes)\n", scalar(() = $pl_src =~ /\n/g), length($pl_src);
printf "XS source:   %d lines (%d bytes)\n", scalar(() = $xs_src =~ /\n/g), length($xs_src);
print "-" x 50, "\n";

bench("indent_c",  sub { Eshu->indent_c($c_src) });
bench("indent_pl", sub { Eshu->indent_pl($pl_src) });
bench("indent_xs", sub { Eshu->indent_xs($xs_src) });

sub bench {
	my ($label, $code) = @_;
	my $t0 = [gettimeofday];
	for (1 .. $iterations) {
		$code->();
	}
	my $elapsed = tv_interval($t0);
	printf "%-12s %8.3f ms total  %8.3f ms/iter\n",
		$label, $elapsed * 1000, ($elapsed / $iterations) * 1000;
}

sub generate_c {
	my ($funcs) = @_;
	my $out = "#include <stdio.h>\n\n";
	for my $i (1 .. $funcs) {
		$out .= "void func_$i(int arg) {\n";
		$out .= "    int x = arg + $i;\n";
		$out .= "    if (x > 0) {\n";
		$out .= "        printf(\"%d\\n\", x);\n";
		$out .= "        for (int j = 0; j < x; j++) {\n";
		$out .= "            x += j;\n";
		$out .= "        }\n";
		$out .= "    } else {\n";
		$out .= "        x = -x;\n";
		$out .= "    }\n";
		$out .= "}\n\n";
	}
	return $out;
}

sub generate_pl {
	my ($subs) = @_;
	my $out = "package Bench;\nuse strict;\nuse warnings;\n\n";
	for my $i (1 .. $subs) {
		$out .= "sub func_$i {\n";
		$out .= "    my (\$self, \$arg) = \@_;\n";
		$out .= "    my \$x = \$arg + $i;\n";
		$out .= "    if (\$x > 0) {\n";
		$out .= "        for my \$j (0 .. \$x) {\n";
		$out .= "            \$x += \$j;\n";
		$out .= "        }\n";
		$out .= "    } else {\n";
		$out .= "        \$x = -\$x;\n";
		$out .= "    }\n";
		$out .= "    return \$x;\n";
		$out .= "}\n\n";
	}
	$out .= "1;\n";
	return $out;
}

sub generate_xs {
	my ($xsubs) = @_;
	my $out = "#include \"EXTERN.h\"\n#include \"perl.h\"\n#include \"XSUB.h\"\n\n";
	$out .= "MODULE = Bench  PACKAGE = Bench\n\n";
	for my $i (1 .. $xsubs) {
		$out .= "int\n";
		$out .= "func_$i(arg)\n";
		$out .= "    int arg\n";
		$out .= "    PREINIT:\n";
		$out .= "        int x;\n";
		$out .= "    CODE:\n";
		$out .= "        x = arg + $i;\n";
		$out .= "        if (x > 0) {\n";
		$out .= "            x = x * 2;\n";
		$out .= "        }\n";
		$out .= "        RETVAL = x;\n";
		$out .= "    OUTPUT:\n";
		$out .= "        RETVAL\n\n";
	}
	return $out;
}
