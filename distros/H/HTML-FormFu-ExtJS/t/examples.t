use Test::More;

use HTML::FormFu::ExtJS;
use File::Find;

require "examples/template_extjs.pl";
require "examples/template_html.pl";

my @forms;

sub wanted {
	push(@forms, $_) if ($_ =~ /\.yml$/);
}

find(\&wanted, "examples/forms");

for(@forms) {
	my $title = $_;
	$form = new HTML::FormFu::ExtJS;
	$form->load_config_file("examples/forms/".$title);
	ok($form->render, $title . "renders fine");
}

done_testing;