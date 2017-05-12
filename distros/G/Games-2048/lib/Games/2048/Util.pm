package Games::2048::Util;
use 5.012;
use strictures;

use if $^O eq "MSWin32", "Win32::Console::ANSI";
use Term::ReadKey;
use Time::HiRes;

eval 'END { ReadMode "normal" }';
ReadMode "cbreak";

# manual and automatic window size updating
my $_window_size;
my $_window_size_is_automatic = eval { $SIG{WINCH} = \&update_window_size; 1 };

sub read_key {
	state @keys;

	if (@keys) {
		return shift @keys;
	}

	my $char;
	my $packet = '';
	while (defined($char = ReadKey -1)) {
		$packet .= $char;
	}

	push @keys, $packet =~ m(
		\G(
			\e \[          # CSI
			[\x30-\x3f]*   # Parameter Bytes
			[\x20-\x2f]*   # Intermediate Bytes
			[\x40-\x7e]    # Final Byte
		|
			.              # Otherwise just any character
		)
	)gsx;

	return shift @keys;
}

sub poll_key {
	while (1) {
		my $key = read_key;
		return $key if defined $key;
		Time::HiRes::sleep(0.1);
	}
	return;
}

sub key_vector {
	my ($key) = @_;
	state $vectors = [ [0, -1], [0, 1], [1, 0], [-1, 0] ];
	state $keys = [ map "\e[$_", "A".."D" ];
	for (0..3) {
		return $vectors->[$_] if $key eq $keys->[$_];
	}
	return;
}

sub frame_delay {
	state $time;

	if (@_ < 1) {
		$time = Time::HiRes::time;
	}
	else {
		my ($frame_time) = @_;

		my $new_time = Time::HiRes::time;
		my $delta_time = $new_time - $time;
		my $delay = $frame_time - $delta_time;
		$time = $new_time;
		if ($delay > 0) {
			Time::HiRes::sleep($delay);
			$time += $delay;
		}
	}
}

sub update_window_size {
	($_window_size) = eval { GetTerminalSize *STDOUT };
	$_window_size //= 80;
}

sub window_size {
	$_window_size;
}

sub window_size_is_automatic {
	$_window_size_is_automatic;
}

sub maybe {
	if    (@_ == 2) { return @_ if defined $_[1] }
	elsif (@_ == 1) { return @_ if defined $_[0] }
	return;
}

1;
