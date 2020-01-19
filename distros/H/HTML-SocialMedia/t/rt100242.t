#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 3;
use lib 't/lib';
use MyLogger;

# Test for https://rt.cpan.org/Ticket/Display.html?id=100242

BEGIN {
	use_ok('HTML::SocialMedia');
}

RT100242: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'hr-HR';
	$ENV{'REMOTE_ADDR'} = '195.29.95.225';

	my $sm = new_ok('HTML::SocialMedia' => [ logger => MyLogger->new() ]);
	ok(defined($sm->as_string(facebook_like_button => 1)));
}
