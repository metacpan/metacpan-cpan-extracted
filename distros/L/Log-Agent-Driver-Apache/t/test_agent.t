package My::Dummy::Apache;
use strict;
# Coax it into thinking it's logging to mod_perl.
sub new { 
	my($this) = shift;
	my($self) = bless({},$this); 
	foreach my $method (qw(debug alert crit error warn notice info)){
		eval sprintf('sub %s { shift()->_do_log("%s",@_);  }',$method,$method);
		$self->{LOG}{$method} = [];
	}
	return($self);
}
sub get_log {
	my($self,$method) = (shift,shift);
	if(! $method){
		my(@rv);
		foreach my $key (qw(debug alert crit error warn notice info)){
			push(@rv,@{$self->{LOG}{$key}});
		}
		return(@rv);
	}
	if(ref($self->{LOG}{$method}) eq 'ARRAY'){ 
		return(@{$self->{LOG}{$method}});
	}
	return();
}
sub _do_log {
	my($self,$method,$str) = (shift,shift,shift);
	push(@{$self->{LOG}{$method}},$str);
}
1;
package My::Test::Runner;
use Log::Agent::Driver::Apache;
use strict;
use Test::Builder;
use Log::Agent;

BEGIN { 
        $My::Test::Runner::tb = new Test::Builder();
}
our(@TESTS, $tb);

@TESTS = qw(
	test_make
	test_debug
	test_others
);
do_setup();

sub do_setup {
	my($self) = new My::Test::Runner();
	my($tm,$ctr) = 0;
	foreach $tm (@TESTS){
		$ctr += $self->$tm(-1);
	}
	$tb->plan('tests',$ctr);
}

sub new {
	my($this) = shift;
	my(%self) = @_;
	return(bless(\%self,$this));
}
sub run {
	my($self) = shift;
	foreach my $tm (@TESTS) {
		print "# running: $tm\n";
		$self->$tm();
	}
}

sub test_make {
	my($self) = shift;
	return(1) if($_[0] == -1);
	
	my($drv) = Log::Agent::Driver::Apache->make('-log' => My::Dummy::Apache->new());
	$tb->ok(ref($drv),"make() method returns reference");
}
sub test_debug {
	my($self) = shift;
	return(2) if($_[0] == -1);

	my($log) = My::Dummy::Apache->new();
	my($drv) = Log::Agent::Driver::Apache->make('-log' => $log);
	logconfig(-driver => $drv, -level => 100);
	logdbg(1, "Debug123");
	logdbg(101,"Nope");
	my(@log) = $log->get_log('debug');
	$tb->like($log[0],qr/Debug123/,'debug works');
	$tb->ok(scalar(@log) == 1,"Did correct log count");
}
sub test_others {
	my($self) = shift;
	return(5) if($_[0] == -1);
	my($log) = My::Dummy::Apache->new();
	my($drv) = Log::Agent::Driver::Apache->make('-log' => $log);
	logconfig(-driver => $drv, -level => 100);
	logerr("error123");
	logwarn("warn123");
	my(@all) = $log->get_log();
	$tb->ok(scalar(@all) == 2,'Logged 2 messages');
	my(@er) = $log->get_log('error');	
	$tb->like($er[0],qr/error123/,'logerr() seems to work');
	my(@wl) = $log->get_log('warn');
	$tb->like($wl[0],qr/warn123/,'logwarn() seems to work');
	eval {
		logcroak("Test me");
	};
	$tb->like($@,qr/Test me/,'logcroak() dies');
	my(@l) = $log->get_log('crit');
	$tb->like($l[0],qr/Test me/,'logcroak() logs error too.');
}

1;
package main;
use strict;

main();
sub main {
        my($t) = My::Test::Runner->new();
        $t->run();
}


1;
# vim:set syntax=perl:
