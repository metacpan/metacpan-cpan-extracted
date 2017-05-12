#!/usr/bin/perl -w
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

use MIDI::ALSA qw(:ALL);
# use Class::MakeMethods::Utility::Ref qw( ref_clone ref_compare );
use Time::HiRes;
use Data::Dumper;
$Data::Dumper::Indent = 0;   # 1.16
use Test::Simple tests => 57;

my @virmidi = virmidi_clients_and_files();
if (@virmidi < 4) {
	print("# To run all tests, four virmidi clients are needed...\n");
	print("# You might need to add the line:\n");
	print("#    modprobe snd_virmidi enable=1   # to create 4 virmidi ports\n");
	print("# to your  /etc/rc.local  :-)\n");
}

$rc = MIDI::ALSA::inputpending();
ok(! defined $rc, "inputpending() with no client returned undef");

my ($cl,$po) = MIDI::ALSA::parse_address('97:3');
ok(($cl==97)&&($po==3), "parse_address('97:3') with no client returned 97,3");

my $my_name = "testpl pid=$$";
$rc = MIDI::ALSA::client($my_name,2,2,1);
ok($rc, "client('$my_name',2,2,1)");

my ($seconds, $microseconds) = Time::HiRes::gettimeofday;
my $start_time = $seconds + 1.0E-6 * $microseconds;

$id = MIDI::ALSA::id();
ok($id > 0, "id() returns $id");

($cl,$po) = MIDI::ALSA::parse_address($my_name);
if (! ok($cl == $id, "parse_address('$my_name') returns $id,$po")) {
	print "# it returned instead: $cl,$po\n";
}

($cl,$po) = MIDI::ALSA::parse_address('testpl');
if (! ok($cl == $id, "parse_address('testpl') returns $id,$po")) {
	print "# it returned instead: $cl,$po\n";
}

# 20121205 apparently fails on 1.0.22 on Centos.
#($cl,$po) = MIDI::ALSA::parse_address('testp');
#if (! ok($cl == $id, "parse_address('testp') returns $id,$po")) {
#	print "# it returned instead: $cl,$po\n";
#}

if (@virmidi >= 2 ) {
	$rc = MIDI::ALSA::connectfrom(1,$virmidi[0],0);
	ok($rc, "connectfrom(1,$virmidi[0],0)");
} else {
	ok(1, "can't see a virmidi client, so skipping connectfrom()");
}

$rc = MIDI::ALSA::connectfrom(1,133,0);
ok(! $rc, 'connectfrom(1,133,0) correctly returned 0');

if (@virmidi >= 2 ) {
	$rc = MIDI::ALSA::connectto(2,$virmidi[2],0);
	ok($rc, "connectto(2,$virmidi[2],0)");
} else {
	ok(1, "can't see two virmidi clients, so skipping connectto()");
}

$rc = MIDI::ALSA::connectto(1,133,0);
ok(! $rc, 'connectto(1,133,0) correctly returned 0');

$rc = MIDI::ALSA::start();
ok($rc, 'start()');

my $qid = MIDI::ALSA::queue_id();
if (! ok(($qid >= 0 and $qid != MIDI::ALSA::SND_SEQ_QUEUE_DIRECT()),
  "queue_id is not negative and not SND_SEQ_QUEUE_DIRECT")) {
	print "# queue_id() returned $qid\n";
}

$fd = MIDI::ALSA::fd();
ok($fd > 0, 'fd()');

my %num2name = MIDI::ALSA::listclients();
ok($num2name{$id} eq $my_name, "listclients()");

my %num2nports = MIDI::ALSA::listnumports();
ok($num2nports{$id} == 4, "listnumports()");

