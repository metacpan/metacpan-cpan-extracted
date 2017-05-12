package Level2;
use strict;
use warnings;
use lib
		'../lib',
		'lib',
	;
use Level3;
#~ print Level3->check_return . "\n"; # expose this line to see the Level3 behaviour with no source filter

sub check_return{
	my $return = Level3->check_return . ' - ';
	###SpecialCase return $return . 'Level2 SpecialCase uncovered';
	###Health return $return . 'Level2 Healing uncovered';
	return $return . 'No Level2 uncovering occured';
}

1;