package t::Exp1;

use warnings;
use strict;

use Lexical::Var ();

our $VERSION = "1.10";

sub import {
	my $exporter = shift;
	my $importer = caller(0);
	no strict "refs";
	foreach(@_) {
		if($_ eq "foo") {
			*{"${importer}::foo"} = sub () { "FOO" };
		} elsif($_ eq "bar") {
			Lexical::Var->import("&bar" => sub () { "BAR" });
		} elsif($_ eq "baz") {
			eval "package $importer; use constant baz => 'BAZ';";
		} else {
			die "$_ is not exported by the $exporter module";
		}
	}
}

1;