if (@virmidi < 2) {
	ok(1, "skipping inputpending() returns $rc");
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2scoreevent() test');
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2scoreevent() test');
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2scoreevent() test');
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2scoreevent() test');
	ok(1, 'skipping listconnectedto() test');
	ok(1, 'skipping listconnectedfrom() test');
} else {
	open(my $inp, '>', $virmidi[1])
	 || die "can't open $virmidi[1]: $!\n";  # client 20
	my $vm = 0 + $virmidi[0];
	select($inp); $|=1; select(STDOUT);

	print("# feeding ourselves a patch_change event...\n");
	print $inp "\xC0\x63"; # string.char(12*16, 99)); # {'patch_change',0,0,99}
	$rc =  MIDI::ALSA::inputpending();
	ok($rc > 0, "inputpending() returns $rc");
	@alsaevent  = MIDI::ALSA::input();
	@correct = (11, 1, 0, 1, 300, [$vm,0], [$id,1], [0, 0, 0, 0, 0, 99] );
	$alsaevent[3] = 1;   # 1.16 sometimes it's 0 ...
	$alsaevent[4] = 300;
	if (! ok(Dumper(@alsaevent) eq Dumper(@correct),
	 "input() returns (11,1,0,1,300,[$vm,0],[id,1],[0,0,0,0,0,99])")) {
		print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.16
		print "# correct  =".Dumper(\@correct)."\n";   # 1.16
	}
	@e = MIDI::ALSA::alsa2scoreevent(@alsaevent);
	#warn("e=".Dumper(\@e)."\n");
	@correct = ('patch_change',300000,0,99);
	ok(Dumper(@e) eq Dumper(@correct),
	 'alsa2scoreevent() returns ("patch_change",300000,0,99)');

	print("# feeding ourselves a control_change event...\n");
	print $inp "\xB2\x0A\x67"; # 11*16+2,10,103 {'control_change',3,2,10,103}
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	@correct = (10, 1, 0, 1, 300, [$vm,0], [$id,1], [2, 0, 0, 0,10,103] );
	$alsaevent[3] = 1;   # 1.16 sometimes it's 0 ...
	$alsaevent[4] = 300;
	if (! ok(Dumper(@alsaevent) eq Dumper(@correct),
	 "input() returns (10,1,0,1,300,[$vm,0],[id,1],[2,0,0,0,10,103])")) {
		print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.16
		print "# correct  =".Dumper(\@correct)."\n";   # 1.16
	}
	@e = MIDI::ALSA::alsa2scoreevent(@alsaevent);
	# warn("e=".Dumper(@e)."\n");
	@correct = ('control_change',300000,2,10,103);
	# warn("correct=".Dumper(@correct)."\n");
	ok(Dumper(@e) eq Dumper(@correct),
	 'alsa2scoreevent() returns ("control_change",300000,2,10,103)');

	print("# feeding ourselves a note_on event...\n");
	print $inp "\x90\x3C\x65"; # (9*16, 60,101));  {'note_on',0,60,101}
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	$save_time = $alsaevent[4];
	@correct = ( 6, 1, 0, 1, 300, [$vm,0], [$id,1], [ 0, 60, 101, 0, 0 ] );
	$alsaevent[3] = 1;   # 1.16 sometimes it's 0 ...
	$alsaevent[4] = 300;
	${$alsaevent[7]}[3] = 0;
	${$alsaevent[7]}[4] = 0;
	if (! ok(Dumper(@alsaevent) eq Dumper(@correct),
	 "input() returns (6,1,0,1,300,[$vm,0],[id,1],[0,60,101,0,0])")) {
		print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.16
		print "# correct  =".Dumper(\@correct)."\n";   # 1.16
	}
	@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
	#$scoreevent[1] = 300000;
	#@correct = ('note_on',300000,0,60,101);
	#ok(Dumper(@scoreevent) eq Dumper(@correct),
	# 'alsa2scoreevent() returns ("note_on",300000,0,60,101)');

	print("# feeding ourselves a note_off event...\n");
	print $inp "\x80\x3C\x65"; # (8*16, 60,101); # {'note_off',0,60,101}
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	$save_time = $alsaevent[4];
	@correct = ( 7, 1, 0, 1, 301, [ $vm,0 ], [ $id,1 ], [ 0, 60, 101, 0, 0 ] );
	$alsaevent[3] = 1;   # 1.16 sometimes it's 0 ...
	$alsaevent[4] = 301;
	${$alsaevent[7]}[4] = 0;
	if (! ok(Dumper(@alsaevent) eq Dumper(@correct),
	 "input() returns (7,1,0,1,301,[$vm,0],[id,1],[0,60,101,0,0])")) {
		print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.16
		print "# correct  =".Dumper(\@correct)."\n";   # 1.16
	}
	@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
	# print('scoreevent='.Dumper(@scoreevent));
	$scoreevent[1] = 300000;
	@correct = ('note',300000,1000,0,60,101);
	ok(Dumper(@scoreevent) eq Dumper(@correct),
	 'alsa2scoreevent() returns ("note",300000,1000,0,60,101)');

	print("# feeding ourselves a sysex_f0 event...\n");
	print $inp "\xF0}hello world\xF7"; # {'sysex_f0',0,'hello world'}
	@alsaevent  = MIDI::ALSA::input();
	$save_time = $alsaevent[4];
	@correct = (130, 5, 0, 1, 300, [$vm,0], [$id,1],
	 ["\xF0}hello world\xF7",undef,undef,undef,0] );
	$alsaevent[3] = 1;   # 1.16 sometimes it's 0 ...
	$alsaevent[4] = 300;
	${$alsaevent[7]}[4] = 0;
	if (! ok(Dumper(@alsaevent) eq Dumper(@correct),
 'input() returns (130,5,0,1,300,[vm,0],[id,1],["\xF0}hello world\xF7"])')) {
		print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.16
		print "# correct  =".Dumper(\@correct)."\n";   # 1.16
	}
	#print('alsaevent='.Dumper(@alsaevent));
	@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
	$scoreevent[1] = 300000;
	@correct = ('sysex_f0',300000,"}hello world\xF7");
	ok(Dumper(@scoreevent) eq Dumper(@correct),
	 'alsa2scoreevent() returns ("sysex_f0",300000,"}hello world\xF7")');

	my @to = MIDI::ALSA::listconnectedto();
	@correct = ([2,0+$virmidi[2],0],);
	#print "to=",Dumper(@to),"correct=",Dumper(@correct);
	ok(Dumper(@to) eq Dumper(@correct),
	 "listconnectedto() returns ([2,$virmidi[2],0])");
	my @from = MIDI::ALSA::listconnectedfrom();
	@correct = ([1,0+$virmidi[0],0],);
	#print "from=",Dumper(@from),"correct=",Dumper(@correct);
	ok(Dumper(@from) eq Dumper(@correct),
	 "listconnectedfrom() returns ([1,$virmidi[0],0])");
}

