use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');
	sub ACTION_dist {
		my $self = shift;
		eval {
			use Pod::Text;
			print "Creating the README file.\n";
			my $parser = Pod::Text->new();
			$parser->parse_from_file('lib/IO/Socket/Multicast6.pm', 'README');
		};
		$self->SUPER::ACTION_dist(@_);
	}
EOF


my $build = $class->new
(
	module_name => 'IO::Socket::Multicast6',
	license => 'perl',
	build_requires => {
		'Module::Build' 	=> '0.20'
	},
	requires => {
		'perl'					=> '5.6.1',
		'Socket'				=> 0,
		'Test::More'			=> 0,
		'Socket6'				=> 0.19,
		'IO::Interface'			=> 1.01,
		'Socket::Multicast6'	=> '0.01',
		'IO::Socket::INET6'		=> '2.51',
	},
);

$build->create_build_script;
