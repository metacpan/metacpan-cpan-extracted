use strict;
use warnings;

use lib '.';
use inc::Module::Install;

name			'JSONLD';
all_from		'lib/JSONLD.pm';
author			'Gregory Todd Williams <gwilliams@cpan.org>';
license			'perl';

test_requires	'Test::More'				=> 0.88;
test_requires	'Test::Exception'			=> 0;
test_requires	'Test::Modern'				=> 0.012;
test_requires	'Attean'					=> 0;

perl_version	'5.014';

requires		'Clone'						=> 0;
requires		'IRI'						=> 0.010;
requires		'List::Util'				=> 1.33;
requires		'JSON'						=> 4.02;
requires		'LWP'						=> 0;
requires		'LWP::Protocol::https'		=> 0;
requires		'Moo'						=> 0;
requires		'namespace::clean'			=> 0;

resources(
	'homepage'		=> "http://search.cpan.org/dist/JSONLD/",
	'repository'	=> "http://github.com/kasei/perl-jsonld/",
	'bugtracker'	=> "https://github.com/kasei/perl-jsonld/issues",
	'IRC'			=> "irc://irc.perl.org/#perlrdf",
);

author_tests('xt');

install_script glob('bin/*');

write_doap_changes "meta/changes.ttl", "Changes", "turtle";

sign;
WriteAll;
