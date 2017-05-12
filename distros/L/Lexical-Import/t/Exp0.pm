package t::Exp0;

use warnings;
use strict;

my $shared_scalar = 100;

sub import {
	my $exporter = shift;
	my $importer = caller(0);
	no strict "refs";
	push @_, qw(successor predecessor) unless @_;
	foreach(@_) {
		if($_ eq "successor") {
			*{"${importer}::successor"} = sub ($) { $_[0] + 1 };
		} elsif($_ eq "predecessor") {
			*{"${importer}::predecessor"} = sub ($) { $_[0] - 1 };
		} elsif($_ eq "\$blank") {
			*{"${importer}::blank"} = \undef;
		} elsif($_ eq "\$zero") {
			*{"${importer}::zero"} = \0;
		} elsif($_ eq "\$one") {
			*{"${importer}::one"} = \1;
		} elsif($_ eq "\$two") {
			*{"${importer}::two"} = \2;
		} elsif($_ eq "\@aaa") {
			*{"${importer}::aaa"} = [qw(a a a)];
		} elsif($_ eq "%hhh") {
			*{"${importer}::hhh"} = {h=>"hh"};
		} elsif($_ eq ":letters") {
			foreach my $l (qw(A B C D E)) {
				my $ll = $l.$l;
				*{"${importer}::$l"} = sub () { $ll };
			}
		} elsif($_ eq ":multi") {
			*{"${importer}::multi"} = \"multi scalar";
			*{"${importer}::multi"} = [qw(multi array)];
			*{"${importer}::multi"} = {multi=>"hash"};
			*{"${importer}::multi"} = sub () { "multi code" };
		} elsif($_ eq "\$ss") {
			*{"${importer}::ss"} = \$shared_scalar;
		} elsif($_ eq "\$us") {
			*{"${importer}::us"} = \(my $unshared_scalar = 100);
		} else {
			die "$_ is not exported by the $exporter module";
		}
	}
}

1;
