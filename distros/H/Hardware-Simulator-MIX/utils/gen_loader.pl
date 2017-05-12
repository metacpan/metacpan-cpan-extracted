my $str;
while (<STDIN>) {
	if (m/\[(.*)\]/) {
		$str .= $1;
		print $1;
		if (length($str) == 80) {
			print "\n";
			$str = "";
		}
	}
}
