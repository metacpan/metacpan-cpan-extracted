
package Foo;

use strict;
use Eixo::Base::Clase 'Eixo::Base::Singleton';

has(

	a=>undef,
	b=>2,
	c=>3,

);

sub initialize{

	#$_[0]->SUPER::initialize(@_[1..$#_]);

	$_[0]->a(1);

}

__PACKAGE__->make_singleton();

package Foo2;

use strict;
use Eixo::Base::Clase 'Eixo::Base::Singleton';

has(

	a=>10,
	b=>20,
	c=>30

);

__PACKAGE__->make_singleton();

package Main;

use t::test_base;
BEGIN{use_ok("Eixo::Base::Singleton")}

ok(Foo->a == 1, 'Accessors seem right');
ok(Foo2->a == 10, 'Accessors seem right');

Foo->a(3);

ok(Foo->a == 3, 'Changes propagate across the system');
ok(Foo2->a == 10, 'Changes propagate across only the singleton');

Foo2->b(22);

ok(Foo2->b == 22, "Changes work in all the singleton separattedly");

Foo2->make_singleton;

ok(Foo2->b == 22, "make_singleton is idempotent");


#
# fork e signals don't work in windows
#
use Config;

unless($Config{'osname'} eq 'MSWin32'){
    if(my $pid = fork){
    
    	my $ok_value = 0;
    
    	$SIG{USR1} = sub {
    
    		$ok_value = 1;
    	};
    
    	waitpid($pid, 0);
    
    	ok($ok_value, "Forks respect singleton values");
    
    }
    else{
    	eval{
    
    		Foo2->make_singleton;
    
    		if(Foo2->b == 22){
    
    			kill("USR1", getppid());
    
    		}
    	};
    
    	exit 0;
    }
}


done_testing();
