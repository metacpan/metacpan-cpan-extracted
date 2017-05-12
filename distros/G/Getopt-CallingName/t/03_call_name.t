use strict;
use warnings;
use English;
use Test::More tests => 5;
use File::Spec::Functions qw(catfile);

use Getopt::CallingName;

test_call_name();

sub test_call_name {
	# This is deliberately local rather than my!
	local $PROGRAM_NAME = '/foo/bar/tv_record.perl';
	my @sent_args = ('lala', 'po');
	my %call_args = (
			 name_prefix => 'tv_',
			 args        => \@sent_args,
			);
	my $ret_val = 'the_same';

	# Does record get called?
	# Does it receive the arguments array?
	# Do we receive its return value?
	is(call_name(%call_args), $ret_val);

	sub record {
		no warnings;
		# ^^^ to stoped the will not stay shared messages, ok cos outer
		#     sub will only be called once.

		my(@received_args) = @_;
		ok(1);  # play called;
		ok(eq_array(\@received_args, \@sent_args));
		return $ret_val;
	}

	# calling a non-existant method
	$PROGRAM_NAME = '/foo/bar/tv_stop.perl';
    my $path = catfile('t', '03_call_name.t'); 
	my $expected = qr!Unable to call subroutine corresponding to name, &main::stop does not exist at \Q$path\E line \d+!;

	eval{
		call_name(%call_args);
	};
	if($@ and $@ =~ m/$expected/) {
		ok(1);
	}
	else {
		print STDERR "Expected: $expected\nGot: $@\n";
		ok(0);
	}

	# Does a called method's exception/die message come out in the same fashion?
	$PROGRAM_NAME = '/foo/bar/tv_play.perl';
	sub play {
		die("I don't want to play!!");
	}

 	eval "play()";
 	$expected = $@;

 	eval {
 		call_name(%call_args);
 	};
 	if($@ and $@ eq $expected) {
 		ok(1);
 	}
 	else {
 		print STDERR "Excepted: $expected\nGot: $@\n";
 		ok(0);
 	}


	
}
