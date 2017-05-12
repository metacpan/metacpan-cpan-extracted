use Graphics::Simple;

@Graphics::Simple::DefSize = (500,500);

set_elem(0,0,1,1);
set_elem(1,0,1,1);
# set_elem(10,10,1);

sub set_elem {
	my($x, $y, $v, $sure) = @_;
	return if not $sure and rand > 0.99;
	return if $val{"$x,$y"} == $v;
	push @chg, [$x, $y, $v-$val{"$x,$y"}];
	$val{"$x,$y"} = $v;
#	print "SET $x $y $v\n";
	if($v) {
		circle($x*3+250,$y*3+250,1);
	}
}

while(1) {
	for my $c (@chg) {
#		print "CH: @$_\n";
		for my $x (map {$c->[0] + $_} -1,0,1) {
			for my $y (map {$c->[1] + $_} -1,0,1) {
				next if !$x and !$y;
				$neigh{"$x,$y"} += $c->[2];
#				print "NEI $x $y: ",$neigh{"$x,$y"},"\n";
				push @next, [$x, $y] if
					$neigh{"$x,$y"} == 2;
			}
		}
	}
	@chg = ();
	for(@next) { 
#		print "NEX: @$_|",$neigh{"$_->[0],$_->[1]"},"\n";
		if($neigh{"$_->[0],$_->[1]"} == 2) {
			set_elem($_->[0], $_->[1], 1);
			push @nnext, $_ if !$val{"$_->[0],$_->[1]"};
		}
	}
	@next = @nnext;
	stop();
}

