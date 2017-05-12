#!perl -T

use Test::More tests => 7;

use Log::Log4perl;
use File::RoundRobin;

my $config;
{ #read the config
	local $/ = undef;
	$config = <DATA>;
}

{ #init Log::Log4per and log something
	Log::Log4perl->init(\$config);
	my $logger = Log::Log4perl->get_logger('test');

	ok($logger,'Log::Log4perl object created');

	ok($logger->debug('Debug test'),'Debug works');
	ok($logger->info('Info test'),'Info works');
	ok($logger->warn('Warn test'),'Warn works');
	ok($logger->error('Error test'),'Error works');
	ok($logger->fatal('Fatal test'),'Fatal works');
}

{ #validate the data we logged
	my $file = File::RoundRobin->new(path => 'test.log', mode=>'read');
	my $content = $file->read(1000);

	my $expected = <<END;
DEBUG : Debug test
INFO : Info test
WARN : Warn test
ERROR : Error test
FATAL : Fatal test
END

is($content,$expected,"File content is correct");
}

unlink('test.log');

__DATA__
log4perl.logger.test 		          	= DEBUG,  FileAppndr1

log4perl.appender.FileAppndr1      	    = Log::Log4perl::Appender::File::FixedSize
log4perl.appender.FileAppndr1.filename 	= test.log
log4perl.appender.FileAppndr1.size	 	= 1M
log4perl.appender.FileAppndr1.layout   	= PatternLayout
log4perl.appender.FileAppndr1.layout.ConversionPattern = %p : %m%n
