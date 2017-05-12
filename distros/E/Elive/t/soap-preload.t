#!perl -T
use warnings; use strict;
use Test::More tests => 65;
use Test::Fatal;
use version;

use lib '.';
use t::Elive;

use Elive;
use Elive::Entity::Preload;
use Elive::View::Session;
use Elive::Util;

use File::Spec qw();
use File::Temp qw();
use Try::Tiny;

our $t = Test::More->builder;
my $class = 'Elive::Entity::Preload' ;

my @data;
$data[0] = 'the quick brown fox. %%(&)+(*)+*(_+';
$data[1] = join('',map {pack('C', $_)} (0..255));

for (0..1) {
    #
    # belongs in util tests
    is(Elive::Util::_hex_decode(Elive::Util::_hex_encode($data[$_])), $data[$_], "hex encode/decode round-trip [$_]");   
}

SKIP: {

    my %result = t::Elive->test_connection(only => 'real');
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests', 63)
	unless $auth;

    my $connection_class = $result{class};
    my $connection = $connection_class->connect(@$auth);
    Elive->connection($connection);

    my @preloads;

    $preloads[0] = Elive::Entity::Preload->upload(
    {
	type => 'whiteboard',
	name => 'test.wbd',
	ownerId => Elive->login,
	data => $data[0],
    },
    );

    isa_ok($preloads[0], $class, 'preload object');

    is($preloads[0]->type, 'whiteboard', "preload type is 'whiteboard'");
    is($preloads[0]->mimeType, 'application/octet-stream','expected value for mimeType (guessed)');
    ok($preloads[0]->name =~ m{test(\.wbd)?$}, 'preload name, as expected');
    is($preloads[0]->ownerId, Elive->login->userId, 'preload ownerId, as expected');
    is($preloads[0]->size, length($data[0]), 'preload size, as expected');

    my $data_download = $preloads[0]->download;

    ok($data_download, 'got data download');
    is($data_download, $data[0], 'download data matches upload');

    ok (my $preload_id = $preloads[0]->preloadId, 'got preload id');

    $preloads[0] = undef;

    ok($preloads[0] = Elive::Entity::Preload->retrieve($preload_id), 'preload retrieval');

    #
    # try upload from a file
    #

    my ($fh, $filename)
	= File::Temp::tempfile('elive-t-soap-preload-XXXXXXXX',
			       SUFFIX => '.wav',
			       DIR => File::Spec->tmpdir() );

    binmode $fh;
    print $fh $data[1];
    close $fh;

    $preloads[1] = Elive::Entity::Preload->upload( $filename );
    unlink( $filename );

    $data_download = $preloads[1]->download;
       
    ok($data_download, 'got data download');
    is($data_download, $data[1], 'download data matches file upload');

    is($preloads[1]->type, 'media','expected value for mimeType (uploaded file)');

    is($preloads[1]->mimeType, 'audio/x-wav','expected value for mimeType (defaulted)');
    is($preloads[1]->ownerId, Elive->login->userId,'preload owner id defaults to login user');

    $preloads[2] = Elive::Entity::Preload->upload(
    {
	type => 'whiteboard',
	name => 'test_unknown_ext.xyz',
	ownerId => Elive->login,
	mimeType => 'video/mpeg',
	data => $data[1],
    },
    );

    is($preloads[2]->mimeType, 'video/mpeg','expected value for mimeType (set)');

    $preloads[3] = Elive::Entity::Preload->upload(
    {
	type => 'plan',
	name => 'test_plan.elpx',
	ownerId => Elive->login,
	data => $data[1],
    },
    );

    is($preloads[3]->type, 'plan','expected type (plan)');
    is($preloads[3]->mimeType, 'application/octet-stream','expected mimeType for plan');

    isnt( exception {$preloads[3]->update({name => 'test_plan.elpx updated'})} => undef, 'preload update - not available');

    $data_download = $preloads[3]->download;

    is($data_download, $data[1], 'plan download matches upload');

    my $check;

    #
    # use three mechanisims to associate meetings with preloads
    #
    # 1. session insert
    # 2. session update
    # 3. add_preload method on meeting

    ok(my $session = Elive::View::Session->insert({
	name => 'created by t/soap-preload.t',
	facilitatorId => Elive->login,
	start => time() . '000',
	end => (time()+900) . '000',
	privateMeeting => 1,
	add_preload => [ $preloads[0], $preloads[1] ],
    }),
	'inserted session');

    # preload 0,1 - added at session setup

    is( exception {$check = $session->check_preload($preloads[0])} => undef,
	     'session->check_preload - lives');

    ok($check, 'check_preload following session creation');

    # preload 2 - meeting level access

    is( exception {$check = $session->meeting->check_preload($preloads[2])} => undef,
	     'session->check_preloads - lives');

    ok(!$check, 'check_preload prior to add - returns false');

    is( exception {$session->meeting->add_preload($preloads[2])} => undef,
	     'adding meeting preloads - lives');

    is( exception {$check = $session->meeting->check_preload($preloads[2])} => undef,
	     'meeting->check_preloads - lives');

    ok($check, 'check_meeting after add - returns true');

    # just to define what happens if we attempt to re-add a preload
    isnt( exception {$check = $session->meeting->add_preload($preloads[2])} => undef,
	     're-add of preload to session - dies');

    # preload 3 - session level access

    is( exception {$check = $session->check_preload($preloads[3])} => undef,
	     'session->check_preloads - lives');

    ok(!$check, 'check_preload prior to add - returns false');

    is( exception {$session->update({add_preload => $preloads[3]})} => undef,
	     'adding meeting preloads - lives');

    is( exception {$check = $session->check_preload($preloads[3])} => undef,
	     'meeting->check_preloads - lives');

    ok($check, 'check_meeting after add - returns true');

    my $preloads_list;
    is( exception {$preloads_list = $session->list_preloads} => undef,
	     'list_session_preloads - lives');

    isa_ok($preloads_list, 'ARRAY', 'preloads list');

    is(@$preloads_list, scalar @preloads, 'meeting has expected number of preloads');

    do {
	my @preload_ids = map {$_->preloadId} @preloads;
	my $n = 0;

	foreach (@$preloads_list) {
	    isa_ok($_, 'Elive::Entity::Preload', "preload_list[$n]");
	    my $preload_id = $_->preloadId;
	    ok((grep {$_ eq $preload_id} @preload_ids), "preload_id[$n] - as expected");
	    ++$n;
	    
	}
    };

    #
    # verify that we can remove a preload
    #
    is( exception {$session->remove_preload($preloads[1])} => undef,
	      'meeting->remove_preload - lives');

    is( exception {$preloads[0]->delete} => undef, 'preloads deletion - lives');
    #
    # just directly delete the second preload
    #
    # the meeting should be left with one preload
    #

    my $preloads_list_2;
    is( exception {$preloads_list_2 = $session->list_preloads} => undef,
             'list_meeting_preloads - lives');

    isa_ok($preloads_list_2, 'ARRAY', 'preloads list');

    is(scalar(@$preloads_list_2), scalar(@preloads)-2, 'meeting still has expected number of preloads');

    $session->delete;

    isnt( exception {$preloads[0]->retrieve($preload_id)} => undef, 'attempted retrieval of deleted preload - dies');
    my $server_details =  Elive->server_details
	or die "unable to get server details - are all services running?";

    my $version = version->parse($server_details->version)->numify;
    TODO: {
	local($TODO);
	$TODO = 'skipping known Elluminate v10.0.0+ bugs'
	    if $version >= '10';

	is( exception {
	    push (@preloads, Elive::Entity::Preload->upload(
		      {
			  type => 'whiteboard',
			  name => 'test_no_extension',
			  ownerId => Elive->login,
			  mimeType => 'video/mpeg',
			  data => $data[1],
		  },
		  ))} => undef,
		  'upload of preload with no extension - lives'
	    );

	is($preloads[-1] && $preloads[-1]->mimeType, 'video/mpeg','expected value for mimeType (set, no-extension)');
    }

    foreach (@preloads) {
	try{ $_->delete } if $_;
    }

    if ($ENV{ELIVE_TEST_PRELOAD_SERVER_PATH}
	&& -e $ENV{ELIVE_TEST_PRELOAD_SERVER_PATH}) {
	# untaint
	my ($path_on_server) = ($ENV{ELIVE_TEST_PRELOAD_SERVER_PATH} =~ m{(.*)});
	note 'running preload import tests ($ELIVE_TEST_PRELOAD_SERVER_PATH set)';
	note "importing server-side file: $path_on_server";
	my $basename = File::Basename::basename($path_on_server);
	my $imported_preload;

	my $expected_size = -s $path_on_server;

	is( exception {
	    $imported_preload = Elive::Entity::Preload->import_from_server(
		{
		    name => $basename,
		    ownerId => Elive->login,
		    fileName => $path_on_server,
		},
		);
		  } => undef,
		  'import_from_server - lives',     
         );

	isa_ok($imported_preload, 'Elive::Entity::Preload', 'imported preload');

	note 'imported preload has size: '.$imported_preload->size.' and type '.$imported_preload->type.' ('.$imported_preload->mimeType.')';

	is($imported_preload->name, $basename, 'imported preload name as expected');
	is($imported_preload->size, $expected_size, 'imported preload has expected size');
	is ( exception {$imported_preload->delete} => undef, 'imported preload delete - lives');

	#
	# try the short form as well
	#
	is( exception {
	    $imported_preload = Elive::Entity::Preload->import_from_server( $path_on_server)
		  } => undef, 'import_from_server (short form) - lives');

	isa_ok($imported_preload, 'Elive::Entity::Preload', 'imported preload');

	note 'imported preload has size: '.$imported_preload->size.' and type '.$imported_preload->type.' ('.$imported_preload->mimeType.')';

	is($imported_preload->name, $basename, 'imported preload name as expected');
	is($imported_preload->size, $expected_size, 'imported preload has expected size');
	is ( exception {$imported_preload->delete} => undef, 'imported preload delete - lives');
 }
    else {
	$t->skip('skipping import_preload_test (set ELIVE_TEST_PRELOAD_SERVER_PATH to run)')
	    for (1 .. 10);
    }
}

Elive->disconnect;

