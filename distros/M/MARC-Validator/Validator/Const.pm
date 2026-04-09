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
Readonly::Hash our %FIELD_504 => (
	'cze' => qr{[rR]ejstřík},
);
Readonly::Hash our %FIELD_655 => (
	'cze' => qr{komiksy|komiksové|manga},
);

our $VERSION = 0.15;

1;

__END__
