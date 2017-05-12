#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 5 }

use Mac::Files;

SKIP: {
#	skip "Mac::Files Constants", 5;

	my $total = 207 - 26;  # 181 ... keep this updated manually
	my @syms  = sort grep { /^(?:k|kio|fs|asi)[A-Z]\w+$/ } @Mac::Files::EXPORT;
	my $bad = my $good = my $bade = my $goode = 0;

	for my $sym (@syms) {
		no strict 'refs';
		if (defined &{'Mac::Files::' . $sym}) {
			$good++;
		} else {
			$bad++;
		}

		if (defined &{$sym}) {
			$goode++;
		} else {
			$bade++;
		}
	}

	is(scalar @syms, $total,                                  "Count constants");
	is($good,  $total,                                        "Count good");
	is($goode, $total,                                        "Count good exports");
	is($bad,   0,                                             "Count bad");
	is($bade,  0,                                             "Count bad exports");
}

__END__
