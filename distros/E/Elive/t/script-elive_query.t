#!perl
use warnings; use strict;
use File::Spec;
use Test::More;
use Test::Fatal;
use English qw(-no_match_vars);
use Try::Tiny;

use lib '.';
use t::Elive;
use Elive;

use File::Spec;

eval "use Test::Script::Run 0.04 qw{:all}";

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Script::Run 0.04+ required to run scripts';
    plan( skip_all => $msg );
}

local ($ENV{TERM}) = 'dumb';

plan(tests => 34);

our $script_name = 'elive_query';
our $t = Test::More->builder;

do {
    #
    # try running script with --help
    #

    my ( $return, $stdout, $_stderr ) = run_script ($script_name, ['--help'] );
    my $status = last_script_exit_code();
    is($status   => 0, "$script_name --help: zero exit status");
    
    like($stdout => qr{usage:}ix, "$script_name --help: stdout =~ 'usage:...''");
};

do {
    # 
    # try with invalid option
    #

    my ( $return, $stdout, $stderr ) = run_script($script_name, ['--invalid-opt']  );
    my $status = last_script_exit_code();

    isnt($status => 0, "$script_name invalid option: non-zero exit status");

    is($stdout   => '', "$script_name invalid option: stdout empty");

    like($stderr => qr{unknown \s+ option}ix, "$script_name invalid option: error");
    like($stderr => qr{usage:}ix, "$script_name invalid option: usage");

};

do {
    #
    # invalid command
    #

    my ( $return, $stdout, $stderr ) = run_script($script_name, [-c => 'blah blah'] );
    my $status = last_script_exit_code();

    isnt($status => 0, "$script_name invalid command: non-zero exit status");
    like($stderr => qr{unrecognised \s command: \s blah}ixs, "$script_name invalid command: error as expected");
    is($stdout   => '', "$script_name invalid command: no output");
};

do {
    #
    # describe one of the entities: user
    #

    my ($return, $stdout, $_stderr) = run_script ($script_name, [-c => 'describe user']);
    my $status = last_script_exit_code();

    is($status   => 0, "$script_name describe user: zero exit status");
    like($stdout => qr{user: \s+ Elive::Entity::User .* userId \s+ : \s+ pkey \s+ Str}ixs, "$script_name describe user: looks like dump of users entity");

};

do {
    #
    # describe unknown entity
    #

    my ( $return, $stdout, $stderr ) = run_script($script_name, [-c => 'describe crud'] );
    my $status = last_script_exit_code();

    isnt($status => 0, "$script_name describe unknown: non-zero exit status");

    like($stderr => qr{unknown \s+ entity: \s+ crud}ix, "$script_name describe unknown: error");
    is($stdout   => '', "$script_name describe unknown: no output");
};

SKIP: {

    my %result = t::Elive->test_connection(only => 'real');
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests', 20)
	unless $auth && @$auth >= 3;

    my ($url, $user, $pass) = @$auth;

    my $connection_class = $result{class};
    my $connection = $connection_class->connect(@$auth)
	or die "failed to connect?";

    foreach my $selection (qw(serverDetailsId * **), 'name,serverDetailsId') {
	#
	# simple query on server details
	#
	my ( $return, $stdout, $stderr ) = run_script(
	    $script_name,
	    [$url,
	     -user => $user,
	     -pass => $pass,
	     -c => "select $selection from serverDetails"]);
       
	my $status = last_script_exit_code();

	is($status  => 0, "$script_name select: zero exit status");

	like($stdout => qr{serverDetailsId .* \w+ }ixs, "$script_name 'select $selection from serverDetails expected output");
	
    };

    try {require YAML::Syck}
    catch {
	# YAML::Syck is a Elive prequesite
	die "unable to load YAML::Syck - can't continue: $_";
    };

    do {
	#
	# simple query on server details - yaml dump of output
	#

	my ( $return, $stdout, $stderr ) = run_script(
	    $script_name,
	    [$url,
	     -user => $user,
	     -pass => $pass,
	     -dump => 'yaml',
	     -c => 'select serverDetailsId,version from serverDetails']);

       
	like($stderr => qr{^connecting}i, "$script_name -c '..' connecting message");

	my $data;
	my @_others;

	#
	# there can potentially be several servers. Pick one and make
	# sure it's known to us.
	#
	is( exception {($data, @_others) = YAML::Syck::Load($stdout)} => undef, '-dump=yaml output is parsable YAML');
	isa_ok($data, 'HASH', 'result');

	my $server_details_id = $data->{ServerDetails}{serverDetailsId};
	my $server_version = $data->{ServerDetails}{version};

	ok($server_details_id, 'hash structure contains ServerDetails.serverDetailsId');
	ok($server_version, 'hash structure contains ServerDetails.version');

	my ($server_details) = grep {$_->serverDetailsId eq $server_details_id} ($connection->server_details);
	ok( $server_details, 'server details fetch via soap query');
	is ($server_details->version, $server_version, 'matching serverDetails.id');
    };

    do {
	#
	# now create and verify a session
	#
	require Elive::View::Session;

	my $session_start = time();
	my $session_end = $session_start + 900;

	$session_start .= '000';
	$session_end .= '000';

	my %insert_data = (
	    name => 'test, generated by t/script-elive_query.t',
	    password => '&&(*',
	    start =>  $session_start,
	    end => $session_end,
	    facilitatorId => $connection->login,
	    privateMeeting => 1,
	    costCenter => 'testing',
	    moderatorNotes => 'test moderator notes. Here are some entities: & > <',
	    userNotes => 'test user notes; some more entities: &gt;',
	    recordingStatus => 'remote',
	    raiseHandOnEnter => 0,
	    maxTalkers => 2,
	    inSessionInvitation => 1,
	    boundaryMinutes => 15,
	    fullPermissions => 1,
	    supervised => 1,
	    seats => 2,
	    );

	my $session = Elive::View::Session->insert(\%insert_data,
						   connection => $connection);
	my $session_id = $session->id;

	my %expected_content = map {$_ => scalar $session->$_} Elive::View::Session->properties;
	my $expected_data = {Session => \%expected_content};

	my ( $return, $stdout, $stderr ) = run_script(
	    $script_name,
	    [$url,
	     -user => $user,
	     -pass => $pass,
	     -dump => 'yaml',
	     -c => 'select * from session where id='.$session_id]);

       
	like($stderr => qr{^connecting}i, "$script_name -c '..' connecting message");

	my $data;
	my @guff;

	is( exception {($data, @guff) = YAML::Syck::Load($stdout)} => undef, '-dump=yaml output is parsable YAML');
	isa_ok($data, 'HASH', 'result');

	ok(!@guff, 'single result returned for single row query');

	is_deeply($data => $expected_data, 'yaml dump matches session contents');

	$session->delete;

	$connection->disconnect;

    };
}
