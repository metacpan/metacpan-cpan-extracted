	my $_exit = 1;
	$_M ||= "Mozilla::Mechanize::GUITester";
	eval "use $_M";
SKIP: {
	skip "No $_M installed", $_T if $@;
	$_exit = undef;
};
	exit if $_exit;

