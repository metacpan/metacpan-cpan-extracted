
use strict;

use Test::More tests=> 18;

use CGI;
use HTML::Template;
use HTML::Template::Associate::FormField;

my %formfields= (
 start_multipart_form=> { type=> 'start_multipart_form' },
 startform     => { type=> 'startform'   },
 textfield     => { type=> 'textfield'   },
 filefield     => { type=> 'filefield'   },
 textarea      => { type=> 'textarea'    },
 password      => { type=> 'password'    },
 checkbox      => { type=> 'checkbox'    },
 checkbox_group=> { type=> 'checkbox_group', values=> ['foo', 'baz'] },
 radio_group   => { type=> 'radio_group',    values=> ['foo', 'baz'] },
 popup_menu    => { type=> 'popup_menu',     values=> ['foo', 'baz'] },
 scrolling_list=> { type=> 'scrolling_list', values=> ['foo', 'baz'] },
 image_button  => { type=> 'image_button', src=> './dummy.gif' },
 button        => { type=> 'button', onclick=> 'history.back();' },
 reset         => { type=> 'reset'       },
 defaults      => { type=> 'defaults'    },
 submit        => { type=> 'submit'      },
 );

my $template= <<END_OF_TEMPLATE;
[startform:<TMPL_VAR NAME="__startform__">]
[start_multipart_form:<TMPL_VAR NAME="__start_multipart_form__">]
[textfield:<TMPL_VAR NAME="__textfield__">]
[filefield:<TMPL_VAR NAME="__filefield__">]
[textarea:<TMPL_VAR NAME="__textarea__">]
[password:<TMPL_VAR NAME="__password__">]
[checkbox:<TMPL_VAR NAME="__checkbox__">]
[checkbox_group:<TMPL_VAR NAME="__checkbox_group__">]
[radio_group:<TMPL_VAR NAME="__radio_group__">]
[popup_menu:<TMPL_VAR NAME="__popup_menu__">]
[scrolling_list:<TMPL_VAR NAME="__scrolling_list__">]
[image_button:<TMPL_VAR NAME="__image_button__">]
[button:<TMPL_VAR NAME="__button__">]
[reset:<TMPL_VAR NAME="__reset__">]
[defaults:<TMPL_VAR NAME="__defaults__">]
[submit:<TMPL_VAR NAME="__submit__">]
END_OF_TEMPLATE

my %hash= (
 textfield=> 'foo',
 filefield=> 'foo',
 textarea => 'foo',
 password => 'foo',
 checkbox => 'foo',
 checkbox_group=> 'foo',
 radio_group=> 'foo',
 popup_menu => 'foo',
 scrolling_list=> 'foo',
 );
my $form= HTML::Template::Associate::FormField->new(\%hash, \%formfields);
my $tp  = HTML::Template->new( scalarref=> \$template, associate=> [$form] );


#> 1
ok($tp->isa('HTML::Template'));

#> 2
my $out= $tp->output;
ok($out);

#> 3
ok($out=~/\[startform\:(.+)\]/s && $1=~/<form\s+/i);

#> 4
ok($out=~/\[start_multipart_form\:(.+)\]/s && do {
	my $multipart= &CGI::MULTIPART;
	$1=~/$multipart/
 });

#> 5
ok($out=~/\[textfield\:(.+?)\]/s && $1=~/textfield/);

#> 6
ok($out=~/\[filefield\:(.+?)\]/s && $1=~/filefield/);

#> 7
ok($out=~/\[textarea\:(.+?)\]/s  && $1=~/textarea/ );

#> 8
ok($out=~/\[password\:(.+?)\]/s  && $1=~/password/ );

#> 9
ok($out=~/\[checkbox\:(.+?)\]/s  && $1=~/checkbox/ );

#> 10
is(($out=~/\[checkbox_group\:(.+?)\]/s && do {
	my @chk= ($1=~/(checkbox_group)/g);
	@chk}), 2);

#> 11
is(($out=~/\[radio_group\:(.+?)\]/s && do {
	my @chk= ($1=~/(radio_group)/g);
	@chk}), 2);

#> 12
is(($out=~/\[popup_menu\:(.+?)\]/s && do {
	my @chk= ($1=~/(<option)/ig);
	@chk}), 2);

#> 13
is(($out=~/\[scrolling_list\:(.+?)\]/s && do {
	my @chk= ($1=~/(<option)/ig);
	@chk}), 2);

#> 14
ok($out=~/\[image_button\:(.+?)\]/s && $1=~/image_button/);

#> 15
ok($out=~/\[button\:(.+?)\]/s   && $1=~/button/  );

#> 16
ok($out=~/\[reset\:(.+?)\]/s    && $1=~/reset/   );

#> 17
ok($out=~/\[defaults\:(.+?)\]/s && $1=~/defaults/);

#> 18
ok($out=~/\[submit\:(.+?)\]/s   && $1=~/submit/  );


