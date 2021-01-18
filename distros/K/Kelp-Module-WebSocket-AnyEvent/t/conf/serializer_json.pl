{
	modules => [qw(JSON Symbiosis WebSocket::AnyEvent)],
	modules_init => {
		'WebSocket::AnyEvent' => {
			serializer => 'json',
		},
		JSON => {
			canonical => 1,
		},
	},
}
