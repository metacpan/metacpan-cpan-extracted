package Our::Simple;

use Our qw/$scalar %hash @array/;

sub thing {
	join '-', $scalar, map { sprintf "%s => %s", $_, $hash{$_} } keys %hash, join ',', @array;
}

1;
