use 5.010001;
use Math::Complex;
use Math::Polynomial::Solve qw(:utility);
use Math::Utils qw(:polynomial :compare);

my $fltcmp = generate_fltcmp(2.5e-7);

sub allzeroes
{
	my($p_ref, @xvals) = @_;
	my @yvals = grep {&$fltcmp($_, 0) != 0} pl_evaluate($p_ref, @xvals);
	return (scalar @yvals)? 0: 1;
}

sub sumof
{
	my $x = cplx(0,0);
	for (@_){$x += $_};
	return $x;
}

sub prodof
{
	my $x = cplx(1,0);
	for (@_){$x *= $_};
	return $x;
}

#
# returns 0 (equal) or 1 (not equal). There's no -1 value, unlike other cmp functions.
#
sub polycmp
{
	my($p_ref1, $p_ref2) = @_;

	my @polynomial1 = @$p_ref1;
	my @polynomial2 = @$p_ref2;

	return 1 if (scalar @polynomial1 != scalar @polynomial2);

	for my $c1 (@polynomial1)
	{
		my $c2 = shift @polynomial2;
		return 1 if (&$fltcmp($c1, $c2) != 0);
	}

	return 0;
}

sub polychain2str
{
	my(@chain) = @_;
	my $str = "";
	for my $j (0..$#chain)
	{
		my @c = @{$chain[$j]};
		$str .= sprintf("    f%2d: [", $j) . join(", ", @c) . "]\n";
	}
	return $str;
}


sub cartesian_format_signed($$@)
{
	my($fmt_re, $fmt_im, @numbers) = @_;
	my(@cfn, $n, $r, $i, $s);

	$fmt_re ||= "%.15g";	# Provide a default real format
	$fmt_im ||= "%.15gi";	# Provide a default im format

	for $n (@numbers)
	{
		#
		# Is the number part of the Complex package?
		#
		if (ref($n) eq "Math::Complex")
		{
			$r = sprintf($fmt_re, Re($n));
			$i = sprintf($fmt_im, abs(Im($n)));
			$s = ('+', '+', '-')[Im($n) <=> 0];
		}
		else
		{
			$r = sprintf($fmt_re, $n);
			$i = sprintf($fmt_im, 0);
			$s = '+';
		}

		push @cfn, $r . $s . $i;
	}

	return wantarray? @cfn: $cfn[0];
}

sub cartesian_format($$@)
{
	my($fmt_re, $fmt_im, @numbers) = @_;
	my(@cfn, $n, $r, $i);

	$fmt_re ||= "%.15g";		# Provide a default real format
	$fmt_im ||= " + %.15gi";	# Provide a default im format

	for $n (@numbers)
	{
		#
		# Is the number part of the Complex package?
		#
		if (ref($n) eq "Math::Complex")
		{
			$r = sprintf($fmt_re, Re($n));
			$i = sprintf($fmt_im, Im($n));
		}
		else
		{
			$r = sprintf($fmt_re, $n);
			$i = sprintf($fmt_im, 0);
		}

		push @cfn, $r . $i;
	}

	return wantarray? @cfn: $cfn[0];
}

sub rootprint
{
	my $i = 0;
	my $line = "";
	for (@_)
	{
		$line .= "\tx[$i] = " . cartesian_format(undef, undef, $_) . "\n";
		$i++;
	}
	print STDERR "\n", $line;
}

sub rootformat
{
	my @fmtlist;
	for (@_)
	{
		push @fmtlist, cartesian_format(undef, undef, $_);
	}
	return "[ " . join(", ", @fmtlist) . " ]";
}

1;
