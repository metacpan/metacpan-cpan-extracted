package Test;

use Filter::PPI::Transform 'TestTransform', sub { s/(\d+)/$1_/ };

sub func1
{
	return 'func1';
}

sub func2
{
	return 'func2';
}

1;
