package Heap::Fibonacci::Fast;

our $VERSION = '0.0101';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new{
	my $class = shift;
	my $type = shift;

	if (
		!defined $type
			||
		$type eq 'min'
	){
		return $class->new_minheap();

	}elsif ($type eq 'max'){
		return $class->new_maxheap();

	}elsif ($type eq 'code'){
		return $class->new_codeheap(shift);

	}else{
		die "Unknown type supplied: $type";
	}
}


1;
