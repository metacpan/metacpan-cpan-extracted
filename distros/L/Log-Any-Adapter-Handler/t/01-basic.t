#!perl

use strict;
use warnings;

use Test::More;
use Log::Any::Adapter;
use Log::Any::Adapter::Handler;

use_ok('Log::Any::Adapter::Handler');
use_ok('Log::Handler');
my @lines;
my $lh = Log::Handler->new(
	forward => {
		forward_to => sub { push @lines, $_[0]->{message} },
		maxlevel => 7
	}
);
isa_ok($lh, 'Log::Handler');
Log::Any->set_adapter('Handler', logger => $lh);
my $log = Log::Any->get_logger();
isa_ok($log, 'Log::Any::Proxy');
my @methods = qw(trace debug notice warn error critical alert emergency);
my @methodsf;
map { push @methodsf, $_.'f' } @methods;
can_ok($log, @methods);
can_ok($log, @methodsf);
shift @methods;
shift @methodsf;
$log->$_('aaargh!', 'aaarg!') for @methods;
ok((shift @lines) =~ /.+$_.+aaargh\!\saaarg\!/i, $_) for @methods;
$log->$_('aaargh! %s', 'aaarg!') for @methodsf;
ok((shift @lines) =~ /.+$_.+aaargh\!\saaarg\!/i, $_.'f') for @methods;

done_testing();
