use Test::More;
use Test::MockObject;

use strict;

# setup tags to test.
# the tag name is "should_be.some.method" . $key,
# the expected outcome is the value.

# this list should pass
my @passing = (
[ q/should_be.some.method/,												q/args/,								],
[ q/should_be.some.method()/,											q/args/,								],
[ q/should_be.some.method('with_param')/,								q/>with_param</,						],
[ q/should_be.some.method(1, 2, 3)/,									q/>1< >2< >3</,							],
[ q/should_be.some.method(-1.3E+09, 12345, +13, -1)/,					q/>-1.3E+09</,							],
[ q/should_be.some.method('with.parens()')/,							q/>with.parens()</,						],
[ q/should_be.some.method('with `quotes`')/,							q/>with `quotes`/,						],
[ q/should_be.some.method('with `quotes` and ( parens ) and {braces} ')/,q/braces} /,							],
[ q/should_be.some.method('something with brackets[1,2,3]')/,			q/>something with brackets[1,2,3]</,	],
);

# this list should fail
my @failing = (
[ q/should_be.some.method('quotes', and, bare, args)/,					q/Attempt to reference nonexisting parameter/,	],
[ q/should_be.some.method(arrays_are_not_possible[1,2,3])/,				q/Attempt to reference nonexisting parameter/,	],
[ q/should_be.some.method$$$/,											q/Trailing characters/,					],
[ q/should_be(object.method)/,											q/Attempt to set nonexistent parameter/,],
);

plan tests => 3						# use_ok
			  + scalar(@passing)	# tests that should pass
			  + scalar(@failing)	# tests that should fail
	;

use_ok('HTML::Template::Pluggable');
use_ok('HTML::Template::Plugin::Dot');
use_ok('Test::MockObject');

my $mock = Test::MockObject->new();
$mock->mock( 'some', sub { $mock } );
$mock->mock(
    'method',
    sub {
		shift; # skip object
        join " ", "args =", map { ">$_<" } @_;
    }
);

foreach my $test ( @passing) {
	my ($pat, $out) = @$test;
	my $tag =  qq{ <tmpl_var name="$pat"> };
	
	my ( $output, $template, $result );
	my $t = HTML::Template::Pluggable->new(
			scalarref => \$tag,
			debug => 0
		);
	$t->param( should_be => $mock );
	$output = $t->output;
	# diag("template tag is $tag");
	# diag("output is $output");
	like( $output, qr/\Q$out/i, $pat);
}

foreach my $test ( @failing) {
	my ($pat, $out) = @$test;
	my $tag =  qq{ <tmpl_var name="$pat"> };
	
	my ( $output, $template, $result );
	my $t = HTML::Template::Pluggable->new(
			scalarref => \$tag,
			debug => 0
		);
	eval {
		$t->param( should_be => $mock );
		$output = $t->output;
	};
	# diag("template tag is $tag");
	# diag("output is $output");
	# diag("exception is $@") if $@;
	like( $@, qr/\Q$out/, $pat);
}


# vi: filetype=perl

__END__
