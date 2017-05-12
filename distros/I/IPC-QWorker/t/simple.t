use Test;
BEGIN { plan tests => 10 };
use IPC::QWorker;
use IPC::QWorker::WorkUnit;
use Data::Dumper;

my $i;
my $qworker = IPC::QWorker->new();
ok(defined($qworker));

$qworker->create_workers(10,
	'dump' => sub { my $ctx = shift(); print $$.": ".Dumper(@_)."\n"; $ctx->{'count'}++; },
	'_init' => sub { my $ctx = shift(); $ctx->{'count'} = 0 ; },
	'_destroy' => sub { my $ctx = shift(); print $$.": did ".$ctx->{'count'}." operations!\n"; }
);
	
ok(scalar(@{$qworker->{'_workers'}}) == 10);

foreach $i (1..120) {
	$qworker->push_queue(IPC::QWorker::WorkUnit->new(
		'cmd' => 'dump',
		'params' => $i,
	));
}

$qworker->push_queue();
ok(scalar(@{$qworker->{'_queue'}}) == 120);

$qworker->process_queue(1);
ok(1);

ok(scalar(@{$qworker->{'_queue'}}) > 0);

$qworker->process_queue();
ok(1);

ok(scalar(@{$qworker->{'_queue'}}) == 0);

$qworker->flush_queue();
ok(1);

ok(scalar(@{$qworker->{'_ready_workers'}}) == 10);

$qworker->stop_workers();
ok(1);

# vim:ts=2:syntax=perl:
