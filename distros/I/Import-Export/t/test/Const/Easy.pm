package Const::Easy;

use Const qw/all/;

sub new { bless {}, $_[0] }

sub hello {
	return thing;
}

sub listing {
	my %l = list;
	return \%l;
}

1;
