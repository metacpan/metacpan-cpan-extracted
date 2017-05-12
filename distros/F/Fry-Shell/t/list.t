#!/usr/bin/perl
use Test::More tests=>42;
use strict;
use lib 'lib';
use base 'Fry::List';
my $list = {};
use lib 't/testlib';
#use Test::Warn;
#use Data::Dumper;
use MyWarn;

#test data;
	my $bart = {qw/id bart a b status son age 10/};
	my $bart2 = {qw/id bart a B status son/};
	my $lisa = {qw/id lisa a l status daughter/};
	my $lisa2 = {qw/id lisa a L status daughter/};
	my $maggie = {qw/id maggie/,a=>[qw/m baby ma/]}; 

#setup;
my $cls = __PACKAGE__;

eval { $cls->list }; ok($@,'&list dies if not subclassed');
*list = sub {$list};
sub defaultSet { shift->setMany('age',@_) }

#&new 
$cls->new(%$bart);
$cls->new(%$lisa);

#td: one of these causing make test to fail
#warn_count( sub {$cls->new(qw/not complete/)},qw/new/);
#warn_count(sub {$cls->new(qw/id lisa/) },qw/new/);

#new internals
	#&setHashDefault
		#n: could also test &setHashDefaults
		$cls->setHashDefault($bart,{qw/friend Milhouse/});
		is($bart->{friend},'Milhouse','&setHashDefault: sets default');
		delete $bart->{friend};
		$cls->setHashDefault($bart,{qw/status bunny/});
		is($bart->{status},'son','&setHashDefaults: doesn\'t override');

		*_hash_default = sub { return {qw/dog chalupo/} };
		my $simple = {qw/id ro/};
		$cls->setHashDefault($simple);
		is_deeply($simple,{qw/id ro dog chalupo/},'&setHashDefaults: _hash_default');
		*_hash_default = sub {};

	my $nonid = {qw/name Marge status mother/};
	$cls->setId(marge=>$nonid);
	is($nonid->{id},'marge','&setId');

	$cls->manyNew(bart2=>$bart2,lisa2=>$lisa2);
	is_deeply([$cls->getObj(qw/lisa2 bart2/)],[$lisa2,$bart2],'&manyNew');
	$cls->unloadObj(qw/bart2 lisa2/);

#object operations
	is_deeply($cls->_obj('bart'),$bart,'&_obj retrieve');
	$cls->_obj(lisa=>$lisa2);
	is_deeply($cls->_obj('lisa'),$lisa2,'&_obj set');
	$cls->_obj(lisa=>$lisa);

	$cls->new(qw/id blah/);
	$cls->unloadObj('blah');
	warn_count (sub {$cls->objExists('blah')},'objExists',0,
		{msg=>'&unloadObj + &objExists warning: no object '});
	is($cls->objExists('lisa'),1,'&objExists');

	#getObj
	is_deeply([$cls->getObj(qw/lisa bart dumbo/)],[$lisa,$bart],'&getObj');

	#setObj
	$cls->setObj(lisa=>$lisa2,bart=>$bart2);
	is_deeply([$cls->_obj('bart'),$cls->_obj('lisa')],[$bart2,$lisa2],'&setObj');
	$cls->setObj(lisa=>$lisa,bart=>$bart);

