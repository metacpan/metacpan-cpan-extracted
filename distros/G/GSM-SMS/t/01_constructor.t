use strict;
use Test::More tests => 29;

BEGIN {
	use_ok( 'GSM::SMS::NBS::Frame' );
	use_ok( 'GSM::SMS::NBS::Message' );
	use_ok( 'GSM::SMS::NBS::Stack' );
	use_ok( 'GSM::SMS::OTA::Bitmap' );
	use_ok( 'GSM::SMS::OTA::CLIicon' );
	use_ok( 'GSM::SMS::OTA::Config' );
	use_ok( 'GSM::SMS::OTA::OTA' );
	use_ok( 'GSM::SMS::OTA::Operatorlogo' );
	use_ok( 'GSM::SMS::OTA::RTTTL' );
	use_ok( 'GSM::SMS::OTA::VCard' );
	use_ok( 'GSM::SMS::OTA::PictureMessage' );
	use_ok( 'GSM::SMS::Config' );
	use_ok( 'GSM::SMS::NBS' );
	use_ok( 'GSM::SMS::PDU' );
	use_ok( 'GSM::SMS::Spool' );
	use_ok( 'GSM::SMS::Transport' );
	use_ok( 'GSM::SMS::Support::RTTTL2MIDI' );
	use_ok( 'GSM::SMS::Transport::File' );
	use_ok( 'GSM::SMS::Transport::MCube' );
	use_ok( 'GSM::SMS::Transport::NovelSoft' );
	use_ok( 'GSM::SMS::Transport::Serial' );
	use_ok( 'GSM::SMS::Transport::Transport' );
	use_ok( 'GSM::SMS::Transport::XmlRpc' );
	use_ok( 'GSM::SMS::EMS::Message' );
	use_ok( 'GSM::SMS::EMS' );
	use_ok( 'GSM::SMS::TransportRouterFactory' );
	use_ok( 'GSM::SMS::TransportRouter::TransportRouter' );
	use_ok( 'GSM::SMS::TransportRouter::Simple' );
	use_ok( 'GSM::SMS::Support::SerialPort' );
}
