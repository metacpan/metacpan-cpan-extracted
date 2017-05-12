#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 4;

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

	# Enable this for debugging
	# ::diag($message);
	::ok($message =~ /Can't determine language from IP 195.29.95.225, country hr/);
}

sub debug {
	my $self = shift;
	my $message = shift;

	# Enable this for debugging
	# ::diag($message);
}

sub trace {
	my $self = shift;
	my $message = shift;

	# Enable this for debugging
	# ::diag($message);
}

sub info {
	my $self = shift;
	my $message = shift;

	::diag($message);
}

sub error {
	my $self = shift;
	my $message = shift;

	::diag($message);
}
