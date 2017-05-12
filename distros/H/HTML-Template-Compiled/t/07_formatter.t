# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 2;
BEGIN { use_ok('HTML::Template::Compiled::Formatter') };

my $formatter = {
	'HTC::Class1' => {
		fullname => sub {
			$_[0]->first . ' ' . $_[0]->last
		},
		first => HTC::Class1->can('first'),
		last => HTC::Class1->can('last'),
	},
};
my $htc = HTML::Template::Compiled::Formatter->new(
	path => 't/templates',
	filename => 'formatter.htc',
	debug => 0,
);
my $obj = bless ({ first => 'Abi', last => 'Gail'}, 'HTC::Class1');

$htc->param(
	test => 23,
	obj => $obj,
);
local $HTML::Template::Compiled::Formatter::formatter = $formatter;
my $out = $htc->output;
my $exp = <<EOM;
23
Abi plus Gail
Abi Gail
EOM
for ($exp, $out) {
	tr/\r\n//d;
}
ok($exp eq $out, "formatter");
sub HTC::Class1::first {
	$_[0]->{first}
}
sub HTC::Class1::last {
	$_[0]->{last}
}

__END__
<%= test%>
<%= obj/first %> plus <%= obj/last%>
<%= obj/fullname%>
