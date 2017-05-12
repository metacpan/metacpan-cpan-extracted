use strict;
use MPEG::MP3Play qw(:msg :state);

$| = 1;

my $has_readkey;
BEGIN {
	eval qq{
		use Term::ReadKey;
		\$has_readkey = 1;
		print "Fine - Term::ReadKey loaded OK!\n";
	}
}

END {
	$has_readkey and ReadMode(0);
}

print "Term::ReadKey missing! ReadKey features disabled!\n" unless $has_readkey;

my $mp3 = new MPEG::MP3Play;

$mp3->print_xaudio_implementation;

my $filename = "test.mp3";

if ( -f $filename ) {
	if ( $has_readkey ) {
		print "playing $filename (q=exit, +/-=volume)...\n";
	} else {
		print "playing $filename (press Ctrl+C to stop)...\n";
	}

	$mp3->open ("$filename");
	$mp3->play;
	
	print_status ($mp3);
} else {
	print "Please copy a mp3 file called 'test.mp3' to this directory.\n";
	print "You should hear it if you run 'runsample play.pl' again.\n";
}

sub print_status {
	my ($mp3) = @_;

	$has_readkey and ReadMode(4);
	
	my $volume = 80;
	$mp3->volume ($volume, 100, 50);
	
	my $finish = 0;
	while ( not $finish ) {
		my $msg = $mp3->get_message_wait(50000);

		if ( defined $msg ) {
			my $code = $msg->{code};
		
			if ( $code == &XA_MSG_NOTIFY_INPUT_TIMECODE ) {
				print "\r";
				printf "TIMECODE: %02d:%02d:%02d",
					$msg->{timecode_h},
					$msg->{timecode_m},
					$msg->{timecode_s}
			} elsif ( $code == &XA_MSG_NOTIFY_PLAYER_STATE ) {
				$finish = 1 if $msg->{state} == &XA_PLAYER_STATE_EOF;
			} else {
#				use Data::Dumper;
#				print Dumper ($msg);
			}
		}
	
		if ( $has_readkey ) {
			my $key = ReadKey(-1) || '';
			$finish = 1 if $key eq 'q';
			if ( $key eq '+' ) {
				$volume += 5;
				$volume = 100 if $volume > 100;
				$mp3->volume ($volume);
			} elsif ( $key eq '-' ) {
				$volume -= 5;
				$volume = 0 if $volume < 0;
				$mp3->volume ($volume);
			}
		}
	}

	$has_readkey and ReadMode(0);

	print "\n\n";
}
