package MyMP3Play;

use MPEG::MP3Play ':state';

@ISA = qw( MPEG::MP3Play );

sub msg_notify_input_position {
	my ($mp3, $msg) = @_;
	
	my $data = $mp3->get_user_data;

	my $percent = $msg->{position_offset}/$msg->{position_range};
	$data->{pbar}->update($percent);
}

sub msg_notify_player_state {
	my ($mp3, $msg) = @_;
	
	my $data = $mp3->get_user_data;

	main::cleanup_and_exit($data->{input_tag})
		if $msg->{state} == &XA_PLAYER_STATE_EOF;
}
