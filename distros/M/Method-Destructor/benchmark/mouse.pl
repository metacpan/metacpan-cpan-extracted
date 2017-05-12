#!perl -w

use strict;
use Benchmark qw(:all);

BEGIN{
	package BaseClass;
	use Mouse;

	sub DEMOLISH{
		my $i = 0;
		$i++;
	}

	__PACKAGE__->meta->make_immutable();
}

BEGIN{
	package UseMD;
	use Mouse;
	use Method::Destructor;

	extends 'BaseClass';

	sub DEMOLISH{
		my $i = 0;
		$i++;
	}

	__PACKAGE__->meta->make_immutable(inline_destructor => 0);

	package UseMD2;
	use Mouse;
	use Method::Destructor;

	extends 'UseMD';

	# no DEMOLISH method

	__PACKAGE__->meta->make_immutable(inline_destructor => 0);

	package UseMD3;
	use Mouse;
	use Method::Destructor;

	extends 'UseMD2';

	sub DEMOLISH{
		my $i = 0;
		$i++;
	}

	__PACKAGE__->meta->make_immutable(inline_destructor => 0);
}

BEGIN{
	package UseMouse;
	use Mouse;

	extends 'BaseClass';

	sub DEMOLISH{
		my $i = 0;
		$i++;
	}

	__PACKAGE__->meta->make_immutable(inline_destructor => 1);

	package UseMouse2;
	use Mouse;

	extends 'UseMouse';

	# no DEMOLISH method

	__PACKAGE__->meta->make_immutable(inline_destructor => 1);

	package UseMouse3;
	use Mouse;

	extends 'UseMouse2';

	sub DEMOLISH{
		my $i = 0;
		$i++;
	}
	__PACKAGE__->meta->make_immutable(inline_destructor => 1);
}

print "Level 1:\n";
cmpthese -1 => {
	'M::D' => sub{
		for(1 .. 100){
			UseMD->new();
		}
	},
	Mouse => sub{
		for(1 .. 100){
			UseMouse->new();
		}
	},
};

print "Level 2:\n";
cmpthese -1 => {
	'M::D' => sub{
		for(1 .. 100){
			UseMD2->new();
		}
	},
	Mouse => sub{
		for(1 .. 100){
			UseMouse2->new();
		}
	},
};

print "Level 3:\n";
cmpthese -1 => {
	'M::D' => sub{
		for(1 .. 100){
			UseMD3->new();
		}
	},
	Mouse => sub{
		for(1 .. 100){
			UseMouse3->new();
		}
	},
};
