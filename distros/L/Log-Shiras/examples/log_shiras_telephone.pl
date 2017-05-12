package MyCoolPackage;
use Moose;
use lib 'lib', '../lib',;
use Log::Shiras::Telephone;

sub make_a_noise{
	my( $self, $message ) = @_;
	my $phone = Log::Shiras::Telephone->new( 
					name_space => 'TellMeAbout::make_a_noise',
					fail_over => 1,
					report => 'spy',
				);
	$phone->talk( level => 'debug',
		message => "Arrived at make_a_noise with the message: $message" );
	print '!!!!!!!! ' . uc( $message  ) . " !!!!!!!!!\n";
	$phone->talk( level => 'info',
		message => "Finished printing message" );
}

package main;

use Modern::Perl;
use Log::Shiras::Switchboard;
use Log::Shiras::Report::Stdout;
use MyCoolPackage;
$| = 1;
my	$agitation = MyCoolPackage->new;
	$agitation->make_a_noise( 'Hello World 1' );#
my	$operator = Log::Shiras::Switchboard->get_operator(
		name_space_bounds =>{
			TellMeAbout =>{
				make_a_noise =>{
					UNBLOCK =>{
						# UNBLOCKing the report (destinations)
						# 	at the 'TellMeAbout::make_a_noise' caller name_space and deeper
						spy	=> 'info',# for info and more urgent messages
					},
				},
			},
		},
	);
	$agitation->make_a_noise( 'Hello World 2' );#
	$operator->add_reports(
		spy =>[ Log::Shiras::Report::Stdout->new, ],
	);
	$agitation->make_a_noise( 'Hello World 3' );#