if (@virmidi < 4) {
	ok(1, 'skipping patch_change event output');
	ok(1, 'skipping control_change event output');
	ok(1, 'skipping note_on event output');
	ok(1, 'skipping note_off event output');
} else {
	open(my $oup, '<', $virmidi[3]) || die "can't open $virmidi[3]: $!\n";
	my $cl_num = $virmidi[2];  # client 25

	print("# outputting a patch_change event...\n");
	my @alsaevent = (11, 1,0,1, 0.5,[$id,0],[$cl_num,0],[0, 0, 0, 0, 0, 99]);
	$rc =  MIDI::ALSA::output(@alsaevent);
	read $oup, $bytes, 2;
	ok($bytes eq "\xC0\x63", 'patch_change event detected');

	print("# outputting a control_change event...\n");
	@alsaevent = (10, 1,0,1, 1.5,[$id,0],[$cl_num,0], [2, 0, 0, 0,10,103]);
	$rc =  MIDI::ALSA::output(@alsaevent);
	read $oup, $bytes, 3;
	ok($bytes eq "\xB2\x0A\x67", 'control_change event detected');

	print("# outputting a note_on event...\n");
	@alsaevent = (6, 1,0,1, 2.0, [$id,1], [$cl_num,0], [0,60,101,0,0]);
	$rc =  MIDI::ALSA::output(@alsaevent);
	read $oup, $bytes, 3;
	#printf "bytes=%vx\n", $bytes;
	ok($bytes eq "\x90\x3C\x65", 'note_on event detected');

	print("# outputting a note_off event...\n");
	@alsaevent = (7, 1,0,1, 2.5, [$id,1], [$cl_num,0], [0, 60, 101, 0, 0]);
	$rc =  MIDI::ALSA::output(@alsaevent);
	read $oup, $bytes, 3;
	#printf "bytes=%vx\n", $bytes;
	ok($bytes eq "\x80\x3C\x65", 'note_off event detected');
}

