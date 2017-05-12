package Demo2b;
$VERSION = '0.01';

use Filter::Simple sub {
	print "[$_]\n";
	s/(\$[a-z])/\L$1/g;
};

1;
