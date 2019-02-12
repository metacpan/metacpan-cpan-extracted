# vim: set ft=perl :

use Test::More tests => 3;
BEGIN { use_ok('Getargs::Mixed') };

sub foo {
	my %args = Getargs::Mixed->new(-undef_ok => 1)->parameters([ qw( x; y z ) ], @_);

	ok(!defined $args{x});
}

# OK with the -undef_ok option.  See errors.t and errors_oo.t for the failures
# without this option.
foo(undef);
foo(-x => undef);
