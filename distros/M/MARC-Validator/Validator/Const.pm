package MARC::Validator::Const;

use strict;
use utf8;
use warnings;

use Readonly;

Readonly::Hash our %FIELD_504 => (
	'cze' => qr{[rR]ejstřík},
);
Readonly::Hash our %FIELD_655 => (
	'cze' => qr{komiksy|komiksové},
);

our $VERSION = 0.13;

1;

__END__
