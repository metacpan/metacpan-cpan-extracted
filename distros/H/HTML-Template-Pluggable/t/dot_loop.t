use Test::More qw(no_plan);
use strict;

use_ok('HTML::Template::Pluggable');
use_ok('HTML::Template::Plugin::Dot');
use_ok('Test::MockObject');

my $mock = Test::MockObject->new();
$mock->mock( 'some', sub { $mock } );
$mock->mock( 'method', sub { "chained methods work inside tmpl_loop" } );
my $mock2 = Test::MockObject->new();
$mock2->mock( 'some', sub { $mock2 } );
$mock2->mock( 'method', sub { "chained methods work inside a loop twice" } );
my ($output, $template, $result);
$template = qq{<tmpl_loop deloop><tmpl_var num><tmpl_var should_be.some.method></tmpl_loop>};

# test a simple template
my $t = HTML::Template::Pluggable->new(
		scalarref => \$template,
		debug => 0
		);

eval {
    $t->param('deloop',[ {should_be => $mock, num => 1}, {should_be => $mock2, num => 2} ]);
    $output =  $t->output;
};

SKIP: {
    skip "HTML::Template subclassing bug for tmpl_loop support. See: http://rt.cpan.org/NoAuth/Bug.html?id=14037", 2 if $@;
    like($output ,qr/chained methods work inside tmpl_loop/);
    like($output ,qr/chained methods work inside a loop twice/);
}
__END__
