#!perl
use Modern::Perl;
use lib 'lib', '../lib',;
use Log::Shiras::Unhide qw( :debug);#
use Log::Shiras::Switchboard;
use Log::Shiras::Telephone;
use Log::Shiras::Report::Stdout;
$| = 1;

sub shout_at_me{
	my $telephone = Log::Shiras::Telephone->new( report => 'run' );
	$telephone->talk( carp_stack => 1, level => 'info', message =>[ @_ ] );
}

###LogSD warn "lets get ready to rumble...";
my $operator = Log::Shiras::Switchboard->get_operator(
		name_space_bounds =>{
			main =>{
				UNBLOCK =>{
					# UNBLOCKing the run reports (destinations)
					# 	at the 'main' caller name_space and deeper
					run	=> 'info',
				},
			},
		},
		reports =>{
			run =>[ Log::Shiras::Report::Stdout->new, ],
		},
	);
###LogSD warn "Getting a Telephone";
my $telephone = Log::Shiras::Telephone->new( report => 'run' );# or just '->new'
$telephone->talk( level => 'trace', message => 'Hello World 1' );
###LogSD warn "message was sent to the report 'run' without sufficient permissions";
$telephone->talk( level => 'info', message => 'Hello World 2' );
###LogSD warn "message sent with sufficient permissions";
shout_at_me( 'Hello World 3' );