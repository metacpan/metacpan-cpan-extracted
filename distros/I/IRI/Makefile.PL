use strict;
use warnings;

use lib '.';
use inc::Module::Install;

name				'IRI';
all_from			'lib/IRI.pm';
author				'Gregory Todd Williams <gwilliams@cpan.org>';
license				'perl';

build_requires		'Test::More'				=> 0.88;
build_requires		'Try::Tiny'					=> 0;

perl_version		'5.010001';

requires			'Moo'						=> 0;
requires			'MooX::HandlesVia'			=> 0;
requires			'Type::Tiny'				=> 0.008; #InstanceOf
build_requires		'URI'						=> 0;

resources(
	'homepage'   => "http://search.cpan.org/dist/IRI/",
	'repository' => "http://github.com/kasei/perl-iri/",
	'bugtracker' => "https://github.com/kasei/perl-iri/issues"
);

author_tests('xt');

write_doap_changes;
write_doap_changes_xml;

sign;

WriteAll;
