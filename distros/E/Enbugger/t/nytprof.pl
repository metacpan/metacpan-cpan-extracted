use lib          qw( ./t/ );

require 'reset_perms.pl';
require Enbugger;
Enbugger->load_debugger( 'NYTProf' );

a();
b() for 1 .. 100;
c();

sub a { 1 for 1 .. 100 }
sub b { 1 for 1 .. 10  }
sub c { d() for 1 .. 10 }
sub d { 1 for 1 .. 10 }
