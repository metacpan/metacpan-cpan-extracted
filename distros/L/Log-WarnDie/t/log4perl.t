#!perl -wT

use warnings;
use strict;

use Test::Most;

my $warn_show = "This warning will be displayed\n";
my $warn_noshow = "This warning will not be displayed\n";
my $die = "This die will not be displayed\n";

LOG4PERL: {
	eval 'use Log::Log4perl';

	if($@) {
		plan skip_all => "Log::Log4perl required for checking log4perl";
	} else {
		eval 'use Test::Log4perl';

		if($@) {
			plan skip_all => "Test::Log4perl required for checking log4perl";
		} else {
			plan tests => 3;

			use_ok('Log::WarnDie');
			can_ok('Log::WarnDie', qw(dispatcher import unimport));

			# Log::Log4perl->easy_init({ level => $Log::Log4perl::DEBUG });
			Log::Log4perl->easy_init({ });

			# Yes, I know the manual says it would be logged
			# under Log::WarnDie, but it's acutally logged under
			# Log.WarnDie

			Log::WarnDie->dispatcher(Log::Log4perl->get_logger('Log.WarnDie'));
			Log::WarnDie->filter(\&filter);

			my $tlogger = Test::Log4perl->get_logger('Log.WarnDie');

			Test::Log4perl->start();

			$tlogger->warn($warn_show);

			warn $warn_show;

			warn $warn_noshow;

			eval {die $die};
			$tlogger->fatal($die);

			Test::Log4perl->end('Test logs all OK');
		}
	}
}

sub filter {
	return 1 if($_[0] eq $warn_show);
	return 1 if($_[0] eq $die);

	return 0;
}
