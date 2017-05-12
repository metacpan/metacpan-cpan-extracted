package Demo2a;
$VERSION = '0.01';

use Filter::Simple sub {
	s/(\$[a-z])/\U$1/g;
};

1;
