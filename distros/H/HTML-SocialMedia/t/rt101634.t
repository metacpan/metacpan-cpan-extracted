#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 3;

# Test for "Use of uninitialized value in lc at /home/nigelhorne/perlmods/share/perl/5.14.2/HTML/SocialMedia.pm line 190"

BEGIN {
	use_ok('HTML::SocialMedia');
}

RT101634: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'no-NO';
	$ENV{'REMOTE_ADDR'} = '77.106.148.148';

	my $sm = new_ok('HTML::SocialMedia' => [ logger => MyLogger->new() ]);
	ok(defined($sm->as_string(facebook_like_button => 1)));
}

# On some platforms it's failing - find out why
package MyLogger;

sub new {
	my ($proto, %args) = @_;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

sub warn {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub info {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub debug {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub trace {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}
