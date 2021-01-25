use Sereal::Encoder qw(SRL_SNAPPY);

{
	modules => [qw(Sereal)],
	modules_init => {
		Sereal => {
			encoder => {
				sort_keys => 1,
				compress => SRL_SNAPPY,
			},
			decoder => {
				incremental => 1,
			},
		},
	},
}