if (@virmidi <2) {
	ok(1, "skipping disconnectfrom()");
	ok(1, 'skipping SND_SEQ_EVENT_PORT_UNSUBSCRIBED event');
	ok(1, "skipping disconnectto()");
} else {
	print("# running  aconnect -d $virmidi[0] $id:1 ...\n");
	system("aconnect -d $virmidi[0] $id:1");
	foreach (1..5) {  # 1.17
		$rc =  MIDI::ALSA::inputpending();
		@alsaevent  = MIDI::ALSA::input();
		if ($alsaevent[0] != MIDI::ALSA::SND_SEQ_EVENT_SENSING()) { last; }
		my $cl = join ":", @{$alsaevent[5]};
		warn "# discarding a SND_SEQ_EVENT_SENSING event from $cl\n";
	}
	if (! ok($alsaevent[0] == MIDI::ALSA::SND_SEQ_EVENT_PORT_UNSUBSCRIBED,
	 'SND_SEQ_EVENT_PORT_UNSUBSCRIBED event received')) {
		print "# inputpending returned $rc\n";   # 1.16+
		print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.16+
	}
	# inside the if (@virmidi<2) else {   1.18
	$rc = MIDI::ALSA::disconnectto(2,$virmidi[2],0);
	ok($rc, "disconnectto(2,$virmidi[2],0)");
}

$rc = MIDI::ALSA::connectto(2,"$my_name:1");
ok($rc, "connectto(2,'$my_name:1') connected to myself by name");
#system 'aconnect -oil';
@correct = (11, 1, 0, $qid, 2.8, [$id,2], [$id,1], [0, 0, 0, 0, 0, 99] );
$rc =  MIDI::ALSA::output(@correct);
foreach (1..5) {  # 1.17
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	if ($alsaevent[0] != MIDI::ALSA::SND_SEQ_EVENT_SENSING()) { last; }
	my $cl = join ":", @{$alsaevent[5]};
	warn "# discarding a SND_SEQ_EVENT_SENSING event from $cl\n";
}
$latency = int(0.5 + 1000000 * ($alsaevent[4]-$correct[4]));
$alsaevent[3] = $qid;  # 1.16 sometimes it's 0... 1.21 or the other way round
$alsaevent[4] = $correct[4];
if (! ok(Dumper(@alsaevent) eq Dumper(@correct),
  "received an event from myself")) {
	print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.16
	print "# correct  =".Dumper(\@correct)."\n";   # 1.16
}
ok($latency < 10000, "latency was $latency microsec");

$rc = MIDI::ALSA::disconnectfrom(1,$id,2);
ok($rc, "disconnectfrom(1,$id,2)");

my($running, $time, $events) = MIDI::ALSA::status();
($seconds, $microseconds) = Time::HiRes::gettimeofday();
my $end_time = $seconds + 1.0E-6 * $microseconds;
ok($running,'status() reports running');
my $elapsed = $end_time-$start_time;
ok(abs($end_time-$start_time - $time) < 0.1,
"status() reports time = $time not $elapsed");

sleep(1);
($running, $time, $events) = MIDI::ALSA::status();
($seconds, $microseconds) = Time::HiRes::gettimeofday();
$end_time = $seconds + 1.0E-6 * $microseconds;
$elapsed = $end_time-$start_time;
ok(abs($end_time-$start_time - $time) < 0.1,
"status() reports time = $time not $elapsed");

$rc = MIDI::ALSA::stop();
ok($rc,'stop() returns success');

@alsaevent = MIDI::ALSA::noteonevent(15, 72, 100, 2.7);
@correct = (6,1,0,$qid,2.7,[0,0],[0,0],[15,72,100,0,0]);
if (! ok(Dumper(@alsaevent) eq Dumper(@correct), 'noteonevent()')) {
	print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.18
	print "# correct  =".Dumper(\@correct)."\n";   # 1.18
}

@alsaevent = MIDI::ALSA::noteoffevent(15, 72, 100, 2.7);
@correct = (7,1,0,$qid,2.7,[0,0],[0,0],[15,72,100,100,0]);
if (! ok(Dumper(@alsaevent) eq Dumper(@correct), 'noteoffevent()')) {
	print "# alsaevent=".Dumper(\@alsaevent)."\n";   # 1.18
	print "# correct  =".Dumper(\@correct)."\n";   # 1.18
}

@alsaevent  = MIDI::ALSA::noteevent(15, 72, 100, 2.7, 3.1);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('note',2700,3100,15,72,100);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'noteevent()');

@alsaevent = MIDI::ALSA::pgmchangeevent(11, 98, 2.7);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('patch_change',2700,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'pgmchangeevent() with time>=0');

