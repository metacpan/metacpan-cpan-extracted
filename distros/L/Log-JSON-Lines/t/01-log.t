use Test::More;
use Log::JSON::Lines;

ok(my $log = Log::JSON::Lines->new(
	'synopsis.log',
	4,
	canonical => 1,
	pretty => 1
));

$log->log('info', 'Lets log JSON lines.');

$log->emerg({ 
	message => 'emergency', 
	definition => [
		'a serious, unexpected, and often dangerous situation requiring immediate action.'
	] 
});

$log->alert({ 
	message => 'alert',
	definition => [
		'quick to notice any unusual and potentially dangerous or difficult circumstances; vigilant.'
	]
});
$log->crit({ 
	message => 'critical',
	definition => [
		'expressing adverse or disapproving comments or judgements.'
	]
});
$log->err({ 
	message => 'error',
	definition => [
		'the state or condition of being wrong in conduct or judgement.'
	]
});
$log->warning({ 
	message => 'warning',
	definition => [
		'a statement or event that warns of something or that serves as a cautionary example.'
	]
});
$log->notice({ 
	message => 'notice', 
	definition => [
		'the fact of observing or paying attention to something.'
	]
});
$log->info({ 
	message => 'information', 
	definition => [
		'what is conveyed or represented by a particular arrangement or sequence of things.'
	]
});

sub debug {
	$log->debug({ 
		message => 'debug', 
		definition => [
			'identify and remove errors from (computer hardware or software).'
		]
	});
}
debug();
done_testing;
