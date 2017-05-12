package Abstract::MyAbstractClass;
use Fukurama::Class::Abstract;
sub new { bless({}, $_[0]) }
sub create { 1 }
sub import {
	$main::IMPORT++;
}
sub get {

	my $i = 0;
	while(my @c = caller($i++)) {
		push(@main::CALLER, \@c);
	}
	$_[1] || 2;
}
sub END {
	push(@$main::REGISTER, 'END');
}
1;