# Common settings
{
	modules => [qw/Symbiosis +TestSymbiont +AnotherTestSymbiont/],
	modules_init => {
		Symbiosis => {
			mount => '/s',
		},
		AnotherTestSymbiont => {
			mount => '/test/test2',
		},
	}
};
