#TODO: almost all tests missing!

# plugin: template

use strict;
use warnings;

use Test::More tests => 3;

#=== Dependencies
$Konstrukt::Handler->{filename} = "test";
use Konstrukt::TagHandler::Plugin;
$Konstrukt::TagHandler::Plugin->init();

#load plugin
my $template = $Konstrukt::TagHandler::Plugin->load_plugin("template");
is(ref($template), "Konstrukt::Plugin::template", "load");

#normalize_input_data: generic form
my $data_generic = {
	fields => {
		field1 => 'value1',
		field2 => 'value2'
	},
	lists => {
		list1 => [
			{ fields => { field1 => 'a', field2 => 'b' } },
			{ fields => { field1 => 'c', field2 => 'd' } },
		]
	}
};
$template->normalize_input_data($data_generic);
#must be identical
is_deeply(
	$data_generic, 
	{
		fields => {
			field1 => 'value1',
			field2 => 'value2'
		},
		lists => {
			list1 => [
				{ fields => { field1 => 'a', field2 => 'b' } },
				{ fields => { field1 => 'c', field2 => 'd' } },
			]
		}
	},
	"normalize: no change on generic form"
);

#normalize_input_data: generic form
my $data_short = {
	field1 => 'value1',
	field2 => 'value2',
	list1 => [
		{ field1 => 'a', field2 => 'b' },
		{ field1 => 'c', field2 => 'd' },
	]
};
$template->normalize_input_data($data_short);
#must be identical
is_deeply(
	$data_short,
	$data_generic,
	"normalize: convert short form"
);
