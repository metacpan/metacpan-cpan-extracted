#!perl -T
use warnings; use strict;
use Test::More tests => 30;
use Test::Fatal;

package main;

use Elive;
use Elive::Connection;
use Elive::Entity::User;
use Elive::Entity::Preload;
use Elive::Entity::Meeting;
use Elive::Entity::MeetingParameters;

use lib '.';
use t::Elive::MockConnection;

Elive->connection( t::Elive::MockConnection->connect() );

isnt(
    exception {
	Elive::Entity::User->construct
	    ({	loginName => 'user',
		loginPassword => 'pass'})} => undef,
##    "can't construct Elive::Entity::User without value for primary key field: userId",
    "construct without primary key - dies"
    );

my %user_data =  (
    userId => 1234,
    loginName => 'bbill',
    loginPassword => 'pass',
    deleted => 0,
    );

my $user_obj;

is(
    exception {
	$user_obj = Elive::Entity::User->construct(\%user_data)
    } => undef,
    "initial construction - lives"
    );

unless ($user_obj) {
    die "dont' have user object - unable to continue testing";
}

$user_obj->loginName( $user_obj->loginName .'x' );

like(
    exception {Elive::Entity::User->construct(\%user_data)} => qr{attempted overwrite of object with unsaved changes}i,
    "reconstructing unsaved object - dies"
    );

$user_obj->revert;

is(
    exception {Elive::Entity::User->construct(\%user_data)} => undef,
    "construction after reverting changes - lives"
    );

is(
    exception {$user_obj->set('email', 'bbill@test.org')} => undef,
    "setter on non-key value - lives"
    );

like(
    exception {$user_obj->set(userId => undef)} => qr{attempt to delete primary key}i,
    "clearing primary key field - dies"
    );

like(
    exception {$user_obj->set('userId', $user_obj->userId.'9')} => qr{attempt to update primary key}i,
    "updating primary key field - dies"
    );

is(
    exception {$user_obj->set('userId', $user_obj->userId)} => undef,
    "ineffective primary key update - lives"
    );

my %meeting_data = (meetingId => 1111111,
		    name => 'test',
		    start => '1234567890123',
		    end => '1234567890123',
		    password => 'work!',
		    restrictedMeeting => 1,
	);

my $meeting;

is(
    exception {$meeting = Elive::Entity::Meeting->construct(\%meeting_data)} => undef,
	 'construct meeting with valid data - lives'
    );

is( exception {$meeting->_readback_check( \%meeting_data, [\%meeting_data] )} => undef,
	 'readback on unchanged data - lives');

like(
    exception {
	my %changed = %meeting_data;
	$changed{meetingId}++;
	$meeting->_readback_check( \%meeting_data, [\%changed] )
    } => qr{Update consistancy check failed}i,
    'readback with changed Int property - dies');

like(
    exception {
	my %changed = %meeting_data;
	$changed{restrictedMeeting} = !$changed{restrictedMeeting};
	$meeting->_readback_check( \%meeting_data, [\%changed] )
    } => qr{Update consistancy check failed}i,
    'readback with changed Bool property - dies');

like(
    exception {
	my %changed = %meeting_data;
	$changed{name} .= 'x';
	$meeting->_readback_check( \%meeting_data, [\%changed] )
    } => qr{Update consistancy check failed}i,
    'readback with changed Str property - dies');

like(
    exception {
	my %changed = %meeting_data;
	$changed{start} .= '9';
	$meeting->_readback_check( \%meeting_data, [\%changed] )
    } => qr{Update consistancy check failed}i,
    'readback with changed hiResDate property - dies');

is(
    exception {
	my %extra = %meeting_data;
	$extra{adapter} = 'test';
	$meeting->_readback_check( \%meeting_data, [\%extra] )
    } => undef,
    'extra readback property - lives');

is(
    exception {
	my %extra = %meeting_data;
	$extra{adapter} = 'test';
	$meeting->_readback_check( \%extra, [\%meeting_data] )
    } => undef,
    'property missing from readback - lives');

is(
    exception {$meeting->set(password => undef)} => undef,
    "setting optional field to undef - lives"
    );

like(
    exception {$meeting->set(start => undef)} => qr{attempt to delete required attribute}i,
    "setting required field to undef - dies"
    );

$meeting->revert;

foreach (qw(meetingId name start end)) {

    my %bad_meeting_data = %meeting_data;
    delete $bad_meeting_data{$_};

    like(
	exception {Elive::Entity::Meeting->construct(\%bad_meeting_data)} => qr{is required}i,
	"meeting without required $_ - dies"
	);
}

foreach my $fld (qw/meetingId start/) {
    like(
	exception {
	    local $meeting_data{$fld} = 'non numeric data';
	    Elive::Entity::Meeting->construct(\%meeting_data);
	} => qr{non numeric}i,
	"meeting with non numeric $fld - dies"
	);
}

is(
    exception {Elive::Entity::MeetingParameters->construct
	     ({
		 meetingId => 1111111,
		 recordingStatus => 'remote',
	      })} => undef,
    'meeting parameters - valid recordingStatus - lives',
    );

like(
    exception {Elive::Entity::MeetingParameters->construct
	     ({
		 meetingId => 222222,
		 recordingStatus => 'CRUD',
	      })} => qr{validation failed}i,
	      'meeting parameters - invalid recordingStatus - dies',
    );       

is(
    exception {Elive::Entity::Preload->construct
	     ({
		 preloadId => 333333,
		 name => 'test.swf',
		 mimeType => 'mimeType=application/x-shockwave-flash',
		 ownerId => 123456789000,
		 size => 1024,
		 type => 'media',
	      })} => undef,
	      'meeting parameters - valid type - lives',
    );

like(
    exception {Elive::Entity::Preload->construct
		   ({
		       preloadId => 333333,
		       name => 'test.swf',
		       mimeType => 'mimeType=application/x-shockwave-flash',
		       ownerId => 123456789000,
		       size => 1024,
		       type => 'crud',
		    })} => qr{validation failed}i,
    'meeting parameters - invalid type - dies',
    );

is(
    exception {Elive::Entity::MeetingParameters->_thaw
	    ({
		MeetingParametersAdapter => {
		    Id => 11111222233334444,
		    RecordingStatus => 'REMOTE',
		}})
    } => undef,
    'thawing valid meeting struct parameters - lives',
    );


like(
    exception {Elive::Entity::MeetingParameters->_thaw
	    ({
		CrudAdapter => {
		    Id => 11111222233334444,
		    RecordingStatus => 'REMOTE',
		}})
    } => qr{unexpected entities in response:: Crud},
    'thawing invalid meeting struct parameters - dies',
    );

$user_obj->revert;
Elive->disconnect;
