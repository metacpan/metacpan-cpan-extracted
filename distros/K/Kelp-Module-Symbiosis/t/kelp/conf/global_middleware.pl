# Common settings
{
	middleware => [qw(ContentMD5)],

	modules => [qw/Symbiosis +TestSymbiont/],
	modules_init => {
		Symbiosis => {
			engine => 'Kelp',
		},

		TestSymbiont => {
			mount => '/test',
			middleware => [qw(ContentLength)]
		},
	}
};

