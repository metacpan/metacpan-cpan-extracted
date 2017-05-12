#!/usr/bin/perl

use strict;
use Test::More tests=>18;
use lib 'lib';
use lib 't/testlib';
#use Test::Warn;
use MyWarn;
#use Data::Dumper;
#use diagnostics;

use base 'Fry::Opt';
use MyBase;
@Fry::Opt::ISA = (qw/Fry::List MyBase/);
use Fry::Var;

my %optobj = (flag=>{qw/id flag a f type flag stop 1 tags counter/},
	var=>{qw/id var type var/,action=>\&actionsub},
	none=>{qw/id none type none noreset 1/});
my @actionsub;
sub actionsub { @actionsub = @_}

main->defaultNew(%optobj);

#&setOptions
	main->setOptions(flag=>1);
	is(main->Flag('flag'),1,'&setOptions with flag-type option');
	main->setOptions(flag=>0);
	main->setOptions(f=>1);
	is(main->Flag('flag'),1,'&setOptions with option\'s alias');

	Fry::Var->new(qw/id var value blah/);
	main->setOptions(var=>'weally');
	is(Fry::Var->get('var','value'),'weally','&setOptions with var-type option');

	main->setOptions(none=>'yep');
	is (main->get(qw/none value/),'yep','&setOptions with none-type option');
	
	#warning_like {main->setOptions(blah=>'blah')} [qr//,qr//],'&setOptions warning: invalid opt';
	warn_count(sub {main->setOptions(blah=>'blah')},'setOptions');

#&Opt
	is(main->Opt('flag'),1,'&Opt with type flag');
	is(main->Opt('var'),'weally','&Opt with type var');
	is(main->Opt('none'),'yep','&Opt with type none');
	ok(! main->Opt('blah'),'&Opt returns undef for invalid argument');
	#warning_like {main->Opt('blah')} [qr//,qr//],'&Opt warning: invalid opt skipped';
	warn_count(sub{main->Opt('blah')},'Opt');

main->_setDefaults;
main->setOptions(none=>'yepper',flag=>0);
is_deeply({main->findSetOptions},{qw/flag 0 none yepper/},'&findSetOptions');

#&resetOptions
	main->resetOptions;
	is(main->Opt('none'),'yepper','&resetOptions: noreset attribute works');
	is(main->Opt('flag'),0,'&resetOptions: stop attribute > 0 prevents reset');

	main->resetOptions({reset=>1});
	is(main->Opt('none'),'yep','&resetOptions: noreset attribute overloaded by sub\'s reset option');
	is(main->Opt('flag'),1,'&resetOptions: stop attribute > 0 overloaded');

main->preParseCmd(flag=>0,var=>'woah');
is(main->_obj('flag')->{stop},1,'stop set to 1 via counter tag and &preParseCmd');
is_deeply(\@actionsub,['main','woah'],'action executed and passed arguments correctly via &preParseCmd');
#warning_like {main->preParseCmd(blah=>'blah')} [qr//,qr//],'&preParseCmd warning: invalid opt skipped';
warn_count(sub{main->preParseCmd(blah=>'blah')},'preParseCmd');
