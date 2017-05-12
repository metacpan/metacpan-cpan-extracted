#!perl

use Test::More tests => 33;
use strict;
use File::Basename;
use_ok('GD::Graph');

my $graph = GD::Graph->new(200,200);
ok($graph,"Got an object from new()");
isa_ok($graph,"GD::Graph");

#bug 20802

my @candidates = (
	[ qw(gif 	logo.gif	logo_gif_noext) ],
	[ qw(jpeg	logo.jpeg	logo_jpeg_noext logo.jpg) ],
	[ qw(png	logo.png	logo_ping_noext logo_alt.PNG) ],
	[ qw(xbm	logo.xbm	logo_xbm_noext) ],
	[ qw(xpm	logo.xpm	logo_xpm_noext) ],
);

my $icon_dir = dirname(__FILE__) . "/images";

foreach my $group (@candidates) {
	# no skipping for now
	my ($type,$withext, $noext,$other) = @$group;
	my $tests = $other ? 6 : 4;
	unless (my $method = GD::Image->can("newFrom\u$type")) {
		my $count = defined $other ? 6 : 4;
		pass("Skipping: GD appears not to support importing \U$type\E files") for 1..$tests;
		next;
	} else {
		my $quirky_test = eval { GD::Image->$method ; $@ };
		if ($quirky_test && $quirky_test =~ /libgd was not built with/) {
			pass("Skipping: GD *really* doesn't support importing \U$type\E files") 
				for 1..$tests;
			next;
		}
	}
	
	$graph->set(logo=> "$icon_dir/$withext");
	ok(my $logo = $graph->_read_logo_file,
		"_read_logo_file succeeds for $type with file extension");
	isa_ok($logo,"GD::Image");
	$graph->set(logo=>"$icon_dir/$noext");
	ok($logo = $graph->_read_logo_file,
		"_read_logo_file succeeds for $type without file extension");
	isa_ok($logo,"GD::Image");
	next unless defined $other;
	$graph->set(logo=>"$icon_dir/$other");
	ok($logo = $graph->_read_logo_file,
		"_read_logo_file succeeds for $type with alternate extension");
	isa_ok($logo,"GD::Image");
}

my @buggy_sets = (
	[ (1)x5 ],
	[ (0)x5 ],
	[ (-1)x5 ],
	
);
use_ok('GD::Graph::bars');
# and now we attempt to reproduce more annoying bugs...
# this is at axestype.pm line 1902
my $foo = GD::Graph::bars->new(100,100);
$foo->set(y_min_value=>1,y_max_value=>1);
ok ( eval { $foo->plot([ [ map "label$_", 1..3], [(1)x3]]) }, 
	"freakish divide-by-zero trick");
ok(!$@, "No fatalities on the above");
# other possibilities for the same bug: setup_x_step_size_v (line 597), _h (628)
# create_y_labels?  (if "tick_number" is set to 0)

$foo = GD::Graph::bars->new(100,100);
$foo->set_legend(qw(Longlegenditemasdfasdf the heck));
my $stat = eval { $foo->plot([ ['A'..'F'], [(0)x7] , [(0)x7] , [(0)x7] ]); };
ok(!$@, "Survived 20792");
ok($stat, "and got a result");

#25975 is a duplicate of #5282

require GD::Graph::lines;
$foo = GD::Graph::lines->new(1200,300);
eval {
	$SIG{ALRM} = sub { die "alarmed" } ;
	alarm 1;
	$foo->plot([ [1..4],[(-1)x4]]);
};
ok(!$@, "No timeout");
