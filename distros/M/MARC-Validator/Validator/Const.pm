package MARC::Validator::Const;

use strict;
use utf8;
use warnings;

use Readonly;

Readonly::Array our @FIELD_300ab_BAD => (
	'cm',
	'mm',
	'°',
);
Readonly::Hash our %FIELD_500 => (
	'cze' => {
		# Not QR ... [rR]ejstřík
		# Not [rR]ejstřík není
		'index' => qr{\A(?!.*\bQR\b)(?s:.*?)[rR]ejstřík(?!\s+není\b)},
	},
);
Readonly::Hash our %FIELD_504 => (
	'cze' => {
		'index' => qr{[rR]ejstřík},
	},
);
Readonly::Hash our %FIELD_655 => (
	'cze' => {
		'comics' => qr{komiksy|komiksové|manga},
		'textbook' => qr{učebnice},
	},
);

our $VERSION = 0.17;

1;

__END__
