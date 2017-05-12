package FIX::Lite::Dictionary;

use warnings;
use strict;

my $fixDict = {};

sub load($) {
	my $ver = shift;
	if ( !defined $fixDict->{$ver} ) {

		require("FIX/Lite/$ver.pm");

		my $f = eval "FIX::Lite::${ver}::getFix()";

		##
		# parse messages,fields and components and build hashes for faster access
		#
		$f->{hMessages} = {};
		for my $a ( @{ $f->{messages} } ) {

			$f->{hMessages}->{ $a->{msgtype} } = $a;
			$f->{hMessages}->{ $a->{name} }    = $a;
		}
		$f->{hFields} = {};
		for my $a ( @{ $f->{fields} } ) {
			$f->{hFields}->{ $a->{name} }   = $a;
			$f->{hFields}->{ $a->{number} } = $a;
		}
		$f->{hComponents} = {};
		for my $a ( @{ $f->{components} } ) {
			$f->{hComponents}->{ $a->{name} } = $a;
		}

		$fixDict->{$ver} = $f;
	}
}

sub new ($) {
	my $proto = shift;

	my $class = ref($proto) || $proto;
	my $self = {};
	bless( $self, $class );
	$self = $fixDict->{FIX44};

	return $self;
}

1;
