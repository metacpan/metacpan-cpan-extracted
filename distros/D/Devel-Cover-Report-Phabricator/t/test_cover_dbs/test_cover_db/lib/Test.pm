=head1 NAME

MODULE

=head1 DESCRIPTION

=head1 AUTHOR

mikec

=cut

package Test;

BEGIN {
	1;
	2;
	3;
}

use strict;
use warnings;

sub foo {
	1;
	2;
	return;
	4;
}

sub bar {
	foo(); 1; 2;
	foo();
}

1;
