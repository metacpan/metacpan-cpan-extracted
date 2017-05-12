use strict;
use MPEG::MP3Play qw(:mask :state);
use Term::ReadKey;

$| = 1;

END { ReadMode(0) }

main: {
	# no output buffering
	$| = 1;

	# usage
	print "function keys:\n";
	print "\t+/-\tvolume control\n";
	print "\tb/B less/more bass\n";
	print "\tt/T less/more treble\n";
	print "\te/E equalizer on/off\n";
	print "\ts\tstop playing\n";
	print "\tm\tpause (mute)\n";
	print "\tp\tstart playing\n";
	print "\td\ttoggle debugging\n";

	# non blocking input
	ReadMode(4);
	
	# creation of a new player
	my $mp3 = new MPEG::MP3Play (
		debug => 'all'
	);
	
	$mp3->print_xaudio_implementation;

	# setting user data: our volume state
	$mp3->set_user_data ({
		volume => 50,
		bass => 0,
		treble => 0,
		'eq' => '1',
		debug => 'on'
	});

	# open and play the file
	$mp3->open ("test.mp3");
	$mp3->play;

	# setting volume to our default values
	$mp3->volume (50, 100, 50);

	# this is optional (and for testing):
	# => we want to recieve this two messages only
	# (the PLAYER_STATE message will be processed by
	#  the default message handler: so the handler will
	#  exit on EOF)
	$mp3->set_notification_mask (
		&XA_NOTIFY_MASK_INPUT_TIMECODE,
		&XA_NOTIFY_MASK_PLAYER_STATE
	);

	# the message handler with 50000 usec timeout,
	# so our work method will be invoked

	$mp3->message_handler (50000);

	print "\n";
}

package MPEG::MP3Play;

sub work {
	my ($mp3) = @_;
	
	# this method is called after message timeouts or
	# message processing

	# read a key, non blocking
	my $key = Term::ReadKey::ReadKey(-1) || '';

	# return false if 'q' is pressed. The builtin message handler
	# exits on false, so our application will exit, too.
	return if $key eq 'q';

	# volume control
	my $data = $mp3->get_user_data;

#	use Data::Dumper; print Dumper($data);

	my $volume = $data->{'volume'};
	my $bass = $data->{'bass'};
	my $treble = $data->{'treble'};

	if ( $key eq '+' ) {
		$volume += 5;
		$volume = 100 if $volume > 100;
		$mp3->volume ($volume);
		print "\n" if $data->{'debug'} eq 'on';
	} elsif ( $key eq '-' ) {
		$volume -= 5;
		$volume = 0 if $volume < 0;
		$mp3->volume ($volume);
		print "\n" if $data->{'debug'} eq 'on';
	} elsif ( $key eq 's' ) {
		$mp3->stop;
		print "\n" if $data->{'debug'} eq 'on';
	} elsif ( $key eq 'm' ) {
		$mp3->pause;
		print "\n" if $data->{'debug'} eq 'on';
	} elsif ( $key eq 'p' ) {
		$mp3->play;
		print "\n" if $data->{'debug'} eq 'on';
	} elsif ( $key eq 'd' ) {
		if ( $data->{'debug'} eq 'on' ) {
			$mp3->debug ('none');
			$data->{'debug'} = 'off';
			print "debugging is off\n";
		} else {
			$mp3->debug ('all');
			$data->{'debug'} = 'on';
			print "debugging is on\n";
		}
	} elsif ( $key eq 'b' ) {
		--$bass;
		$bass = -10 if $bass < -10;
		set_eq ($mp3, $bass, $treble);
	} elsif ( $key eq 'B' ) {
		++$bass;
		$bass = 10 if $bass > 10;
		set_eq ($mp3, $bass, $treble);
	} elsif ( $key eq 't' ) {
		--$treble;
		$treble = -10 if $treble < -10;
		set_eq ($mp3, $bass, $treble);
	} elsif ( $key eq 'T' ) {
		++$treble;
		$treble = 10 if $treble > 10;
		set_eq ($mp3, $bass, $treble);
	} elsif ( $key eq 'e' ) {
		print "eq off\n";
		$mp3->equalizer();
	} elsif ( $key eq 'E' ) {
		set_eq ($mp3, $bass, $treble);
	}
	
	$data->{'volume'} = $volume;
	$data->{'bass'} = $bass;
	$data->{'treble'} = $treble;

	# always return true in a message handler
	1;
}

sub set_eq {
	my ($mp3, $bass, $treble) = @_;
	
#	print "bass=$bass treble=$treble\n";
	
	my $bass_max = $bass*12;
	my $treble_max = $treble*12;
	
	my @eq = (0) x 32;
	for (my $i=0; $i < 10; ++$i) {
		$eq[9-$i] = $bass_max * $i / 10;
		$eq[22+$i] = $treble_max * $i / 10;
	}
	
	$mp3->equalizer ( \@eq, \@eq );
	$mp3->get_equalizer;
}

sub msg_notify_input_timecode {
	my ($mp3, $msg) = @_;
	
	# display some nice timecode
	
	print "\r";
	printf "TIMECODE: %02d:%02d:%02d",
		$msg->{timecode_h},
		$msg->{timecode_m},
		$msg->{timecode_s};

	# always return true in a message handler
	1;
}

sub msg_notify_codec_equalizer {
	my ($mp3, $msg) = @_;
	
	my $eq = $msg->{'equalizer'};

	print "EQ: ", join (" ", @{$eq->{left}}), "\n";

}
