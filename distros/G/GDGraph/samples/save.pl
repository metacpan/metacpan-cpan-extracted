sub save_chart
{
	my $chart = shift or die "Need a chart!";
	my $name = shift or die "Need a name!";

	my $ext = $chart->export_format;

	open(my $out, '>', "$name.$ext") or
		die "Cannot open '$name.$ext' for write: $!";
	binmode $out;
	print $out $chart->gd->$ext();
	close $out;
}

1;
