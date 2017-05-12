#!/usr/bin/perl
use strict;
use warnings;
use lib qw{./lib};
use My::Fuz;

=head1 NAME

Method-Autoload-example.pl - Method::Autoload Example

=cut

my $obj=MyPackage->new(packages=>[qw{My::Foo My::Bar My::Baz My::Fuz My::Zuz}]);
printf "Search Packages: %s\n", join(",", $obj->packages);
printf "foo: %s\n", $obj->foo; #in line package with duplicate method
printf "bar: %s\n", $obj->bar; #in line package
printf "baz: %s\n", $obj->baz; #lib loaded from file
printf "fuz: %s\n", $obj->fuz; #lib loaded used by script

printf "foo: %s\n", $obj->foo; #autoloaded
printf "bar: %s\n", $obj->bar; #autoloaded
printf "baz: %s\n", $obj->baz; #autoloaded
printf "fuz: %s\n", $obj->fuz; #autoloaded

print map {sprintf("Autoloaded: %s => %s\n", $_, $obj->autoloaded->{$_})}
        sort keys %{$obj->autoloaded};

package MyPackage;
use strict;
use warnings;
use base qw{Method::Autoload};
1;

package My::Foo;
use strict;
use warnings;
sub foo {"My::Foo::foo"};
1;

package My::Bar;
use strict;
use warnings;
sub foo {"My::Bar::foo"};
sub bar {"My::Bar::bar"};
1;
