use lib('t/testlib/');
use _Auxiliary;

chdir 'templates';

# vary simple
test 'simple.tmpl', { ADJECTIVE => 'very' }, 'simple';

# Let's try something more cool
# (to try something cool, you have to write something cool)
test 'medium.tmpl', {
	'ALERT', 'I am alert.',
	COMPANY_NAME => "MY NAME IS",
	COMPANY_ID => "10001",
	OFFICE_ID => "10103214",
	NAME => 'SAM I AM',
	ADDRESS => '101011 North Something Something',
	CITY => 'NEW York',
	STATE => 'NEw York',
	ZIP => '10014',
	PHONE => '212-929-4315',
	PHONE2 =>  '',
	SUBCATEGORIES => 'kfldjaldsf',
	DESCRIPTION => "dsa;kljkldasfjkldsajflkjdsfklfjdsgkfld\nalskdjklajsdlkajfdlkjsfd\n\talksjdklajsfdkljdsf\ndsa;klfjdskfj",
	WEBSITE => 'http://www.assforyou.com/',
	INTRANET_URL => 'http://www.something.com',
	REMOVE_BUTTON => "<INPUT TYPE=SUBMIT NAME=command VALUE=\"Remove Office\">",
	COMPANY_ADMIN_AREA => "<A HREF=administrator.cgi?office_id={office_id}&command=manage>Manage Office Administrators</A>",
	CASESTUDIES_LIST => "adsfkljdskldszfgfdfdsgdsfgfdshghdmfldkgjfhdskjfhdskjhfkhdsakgagsfjhbvdsaj hsgbf jhfg sajfjdsag ffasfj hfkjhsdkjhdsakjfhkj kjhdsfkjhdskfjhdskjfkjsda kjjsafdkjhds kjds fkj skjh fdskjhfkj kj kjhf kjh sfkjhadsfkj hadskjfhkjhs ajhdsfkj akj fkj kj kj  kkjdsfhk skjhadskfj haskjh fkjsahfkjhsfk ksjfhdkjh sfkjhdskjfhakj shiou weryheuwnjcinuc 3289u4234k 5 i 43iundsinfinafiunai saiufhiudsaf afiuhahfwefna uwhf u auiu uh weiuhfiuh iau huwehiucnaiuncianweciuninc iuaciun iucniunciunweiucniuwnciwe", 
	NUMBER_OF_CONTACTS => "aksfjdkldsajfkljds",
	COUNTRY_SELECTOR => "klajslkjdsafkljds",
	LOGO_LINK => "dsfpkjdsfkgljdsfkglj",
	PHOTO_LINK => "lsadfjlkfjdsgkljhfgklhasgh"
	}, 'medium';

# Simple loop
test 'simple-loop.tmpl', 
	{ ADJECTIVE_LOOP =>
		[ 
			{ ADJECTIVE => 'really' }, 
			{ ADJECTIVE => 'very' } 
		] 
	},
	'simple-loop';

# Simple loop - nonames
test 'simple-loop-nonames.tmpl',
	{ ADJECTIVE_LOOP =>
		[ 
			{ ADJECTIVE => 'really' }, 
			{ ADJECTIVE => 'very' } 
		] 
	},
	'loop-nonames';
#test 'other-loop.tmpl', {};
test 'loop-nested.tmpl',
	{ NUM =>
		[
			{ 'title' => 'binary', 'values' => [
					{ value => '010' },
					{ value => '110'}
				]
			},
			{ 'title' => 'decimal', 'values' => [
					{ value => '2'},
					{ value => '6'}
				]
			}
		]
	},
	'nested loops';
test 'double_loop.tmpl', 
	{ myloop => 
		[
		    { var => 'first'}, 
		    { var => 'second' }, 
		    { var => 'third' }
		]
	},
	'two loop with the same name';

# Include
test 'include.tmpl', {}, 'include';
	
# Include with other tags
test 'include2.tmpl', 
	{ ADJECTIVE_LOOP =>
		[ 
			{ ADJECTIVE => 'really' }, 
			{ ADJECTIVE => 'very' } 
		] 
	},
	'include - complex text';

# Simple if
test 'if.tmpl', { BOOL => 1 }, 'if';

# Simple unless
test 'unless.tmpl', { BOOL => 1}, 'unless';

# Multiline tags
test 'multiline_tags.tmpl', { FOO => '', BAR => [{}, {}] };

test 'newline_test1.tmpl', {};
test 'newline_test2.tmpl', {};

