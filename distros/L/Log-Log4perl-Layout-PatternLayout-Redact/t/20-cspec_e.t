#!perl -T

use strict;
use warnings;

use Data::Dumper;
use File::Temp;
use Log::Log4perl;
use Log::Log4perl::Appender::File;
use Log::Log4perl::Layout::PatternLayout::Redact;
use Perl6::Slurp;
use Test::Exception;
use Test::More tests => 9;
use Try::Tiny;


my $TEST_PASSWORD = 'abc123';
my $TEST_PASSWORD_CONFIRMATION = 'def456';
my $TEST_MESSAGE = qq|
	<envelope version="1.0">
		<body>
			<accounts>
				<account row="0" password="$TEST_PASSWORD" password_confirmation="$TEST_PASSWORD_CONFIRMATION"/>
			</accounts>
		</body>
	</envelope>
|;

ok(
	local $Log::Log4perl::Layout::PatternLayout::Redact::MESSAGE_REDACTION_CALLBACK = sub
	{
		my ( $message ) = @_;
		
		$message =~ s/((?:password|password_confirmation)=")[^"]+(")/$1\[redacted\]$2/g;
		
		return $message;
	},
	'Define message redaction callback.',
);

ok(
	my $filehandle = File::Temp->new(),
	'Create temp file.',
);
ok(
	my $file_name = $filehandle->filename(),
	'Fetch temp filename.',
);

my $logger_configuration =
qq|
	log4perl.logger = WARN, logfile
	log4perl.appender.logfile                          = Log::Log4perl::Appender::File
	log4perl.appender.logfile.filename                 = $file_name
	log4perl.appender.logfile.layout                   = Log::Log4perl::Layout::PatternLayout::Redact
	log4perl.appender.logfile.layout.ConversionPattern = %d %p: (%X{host}) %P %F:%L %M - %e
	log4perl.appender.logfile.recreate                 = 1
	log4perl.appender.logfile.mode                     = append
|;

lives_ok(
	sub
	{
		Log::Log4perl->init(
			\$logger_configuration
		);
	},
	'Initialize the logger.',
) || diag( "Logger configuration: $logger_configuration" );

ok(
	my $logger = Log::Log4perl::get_logger(),
	'Create a Log::Log4perl object.',
);

lives_ok(
	sub
	{
		$logger->error( $TEST_MESSAGE );
	},
	'Log test message.',
);

ok(
	my $log_contents = Perl6::Slurp::slurp( $file_name ),
	'Slurp file contents.',
) || diag( "Error: $!" );

unlike(
	$log_contents,
	qr/$TEST_PASSWORD/,
	'Password is not in the log.',
) || diag( "---- begin: logger content ----\n$log_contents\n---- end: logger content ----\n" );

unlike(
	$log_contents,
	qr/$TEST_PASSWORD_CONFIRMATION/,
	'Password confirmation is not in the log.',
) || diag( "---- begin: logger content ----\n$log_contents\n---- end: logger content ----\n" );
