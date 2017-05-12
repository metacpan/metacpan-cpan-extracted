use Test;
use JavaScript::DebugConsole;

BEGIN {
	local $@;
	eval { require Template; require Template::Plugin::Class };
	my $tt2 = $@ ? 0 : 1;
	# Skip this test if Template is not installed
	unless($tt2) {
		print "1..0\n";
		exit 0;
	}	
	plan tests => 2;
}

my $template = Template->new();
ok( $template );
my $output;
ok( $template->process(\*DATA, { title  => "TT2 JavaScript::DebugConsole test\n" }, \$output) );
print $output;

__DATA__
[% title %]

[% USE q = CGI %]
[% USE c = Class('JavaScript::DebugConsole') %]
[% jdc = c.new %]
[% jdc.add('test1', 'and', ' test1', ' again') %]
[% jdc.add('test2') %]

[% jdc.debugConsole('title', 'Debug Text 2', 'auto_open', 0) %]

[% jdc.debugConsole( content => "Another text2", title => "Debug Text 2", auto_open => 0, form => q ) %]

<p>Click <a href="[% jdc.link %]">here</a> to open the console!</p>
