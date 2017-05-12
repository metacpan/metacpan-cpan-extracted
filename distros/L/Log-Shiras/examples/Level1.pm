package Level1;
use strict;
use warnings;
use lib
		'../lib',
		'lib',
	;
use Level2;

#~ print Level2->check_return . "\n"; # expose this line to see the Level2 behaviour with no source filter
sub check_return{
	my $return = Level2->check_return . ' - ';
	###SpecialCase return $return . 'Level1 SpecialCase uncovered';
	###Family return $return . 'Level1 Joy uncovered';
	return $return . 'No Level1 uncovering occured';
}

1;