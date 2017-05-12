# watch -*-perl-*-

use strict;
use Test; plan test => 6;
use Event qw(loop unloop);

# $Event::DebugLevel = 2;

my $var1 = 1;
my $var2 = 3;
my $var3 = 0;

Event->var(var => \$var1, cb =>
	   sub {
	       my $var = shift->w->var;
	       ok $$var, 2;
	       $var2++;
	   },
	   desc => "var1"
);

Event->var(var => \$var1, cb => sub { ok $var1, 2 });

Event->var(var => \$var2, cb =>
	   sub {
	       $var3 = 3;
	       ok $var2, 4;
	       unloop;
	   },
	   desc => "var2");

Event->var(var => \$var3, async => 1, cb => sub { ok $var3, 3; });

Event->idle(cb => sub {
		ok $var1, 1;
		$var1++;
	    });

my $var4 = 0;
my $e = Event->var(poll => 'r', var => \$var4, cb => sub {
		       my $e = shift;
		       ok $e->hits, 1;
		   });
my $str = "$var4";  #read
$var4 = 5;          #write

loop;
