
sub must_die(&$$) {
	my ( $sub, $re, $name, $passed ) =
		( @_, 0 );
	local $SIG{__WARN__}=sub { 1; };
	my $msg;
	local $SIG{__DIE__} =sub { $msg = "@_"; die "@_"; };
	eval {
		$sub->();
		fail("$name: did not die");
		1;
	} && return;
	like($msg,$re,$name);
};
1;
