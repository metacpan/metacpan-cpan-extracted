package main ;
use strict ;

sub whats_your_name {
	return "perl" ;
}


sub sum_array_list {
	my $a = shift ;

	my $sum = 0 ;
	for (my $i = 0 ; $i < $a->size() ; $i++){
		$sum += $a->get($i) ;
	}

	return $sum ;
}

1 ;
