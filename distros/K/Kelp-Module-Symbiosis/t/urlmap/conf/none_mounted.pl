# Common settings
{
	modules => [qw/Symbiosis +TestSymbiont +AnotherTestSymbiont/],
	modules_init => {
		Symbiosis => {
			mount => undef,
		},
	}
};
