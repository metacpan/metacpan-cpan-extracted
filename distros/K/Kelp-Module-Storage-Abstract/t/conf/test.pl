{
	modules => [qw(Storage::Abstract)],
	modules_init => {
		'Storage::Abstract' => {
			driver => 'memory',
			public_routes => {
				'/publicurl' => '/public',
			},
			kelp_extensions => 1,
		},
	},
}

