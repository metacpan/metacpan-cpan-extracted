use strict ;
use Test ;

sub test {
	my $l = shift ;

	Inline::Select->bind(
		PACKAGE => 'Calc',
		Inline => $l,
	) ;

	my $c = new Calc() ;
	ok($c->language(), $l) ;
	ok($c->add(2, 3), 5) ;
}


1 ;
