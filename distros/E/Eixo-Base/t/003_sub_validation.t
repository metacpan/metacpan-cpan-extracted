use t::test_base;

BEGIN{use_ok("Eixo::Base::Util")}

sub sum : Sig(i,i) {
	
	$_[0] + $_[1];	

}

sub concat : Sig(s, ARRAY) {

	map { $_[0] .$_ } @{$_[1]};
}

is(&sum(20, 20), 40, 'Normal call works perfectly');

$@ = undef;
eval{
	&sum(0.2, {});
};

ok($@, 'Invalid arguments are controlled');


my @cadenas = qw(a b c d e f g h i j k l m n );

is(scalar(grep {

	$_ =~ /^L_/

} &concat('L_', \@cadenas)), @cadenas, 'Concatenations work perfectly');




done_testing();