#attribute operations
	is($cls->get(qw/bart status/),'son','&get: normal');
	is($cls->get(qw/bart coolness/),undef,'&get: returns undef on fail');
	#warning_like {$cls->get(qw/bart coolness/) } qr//, '&get warning: nonexistant attribute';
	warn_count( sub {$cls->get(qw/bart coolness/) },qw/get 0/);

	is($cls->attrExists(qw/bart coolness/),0,'&attrExists: returns 0 if not found');
	#warning_like {$cls->attrExists(qw/bart coolness/) } '', '&attrExists: no warning';
	warn_count(sub {$cls->attrExists(qw/bart coolness/) },qw/attrExists 0/);#, '&attrExists: no warning';

	$cls->set(qw/bart status punk/);
	is($cls->get(qw/bart status/),'punk','&set');
	#warning_like {$cls->set(qw/bart status/)} qr//,'&set warning: not enough arguments';
	warn_count(sub {$cls->set(qw/bart status/)},'set');#'&set warning: not enough arguments';

	#warning_like {$cls->getMany(qw/a bart blah lisa/)} [qr//,qr//],'&getMany warning: undef passed';
	warn_count( sub {$cls->getMany(qw/a bart blah lisa/)} ,'getMany');
	is_deeply([$cls->getMany(qw/a bart blah lisa/)],['b',undef,'l'],'&getMany: invalid id returns undef');

	#setMany
	#warning_like { $cls->setMany('a',qw/bart B lisa L bozo boz/) } [qr//,qr//],
	#'&setMany warning: invalid id';
	warn_count( sub { $cls->setMany('a',qw/bart B lisa L bozo boz/) },'setMany');
	is_deeply([$cls->getMany(qw/a bart lisa/)],[qw/B L/],'&setMany');
	$cls->setMany('a',qw/bart b lisa l/);

#other

	is_deeply([$cls->findIds(qw/id = bart/)],['bart'],'&findIds: =');
	is_deeply([$cls->findIds(qw/age > 8/)],['bart'],'&findIds: >');
	is_deeply([$cls->findIds(qw/age < 8/)],[],'&findIds: <');
	is_deeply([ sort $cls->findIds(qw/id ~ a/)],[qw/bart lisa/],'&findIds: ~');
	#warnings_like {$cls->findIds(qw/id ~/)} qr//,'&findIds warning: not enough arguments';
	warn_count ( sub {$cls->findIds(qw/id ~/)},'findIds');

	is_deeply([sort $cls->listIds],[qw/bart lisa/],'&listIds');
	is_deeply([sort $cls->listAlias],[qw/b l/],'&listAlias');
	is_deeply([sort $cls->listAliasAndIds],[qw/b bart l lisa/],'&listAliasAndIds');
	is($cls->findAlias('b'),'bart','&findAlias given alias');
	is($cls->findAlias('bart'),'bart','&findAlias given id');
	is($cls->findAlias('bt'),undef,'&findAlias: invalid id returns undef');
	#warning_like {$cls->findAlias('bt') } qr//,'&findAlias warning: invalid id';
	warn_count(sub { $cls->findAlias('bt') },'findAlias');
	is($cls->anyAlias('bart'),'bart','&anyAlias given id');

	#pushArray
	my @enemies = (qw/skinner nelson/);
	$cls->pushArray(qw/bart enemies/,@enemies); 
	#warning_like {$cls->pushArray(qw/bart status/,@enemies) } qr//,
	#'&pushArray warning: invalid attr';
	warn_count(sub { $cls->pushArray(qw/bart status/,@enemies) },'pushArray');
	is_deeply($cls->get(qw/bart enemies/),\@enemies,'&pushArray');
	delete $cls->_obj('bart')->{enemies};

	$cls->new(%$maggie);
	is_deeply([sort $cls->allAttr('a')],[qw/b baby l m ma/],'&allAttr: handles an \@ attribute');

	
	my %args = qw/dad homer son bart/;
	$cls->convertScalarToHash(\%args,'value');
	is_deeply(\%args,{dad=>{value=>'homer'},son=>{value=>'bart'}},'&convertScalarToHash');
#print Dumper $cls->Obj('bart');
	$cls->setOrMake(bart=>'blah');#,{force=>1});
#print Dumper $cls->Obj('bart');
	is_deeply($cls->get('bart','age'),'blah','&setOrMake: sets');
	$cls->setOrMake(bart2=>$bart2,lisa2=>$lisa2);
	is_deeply([$cls->getObj(qw/lisa2 bart2/)],[$lisa2,$bart2],'&setOrMake: makes');
	$cls->unloadObj(qw/bart2 lisa2/);

#http://search.cpan.org/src/MSCHWERN/ExtUtils-MakeMaker-6.21/t/lib/
#<Schwern> TieIn and TieOut
#<Schwern> t/hints.t has an ok example of its use
