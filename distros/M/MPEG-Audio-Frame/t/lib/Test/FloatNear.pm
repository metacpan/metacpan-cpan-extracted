#!/usr/bin/perl -w

package Test::FloatNear;

use strict;

use base qw/Exporter/;
use vars qw/@EXPORT/;

@EXPORT = qw/is_near/;

sub is_near ($$;@) {
	my ($got, $expected) = (shift, shift);
	@_ = (abs($got - $expected), "<", 0.001, @_);
	goto \&Test::More::cmp_ok;
}

__PACKAGE__

__END__
