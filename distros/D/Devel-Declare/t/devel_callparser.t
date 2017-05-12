use warnings;
use strict;

use Test::More;
use Test::Requires 'Devel::CallParser';

plan tests => 1;

use Devel::CallParser ();

sub method {
	my ($usepack, $name, $inpack, $sub) = @_;
	no strict "refs";
	*{"${inpack}::${name}"} = $sub;
}

use Devel::Declare method => sub {
	my ($usepack, $use, $inpack, $name) = @_;
	return sub (&) { ($usepack, $name, $inpack, $_[0]); };
};

method bar {
	return join(",", @_);
};

is +__PACKAGE__->bar(qw(x y)), "main,x,y";

1;
