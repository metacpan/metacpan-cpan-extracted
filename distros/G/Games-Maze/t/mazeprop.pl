use Games::Maze;

sub logfailure
{
	my($obj) = @_;
	my($failure) = "failed.log";
	my($hex_print) = 1;

	open(FAIL, "> $failure") or die "Couldn't open log file $failure: $!";

	my $asc = $obj->to_ascii();
	print FAIL "x", $asc, "x\n";
	if ($hex_print)
	{
		my $xlvls = $obj->to_hex_dump();
		print FAIL $xlvls;
	}

	my %p = $obj->describe();

	foreach (sort keys %p)
	{
		if (ref $p{$_} eq "ARRAY")
		{
			print FAIL "$_ => [", join(", ", @{$p{$_}}), "]\n";
		}
		else
		{
			print FAIL "$_ => ", $p{$_}, "\n";
		}
	}
	print FAIL "\n";
	%p = $obj->internals();

	print FAIL "$_ => ", $p{$_}, "\n" foreach (sort keys %p);
	print FAIL "\n";
	close FAIL;
}

