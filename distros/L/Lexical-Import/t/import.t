use warnings;
use strict;

use Test::More tests => 71;

our($blank, $one, $three) = qw(z z z);
($main::zero, $main::two) = qw(z z);

{
	use Lexical::Import "t::Exp0";
	ok defined(&successor);
	ok defined(&predecessor);
	is &successor(5), 6;
	is successor(5), 6;
	is predecessor(6), 5;
	is successor(@{[11,22,33]}), 4;
	is $one, "z";
	ok \$one == \$main::one;
}

ok !defined(&successor);
ok !defined(&predecessor);

{
	use Lexical::Import qw(t::Exp0 $blank $zero $one $two);
	ok !defined(&successor);
	is $blank, undef;
	is $zero, 0;
	is $one, 1;
	is $two, 2;
	is $three, "z";
	ok \$blank != \$main::blank;
	ok \$zero != \$main::zero;
	ok \$one != \$main::one;
	ok \$two != \$main::two;
	ok \$three == \$main::three;
}

is $blank, "z";
is $one, "z";
is $three, "z";
ok \$blank == \$main::blank;
ok \$one == \$main::one;
ok \$three == \$main::three;

{
	use Lexical::Import qw(t::Exp0 @aaa %hhh);
	is_deeply \@aaa, [qw(a a a)];
	is_deeply \%hhh, {h=>"hh"};
}

{
	use Lexical::Import qw(t::Exp0 :letters);
	is(A(), "AA");
	is(B(), "BB");
	is(C(), "CC");
	is(D(), "DD");
	is(E(), "EE");
}

{
	use Lexical::Import qw(t::Exp0 :multi);
	is $multi, "multi scalar";
	is_deeply \@multi, [qw(multi array)];
	is_deeply \%multi, {multi=>"hash"};
	is multi(), "multi code";
}

eval q{
	no strict "vars";
	use Lexical::Import qw(t::Exp0 $one);
	die unless $one == 1;
	die unless $two eq "z";
};
is $@, "";
is $one, "z";
ok \$one == \$main::one;

eval q{
	use Lexical::Import qw(t::Exp0 $wibble);
};
like $@, qr/\A\$wibble is not exported by the t::Exp0 module/;

eval q{
	use Lexical::Import qw(t::Exp0 $one);
	$one = 2;
};
like $@, qr/\A(?:Modification\ of\ a\ read-only\ value\ attempted
		|Can't\ modify\ constant\ item\ in\ scalar\ assignment)/x;

{
	my $pa = do { use Lexical::Import qw(t::Exp0 $ss); \$ss };
	my $pb = do { use Lexical::Import qw(t::Exp0 $ss); \$ss };
	ok $pa == $pb;
	is $$pa, 100;
	is $$pb, 100;
	$$pa = 222;
	is $$pa, 222;
	is $$pb, 222;
	$$pb = 333;
	is $$pa, 333;
	is $$pb, 333;
}

{
	my $pa = do { use Lexical::Import qw(t::Exp0 $us); \$us };
	my $pb = do { use Lexical::Import qw(t::Exp0 $us); \$us };
	ok $pa != $pb;
	is $$pa, 100;
	is $$pb, 100;
	$$pa = 222;
	is $$pa, 222;
	is $$pb, 100;
	$$pb = 333;
	is $$pa, 222;
	is $$pb, 333;
}

{
	use Lexical::Import qw(t::Exp1);
	ok !defined(&foo);
	ok !defined(&bar);
	ok !defined(&baz);
}

{
	use Lexical::Import qw(t::Exp1 foo bar baz);
	ok defined(&foo);
	ok defined(&bar);
	ok defined(&baz);
	is foo(), "FOO";
	is bar(), "BAR";
	is baz(), "BAZ";
}

{
	use Lexical::Import qw(t::Exp2);
	ok !defined(&identity);
}

{
	use Lexical::Import qw(-t::Exp2);
	ok defined(&identity);
	is identity(3), 3;
}

ok !defined(&identity);

ok !grep { /\A__STAGE/ } keys %Lexical::Import::;

1;
