our $sub = sub { print "snack\n" };

{
package foo;


*sub = \$main::sub;


}

$foo::sub->();
