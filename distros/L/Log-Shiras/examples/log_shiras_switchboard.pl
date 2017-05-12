#!perl
use Modern::Perl;
use lib 'lib', '../lib',;
use Log::Shiras::Unhide qw( :debug :InternalSwitchboarD );# ;#
use Log::Shiras::Switchboard;
###InternalSwitchboarD	use Log::Shiras::Report::Stdout;
$| = 1;
###LogSD warn "lets get ready to rumble...";
my $operator = Log::Shiras::Switchboard->get_operator(
		name_space_bounds =>{
			main =>{
				UNBLOCK =>{
					# UNBLOCKing the quiet, loud, and run reports (destinations)
					# 	at the 'main' caller name_space and deeper
					quiet	=> 'warn',
					loud	=> 'info',
					run		=> 'trace',
				},
			},
			Log =>{
				Shiras =>{
###InternalSwitchboarD	Switchboard =>{#<-- Internal reporting enabled here
###InternalSwitchboarD		get_operator =>{
###InternalSwitchboarD			UNBLOCK =>{
###InternalSwitchboarD				# UNBLOCKing log_file
###InternalSwitchboarD				# 	at Log::Shiras::Switchboard::get_operator
###InternalSwitchboarD				#	(self reporting)
###InternalSwitchboarD				log_file => 'info',
###InternalSwitchboarD			},
###InternalSwitchboarD		},
###InternalSwitchboarD		master_talk =>{
###InternalSwitchboarD			_buffer_decision =>{
###InternalSwitchboarD				UNBLOCK =>{
###InternalSwitchboarD					# UNBLOCKing log_file
###InternalSwitchboarD					# 	at Log::Shiras::Switchboard::master_talk::_buffer_decision
###InternalSwitchboarD					#	(self reporting)
###InternalSwitchboarD					log_file => 'trace',
###InternalSwitchboarD				},
###InternalSwitchboarD			},
###InternalSwitchboarD		},
###InternalSwitchboarD		send_buffer_to_output =>{
###InternalSwitchboarD			UNBLOCK =>{
###InternalSwitchboarD				# UNBLOCKing log_file
###InternalSwitchboarD				# 	at Log::Shiras::Switchboard::_flush_buffer
###InternalSwitchboarD				#	(self reporting)
###InternalSwitchboarD				log_file => 'info',
###InternalSwitchboarD			},
###InternalSwitchboarD		},
###InternalSwitchboarD	},#<-- Internal reporting enabled through here
				},
			},
		},
		reports =>{
			quiet =>[
				Print::Wisper->new,
			],
			loud =>[
				{
					package => 'Print::Excited',
					add_methods =>{
						add_line => sub{
							shift;
							my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ?
											@{$_[0]->{message}} : $_[0]->{message};
							my @new_list;
							map{ push @new_list, $_ if $_ } @input;
							chomp @new_list;
							print '!!!' . uc(join( ' ', @new_list)) . "!!!\n";
						}
					},
				}
			],
###InternalSwitchboarD	log_file =>[
###InternalSwitchboarD		Log::Shiras::Report::Stdout->new,
###InternalSwitchboarD	],
		},
		all_buffering =>{
			quiet => [],
		},
	);
###LogSD warn "sending the message 'Hello World 1'";
$operator->master_talk({
 	report => 'log_file', level => 'warn', name_space => 'main',
	message =>[ 'Hello World 1' ] });
###LogSD warn "The name_space 'main' does not have destination 'log_file' permissions";
###LogSD warn "sending the message 'Hello World 2' to the report 'quiet'";
$operator->master_talk({
	report => 'quiet', level => 'warn', name_space => 'main',
	message =>[ 'Hello World 2' ] });
###LogSD warn "message went to the buffer - turning off buffering for the 'quiet' destination ...";
$operator->stop_buffering( 'quiet' );
###LogSD warn "should have printed what was in the 'quiet' buffer ...";
$operator->master_talk({
	report => 'quiet', level => 'debug', name_space => 'main',
	message =>[ 'Hello World 3' ] });
###LogSD warn "sending the message 'Hello World 4' to the report 'loud'";
$operator->master_talk({
	report => 'loud', level => 'info', name_space => 'main',
	message =>[ 'Hello World 4' ] });
###LogSD warn "sending the message 'Hello World 5' to the report 'run'";
my $result = 1;
$result = $operator->master_talk({
 	report => 'run', level => 'warn', name_space => 'main',
	message =>[ 'Hello World 5' ] });
###LogSD warn "message to 'run' at 'warn' level was approved";
###LogSD warn "...but found -$result- reporting destinations (None were set up)";

package Print::Wisper;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ?
					@{$_[0]->{message}} : $_[0]->{message};
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	print '--->' . lc(join( ' ', @new_list )) . "<---\n";
}

1;