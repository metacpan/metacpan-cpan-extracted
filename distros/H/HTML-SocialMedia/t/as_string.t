#!perl -Tw

use strict;
use warnings;
use Test::Most;

eval 'use autodie qw(:all)';	# Test for open/close failures

unless(-e 't/online.enabled') {
	plan skip_all => 'On-line tests disabled';
} else {
	plan tests => 66;

	use_ok('Test::NoWarnings');
	use_ok('HTML::SocialMedia');
	delete $ENV{'LANG'};

	my $sm = new_ok('HTML::SocialMedia');
	ok(!defined($sm->as_string()));

	$sm = new_ok('HTML::SocialMedia' => [ twitter => 'example' ]);
	ok(!defined($sm->as_string()));
	ok(defined($sm->as_string(twitter_follow_button => 1)));
	ok($sm->as_string(twitter_tweet_button => 1) !~ /data-related/);
	ok($sm->as_string(twitter_tweet_button => 1) =~ /https:..twitter.com/);
	ok($sm->as_string(twitter_follow_button => 1) !~ /data-lang="/);
	ok($sm->as_string(twitter_follow_button => 1) =~ /http:..twitter.com/);
	ok($sm->as_string(twitter_follow_button => 1) !~ /facebook/);

	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr-FR';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr-FR; rv:1.9.2.19) Gecko/20110707 Firefox/3.6.19';
	$sm = new_ok('HTML::SocialMedia' => []);
	ok(defined($sm->as_string(facebook_like_button => 1)));
	ok($sm->as_string(facebook_like_button => 1) =~ /fr_FR/);
	# No twitter account given, so we can't get a tweet button
	ok(!defined($sm->as_string(twitter_tweet_button => 1)));
	ok($sm->as_string(facebook_like_button => 1) !~ /http:..twitter.com/);

	# Asking for French with a US browser should display in French
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.19) Gecko/20110707 Firefox/3.6.19';
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr';
	$sm = new_ok('HTML::SocialMedia' => []);
	ok(defined($sm->as_string(facebook_like_button => 1)));
	# Handle when there is no fr_US locale for Facebook, so
	# HTML::SocialMedia falls back to en_GB.
	# TODO: It should fall back to fr_FR
	my $button = $sm->as_string(facebook_like_button => 1);
	like($button, qr/en_GB|fr_US/, 'Contains English or French Facebook button');
	ok(!defined($sm->as_string(twitter_tweet_button => 1)));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr-FR';
	$sm = new_ok('HTML::SocialMedia' => []);
	ok(defined($sm->as_string(facebook_like_button => 1)));
	ok($sm->as_string(facebook_like_button => 1) =~ /fr_FR/);
	ok(!defined($sm->as_string(twitter_tweet_button => 1)));

	$sm = new_ok('HTML::SocialMedia' => [ twitter => 'example', twitter_related => ['example1', 'description of example1'] ]);
	ok(defined($sm->as_string(twitter_tweet_button => 1)));
	ok($sm->as_string(twitter_follow_button => 1) =~ /data-lang="fr"/);

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (X11; Linux x86_64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Iceweasel/6.0.2';
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb,en;q=0.5';
	$sm = new_ok('HTML::SocialMedia' => []);
	ok(defined($sm->as_string(facebook_like_button => 1)));
	ok($sm->as_string(facebook_like_button => 1) =~ /en_GB/);
	ok(!defined($sm->as_string(twitter_tweet_button => 1)));

	$sm = new_ok('HTML::SocialMedia' => [ twitter => 'example', twitter_related => ['example1', 'description of example1'] ]);
	ok(defined($sm->as_string(facebook_like_button => 1)));
	ok($sm->as_string(facebook_like_button => 1, twitter_follow_button => 1, twitter_tweet_button => 1, google_plusone => 1) =~ /en_GB/);
	ok($sm->as_string(twitter_follow_button => 1) !~ /data-lang="/);

	$sm = new_ok('HTML::SocialMedia' => [ twitter => 'example', twitter_related => ['example1', 'description of example1'] ]);
	ok(defined($sm->as_string(twitter_tweet_button => 1)));
	ok($sm->as_string(twitter_tweet_button => 1) =~ /data-related/);
	ok($sm->as_string(twitter_tweet_button => 1) =~ /example1:description of example1/);
	ok($sm->as_string(twitter_follow_button => 1) !~ /data-lang="/);
	ok($sm->as_string(linkedin_share_button => 1) =~ /linkedin/);
	ok($sm->as_string(twitter_tweet_button => 1) !~ /linkedin/);
	ok($sm->as_string(twitter_follow_button => 1) eq $sm->render(twitter_follow_button => 1));

	$sm = $sm->new();
	ok(defined($sm->as_string(facebook_like_button => 1)));
	ok(defined($sm->as_string(facebook_share_button => 1)));
	ok($sm->as_string({ facebook_share_button => 1, facebook_like_button => 1 }) =~ /en_GB/);
	ok($sm->as_string({ facebook_share_button => 1, facebook_like_button => 1 }) =~ /"like"/);
	ok($sm->as_string({ facebook_share_button => 1, facebook_like_button => 1 }) =~ /Share/);
	ok($sm->as_string({ facebook_share_button => 1 }) !~ /"like"/);
	ok($sm->as_string({ facebook_like_button => 1 }) !~ /Share/);
	ok($sm->as_string(google_plusone => 1) =~ /en-GB/);

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr-FR';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr-FR; rv:1.9.2.19) Gecko/20110707 Firefox/3.6.19';
	$sm = new_ok('HTML::SocialMedia' => []);
	ok($sm->as_string(google_plusone => 1) =~ /fr-FR/);

	my $cache;

	eval {
		require CHI;

		CHI->import;
	};

	if($@) {
		diag("CHI not installed");
		$cache = undef;
	} else {
		diag("Using CHI $CHI::VERSION");
		my $hash = {};
		$cache = CHI->new(driver => 'Memory', datastore => $hash);
	}

	$sm = new_ok('HTML::SocialMedia' => [ cache => $cache ]);
	ok(defined($sm->as_string(reddit_button => 1)));
	ok($sm->as_string(reddit_button => 1) =~ /reddit\.com/);
	ok($sm->as_string(reddit_button => 1) !~ /facebook/);
	ok($sm->as_string({ reddit_button => 1, facebook_like_button => 1 }) =~ /reddit\.com/);
	ok($sm->as_string({ reddit_button => 1, facebook_like_button => 1 }) =~ /<p>/);
	ok($sm->as_string({ reddit_button => 1, facebook_like_button => 1 }) !~ /<p align="right">/);
	ok($sm->as_string({ reddit_button => 1, facebook_like_button => 1, align => 'right' }) =~ /reddit\.com/);
	ok($sm->as_string({ reddit_button => 1, facebook_like_button => 1, align => 'right' }) !~ /<p>/);
	ok($sm->as_string({ reddit_button => 1, facebook_like_button => 1, align => 'right' }) =~ /<p align="right">/);
	ok($sm->as_string(reddit_button => 1) !~ /linkedin/);
}
