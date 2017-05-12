use Test::More tests => 15001;
BEGIN { use_ok('Graphics::ColorObject') };

foreach my $rs1 (&Graphics::ColorObject::list_rgb_spaces())
{
	foreach my $rs2 (&Graphics::ColorObject::list_rgb_spaces())
	{
		foreach my $rgb (
					  [1, 1, 1],
					  [1, 1, 0],
					  [0, 1, 1],
					  [0, 1, 0],
					  [1, 0, 1],
					  [1, 0, 0],
					  [0, 0, 1],
					  [0, 0, 0]
					  )
		{
			ok( &roundtrip_rgb_convert($rgb, $rs1, $rs2), "$rs1 -> $rs2 -> $rs1 [0-1]" );
			my $rgb1 = &Graphics::ColorObject::_mult_m33_v3([[3/4,0,0],[0,3/4,0],[0,0,3/4]], $rgb);
			ok( &roundtrip_rgb_convert($rgb1, $rs1, $rs2), "$rs1 -> $rs2 -> $rs1 [0-0.75]" );
			my $rgb2 = &Graphics::ColorObject::_add_v3(
					   &Graphics::ColorObject::_mult_m33_v3(
						   [[1/2,0,0],[0,1/2,0],[0,0,1/2]], $rgb),
						   [0.25, 0.25, 0.25]);
			ok( &roundtrip_rgb_convert($rgb2, $rs1, $rs2), "$rs1 -> $rs2 -> $rs1 [0.25-0.75]" );
		}
	}
}

sub roundtrip_rgb_convert
{
	my ($rgb, $rs1, $rs2) = @_;
	my ($c1, $c2, $c1_copy, $rgb_copy);

	# eval is only used here to save writing out a whole lot of code by hand
	# we don't really want to trap fatal errors
	$c1 = $rgb;
	eval '$c2 = Graphics::ColorObject->new_RGB($c1, space=>"'.$rs1.'")->as_RGB(space=>"'.$rs2.'")'; # s1 -> $rs2
	if ($@) { print STDERR "\n failed with fatal error: RGB $rs1 -> $rs2 : $@ \n"; return 0; };
	eval '$c1_copy = Graphics::ColorObject->new_RGB($c2, space=>"'.$rs2.'")->as_RGB(space=>"'.$rs1.'")'; # s1 -> $rs2
	if ($@) { print STDERR "\n failed with fatal error: RGB $rs2 -> $rs1 : $@ \n"; return 0; };

	my $delta = &Graphics::ColorObject::_delta_v3( $c1, $c1_copy );
	my $result = ($delta < 0.000005);
	#(&Graphics::ColorObject::_delta_v3( $c1, $c1_copy ) < 0.001 * ($c1->[0]+$c1->[1]+$c1->[3]));

	#print STDERR "$rs1 -> $rs2 -> $rs1 : ", ($result  ? 'ok' : 'not ok'), "\n";
	if (! $result)
	{
		print STDERR "\nroundtrip conversion failed : $rs1 -> $rs2 -> $rs1 : ";
		print STDERR "$rs1=[ $c1->[0], $c1->[1], $c1->[2] ] -> ";
		print STDERR "$rs2=[ $c2->[0], $c2->[1], $c2->[2] ] -> ";
		print STDERR "$rs1=[ $c1_copy->[0], $c1_copy->[1], $c1_copy->[2] ]";
		print STDERR "\n delta=$delta\n";
	}

	return $result;
}
