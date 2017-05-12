#!perl -T

use strict;
use warnings;
use Test::More;

plan tests => 64;

use_ok('JQuery::Mobile');

can_ok('JQuery::Mobile', qw(new head header footer table panel popup page pages form listview collapsible collapsible_set navbar button controlgroup input rangeslider select checkbox radio textarea));

my $jquery_mobile = JQuery::Mobile->new(
	config => {
		'app-title' => 'Hello Mobile World', 
		'app-js' => ['https://raw.github.com/dannyglue/jQuery-Mobilevalidate/master/jquery.mobilevalidate.min.js'],
		'app-inline-js' => '$(document).bind("pageinit", function(){
			$("form").mobilevalidate({novalidate: true});
		});',
		'label' => sub {
			my $args = shift;
			return '<strong>' . $args->{label} . '*</strong>' if $args->{required};
			return $args->{label};
		},
	}
);

like ($jquery_mobile->{config}->{'app-title'}, qr/Hello Mobile World/, 'App JS');

my $header = $jquery_mobile->header(
	content => $jquery_mobile->button(href => '#', value => 'Home', icon => 'home', iconpos => 'notext') . '<h1>Main Title</h1>',
);
like ($header, qr/<div data-role="header">/, 'Header Start');
like ($header, qr/<a data-icon="home" data-iconpos="notext" data-role="button" href="#">Home<\/a>/, 'Header Content and button');


my $custom_header = $jquery_mobile->header(
	'content' => '<h1>Header Content</h1>',
	'id' => 'home-main-header',
	'class' => 'site-header',
	'data-id' => 'main-header', # use the 'data-*' prefix since 'id' is both a HTML and data atrribute
	'fullscreen' => 'true',
	'position' => 'fixed',
	'theme' => 'e'
);
like ($custom_header, qr/<div data-role="header" data-fullscreen="true" id="home-main-header" class="site-header" data-id="main-header" data-fullscreen="true" data-position="fixed" data-theme="e">/, 'Customised Header Start');
like ($custom_header, qr/<h1>Header Content<\/h1>/, 'Customised Header Content');
like ($custom_header, qr/<\/div>/, 'Customised Header End');

my $footer = $jquery_mobile->footer(
	position => 'fixed',
	content => 'Footer content'
);
like ($footer, qr/<div data-role="footer" data-position="fixed">/, 'Footer Start');
like ($footer, qr/<\/div>/, 'Footer End');

