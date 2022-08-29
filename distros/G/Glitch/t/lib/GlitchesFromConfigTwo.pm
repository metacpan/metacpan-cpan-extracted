package GlitchesFromConfigTwo;

use JSON;

use Glitch (
	glitch_config => 't/glitch-two.conf',
	glitch_config_parser => sub {
		JSON->new->decode($_[0]);
	},
	glitch_logger => sub {
		print $_[0] . "\n";
	}
);

1;
