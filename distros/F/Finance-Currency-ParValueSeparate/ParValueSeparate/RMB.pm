package Finance::Currency::ParValueSeparate::RMB;
use base 'Finance::Currency::ParValueSeparate';

sub currency_name { 'RMB' }
sub dollar {
	return qw( 100 50 20 10 5 2 1 );
}
sub cent {
	return qw( 50 20 10 5 2 1 );
}

1;