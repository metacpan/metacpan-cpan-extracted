# Common settings
{
	modules => [qw/Symbiosis +TestSymbiont +AnotherTestSymbiont/],
	modules_init => {
		Symbiosis => {
			engine => 'Kelp',
		},

		AnotherTestSymbiont => {
			mount => '/test/test2',
		},
	}
};

