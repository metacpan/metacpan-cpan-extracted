# These are the files on which we do substitutionization.
use vars qw($subst_files);
$subst_files = {
		'wrapper.IN' => 'wrapper',
		'launche.IN' => 'launche',
		'DB.IN' => 'DB.pm',
		'test.IN' => 'test.env',
		'profile.IN' => 'etc/login/dot.profile',
		'login.IN' => 'etc/login/dot.login',
		'envy.IN' => 'envy.pl',
	    };

1;