@alsaevent = MIDI::ALSA::pgmchangeevent(11, 98);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('patch_change',0,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'pgmchangeevent() with time undefined');

@alsaevent = MIDI::ALSA::pitchbendevent(11, 98, 2.7);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('pitch_wheel_change',2700,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'pitchbendevent() with time>=0');

@alsaevent = MIDI::ALSA::pitchbendevent(11, 98);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('pitch_wheel_change',0,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'pitchbendevent() with time undefined');

@alsaevent = MIDI::ALSA::chanpress(11, 98, 2.7);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
# print('alsaevent='.Dumper(@alsaevent)."\n");
# print('scoreevent='.Dumper(@scoreevent)."\n");
@correct = ('channel_after_touch',2700,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'chanpress() with time>=0');

@alsaevent = MIDI::ALSA::chanpress(11, 98);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
# print('alsaevent='.Dumper(@alsaevent)."\n");
# print('scoreevent='.Dumper(@scoreevent)."\n");
@correct = ('channel_after_touch',0,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'chanpress() with time undefined');

@correct = ('note',0,1000,15,72,100);
@alsaevent = MIDI::ALSA::scoreevent2alsa(@correct);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'scoreevent2alsa("note"...)');

@correct = ('control_change',10,15,72,100);
@alsaevent = MIDI::ALSA::scoreevent2alsa(@correct);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
ok(Dumper(@scoreevent) eq Dumper(@correct),
  'scoreevent2alsa("control_change"...)');

@correct = ('patch_change',10,15,72);
@alsaevent = MIDI::ALSA::scoreevent2alsa(@correct);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
ok(Dumper(@scoreevent) eq Dumper(@correct),
  'scoreevent2alsa("patch_change"...)');

@correct = ('pitch_wheel_change',10,15,3232);
@alsaevent = MIDI::ALSA::scoreevent2alsa(@correct);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
ok(Dumper(@scoreevent) eq Dumper(@correct),
  'scoreevent2alsa("pitch_wheel_change"...)');

@correct = ('channel_after_touch',10,15,123);
@alsaevent = MIDI::ALSA::scoreevent2alsa(@correct);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
ok(Dumper(@scoreevent) eq Dumper(@correct),
  'scoreevent2alsa("channel_after_touch"...)');

@correct = ('sysex_f0',2,"}hello world\xF7");
@alsaevent = MIDI::ALSA::scoreevent2alsa(@correct);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
ok(Dumper(@scoreevent) eq Dumper(@correct),
  'scoreevent2alsa("sysex_f0"...)');

@correct = ('sysex_f7',2,"that's all folks\xF7");
@alsaevent = MIDI::ALSA::scoreevent2alsa(@correct);
# print "alsaevent=",Dumper(@alsaevent);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
# print "scoreevent=",Dumper(@scoreevent),"correct=",Dumper(@correct);
ok(Dumper(@scoreevent) eq Dumper(@correct),
  'scoreevent2alsa("sysex_f7"...)');

# --------------------------- infrastructure ----------------
sub virmidi_clients_and_files {
	if (!open(P, 'aconnect -oil|')) {
		die "can't run aconnect; you may need to install alsa-utils\n";
	}
	my @virmidi = ();
	while (<P>) {
		if (/^client (\d+):\s*\W*Virtual Raw MIDI (\d+)-(\d+)/) {
			my $f = "/dev/snd/midiC$2D$3";
			if (! -e $f) {
				warn "client $1: can't see associated file $f\n";
				last;
			}
			push @virmidi, 0+$1, $f;
			if (@virmidi >= 4) { last; }
		}
	}
	close P;
	return @virmidi;
}
sub equal { my ($xref, $yref) = @_;
	my @x = @$xref; my @y = @$yref;
	if (scalar @x != scalar @y) { return 0; }
	my $i; for ($i=$[; $i<=$#x; $i++) {
		if (abs($x[$i]-$y[$i]) > 0.0000001) { return 0; }
	}
	return 1;
}

__END__

=pod

=head1 NAME

test.pl - Perl script to test MIDI::ALSA.pm

=head1 SYNOPSIS

 perl test.pl

=head1 DESCRIPTION

This script tests MIDI::ALSA.pm

=head1 AUTHOR

Peter J Billam  http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

MIDI::ALSA.pm , http://www.pjb.com.au/ , perl(1).

=cut

