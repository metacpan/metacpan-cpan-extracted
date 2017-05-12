package Main;

use Test::More;

use_ok("Eixo::Base::Data");

my $data = Foo->get;

my @lines = split(/\n/, $data);

ok($lines[0] eq "string test", "Line1 is ok");
ok($lines[1] eq "string test2", "Line2 is ok");
ok($lines[2] eq "string test3", "Line3 is ok");

$data = Foo->get;

@lines = split(/\n/, $data);

ok($lines[0] eq "string test", "Line1 is ok");
ok($lines[1] eq "string test2", "Line2 is ok");
ok($lines[2] eq "string test3", "Line3 is ok");


done_testing();


package Foo;

use strict;

sub get{

	&Eixo::Base::Data::getData(__PACKAGE__);
}




__DATA__
string test
string test2
string test3
