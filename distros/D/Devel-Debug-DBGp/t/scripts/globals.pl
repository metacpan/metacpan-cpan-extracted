package foo;

use vars qw($ffoo @fbar %fbaz $fundef);

use constant moo => 1; # this creates a special symbol table entry

$ffoo = 123;
@fbar = (1, 2);
%fbaz = (a => 1);

sub foo {
    $DB::single = 1;

    1; # to avoid immediate return
}

package bar;

sub baz { } # extraneous typeglob

sub bar {
    $DB::single = 1;

    1; # to avoid immediate return
}

package bar::moo; # another extraneous typeglob

package main;

use vars qw($mfoo @mbar %mbaz);

foo::foo();
bar::bar();

1; # to avoid the program terminating
