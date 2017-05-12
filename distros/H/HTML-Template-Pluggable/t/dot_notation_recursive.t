use Test::More;
use Test::MockObject;

use strict;

my @tests = (
[q/Formatter.sprintf('%.2f', mock.value)/,					q/ 3.20 / ],
[q/Formatter.sprintf('%.2f', mock.nested(3.1459).key)/,		q/ 3.15 / ],
[q/Formatter.sprintf('%20s', mock.nested(bareword, 'literal1', non.bareword).key)/,	q/ bare value := / ],
[q/Formatter.sprintf('%20s %4s %7s', bareword, 'literal1', non.bareword)/,	q/ bare value := / ],
# [q/mock.nested(Formatter.sprintf('%.3f', 3.14159)).key/,	q/ 3.142 / ], ### eeewww. other way around obviously doesn't work, as it needs the param setting reversed.

);

plan tests => 3						# use_ok
			  + scalar(@tests)		# recursion tests
	;

use_ok('HTML::Template::Pluggable');
use_ok('HTML::Template::Plugin::Dot');
use_ok('Test::MockObject');

my $formatter = Test::MockObject->new();
$formatter->mock( 'sprintf' , sub { shift; sprintf(shift(), @_) } );

my $mock = Test::MockObject->new();
$mock->mock( 'name',   sub { 'Mock' } );
$mock->mock( 'value',  sub { '3.196002'  } );
$mock->mock( 'nested', sub { $mock->{key} = $_[1]; $mock } );

foreach my $test(@tests) {
	my ($pat, $out) = @$test;

	my ( $output, $template, $result );

	my $tag =  qq{ <tmpl_var name="$pat"> := <tmpl_var name="mock.name"> <tmpl_var name="Formatter.sprintf('%s','')"> <tmpl_var bareword> <tmpl_var non.bareword>}; # 

	my $t = HTML::Template::Pluggable->new(
			scalarref => \$tag,
			debug => 0
		);
	
	# diag("template tag is $tag");
	$t->param( bareword	 => 'bare value' );
	$t->param('non.bareword'	 => 'non bare value' );
	$t->param( mock		 => $mock );
	$t->param( Formatter => $formatter );
	$output = $t->output;
	like( $output, qr/$out/, $pat);
	# diag("output is $output");
	# diag("mock is ", $t->param('mock'));
}

# vi: filetype=perl

__END__
