#!perl -T
use warnings; use strict;
use Test::More;
use Test::Warn;

use Elive;
use Elive::Connection;
use Elive::Entity;
use Elive::Entity::User;
use Elive::Entity::Meeting;
use Elive::Entity::Preload;
use Elive::Entity::Recording;
use Elive::Entity::Participant;

use lib '.';
use t::Elive::MockConnection;

if (Elive->debug) {
    # because debugging adds spurious warnings
    plan skip_all => "Can't run this test when debugging is enabled";
}

plan tests => 15;

Elive->connection( t::Elive::MockConnection->connect() );

my $meeting;

warnings_like (sub {$meeting = meeting_with_lowres_dates()},
	      qr{doesn't look like a hi-res date},
	      'low-res date gives warning'
    );

warnings_like (sub {$meeting = meeting_with_lowres_dates('-123456789000')},
	      qr{doesn't look like a hi-res date},
	      'negative date gives warning'
    );

warnings_like (\&do_unsaved_update,
	      qr{destroyed without saving .* changes},
	      'unsaved change gives warning'
    );

my $user_1;

warnings_like(
    sub {$user_1 = construct_unknown_property()},
    qr{unknown propert(y|ies)},
    'constructing unknown property gives warning',
    );

ok(!(exists $user_1->{junk1}),"construct discards unknown property");

warnings_like(
    sub {$user_1->_db_data->is_changed},
    qr{is_changed called on non-database object},
    'calling is_changed on non-database object produces a warning'
    );


non_pkey_changed();

warnings_like(
    \&pkey_changed,
    qr(rimary key field has been modified),
    "is_changed warning following pkey update"
    );

my $user_2;

warnings_like(
sub {$user_2 = set_unknown_property()},
    qr{unknown property},
    "setting unknown property gives warning"
    );

ok(!(exists $user_2->{junk2}),"set discards unknown property");

my $thawed_data;

my $preload_data = {
    PreloadAdapter => {
	Id => '1122334455667',
	Name => 'test.bin',
	Type => 'MEdia',
	Mimetype => 'application/octet-stream',
	OwnerId => '123456789000',
	Size => 42,
    },
};

$thawed_data = Elive::Entity::Preload->_thaw($preload_data);
is($thawed_data->{type}, 'media', "type (media) as expected");

warnings_like(
    sub {$thawed_data = thaw_with_bad_preload_type($preload_data)},
    qr(ignoring unknown media type),
    "thawing unknown media type gives warning"
    );

ok(!exists $thawed_data->{type}, "unknown media type filtered from data");

my $meeting_parameter_data = {
    MeetingParametersAdapter => {
	Id => '11111222233334444',
	RecordingStatus => 'rEMoTE',
    },
};

$thawed_data = Elive::Entity::MeetingParameters->_thaw($meeting_parameter_data);
is($thawed_data->{recordingStatus}, 'remote', "valid recording status conversion");

warnings_like(
    sub {$thawed_data = thaw_with_bad_recording_status($meeting_parameter_data)},
    qr(ignoring unknown recording status),
    "thawing unknown media type gives warning"
    );

guest_participant_valid();

warnings_like( \&guest_participant_with_forced_moderator_role,
	       qr{ignoring moderator role},
	       'guest participant with forced moderator role gives warning'
    );

exit(0);

########################################################################

sub meeting_with_lowres_dates {

    my $start = shift || '1234567890';

    my $meeting = Elive::Entity::Meeting->construct
	({
	    meetingId => 11223344,
	    name => 'test meeting',
	    start => $start,  #too short
	    end => '1244668890000', #good
         },
	);
}

sub do_unsaved_update {

    my $user = Elive::Entity::User->construct
	({
	    userId => 123456,
	    loginName => 'some_user',
	    loginPassword => 'some_pass',
         },
	);

    $user->loginName($user->loginName . 'x');
    $user = undef;
}

sub construct_unknown_property {
    my $user = Elive::Entity::User->construct
	({  userId => 1234,
	    loginName => 'user',
	    loginPassword => 'pass',
	    junk1 => 'abc',
	 });

    return $user;
}

sub set_unknown_property {
    my $user = Elive::Entity::User->construct
	({  userId => 5678,
	    loginName => 'user',
	    loginPassword => 'pass',
	});
    $user->set(junk2 => 'xyz');
    return $user;
}

sub non_pkey_changed {
    my $user = Elive::Entity::User->construct
	({  userId => 5678,
	    loginName => 'user',
	    loginPassword => 'pass',
	});
    $user->{loginPassword} = 'pass2';
    $user->is_changed;
    $user->revert;
}

sub pkey_changed {
    my $user = Elive::Entity::User->construct
	({  userId => 5678,
	    loginName => 'user',
	    loginPassword => 'pass',
	});
    $user->{userId} = 998877;
    $user->is_changed;
    $user->{userId} = 5678;

}

sub thaw_with_bad_preload_type {
    my $preload_data = shift;

    local $preload_data->{PreloadAdapter}{Type} = 'guff';

    return Elive::Entity::Preload->_thaw($preload_data);
}

sub thaw_with_bad_recording_status {
    my $preload_data = shift;

    local $preload_data->{MeetingParametersAdapter}{RecordingStatus} = 'guff';

    return Elive::Entity::MeetingParameters->_thaw($preload_data);
}

sub guest_participant_valid {
    my $participant = Elive::Entity::Participant->construct(
      {
	  type => 2,
	  guest => {
	      invitedGuestId => 1111,
	      loginName => 'bob@acme.com',
	      displayName => 'Robert'
	  },
	  role => 3,
      });
    $participant->stringify;
};

sub guest_participant_with_forced_moderator_role {
    my $participant = Elive::Entity::Participant->construct(
      {
	  type => 2,
	  guest => {
	      invitedGuestId => 2222,
	      loginName => 'bob@acme.com',
	      displayName => 'Robert'
	  },
	  role => 2,
      });
};




