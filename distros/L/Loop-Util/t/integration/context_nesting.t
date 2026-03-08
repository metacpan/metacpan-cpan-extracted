use Test2::V0;
use Loop::Util;

{
	my @out;
	my @arr = (0..1);
	
	loop(3) {
		for (@arr) {
			push @out, __IX__;
		}
	}
	
	is( \@out, [qw/ 0 1 0 1 0 1 /] );
}

{
	my @out;
	my @arr = (0..2);
	
	loop(2) {
		for (@arr) {
			push @out, __IX__;
		}
	}
	
	is( \@out, [qw/ 0 1 2 0 1 2 /] );
}

{
	my @out;
	my @arr = (0..2);
	
	for (@arr) {
		loop(2) {
			push @out, __IX__;
		}
	}
	
	is( \@out, [qw/ 0 1 0 1 0 1 /] );
}

{
	my @out;
	my @arr = (0..1);
	
	for (@arr) {
		loop(3) {
			push @out, __IX__;
		}
	}
	
	is( \@out, [qw/ 0 1 2 0 1 2 /] );
}

done_testing;
