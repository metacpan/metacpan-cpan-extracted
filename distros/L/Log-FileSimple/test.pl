# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 9;
use Log::FileSimple;
use FileHandle;


# force autoflush on log file for testing 
my $log	= new Log::FileSimple( 	name 		=> 'Log::FileSimple logs',
								file		=> './log.log',
								mask		=> -1,
								autoflush 	=> 1,
							);

ok( defined $log,              		'new() returned something' );
ok( $log->isa('Log::FileSimple'),	'  and it\'s the right class' );

my $message;

$message 	= 'Simple log message';
$log->log(	message => $message);
ok(	&test_log_string($message), 	'printing simple log message');

$message 	= 'Another printed message';
$log->log(	message	=> $message, id	=> 0b1);
ok(	&test_log_string($message), 	'printing message using id');

$log->mask(0b10);
ok($log->mask == 0b10,				'changing mask to filter message');

$message 	= 'This will not be printed owing to mask';
$log->log(	message	=> $message, id	=> 0b1);
ok(	!&test_log_string($message), 	'rejected message owing to filter mask');


$message 	= 'This will be printed';
$log->log(	message	=> $message, id	=> 0b10);
ok(	&test_log_string($message), 	'accepted message owing to filter mask');


$message 	= 'This is a dump of myself';
$log->log(	message	=> $message, id	=> 0b10, objects => [$log]);
ok(	&test_log_string(q|\'file\' \=\> \'\.\/log.log\'|),
									'log dumping of myself');

$message 	= 'This is a dump of two structures';
$log->log(	message	=> $message, id	=> 0b10, objects => [ {a=>1, b=>2},['one', 'two', 'three']]);
ok(	&test_log_string(q|\'a\'\s*\=\>\s*1\,\n\s+\'b\'\s*\=\>\s*2|), 
									'log dumping of an hashref and of an arrayref');


undef $log;
unlink './log.log';

sub test_log_string() {
	my $test_string = shift;
	open(LOG,"./log.log");
	local undef $/;
	my $logs	= <LOG>;
	close(LOG);
	return $logs=~m|$test_string|s;
}




#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

