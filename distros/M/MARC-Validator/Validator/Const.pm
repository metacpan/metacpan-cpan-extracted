package MARC::Validator::Const;

use strict;
use utf8;
use warnings;

use Readonly;

Readonly::Hash our %FIELD_504 => (
	'cze' => qr{[rR]ejstřík},
);
Readonly::Hash our %FIELD_655 => (
	'cze' => qr{komiksy|komiksové|manga},
);

our $VERSION = 0.14;

1;

__END__
