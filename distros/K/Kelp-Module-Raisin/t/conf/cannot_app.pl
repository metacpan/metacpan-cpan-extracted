{
	modules => [qw(Symbiosis Raisin)],
	modules_init => {
		Raisin => {
			mount => '/api',
			class => 'AppWithNoAppMethod',
		},
	},
}
