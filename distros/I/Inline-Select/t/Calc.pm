package Calc ;

sub new {
	my $class = shift ;
	bless({}, $class) ;
}

sub add {
	my $this = shift ;
	my $a = shift ;
	my $b = shift ;

	return $a + $b ;
}


sub language {
	return "Perl" ;
}


1 ;
