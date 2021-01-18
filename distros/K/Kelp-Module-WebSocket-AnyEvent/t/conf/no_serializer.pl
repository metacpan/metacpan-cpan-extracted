{
	modules => [qw(JSON Symbiosis WebSocket::AnyEvent)],
	modules_init => {
		JSON => {
			allow_nonref => 1,
		},
	},
}
