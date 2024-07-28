
use strict;
use warnings;

use Test::Deep;
use Test::More;
BEGIN { use_ok('FreeDesktop::Icons') };

my @iconpath = ('t/Themes2');
my @theme = qw( png_1 png_2 svg_1 );


my $depot = new FreeDesktop::Icons( @iconpath );
$depot->rawpath([ 't/Raw' ]);
ok (defined $depot, "creation");

$depot->theme('png_1');
my $resize = 0;

my @tests = (
	{
		name => 'Available themes',
		args => [],
		method => 'availableThemes',
		expected => [ 'png_1', 'png_2', 'svg_1' ]
	},

	# Testing available contexts
	{
		name => 'All available contexts',
		args => ['png_1' ],
		method => 'availableContexts',
		expected => [ 'Actions', 'Applications', ]
	},
	{
		name => 'Available contexts in name',
		args => ['png_1', 'edit-cut' ],
		method => 'availableContexts',
		expected => [ 'Actions', ]
	},
	{
		name => 'No available contexts in name',
		args => ['png_1', 'does-not-exist' ],
		method => 'availableContexts',
		expected => [ ]
	},
	{
		name => 'available contexts in name and size',
		args => ['png_1', 'edit-cut', 32 ],
		method => 'availableContexts',
		expected => [ 'Actions', ]
	},
	{
		name => 'No available contexts in name and size 1',
		args => ['png_1', 'does-not-exist', 32 ],
		method => 'availableContexts',
		expected => [ ]
	},
	{
		name => 'No available contexts in name and size 2',
		args => ['png_1', 'edit-cut', 45 ],
		method => 'availableContexts',
		expected => [ ]
	},
	{
		name => 'available contexts in size',
		args => ['png_1', undef, 22 ],
		method => 'availableContexts',
		expected => [ 'Actions', 'Applications', ]
	},
	{
		name => 'No available contexts in size',
		args => ['png_1', undef, 46 ],
		method => 'availableContexts',
		expected => [ ]
	},

	# Testing available icons
	{
		name => 'All available icons',
		args => ['png_1' ],
		method => 'availableIcons',
		expected => [ 'accessories_text_editor', 'arrow_left_double', 'arrow_up_double', 'arrowdown',
			'arrowleft', 'callstart', 'checkbox', 'document_new', 'document_save', 'editcut', 'editfind',
			'gwenview', 'helpbrowser', 'inkscape', 'multimedia_volume_control', 'system_file_manager' ]
	},
	{
		name => 'available icons in size',
		args => ['png_1', 32 ],
		method => 'availableIcons',
		expected => [ 'accessories_text_editor', 'arrow_left_double', 'arrow_up_double', 
			'editcut', 'editfind', 'gwenview', 'helpbrowser', 'inkscape' ]
	},
	{
		name => 'No available icons in size',
		args => ['png_1', 47 ],
		method => 'availableIcons',
		expected => [ ]
	},
	{
		name => 'available icons in size and context',
		args => ['png_1', 32, 'Actions' ],
		method => 'availableIcons',
		expected => [ 'arrow_left_double', 'arrow_up_double', 'editcut', 'editfind', ]
	},
	{
		name => 'No available icons in size and context 1',
		args => ['png_1', 48, 'Actions' ],
		method => 'availableIcons',
		expected => [ ]
	},
	{
		name => 'No available icons in size and context 2',
		args => ['png_1', 32, 'Blobber' ],
		method => 'availableIcons',
		expected => [ ]
	},
	{
		name => 'available icons in context',
		args => ['png_1', undef, 'Actions' ],
		method => 'availableIcons',
		expected => [ 'arrow_left_double', 'arrow_up_double', 'arrowdown', 'arrowleft',
			'document_new', 'document_save', 'editcut', 'editfind' ]
	},
	{
		name => 'No available icons in context',
		args => ['png_1', undef, 'Blobber' ],
		method => 'availableIcons',
		expected => [ ]
	},

	# Testing available sizes
	{
		name => 'All available sizes',
		args => ['png_1' ],
		method => 'availableSizes',
		expected => [ 22, 32 ]
	},
	{
		name => 'available sizes in name',
		args => ['png_1', 'edit-cut'],
		method => 'availableSizes',
		expected => [ 32 ]
	},
	{
		name => 'No available sizes in name',
		args => ['png_1', 'does-not-exist'],
		method => 'availableSizes',
		expected => [ ]
	},
	{
		name => 'available sizes in name and context',
		args => ['png_1', 'edit-cut', 'Actions'],
		method => 'availableSizes',
		expected => [ 32 ]
	},
	{
		name => 'No available sizes in name and context 1',
		args => ['png_1', 'does-not-exist', 'Actions' ],
		method => 'availableSizes',
		expected => [ ]
	},
	{
		name => 'No available sizes in name and context 2',
		args => ['png_1', 'edit-cut', 'Blobber' ],
		method => 'availableSizes',
		expected => [ ]
	},
	{
		name => 'available sizes in context',
		args => ['png_1', undef, 'Actions'],
		method => 'availableSizes',
		expected => [ 22, 32 ]
	},
	{
		name => 'No available sizes in context',
		args => ['png_1', undef, 'Blobber'],
		method => 'availableSizes',
		expected => [ ]
	},

	# Testing finding icon files
	{
		name => 'Find correct size',
		args => ['document-new', 22, 'Actions' ],
		method => 'get',
		expected => [ 't/Themes2/PNG1/actions/22/document_new.png' ]
	},
	{
		name => 'Find incorrect size',
		args => ['document-new', 32, 'Actions', \$resize ],
		method => 'get',
		expected => [ 't/Themes2/PNG1/actions/22/document_new.png' ]
	},
	{
		name => 'Find incorrect context',
		args => ['document-new', 22, 'Applications' ],
		method => 'get',
		expected => [ 't/Themes2/PNG1/actions/22/document_new.png' ]
	},
	{
		name => 'Find in parent theme',
		args => ['arrow-down', 22, 'Actions' ],
		method => 'get',
		expected => [ 't/Themes2/PNG2/actions/22/arrowdown.png' ]
	},
	{
		name => 'Find nothing',
		args => ['no-exist', 22, 'Applications' ],
		method => 'get',
		expected => [ undef ]
	},
	{
		name => 'Find raw',
		args => ['git-icon', 22 ],
		method => 'get',
		expected => ['t/Raw/git-icon.png' ]
	},

);

for (@tests) {
	my $args = $_->{args};
	my $expected = $_->{expected};
	my $method = $depot->can($_->{method});
	my $name = $_->{name};
	my $validate = 'list';
	if (exists $_->{validate}) {
		$validate = $_->{validate}
	}
	my @result = &$method($depot, @$args);
	cmp_deeply(\@result, $expected, $name);
}
ok($resize eq 1, "resize request");

done_testing(@tests + 3);
