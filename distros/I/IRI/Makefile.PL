use strict;
use warnings;

use lib '.';
use inc::Module::Install;
use Module::Install::DOAPChangeSets;
use Module::Install::AuthorTests;

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

write_doap_changes "meta/changes.ttl", "Changes", "turtle";

# On MacOS, prefer homebrew-installed GNU tar so that we don't include Mac-specific
# extended header data (which results in "Ignoring unknown extended header keyword"
# messages on non-Mac systems when extracting data.
if (-x '/opt/homebrew/bin/gtar') {
	makemaker_args(
		dist => {
			TAR => '/opt/homebrew/bin/gtar'
		}
	);
}

sign if ! exists $ENV{CI};
WriteAll;
