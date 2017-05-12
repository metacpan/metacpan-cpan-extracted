
sub test_hs_return {
	my ($code, $returns) = @_;
	my @returns = @{$returns};

	my $hs = new Language::Homespring();
	$hs->parse($code);

	for(@returns){
		my $out = $hs->tick();
		if ($_ ne $out){
			print qq!expected "$_", got "$out"\n!;
			return 0;
		}
	}
	return 1;
}

1;

