package Demo_Importer;
$VERSION = '0.01';

use Filter::Simple;

sub import { 
	use Data::Dumper 'Dumper';
	print Dumper [ caller 0 ];
	print Dumper [ @_ ];
}

FILTER {
	s/dye/die/g;
}
