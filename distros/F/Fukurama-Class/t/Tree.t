#!perl -T
use Test::More tests => 11;
use strict;
use warnings;

use Fukurama::Class::Tree();
my $t = 'Fukurama::Class::Tree';
our $TEST_COUNTER;
BEGIN {
	my $BUILD = sub {
		my $classname = $_[0];
		my $def = $_[1];
		$def->{'test'} = 1 if($classname =~ /^My/);
	};
	my $CHECK = sub {
		my $classname = $_[0];
		my $def = $_[1];
		$main::TEST_COUNTER++ if($def->{'test'});
	};
	
	Fukurama::Class::Tree->register_build_handler($BUILD);
	Fukurama::Class::Tree->register_check_handler($CHECK);
}
{
	package MyA;
	sub new {}
	sub import {}
	sub DESTROY {}
}
{
	package MyB;
	use base 'MyA';
}
{
	package MyC;
	use base 'MyB';
}
{
	package MyD;
	use base 'MyA';
	use base 'MyC';
}
{
	package MyE;
	use base 'MyB';
	use base 'MyD';
}
{
	package MyF;
	use base 'MyE';
	use base 'MyD';
	use base 'MyC';
	
	BEGIN {
		my $old = $SIG{__WARN__};
		$SIG{__WARN__} = sub {
			if($_[0] =~ /^Deep recursion on subroutine "Fukurama::Class::Tree::_read_class"/) {
				main::fail('Endless recursion in Tree.pm by searching for all classes');
				exit();
			}
			goto &$old if(ref($old) eq 'CODE');
			return;
		};
	}
	eval {
		
		#local $SIG{'
		
		no warnings 'once';
		no warnings 'uninitialized';
		
		__PACKAGE__->$NOTEXISTING_CLASS::notexisting_sub;
	};
	main::like($@, qr/object method ""/, 'access to notexisting sub');
}

my $paths = $t->get_inheritation_path('MyF');
is(scalar(@$paths), 3, 'inheritation-pathes');
is_deeply($paths->[0], ['MyE', 'MyB', 'MyA'], 'path one');
is_deeply($paths->[1], ['MyE', 'MyD', 'MyA'], 'path two');
is_deeply($paths->[2], ['MyE', 'MyD', 'MyC', 'MyB', 'MyA'], 'path three');

my @subs = $t->get_class_subs('MyA');
is_deeply(\@subs, ['new'], 'get subs without specials');

is($t->is_special_sub('import'), 1, 'detect special sub');
is($t->is_special_sub('Import'), 0, 'detect normal sub');

is($TEST_COUNTER, 6, 'all classes build and checked');

$t->run_check();
is($TEST_COUNTER, 12, 'all classes build and checked twice');
$t->run_check();
is($TEST_COUNTER, 12, 'all classes build and checked not a third time');