my $popup = $jquery_mobile->popup(id => 'popup', content => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit');
like ($popup, qr/<div id="popup" data-role="popup">/, 'Popup Start');
like ($popup, qr/<\/div>/, 'Popup End');


my $panel = $jquery_mobile->panel(content => 'Panel Content');
like ($panel, qr/<div data-role="panel">/, 'Panel');

my $page = $jquery_mobile->page(
	header => {
		content => $jquery_mobile->button(href => '#', value => 'Home', icon => 'home', iconpos => 'notext') . '<h1>Main Title</h1>',
	},
	footer => {
		position => 'fixed',
		content => '<h3>Footer content</h3>'
	},
	content => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit'
);
like ($page, qr/<html>/, 'Page HTML');
like ($page, qr/<head>/, 'Page Head');
like ($page, qr/<div data-role="page">/, 'Page Start');
like ($page, qr/<div data-role="header">/, 'Page Header');
like ($page, qr/<div data-role="content">/, 'Page Content');
like ($page, qr/<div data-role="footer" data-position="fixed">/, 'Page Footer');

my $pages = $jquery_mobile->pages(
	pages => [
		{id => 'page-1', header => {content => '<h1>Page One Heading</h1>'}, content => 'Cillum dolore eu fugiat nulla pariatur. ' . $jquery_mobile->button(icon => 'arrow-r', value => 'Page 2', href => '#page-2')},
		{id => 'page-2', header => {content => '<h1>Page Two Heading</h1>'}, content => 'Excepteur sint occaecat cupidatat non'},
	]
);
like ($pages, qr/<html>/, 'Page HTML');
like ($pages, qr/<head>/, 'Page Head');
like ($pages, qr/<div id="page-1" data-role="page">/, 'Page 1');
like ($pages, qr/<a data-icon="arrow-r" data-role="button" href="#page-2">Page 2<\/a>/, 'Page 1 Button');
like ($pages, qr/<div id="page-2" data-role="page">/, 'Page 2');

my $table = $jquery_mobile->table(
	class => 'ui-responsive',
		th => {
		'First Name' => {priority => '1'}, 
		'Last Name' => {priority => '2'}, 
		'Email' => {priority => '3'}, 
		'Gender' => {priority => '4'}, 
	},
	headers => ['First Name', 'Last Name', 'Email', 'Gender'],
	rows => [
		['John', 'Smith', 'john@work.com', 'Male'],
		['Ann', 'Smith', 'ann@work.com', 'Female'],
	],
);

like ($table, qr/<table data-role="table" class="ui-responsive">/, 'Table Start');
like ($table, qr/<th data-priority="1">First Name<\/th>/, 'Table Head 1');
like ($table, qr/<td>John<\/td>/, 'Table Data 1');

my $form = $jquery_mobile->form(
	title => 'The Form',
	description => 'A description of the form',
	action => '/',
	method => 'get', # defaulted to 'post'
	fields => [
		{name => 'first_name', required => 'required'},
		{name => 'last_name', label => 'Surname', required => 'required'},
		{name => 'email', type => 'email', required => 'required'},
		{name => 'password', type => 'password'},
		{name => 'avatar', type => 'file', accept => 'image/*', capture=> 'camera'},
		{name => 'comment', type => 'textarea'},
		{type => 'radio', name => 'gender', options => ['Male', 'Female']},
		{type => 'checkbox', name => 'country', options => {'AU' => 'Austalia', 'US' => 'United States'}, value => 'AU'},
		{type => 'select', name => 'heard', label => 'How did you hear about us', options => ['Facebook', 'Twitter', 'Google', 'Radio', 'Other']},
		{type => 'rangeslider', name => 'range', mini => 'true', from => {label => 'Range', name => 'from', min => 18, max => 100}, to => {name => 'to', min => 18, max => 100}},
	],
	controlgroup => {type => 'horizontal'}, # use controlgroup to group the buttons, default to false, accepts "1" or a hashref
	buttons => [
		{value => 'Submit', type => 'submit', icon => 'arrow-r', theme => 'b'},
		{value => 'Cancel', href => '#', icon => 'delete'}
	],
);
like ($form, qr/<form action="\/" method="get">/, 'Form Start');
like ($form, qr/<h1>The Form<\/h1>/, 'Form Title');
like ($form, qr/<p>A description of the form<\/p>/, 'Form Description');
like ($form, qr/<div data-role="fieldcontain"><label for="first_name"><strong>First Name\*<\/strong>:<\/label><input id="first_name" name="first_name" required="required" type="text" value="" \/><\/div>/, 'Form First Name');
like ($form, qr/<div data-role="fieldcontain"><label for="avatar">Avatar:<\/label><input id="avatar" name="avatar" type="file" value="" accept="image\/\*" capture="camera" \/><\/div>/, 'Form Avatar');
like ($form, qr/<div data-role="fieldcontain"><label for="comment">Comment:<\/label><textarea id="comment" name="comment" rows="8" cols="40"><\/textarea><\/div>/, 'Form Comment');
like ($form, qr/<legend>Gender:<\/legend><input type="radio" name="gender" id="gender-male" value="Male" \/><label for="gender-male">Male<\/label><input type="radio" name="gender" id="gender-female" value="Female" \/><label for="gender-female">Female<\/label>/, 'Form Gender');
like ($form, qr/<legend>Country:<\/legend><input type="checkbox" name="country" id="country-au" value="AU" checked="checked" \/><label for="country-au">Austalia<\/label><input type="checkbox" name="country" id="country-us" value="US" \/><label for="country-us">United States<\/label>/, 'Form Country');
like ($form, qr/<div data-role="fieldcontain"><label for="heard">How did you hear about us:<\/label><select name="heard" id="heard"><option value="Facebook" >Facebook<\/option><option value="Twitter" >Twitter<\/option><option value="Google" >Google<\/option><option value="Radio" >Radio<\/option><option value="Other" >Other<\/option><\/select><\/div>/, 'Form Heard from');
like ($form, qr/<div data-role="controlgroup" data-type="horizontal">/, 'Form Controlgroup');
like ($form, qr/<div data-role="rangeslider" name="range" data-mini="true">/, 'Rangeslider');
like ($form, qr/<label for="from">Range:<\/label><input id="from" max="100" min="18" name="from" type="range" value="" \/>/, 'Rangeslider From');
like ($form, qr/<label for="to">To:<\/label><input id="to" max="100" min="18" name="to" type="range" value="" \/>/, 'Rangeslider To');
like ($form, qr/<input data-icon="arrow-r" data-role="button" data-theme="b" type="submit" value="Submit"\/>/, 'Form Submit Button');
like ($form, qr/<a data-icon="delete" data-role="button" href="#">Cancel<\/a>/, 'Form Cancel Button');
like ($form, qr/<\/form>/, 'Form End');

my $list = $jquery_mobile->listview(
	anchor => {rel => 'dialog', transition => 'pop'}, # anchor configuration
	items => [
		{value => 'Quick List', divider => 1},
		{aside => '02/06', count => '6', image => 'http://placehold.it/100x100', title => 'One', href => '#'},
		{aside => '03/07', count => '8', image => 'http://placehold.it/100x100', title => 'Two', href => '#'},
		{aside => '04/08', count => '10', image => 'http://placehold.it/100x100', title => 'Three', href => '#'},
	],
	inset => 'true',
	filter => 'true',
);
like ($list, qr/<ul data-role="listview" data-filter="true" data-inset="true">/, 'List Start');
like ($list, qr/<li data-role="list-divider">Quick List<\/li>/, 'List Item Divider');
like ($list, qr/<li><a data-rel="dialog" data-transition="pop" href="#"><img src="http:\/\/placehold.it\/100x100" \/><h3>One<\/h3><span class="ui-li-count">6<\/span><p class="ui-li-aside">02\/06<\/p><\/a><\/li>/, 'List Item');
like ($list, qr/<\/ul>/, 'List End');

my $split_list = $jquery_mobile->listview(
	anchor => {rel => 'dialog', transition => 'pop'},
	split_anchor => {transition => 'fade', theme => 'e'},
	items => [
		{title => 'One', href => '#link-1', split => '#split-link-1', split_value => 'Split Value One'},
		{title => 'Two', href => '#link-2', split => '#split-link-2', split_value => 'Split Value Two'},
		{title => 'Three', href => '#link-3', split => '#split-link-3', split_value => 'Split Value Three'},
	]
);
like ($split_list, qr/<li><a data-rel="dialog" data-transition="pop" href="#link-1"><h3>One<\/h3><\/a><a data-theme="e" data-transition="fade" href="#split-link-1">Split Value One<\/a><\/li>/, 'Split List Item');


my $collapsible_set = $jquery_mobile->collapsible_set(
	collapsibles => [
		{content => '<h3>Item Heading One</h3><p>Item One Content</p>'},
		{content => '<h3>Item Heading Two</h3><p>Item Two Content</p>'},
	]
);
like ($collapsible_set, qr/<div data-role="collapsible-set">/, 'Collapsible Set Start');
like ($collapsible_set, qr/<div data-role="collapsible">/, 'Collapsible Start');
like ($collapsible_set, qr/<h3>Item Heading Two<\/h3><p>Item Two Content<\/p>/, 'Collapsible Two Content');
like ($collapsible_set, qr/<\/div>/, 'Collapsible End');

my $accordion = $jquery_mobile->collapsible_set(    
	active => {
		option => 'title', # what listview item attribute to check for and set it as active 
		value => 'Menu A Item Two' # open the accordion menu where the listview item has the title: 'Menu A Item Two'
	},
	collapsibles => [
		{
			title => 'Menu A',
			listview => {
			  items => [
			    {title => 'Menu A Item One', href => '#'},
			    {title => 'Menu A Item Two', href => '#'},
			  ]
			}
		},
		{
			title => 'Menu B',
			listview => {
			  items => [
			    {title => 'Menu B Item One', href => '#'},
			    {title => 'Menu B Item Two', href => '#'},
			  ]
			}
		},
	]
);
like ($accordion, qr/<ul data-role="listview">/, 'Collapsible Set Accordion Listview');
like ($accordion, qr/<li class="ui-btn-active"><a href="#"><h3>Menu A Item Two<\/h3><\/a><\/li>/, 'Collapsible Set Accordion Active Item');

my $navbar = $jquery_mobile->navbar(
	items => [
		{value => 'Item One', href => '#'}, 
		{value => 'Item Two', href => '#', active => 1, persist => 1},
		{value => 'Item Three', href => '#'}
	]
);
like ($navbar, qr/<div data-role="navbar">/, 'Navbar Start');
like ($navbar, qr/<ul>/, 'Navbar List Start');
like ($navbar, qr/<li><a href="#" class="ui-btn-active ui-btn-persist">Item Two<\/a><\/li>/, 'Navbar List Active Persist Item');
like ($navbar, qr/<\/ul>/, 'Navbar List End');
like ($navbar, qr/<\/div>/, 'Navbar End');

my $anchor_button = $jquery_mobile->button(
	role => 'button', # could be 'button' or 'none', defaulted to 'button'
	href => 'https://www.google.com',
	mini => 'true',
	value => 'Learn More',
	icon => 'arrow-r',
	iconpos => 'right',
	inline => 'true',
	ajax => 'false',
);
like ($anchor_button, qr/<a data-ajax="false" data-icon="arrow-r" data-iconpos="right" data-inline="true" data-mini="true" data-role="button" href="https:\/\/www.google.com">Learn More<\/a>/, 'Anchor Button');

my $submit_button = $jquery_mobile->button(
	type => 'submit',
	value => 'Join Now',
	theme => 'e'
);
like ($submit_button, qr/<input data-role="button" data-theme="e" type="submit" value="Join Now"\/>/, 'Submit Button');

my $controlgroup = $jquery_mobile->controlgroup(
	mini => 'true',
	type => 'horizontal',
	content => '<a href="#" data-role="button">Yes</a><a href="#" data-role="button">No</a>'
);
like ($controlgroup, qr/<div data-role="controlgroup" data-mini="true" data-type="horizontal">/, 'Controlgroup Start');
like ($controlgroup, qr/<a href="#" data-role="button">Yes<\/a><a href="#" data-role="button">No<\/a>/, 'Controlgroup Content');
like ($controlgroup, qr/<\/div>/, 'Controlgroup End');

# diag($controlgroup);