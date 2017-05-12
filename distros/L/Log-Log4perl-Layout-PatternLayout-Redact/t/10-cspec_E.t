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
use Test::More tests => 13;
use Try::Tiny;


my %confidential_data =
(
	'username'     => 'yoda',
	'password'     => 'thereisnotry',
	'planet'       => 'degobah',
	'ship_zip'     => '01138',
	'gift_message' => "Happy\nBirthday\n\tLove,\n\tTimmy",
);
my $test_credit_card_number = '4111111111111111';


ok(
	local $Carp::MaxArgNums = 20,
	'Set Carp::MaxArgsNums to a value that will show all arguments.',
);

ok(
	my $filehandle = File::Temp->new(),
	'Create temp file.',
);
ok(
	my $file_name = $filehandle->filename(),
	'Fetch temp filename.',
);

ok(
	local $Log::Log4perl::Layout::PatternLayout::Redact::SENSITIVE_ARGUMENT_NAMES =
	[
		'ship_zip',
		'password',
	],
	'Set the argument names to redact.',
);

my $logger_configuration =
qq|
	log4perl.logger = WARN, logfile
	log4perl.appender.logfile                          = Log::Log4perl::Appender::File
	log4perl.appender.logfile.filename                 = $file_name
	log4perl.appender.logfile.layout                   = Log::Log4perl::Layout::PatternLayout::Redact
	log4perl.appender.logfile.layout.ConversionPattern = %d %p: (%X{host}) %P %F:%L %M - %m{chomp}%E
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

# We can't use Test::Exception::lives_ok(). At least with Carp 1.24, this
# somehow causes the stacktrace to lose the arguments for the subroutines.
# We're not sure why, but if you find out how to get this to work with
# Test::Exception, let us know!
try
{
	test_trace(
		%confidential_data,
		$test_credit_card_number,
	);
}
finally
{
	my @error = @_;
	ok(
		!@error,
		'Log data.',
	) || diag( 'Errors: ' . Dumper( @error ) );
};

ok(
	my $log_contents = Perl6::Slurp::slurp( $file_name ),
	'Slurp file contents.',
) || diag( "Error: $!" );

unlike(
	$log_contents,
	qr/$confidential_data{'password'}/,
	'Password is not in the log.',
) || diag( "---- begin: logger content ----\n$log_contents\n---- end: logger content ----\n" );

unlike(
	$log_contents,
	qr/$confidential_data{'ship_zip'}/,
	'ship_zip is not in the log.',
) || diag( "---- begin: logger content ----\n$log_contents\n---- end: logger content ----\n" );

like(
	$log_contents,
	qr/$confidential_data{'username'}/,
	'username is not redacted.',
) || diag( "---- begin: logger content ----\n$log_contents\n---- end: logger content ----\n" );

like(
	$log_contents,
	qr/\[redacted\]/,
	'[redacted] is present.',
) || diag( "---- begin: logger content ----\n$log_contents\n---- end: logger content ----\n" );

unlike(
	$log_contents,
	qr/$test_credit_card_number/,
	'The test credit card number is not in the log.',
) || diag( "---- begin: logger content ----\n$log_contents\n---- end: logger content ----\n" );


# This subroutine exists because we want to redact from the subroutine trace of
# the arguments, so we need a level of indirection.

sub test_trace
{
	$logger->error( "$$: Test.");
}
