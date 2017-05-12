package Log::Shiras::Switchboard;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalSwitchboarD );
###InternalSwitchboarD	warn "You uncovered internal logging statements for Log::Shiras::Switchboard-$VERSION" if !$ENV{hide_warn};
use MooseX::Singleton;
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
use DateTime;
use Carp qw( cluck confess longmess );
$Carp::CarpInternal{'Log::Shiras::Switchboard'}++;
use MooseX::Types::Moose qw(
		HashRef			ArrayRef		Bool		RegexpRef		Str
		Int				Maybe			Undef
	);
use Clone 'clone';
use Data::Dumper;
use lib
		'lib',
		'../lib',
		;
use MooseX::ShortCut::BuildInstance v1.44 qw( build_instance should_re_use_classes );
should_re_use_classes( 1 );
use Data::Walk::Extracted v0.28;
use Data::Walk::Prune v0.028;
use Data::Walk::Graft v0.028;
use Data::Walk::Print v0.028;
use Data::Walk::Clone v0.024;
use Log::Shiras::Types qw(
		ElevenArray		ElevenInt		ReportObject		YamlFile
		JsonFile		FileHash		ArgsHash
	);#

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

my 	@default_levels = (
		'trace', 'debug', 'info', 'warn', 'error', 'fatal',
		undef, undef, undef, undef, undef, 'eleven',# This one goes to eleven :^|
	);
my $time_zone = DateTime::TimeZone->new( name => 'local' );
use constant TALK_DEBUG => 0; # Author testing only
use constant IMPORT_DEBUG => 0; # Author testing only
use constant GET_OPERATOR_DEBUG => 0; # Author testing only

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has name_space_bounds =>(
		isa		=> HashRef[HashRef],
		reader	=> 'get_name_space',
		clearer	=> '_clear_all_name_space',
		writer	=> '_set_whole_name_space',
		default	=> sub{ {} },
		trigger	=> \&_clear_can_communicate_cash,
	);

has	reports =>(
		traits	=> ['Hash'],
		isa		=> HashRef[ArrayRef],
		reader	=> 'get_reports',
		writer	=> '_set_all_reports',
		handles	=>{
			has_no_reports	=> 'is_empty',
			_set_report		=> 'set',
			get_report		=> 'get',
			remove_reports	=> 'delete',
		},
		default	=> sub{ {} },
	);

has	logging_levels =>(
		traits	=> ['Hash'],
		isa		=> HashRef[ElevenArray],
		handles	=>{
			has_log_levels 		=> 'exists',
			add_log_levels 		=> 'set',
			_get_log_levels		=> 'get',
			remove_log_levels 	=> 'delete',
		},
		writer	=> 'set_all_log_levels',
		reader	=> 'get_all_log_levels',
		default	=> sub{ {} },
	);

has all_buffering =>(
		isa		=> HashRef[ArrayRef],
		traits	=> ['Hash'],
		writer => 'set_all_buffering',
		reader => '_get_all_buffering',
		handles	=>{
			has_buffer		=> 'exists',
			stop_buffering	=> 'delete',
			_set_buffer		=> 'set',
			_get_buffer		=> 'get',
			_get_buffer_list => 'keys',
		},
		default	=> sub{ {} },
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub import {
    my( $class, @args ) = @_;
	my $instance = $class->instance;#Returns a pre-existing instance if it exists
	return 1 if $instance->_has_import_recursion_block; # Only accept the first build!
	$instance->_set_import_recursion_block( 1 );
	warn "Received args:" . join( '~|~', @args ) if @args and IMPORT_DEBUG;

	# Handle versions (and other nonsense)
	if( $args[0] and $args[0] =~ /^v?\d+\.?\d*/ ){# Version check since import highjacks the built in
		warn "Running version check on version: $args[0]" if IMPORT_DEBUG;
		my $result = $VERSION <=> version->parse( $args[0]);
		warn "Tested against version -$VERSION- gives result: $result" if IMPORT_DEBUG;
		if( $result < 0 ){
			confess "Version -$args[0]- requested for Log::Shiras::Switchboard " .
					"- the installed version is: $VERSION";
		}
		shift @args;
	}
	if( @args ){
		confess "Unknown flags passed to Log::Shiras::Switchboard: " . join( ' ', @args );
	}

	# Still not sure why this is needed but maybe because of the singlton?
	no warnings 'once';
	if($Log::Shiras::Unhide::strip_match) {
		eval 'use Log::Shiras::Unhide';
	}
	use warnings 'once';
	warn "Finished the switchboard import" if IMPORT_DEBUG;
}

#Special MooseX::Singleton instantiation that pulls multiple instances into the same master case
# This method won't report until the caller name_space and report destination are set up
#  use the constant GET_OPERATOR_DEBUG to see unreported messages
sub get_operator{
	my( $maybe_class, @args ) = @_;
	if( $maybe_class ne __PACKAGE__ ){
		unshift @args, $maybe_class;
		$maybe_class = __PACKAGE__;
	}
	my	$instance = $maybe_class->instance;#Returns a pre-existing instance if it exists
	my	$arguments =
			( !@args) ? undef :
			( ( @args > 1 ) and ( scalar( @args ) % 2 == 0 ) ) ? { @args } :
			( is_YamlFile( $args[0] ) or is_JsonFile( $args[0] ) ) ? to_FileHash( $args[0] ) :
				to_ArgsHash( $args[0] );
	###InternalSwitchboarD	my $talk_result = 1;
	###InternalSwitchboarD	$talk_result = $instance->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
	###InternalSwitchboarD		message =>[ "Initial parsing of arguments yeilds:", $arguments ], } );
	###InternalSwitchboarD	warn "Initial parsing of arguments yeilds:" . Dumper( $arguments ) if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
	if( $arguments and exists $arguments->{conf_file} ){
		my $file_hash = to_FileHash( $arguments->{conf_file} );
		delete $arguments->{conf_file};
		$arguments = $instance->graft_data( tree_ref => $file_hash, scion_ref => $arguments );
	}
	###InternalSwitchboarD	$talk_result = $instance->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
	###InternalSwitchboarD		message =>[ "Updated arguments with conf_file key parsed:", $arguments ], } );
	###InternalSwitchboarD	warn "Updated arguments with conf_file key parsed:" . Dumper( $arguments ) if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
	my $level = 1;
	my	$message = [ "Starting get operator" ];
	if( keys %$arguments ){
		$level = 2;
		push @$message, 'With updates to:' , keys %$arguments;
	}
	###InternalSwitchboarD	$talk_result = $instance->master_talk( { report => 'log_file', level => $level,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
	###InternalSwitchboarD		message =>[ $message, $arguments ], } );
	###InternalSwitchboarD	warn Dumper( $message, $arguments ) if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
	my @action_list;
	for my $key ( keys %$arguments ){
		push @action_list, $key;
		my $method_1 = "add_$key";
		my $method_2 = "set_$key";
		my $input = is_HashRef( $arguments->{$key} ) ? $arguments->{$key} : {$arguments->{$key}};
		###InternalSwitchboarD	$talk_result = $instance->master_talk( { report => 'log_file', level => 0,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
		###InternalSwitchboarD		message =>[ "Processed key -$key- to the methods -$method_1- and -$method_2-",
		###InternalSwitchboarD					"used to implement arguments:", $arguments->{$key} ], } );
		###InternalSwitchboarD	warn "Processed key -$key- to the methods -$method_1- and -$method_2-" if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
		###InternalSwitchboarD	warn "used to implement arguments:" . Dumper( $arguments->{$key} ) if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
		if( $instance->can( $method_1 ) ){
			###InternalSwitchboarD	$talk_result = $instance->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
			###InternalSwitchboarD		message =>[ "Using method: $method_1" ], } );
			###InternalSwitchboarD	warn "Using method: $method_1" if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
			$instance->$method_1( $input );
		}else{
			###InternalSwitchboarD	$instance->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
			###InternalSwitchboarD		message =>[ "Using method: $method_2" ], } );
			###InternalSwitchboarD	warn "Using method: $method_2" if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
			$instance->$method_2( $input );
		}
	}
	###InternalSwitchboarD	$talk_result = $instance->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
	###InternalSwitchboarD		message =>[ "Switchboard finished updating the following arguments: ", @action_list ], } );
	###InternalSwitchboarD	warn "Switchboard finished updating the following arguments: " . Dumper( @action_list ) if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
	###InternalSwitchboarD	$talk_result = $instance->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::get_operator',
	###InternalSwitchboarD		message =>[ 'The switchboard instance is:', $instance ], } );
	###InternalSwitchboarD	warn 'The switchboard instance is:' . Dumper( $instance ) if GET_OPERATOR_DEBUG and ($talk_result == 0 or $talk_result == -3);
	return $instance;
}

# This is the only method that can't self report - use the constant TALK_DEBUG instead
#  (Any self reporting from here is by definition a trigger for deep recursion fails)
sub master_talk{
	my ( $self, $data_ref ) = @_;
	my $recursion = $self->_has_message_recursion_block;
	###InternalSwitchboarD	warn "Arrived at master_talk with recursion level -$recursion- from line: " . (caller(0))[2] if TALK_DEBUG;
	if( $recursion == 0 ){
	###InternalSwitchboarD		warn '---->Recursion level 0 acceptable!' if TALK_DEBUG;
	}elsif( $recursion == 1 ){# Allow for one level so internal junk can report
	###InternalSwitchboarD		warn '------------------->Recursion level 1 acceptable!' if TALK_DEBUG;
	}else{
	###InternalSwitchboarD		warn "Allowed recursion level exceeded!" if TALK_DEBUG;
		return -1; # Special return state for recursion-fail
	}
	$self->_set_message_recursion_block( 1 + $recursion );
	###InternalSwitchboarD	warn "Arrived at master_talk with the instructions:" . Dumper( $data_ref ) if TALK_DEBUG;

	# Check the NameSpace
	###InternalSwitchboarD	warn "Checking if report -$data_ref->{report}- level -$data_ref->{level}- and NameSpace -$data_ref->{name_space}- are allowed to communicate" if TALK_DEBUG;
	if(	$self->_can_communicate(
			$data_ref->{report}, $data_ref->{level}, $data_ref->{name_space} ) ){
	###InternalSwitchboarD		warn "The message passed the name_space test" if TALK_DEBUG;
	}else{
	###InternalSwitchboarD		if( TALK_DEBUG ){
	###InternalSwitchboarD			my $message = '<----';
	###InternalSwitchboarD			$message .= $recursion == 1 ? '---------------' : '' ;
	###InternalSwitchboarD			$message .= 'Reducing recursion level!';
	###InternalSwitchboarD			warn $message;
	###InternalSwitchboarD			warn "The message did NOT pass the name_space test";
	###InternalSwitchboarD		}
		$self->_set_message_recursion_block( $recursion );# Early return so cleanup needed
		return -3;
	}

	### Add some meta_data
	# Add message time
	$data_ref->{date_time} = DateTime->now( time_zone => $time_zone )->format_cldr( 'yyyy-MM-dd hh:mm:ss' );

	# Add carp_stack as needed
	$data_ref = $self->_add_carp_stack( $data_ref );

	# Add source keys
	$data_ref = $self->_add_caller( $data_ref );
	###InternalSwitchboarD	warn "The message metadata load is complete" if TALK_DEBUG;

	# Check if the message is buffered
	my	$y = $self->_buffer_decision( $data_ref );
	###InternalSwitchboarD	warn "Buffer decision result: $y" if TALK_DEBUG;

	# Send message to report as needed
	my $x = ( $y eq 'report' ) ? $self->_really_report( $data_ref ) : -2;
	###InternalSwitchboarD	warn "Returned from _really_report-ing with: $x" if TALK_DEBUG;

	###InternalSwitchboarD	if( TALK_DEBUG ){
	###InternalSwitchboarD		my $message = '<----';
	###InternalSwitchboarD		$message .= $recursion == 1 ? '---------------' : '' ;
	###InternalSwitchboarD		$message .= 'Reducing recursion level!';
	###InternalSwitchboarD		warn $message;
	###InternalSwitchboarD	}
	$self->_set_message_recursion_block( $recursion );
	return $x;
}

sub add_name_space_bounds{
	my ( $self, $name_space_ref ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_name_space_bounds',
	###InternalSwitchboarD		message =>[ 'Arrived at add_name_space_bounds with:', $name_space_ref,
	###InternalSwitchboarD					'...against current master name_space_bounds:', $self->get_name_space ], } );
	my 	$new_sources = 	$self->graft_data(
							tree_ref 	=> $self->get_name_space,
							scion_ref	=> $name_space_ref,
						);
	my	$result = $self->_set_whole_name_space( $new_sources );
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_name_space_bounds',
	###InternalSwitchboarD		message =>[ 'Updated master name_space_bounds:', $new_sources ], } );
	return 1;
}

sub remove_name_space_bounds{
	my ( $self, $removal_ref ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::remove_name_space_bounds',
	###InternalSwitchboarD		message =>[ 'Arrived at remove_name_space_bounds with:', $removal_ref,
	###InternalSwitchboarD					'...against current master name_space_bounds:', $self->get_name_space ], } );
	my	$result;
	$self->_set_whole_name_space(
		$result = $self->prune_data( 	tree_ref => $self->get_name_space, 	slice_ref => $removal_ref, )
	);
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::remove_name_space_bounds',
	###InternalSwitchboarD		message =>[ 'Updated master name_space_bounds:', $result ], } );
	return $result;
}

sub add_reports{
	my( $self, @args ) = @_;
	my %report_hash = ( scalar( @args ) == 1 ) ? %{$args[0]} : @args ;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
	###InternalSwitchboarD		message =>[ 'Arrived at add_reports with:', {%report_hash},
	###InternalSwitchboarD					'Current master reports:', $self->get_reports ], } );
	for my $name ( keys %report_hash	){
		my $report_list = [];
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
		###InternalSwitchboarD		message =>[ "Adding output to the report named: $name" ], } );
		for my $report ( @{$report_hash{$name}} ){
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
			###InternalSwitchboarD		message =>[ 'processing:', $report ], } );
			if( is_ReportObject( $report ) ){
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
				###InternalSwitchboarD		message =>[ 'no object creation needed for this output' ], } );
			}else{
				$report = to_ReportObject( $report );
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
				###InternalSwitchboarD		message =>[ 'after building the instance:', $report  ], } );
			}
			push @{$report_list} , $report;
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
			###InternalSwitchboarD		message =>[ 'updated report list:', $report_list  ], } );
		}
		$self->_set_report( $name => $report_list );
	}

	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
	###InternalSwitchboarD		message =>[ 'Final report space:', $self->get_reports  ], } );
	return 1;
}

sub get_log_levels{
	my ( $self, $report ) = @_;
	$report //= 'log_file';
	my	$output;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
	###InternalSwitchboarD		message =>[ "Reached get_log_levels for report: $report"  ], } );
	my  $x = 0;
	if( $self->has_log_levels( $report ) ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
		###InternalSwitchboarD		message =>[ "Custom log level for -$report- found"  ], } );
		$output = $self->_get_log_levels( $report );
	}else{
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
		###InternalSwitchboarD		message =>[ "No custome log levels in force for -$report- sending the defaults" ], } );
		$output = [ @default_levels ];
	}
	no warnings 'uninitialized';#OK to have undef at some levels
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::add_reports',
	###InternalSwitchboarD		message =>[ "Returning the log levels for -$report-" . join( ', ', @$output ) ], } );
    use warnings 'uninitialized';
	return $output;
}

sub send_buffer_to_output{
    my ( $self, $report ) = @_;
	$report //= 'log_file';
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::send_buffer_to_output',
	###InternalSwitchboarD		message =>[ "Reached send_buffer_to_output for report: $report" ], } );
	my  $x = 0;
	if( $self->has_buffer( $report ) ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::send_buffer_to_output',
		###InternalSwitchboarD		message =>[ "Flushing the buffer ..." ], } );
		for my $message_ref ( @{$self->_get_buffer( $report )} ) {
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::send_buffer_to_output',
			###InternalSwitchboarD		message =>[ "Sending:", $message_ref->{message} ], } );
			$x += $self->_really_report( $message_ref );
		}
		$self->_set_buffer( $report => [] );
	}else{
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 3,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::send_buffer_to_output',
		###InternalSwitchboarD		message =>[ "Attempting to send buffer to output when no buffering is in force!" ], } );
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::send_buffer_to_output',
	###InternalSwitchboarD		message =>[ "Returning from attempt to flush buffer with: $x" ], } );
    return $x;
}

sub clear_buffer{
	my ( $self, $report ) = @_;
	$report //= 'log_file';
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::clear_buffer',
	###InternalSwitchboarD		message =>[ "Reached clear_buffer for report: $report" ], } );
	my  $x = 0;
	if(	$self->has_buffer( $report ) ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::clear_buffer',
		###InternalSwitchboarD		message =>[ "clearing the buffer ..." ], } );
		$self->_set_buffer( $report => [] );
		$x = 1;
	}else{
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::clear_buffer',
		###InternalSwitchboarD		message =>[ "Attempting to clear a buffer to output when no buffering is in force!" ], } );
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::clear_buffer',
	###InternalSwitchboarD		message =>[ "Returning from attempt to clear the buffer with: $x" ], } );
    return $x;
}

sub start_buffering{
	my ( $self, $report ) = @_;
	$report //= 'log_file';
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::start_buffering',
	###InternalSwitchboarD		message =>[ "Reached set_buffering for report: $report" ], } );
	my  $x = 0;
	if(	$self->has_buffer( $report ) ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 3,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::start_buffering',
		###InternalSwitchboarD		message =>[ "Attempting to turn on a buffer to when it already exists!" ], } );
	}else{
		$self->_set_buffer( $report => [] );
		$x = 1;
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::start_buffering',
		###InternalSwitchboarD		message =>[ "Buffering turned on ..." ], } );
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::start_buffering',
	###InternalSwitchboarD		message =>[ "Returning from attempt to set the buffer with: $x" ], } );
    return $x;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _import_recursion_block =>(
		isa	=> Bool,
		reader => '_has_import_recursion_block',
		writer => '_set_import_recursion_block',
		init_arg => undef,
		default => 0,
	);

has _message_recursion_block =>(
		isa		=> Int,
		reader	=> '_has_message_recursion_block',
		writer	=> '_set_message_recursion_block',
		init_arg => undef,
		default	=> 0,
	);

has _data_walker =>(
		isa		=> 'Walker',
		handles =>[ qw( graft_data prune_data print_data ) ],
		writer  => '_set_data_walker',
		predicate => '_has_data_walker',
		init_arg  => undef,
		builder   => '_build_data_walker',
		#~ lazy => 1,
	);

has _can_communicate_cash =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		clearer	=> '_clear_can_communicate_cash',
		handles	=>{
			_has_can_com_cash	=> 'exists',
			_set_can_com_cash	=> 'set',
			_get_can_com_cash	=> 'get',
		},
		init_arg => undef,
		default	=> sub{ {} },
	);

has _test_buffer =>(
		isa		=> HashRef[ArrayRef],
		clearer	=> '_clear_all_test_buffers',
		traits	=> ['Hash'],
		handles	=>{
			_has_test_buffer	=> 'exists',
			_set_test_buffer	=> 'set',
			_get_test_buffer	=> 'get',
		},
		default	=> sub{ {} },
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _can_communicate{
	my ( $self, $report, $level, $name_string ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
	###InternalSwitchboarD		message =>[ "Arrived at _can_communicate to see if report: $report",
	###InternalSwitchboarD					"- will accept a call at the urgency of: $level",
	###InternalSwitchboarD					"- from the name_space: $name_string" ], } );
	my $cash_string = $name_string . $report . $level;
	my $pass = 0;
	my $x = "Report -$report- is NOT UNBLOCKed for the name-space: $name_string";
	if( $self->_has_can_com_cash( $cash_string ) ){
		( $pass, $x ) = @{$self->_get_can_com_cash( $cash_string )};
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
		###InternalSwitchboarD		message =>[ "Found the permissions cached: $pass" ], } );
	}else{
		my	$source_space = $self->get_name_space;
		return $pass if !keys %$source_space;
		my 	@telephone_name_space = ( split /::/, $name_string );
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
		###InternalSwitchboarD		message =>[ 'Consolidating permissions for the name space:', @telephone_name_space ,
		###InternalSwitchboarD					'against the source space:', $source_space ], } );
		my 	$level_ref = {};
		$level_ref = $self->_get_block_unblock_levels( $level_ref, $source_space );
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
		###InternalSwitchboarD		message =>[ '_get_block_unblock_levels returned returned the level ref:', $level_ref ], } );
		SPACETEST: for my $next_level ( @telephone_name_space ){
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
			###InternalSwitchboarD		message =>[ "Checking for additional adjustments at: $next_level" ], } );
			if( exists $source_space->{$next_level} ){
				$source_space = clone( $source_space->{$next_level} );
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
				###InternalSwitchboarD		message =>[ "The next level -$next_level- exists", $source_space ], } );
				$level_ref = $self->_get_block_unblock_levels( $level_ref, $source_space );
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
				###InternalSwitchboarD		message =>[ '_get_block_unblock_levels returned the level ref:', $level_ref ], } );
			}else{
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
				###InternalSwitchboarD		message =>[ "Didn't find the next level -$next_level-" ], } );
				last SPACETEST;
			}
		}
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
		###InternalSwitchboarD		message =>[ 'Final level collection is:', $level_ref,
		###InternalSwitchboarD					"Checking for the report name in the consolidated level ref"], } );
		REPORTTEST: for my $key ( keys %$level_ref ){
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
			###InternalSwitchboarD		message =>[ "Testing: $key" ], } );
			if( $key =~ /$report/i ){
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
				###InternalSwitchboarD		message =>[ "Matched key to the target report: $report" ], } );
				my $allowed = $self->_convert_level_name_to_number( $level_ref->{$key}, $report );
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
				###InternalSwitchboarD		message =>[ "The allowed level for -$report- is: $allowed" ], } );
				my $attempted = $self->_convert_level_name_to_number( $level, $report );
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
				###InternalSwitchboarD		message =>[ "The attempted level for -$level- is: $attempted" ], } );
				if( $attempted >= $allowed ){
					$x = "The message clears for report -$report- at level: $level";
					$pass = 1 ;
				}else{
					$x = "The destination -$report- is UNBLOCKed but not to the -$level- level at the name space: $name_string";
				}
				last REPORTTEST;
			}
		}
		$self->_set_can_com_cash( $cash_string => [ $pass, $x ] );
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate',
	###InternalSwitchboarD		message =>[ $x ], } );
	return $pass;
}

sub _add_caller{
	my ( $self, $data_ref ) = @_;
	my $level = 2;
	if( !exists $data_ref->{source_sub} ){
		$data_ref->{source_sub} = 'Log::Shiras::Switchboard::master_talk';
		$level = 1;
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_add_caller',
	###InternalSwitchboarD		message =>[ "Arrived at _get_caller for start level (up): $level",
	###InternalSwitchboarD					"and source sub: $data_ref->{source_sub}",  ], } );
	my( $caller_ref, $complete, $last_ref,);
	while( !$complete ){
		@$caller_ref{qw( package filename line subroutine )} = (caller($level))[0..3];
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_add_caller',
		###InternalSwitchboarD		message =>[ "Retrieved caller data from up level: $level", $caller_ref ], } );
		if( $caller_ref->{subroutine} eq $data_ref->{source_sub} ){
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_add_caller',
			###InternalSwitchboarD		message =>[ "Matched: $data_ref->{source_sub}" ], } );
			$complete = 1;
		}
		$level++;
		last if $level > 6;# safety valve
	}
	#~ my $caller_ref = $data_ref->{source_sub} eq 'IO::Callback::print' ?
						#~ $self->_alt_caller( $data_ref, $level ) :
						#~ $self->_main_caller( $data_ref, $level );
	#~ ###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	#~ ###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_add_caller',
	#~ ###InternalSwitchboarD		message =>[ "Returned from caller search with:", $caller_ref ], } );
	delete $caller_ref->{subroutine};
	$caller_ref->{filename} =~ s/\\/\//g;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => '2',
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_add_caller',
	###InternalSwitchboarD		message =>[ "Caller ref - ending at level: $level", $caller_ref], } );
	return { %$caller_ref, %$data_ref };
}

sub _add_carp_stack{
	my ( $self, $data_ref ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_add_carp_stack',
	###InternalSwitchboarD		message =>[ "Arrived at _add_carp_stack for action: " . exists $data_ref->{carp_stack} ], } );

	if( $data_ref->{carp_stack} ){
		my @carp_list = split( /\n\s*/, longmess() );
		push @{$data_ref->{message}}, @carp_list;
	}
	delete $data_ref->{carp_stack};
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => '0',
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_add_carp_stack',
	###InternalSwitchboarD		message =>[ "Longmess test complete with message: ", $data_ref->{message} ], } );
	return $data_ref;
}

sub _buffer_decision{
	my ( $self, $report_ref ) = @_;
	#~ warn Dumper( $report_ref );
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_buffer_decision',
	###InternalSwitchboarD		message =>[ "Arrived at _buffer_decision for report: $report_ref->{report}",
	###InternalSwitchboarD					"..with buffer setting: " . $self->has_buffer( $report_ref->{report} ), ], } );

	# Check if the regular buffer is active (and load buffer or report)
	my $x = 'report';
	if(	$self->has_buffer( $report_ref->{report} ) ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_buffer_decision',
		###InternalSwitchboarD		message =>[ "The buffer is active - sending the message to the buffer (not the report)." ], } );
		push @{$self->_get_buffer( $report_ref->{report} )}, $report_ref;# Load the buffer
		$x = 'buffer';
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_buffer_decision',
	###InternalSwitchboarD		message =>[ "Current action for report -$report_ref->{report}- is: $x" ], } );
	return $x;
}

sub _load_test_buffer{
	my ( $self, $report_ref ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_load_test_buffer',
	###InternalSwitchboarD		message =>[ "Arrived at _test_buffer for report: $report_ref->{report}",
	###InternalSwitchboarD					"..with test buffer setting: " . $self->_has_test_buffer( $report_ref->{report} ), ], } );

	# Start a test buffer for the report if it doesn't exist
	if( !$self->_has_test_buffer( $report_ref->{report} ) ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_load_test_buffer',
		###InternalSwitchboarD		message =>[ "This is a new TEST buffer request for report " .
		###InternalSwitchboarD			"-$report_ref->{report}- turning the buffer on!" ], } );
		$self->_set_test_buffer( $report_ref->{report} =>[] );
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_load_test_buffer',
	###InternalSwitchboarD		message =>[ "Loading the line to the test buffer" ], } );
	unshift @{$self->_get_test_buffer( $report_ref->{report} )}, $report_ref;

	# Reduce the buffer size as needed
	while(	$#{$self->_get_test_buffer( $report_ref->{report} )} > $Log::Shiras::Test2::last_buffer_position	){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_load_test_buffer',
		###InternalSwitchboarD		message =>[ "The TEST buffer has outgrown it's allowed size.  Reducing it from: " .
		###InternalSwitchboarD					$#{$self->_get_test_buffer( $report_ref->{report} )} ], } );
		pop @{$self->_get_test_buffer( $report_ref->{report} )};
	}

	return 1;
}

sub _really_report{
	my ( $self, $report_ref ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_really_report',
	###InternalSwitchboarD		message =>[ "Arrived at _really_report to report -$report_ref->{report}- with message:", $report_ref->{message} ], } );

	# Load the test buffer as called
	if( $Log::Shiras::Test2::last_buffer_position ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_really_report',
		###InternalSwitchboarD		message =>[ "Sending the message to the test buffer too!" ], } );
		$self->_load_test_buffer( $report_ref );
	}

	# Send the data to the reports
	my $x = 0;
	my 	$report_array_ref = $self->get_report( $report_ref->{report} );
	if( $report_array_ref ){
		for my $report ( @{$report_array_ref} ){
			next if !$report;
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_really_report',
			###InternalSwitchboarD		message =>[ 'sending message to: ' .  $report_ref->{report}, ], } );
			$report->add_line( $report_ref );
			$x++;
		}
		###InternalSwitchboarD	warn 'Checking if this is a fatal message' if TALK_DEBUG;
		$self->_is_fatal( $report_ref );
		###InternalSwitchboarD	warn 'The message was not fatal!' if TALK_DEBUG;
	}else{
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_really_report',
		###InternalSwitchboarD		message =>[ "The report name -$report_ref->{report}- does not have any destination instances to use!" ], } );
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_really_report',
	###InternalSwitchboarD		message =>[ "Message was reported -$x- times" ], } );
	return $x;
}

sub _is_fatal{
	my ( $self, $data_ref ) = @_;#, $recursion
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_is_fatal',
	###InternalSwitchboarD		message =>[ "Arrived at _is_fatal to see if urgency -$data_ref->{level}- equals fatal", ], } );
	if( $data_ref->{level} =~ /fatal/i ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 3,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_is_fatal',
		###InternalSwitchboarD		message =>[ "Checking which message to send based on the message content:",  $data_ref->{message} ], } );
		#~ $self->_set_message_recursion_block( $recursion );# Early return so cleanup needed (for the case of an eval'd fatal)
		my $fatality = '';
		my $empty = "Fatal call sent to the switchboard";
		if(!$data_ref->{message} ){
			$fatality = $empty;
		}else{
			my $i = 0;
			for my $element ( @{$data_ref->{message}} ){
				if( !$element or length( $element ) == 0 ){
				}elsif( $i ){
					$fatality .= "\n" . ( ref $element ? Dumper( $element ) : $element );
					$i++;
				}else{
					$fatality = "\n" . ( ref $element ? Dumper( $element ) : $element );
					$i++;
				}
			}
			$fatality .= length( $fatality ) > 0 ? "<- sent at a 'fatal' level" : $empty ;
		}
		confess( $fatality );
	}
	return 1;
}

sub _get_block_unblock_levels{
	my ( $self, $level_ref, $space_ref ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate::_get_block_unblock_levels',
	###InternalSwitchboarD		message =>[ 'Arrived at _get_block_unblock_levels for:', $space_ref,
	###InternalSwitchboarD					'Received the level ref:', $level_ref ], } );
	if( exists $space_ref->{UNBLOCK} ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate::_get_block_unblock_levels',
		###InternalSwitchboarD		message =>[ 'Found an UNBLOCK at this level:', $space_ref->{UNBLOCK} ], } );
		for my $report ( keys %{$space_ref->{UNBLOCK}} ){
			$level_ref->{$report} = $space_ref->{UNBLOCK}->{$report};
		}
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate::_get_block_unblock_levels',
		###InternalSwitchboarD		message =>[ 'level ref with UNBLOCK changes:', $level_ref ], } );
	}
	if( exists $space_ref->{BLOCK} ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate::_get_block_unblock_levels',
		###InternalSwitchboarD		message =>[ 'Found an BLOCK at this level:', $space_ref->{BLOCK} ], } );
		for my $report ( keys %{$space_ref->{BLOCK}} ){
			delete $level_ref->{$report};
		}
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate::_get_block_unblock_levels',
		###InternalSwitchboarD		message =>[ 'level ref with BLOCK changes:', $level_ref ], } );
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_can_communicate::_get_block_unblock_levels',
	###InternalSwitchboarD		message =>[ 'Returning the level ref:', $level_ref ], } );
	return $level_ref;
}

sub _convert_level_name_to_number{
	my ( $self, $level, $report ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_convert_level_name_to_number',
	###InternalSwitchboarD		message =>[ "Arrived at _convert_level_name_to_number with level -$level" ], } );
	my 	$x = 0;
	if( is_ElevenInt( $level ) ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 0,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_convert_level_name_to_number',
		###InternalSwitchboarD		message =>[ "-$level- is already an integer in the correct range." ], } );
		$x = $level;
	}else{
		my	$level_ref = 	( !$report ) 							? [ @default_levels ] :
							( $self->has_log_levels( $report ) ) 	? $self->get_log_levels( $report ) :
																		[ @default_levels ] ;
		if(	!$level_ref ){
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 4,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_convert_level_name_to_number',
			###InternalSwitchboarD		message =>[ "After trying several options no level list could be isolated for report -" .
			###InternalSwitchboarD				$report . "-.  Level -" . ( $level // 'UNDEFINED' ) .
			###InternalSwitchboarD				"- will be set to 0 (These go to eleven)" ], } );
		}else{
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_convert_level_name_to_number',
			###InternalSwitchboarD		message =>[ 'Checking for a match for -$level- in the level ref:', $level_ref ], } );
			my $found = 0;
			for my $word ( @$level_ref ){
				if( $word and $level =~ /^$word$/i ){
					###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 2,
					###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_convert_level_name_to_number',
					###InternalSwitchboarD		message =>[ "Level word -$word- matches passed level: $level" ], } );
					$found = 1;
					last;
				}
				$x++;
			}
			if( !$found ){
				###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 3,
				###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_convert_level_name_to_number',
				###InternalSwitchboarD		message =>[ "No match was found for the level -$level-" .
				###InternalSwitchboarD			" assigned to the report -$report-", ], } );
				$x = 0;
			}
		}
	}
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::master_talk::_convert_level_name_to_number',
	###InternalSwitchboarD		message =>[ "Returning -$level- as the integer: $x" ], } );
	return $x;
}

before stop_buffering => sub{
	my ( $self, @buffer_list ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::stop_buffering',
	###InternalSwitchboarD		message =>[ "Action 'before' clearing the buffers:", @buffer_list ], } );
	for my $report ( @buffer_list ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::stop_buffering',
		###InternalSwitchboarD		message =>[ "Checking the buffers for report: $report" ], } );
		if( $self->has_buffer( $report) ){
			###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
			###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::stop_buffering',
			###InternalSwitchboarD		message =>[ "Flushing the buffer for: $report" ], } );
			$self->send_buffer_to_output( $report );
		}
	}
	return @buffer_list;
};

before set_all_buffering => sub{
	my ( $self, $buffer_ref ) = @_;
	###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
	###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::set_all_buffering',
	###InternalSwitchboarD		message =>[ "Setting up new buffers:", $buffer_ref, $self->_get_buffer_list ], } );
	for my $report ( $self->_get_buffer_list ){
		###InternalSwitchboarD	$self->master_talk( { report => 'log_file', level => 1,
		###InternalSwitchboarD		name_space => 'Log::Shiras::Switchboard::set_all_buffering',
		###InternalSwitchboarD		message =>[ "Flushing the buffer for: $report" ], } );
		$self->send_buffer_to_output( $report );
	}
	return $buffer_ref;
};

after '_set_whole_name_space' => sub{ __PACKAGE__->_clear_can_communicate_cash };

sub _build_data_walker{
	my ( $self, ) = @_;
	###InternalSwitchboarD	warn "Arrived at _build_data_walker" if IMPORT_DEBUG;
	return	build_instance(
				package => 'Walker',
				superclasses => ['Data::Walk::Extracted',],
				roles =>[
					'Data::Walk::Graft',
					'Data::Walk::Clone',
					'Data::Walk::Prune',
					'Data::Walk::Print',
				],
				skipped_nodes =>{
					OBJECT => 1,
					CODEREF => 1,
				},
				to_string => 1,
			);
}

#~ sub DEMOLISH{
	#~ my ( $self ) = @_;
#~ }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no MooseX::Singleton;
__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::Switchboard - Log::Shiras message screening and delivery

=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of
Moose found in the western United States (of America).

This is the class for message traffic control in the 'Log::Shiras' package.  For a
general overview of the whole package see L<the top level documentation
|Log::Shiras>.  Traffic is managed using name spaces.  For the purposes of logging this
package uses three types of name space with an additional wrapper.  The first name space
is the source code name space.  This name space is managed by putting labeled comment
tags in the code and then exposing them with a source code filter.  This is mostly used
when you want to have debug code available that does not impact your regular runs of the
code.  This space is managed by L<Log::Shiras::Unhide>.  The source code name space is a
flat list.  The next name space is the caller name space.  The caller name space is
assigned in the code with targeted embedded statements to the L<master_talk
|/master_talk( $args_ref )> method.  Boilerplate for managing these calls can be found
in L<Log::Shiras::Telephone>.  If you wish to inject name_space modifications from the
calling script you can use the role L<Log::Shiras::LogSpace>.  The caller namespace can
be heirarchical and represented by a Hash of hashrefs.  The final name space is the
destination or L<report|/reports> namespace.  This namespace is flat but each position can contain
more than one actual report.  Any message to a specific report name is sent to all reports
assigned to that name.  Managing the traffic between the caller name space and the report
name space is done by setting allowed L<urgency|/logging_levels> levels in the
L<name space bounds|/name_space_bounds>., urgency levels, and report names.

In order to stich all this together at run time this is a singleton class and so
'new' is the wrong way to get a new instance of this class.  The right way is to use the
method L<get_operator|/get_operator( %args )>. The upside of using a singleton is you
can write a caller (message source) with an intended urgency and destination name and not
build the actual destination till run time.

=head2 Initialization

This class does not use ->new.  Use 'get_operator' instead.

=head3 get_operator( %args )

=over

B<Definition:> This method replaces the call to -E<gt>new or other instantiation
methods.  The Log::Shiras::Switchboard class is a L<MooseX::Singleton
|https://metacpan.org/module/MooseX::Singleton>  and as such needs to be called in a
slightly different fashion.  This method can be used to either connect to the existing
switchboard or start the switchboard with new settings.  Each call to this method will
implement the settings passed in %args merging them with any pre-existing settings.
Where pre-existing settings disagree with new settings the new settings take
precedence.  So be careful!

B<Accepts:> [%args|$args_ref|full/file/path.(json|yml)] %args are treated the same
as attributes passed to other class style calls to new.  The data can either be
passed as a fat comma list or a hashref.  If this method receives a string it will
try to treat it like a full file path to a JSON or YAML file with the equivalent
$args_ref stored.  See L<conf_file|/conf_file> to pass a file path and arguments.

B<Returns:> an instance of the Log::Shiras::Switchboard class called an 'operator'.
This operator can act on the switchboard to perform any of the methods including
any attribute access methods.

=back

=head2 Attributes

Data passed to L<get_operator|/get_operator( %args )> when creating an instance.  For
modification of these attributes see the remaining L<Methods|/Methods>
used to act on the operator.  B<DO NOT USE 'Log::Shiras::Switchboard-E<gt>new' to get
a new class instance>

=head3 name_space_bounds

=over

B<Definition:> This attribute stores the boundaries set for the name-space management of
communications (generally from L<Log::Shiras::Telephone>) message data sources. This
value ref defines where in the name-space, to which L<reports|/reports>, and at L<what
urgency level|/logging_levels> messages are allows to pass.  Name spaces are stored as
a L<hash of hashes|http://perldoc.perl.org/perldsc.html#HASHES-OF-HASHES> that goes as
deep as needed.  To send a message between a specific caller name-space and a named
'report' destination this hash ref tree must have the key 'UNBLOCK' at or below the
target name space in the hashref tree.  The UNBLOCK key must have as a value a hashref
with report names as keys and the minimum allowed L<pass level|/logging_levels> as the
value.  That(ose) report(s) then remain(s) open to communication farther out on the
caller name space branch until a new UNBLOCK key sets different permission level or
a 'BLOCK' key is implemented.  The difference between a BLOCK and UNBLOCK key is that
a BLOCK key value only needs to contain report keys (the key values are unimportant).
Any level assigned to the report name by a BLOCK key is ignored and all communication
at that point and further in the branch is cut off all for all deeper levels of the
name space branch for that report.  There are a couple of significant points for review;

=over

B<*> UNBLOCK and BLOCK should not be used as branch of the telephone name-space tree

B<*> If a caller name-space is not listed here or a report name is not explicitly
UNBLOCKed then the message is blocked by default.

B<*> Even though 'log_file' is the default report it is not 'UNBLOCK'ed by default.
It must be explicitly UNBLOCKed to be used.

B<*> UNBLOCKing or BLOCKing of a report can occur independant of it's existance.
This allows the addition of a report later and have it work upon its creation.

B<*> If an UNBLOCK and BLOCK key exist at the same point in a name space then
the hashref associated with the UNBLOCK key is evaluated first and the hashref
associated with the BLOCK key is evaluated second.  This means that the BLOCK
command can negate a report UNBLOCKing level.

B<*> Any name space on the same branch (but deeper) than an UNBLOCK command remains
UNBLOCKed for the listed report urgency levels until a deeper UNBLOCK or BLOCK is
registered for that report.

B<*> When UNBLOCKing a report at a deeper level than an initial UNBLOCK setting
the new level can be set higher or lower than the initial setting.

B<*> BLOCK commands are only valuable deeper than an initial UNBLOCK command.  The
Tree trunk starts out 'BLOCK'ed by default.

B<*> All BLOCK commands completly block the report(s) named for that point and
deeper independant of the urgency value associated with report name key in
the BLOCK hashref.

B<*> The hash key whos hashref value contains an UNBLOCK hash key is the point in
the NameSpace where the report is UNBLOCKed to the defined level.

=back

B<Default> all caller name-spaces are blocked (no reporting)

B<Range> The caller name-space is stored and searched as a hash of hashes.  No
array refs will be correctly read as any part of the name-space definition.  At each
level of the name-space the switchboard will also recognize the special keys 'UNBLOCK'
and 'BLOCK' I<in that order>.  As a consequence UNBLOCK and BLOCK are not supported as
name-space elements.  Each UNBLOCK (or BLOCK) key should have a hash ref of L<report
|/reports> name keys as it's value.  The hash ref of report name keys should contain
the minimum allowed urgency level down to which the report is UNBLOCKed.  The value
associated with any report key in a BLOCK hash ref is not tested since BLOCK closes
all reporting from that point and deeper.

B<Example>

	name_space_bounds =>{
		Name =>{#<-- name-space
			Space =>{#<-- name-space
				UNBLOCK =>{#<-- Telephone name-space 'Name::Space' is unblocked
					log_file => 'warn'#<-- but only for calls to the 'log_file' report
				},					  #     with an urgency of 'warn' or greater
				Boundary =>{#<-- name-space
					UNBLOCK =>{#<-- The deeper space 'Name::Space::Boundary' receives a new setting
						log_file => 'trace',#<-- messages are allowed at 'trace' urgency now
						special_report => 'eleven',<-- a new report and level are added
					},
					Place =>{},<-- deeper name-space - log_file permissions still 'trace'
				},
			},
		},
	}

B<Warning> All active name-space boundaries must coexist in the singleton.  There
is only one master name-space for the singleton.  New calls for object intances can
overwrite existing object instances name-space boundaries.  No cross instance name-space
protection is done. This requires conscious managment!  I<It is entirely possible to call
for another operator in the same program space with overlapping name-space boundaries that
changes reporting for a callers originally used in the context of the original operator.>

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_name_space>

=over

B<Definition:> Returns the full program namespace

=back

=back

=back

=head3 reports

=over

B<Definition:> This attribute stores report names and associated composed class
instances for that name.  The attribute expects a L<hash of arrays
|http://perldoc.perl.org/perldsc.html#HASHES-OF-ARRAYS>.  Each hash key is the
report name and the array contains the report instances associated with that name.  Each
passed array object will be tested to see if it is an object that can( 'add_line' ).
If not this code will try to coerce the passed reference at the array position into an
object using L<MooseX::ShortCut::BuildInstance>.

B<Default> no reports are active.  If a message is sent to a non-existant report
name then nothing happens unless L<self reporting|Log::Shiras::Unhide> is fully enabled.
Then it is possible to collect various warning messages related to the failure of a
message.

B<Example>

	reports =>{
		log_file =>[<-- report name
				Print::Wisper->new,#<-- a reporting instance of a class ( see Synopsis )
				{#<-- MooseX::ShortCut::BuildInstance definition for a different report
					package => 'Print::Excited',#<-- name this (new) class
					add_methods =>{
						add_line => sub{#<-- ensure it has an 'add_line' method
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
		other_name =>[],#<-- name created but no report instances added (maybe later?)
	},

B<warning:> any re-definition of the outputs for a report name will only push the new
report instance onto the existing report array ref.  To remove an existing report output
instance you must L<delete|/remove_reports( @report_list )> all report instances and the
report name and then re-implement the report name and it's outputs.

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_reports>

=over

B<Definition:> Returns the full report hashref of arrays

=back

B<has_no_reports( $report )>

=over

B<Definition:> Checks if the $report requested has a key in the hashref

=back

B<get_report( $report )>

=over

B<Definition:> Returns the array ref of stored report objects for that $report

=back

B<remove_reports( $report1 [, $report2] )>

=over

B<Definition:> Deletes all storeage (and use of) $report1 etc.

=back

=back

=back

=head3 logging_levels

=over

B<Definition:> Each report name recognizes 12 different logging levels [0..11]
(L<They go to 11!
|http://en.wikipedia.org/wiki/Up_to_eleven#Original_scene_from_This_Is_Spinal_Tap> :).  Each
position within the logging levels can be assigned a name that is not case sensitive.
Either the position integer or the name assigned to that position can be used to describe
the urgency 'level'.  Each message can be sent with name.  The urgency level of a message
L<can be defined|master_talk( $args_ref )> for each sent message.  If you do not wish to
use the default name for each logging position or you wish to name the logging positions
that are not named then use this attribute.  Not all of the elements need to be defined.
There can be gaps between defined levels but counting undefined positions there can never
be more than 12 total positions in the level array.  The priority or urgency is lowest
first to highest last on the list.  Where requests sent with an urgency at or above the
permissions barrier will pass.  Since there are default priority names already in place
this attribute is a window dressing setting and not much more.

B<Default> The default array of priority / urgency levels is;

	'trace', 'debug', 'info', 'warn', 'error', 'fatal',
	undef, undef, undef, undef, undef, 'eleven',

Any report name without a custom priority array will use the default array.

B<Example>

	logging_levels =>{
		log_file =>[ qw(<-- report name (others use the default list)
				foo
				bar
				baz
				fatal
		) ],
	}

B<fatal> The Switchboard will L<confess|Carp/confess> for all messages sent with a
priority or urgency level that matches qr/fatal/i.  The switchboard will fully dispatch 
the message to it's intended report(s) prior to confessing the message.  At this point 
the script will die.  If the message is not approved (even at the fatal level) then 
nothing happens.  'fatal' can be set anywhere in the custom priority list from lowest 
to highest but fatal is the only string that will die.  (priorities higher than fatal 
will not die) B<But>, if the message is blocked for the message I<name-space, report, 
and level> then the code will NOT die.>  If 'fatal' is the requested level from the 
caller but it is not on the (custom) list for the report desination then the priority 
of the message drops to 0 (trace equivalent) and that level of urgencie must be accepted 
for the report to die. (even if the listed level at the 0 position is not 'fatal').

=back

B<attribute methods> Methods provided to adjust this attribute

=over

B<has_log_levels( $report )>

=over

B<Definition:> Indicates if a custom log level list is stored for $report.

=back

B<add_log_levels( $report )>

=over

B<Definition:> Sets the log level name strings for $report

B<Accepts:> the value must be an array ref of no more than 12 total positions

=back

B<remove_log_levels( $report1 [, $report2] )>

=over

B<Definition:> Removes the custom log_level list for the $report[s]

=back

B<set_all_log_levels( $full_hashref_of_arrayrefs )>

=over

B<Definition:> Completely resets all custom log levels to $full_hashref_of_arrayrefs

=back

B<get_all_log_levels>

=over

B<Definition:> Returns the full hashref of arrayrefs for all custom log levels

=back

=back

=head3 all_buffering

=over

B<Definition:> Buffering in this package is only valuable if you want to eliminate some
of the sent messages after they were created.  Buffering allows for clearing of sent
messages from between two save points.  For this to occur buffering must be on and
L<flushing the buffer|/send_buffer_to_output( $report_name )> to the report need to
occur at all known good points.  When some section of prior messages are to be discarded
then a L<clear_buffer|/clear_buffer( $report_name )> command can be sent and all buffered
messages after the last flush will be discarded.  If buffering is turned off the
messages are sent directly to the report for processing with no holding period.  This
attribute accepts a hash ref where the keys are report names and the values empty arrayrefs
You could theoretically pre-load your buffer here but it is not reccomended.  If a new
instance of this class is called with an 'all_buffering' arg sent then it will flush any
pre-existing buffers (even if they are duplicated in the new call) then delete them and
set the new passed list fresh.

B<Default> All buffering is off

B<Example>

	buffering =>{
		log_file => [],
	}

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_all_buffering( $hasref_of_arrayrefs )>

=over

B<Definition:> completely resets all buffers to $hasref_of_arrayrefs but flushes
all the old buffers first

=back

B<has_buffer( $report )>

=over

B<Definition:> Checks if there is an active buffer for $report

=back

B<stop_buffering( $report1 [, $report2] )>

=over

B<Definition:> Removes the buffer for the $report[s] (flushing them first)

=back

=back

=back

=head3 conf_file

=over

B<Definition:> It is possible to pass all the Attribute settings to L<get_operator
|/get_operator( %args )> as a config file.  If you wish to mix your metaphores then
one of the attribute keys can be 'conf_file' with the value being the full file path
of a YAML or JSON file.  If you pass other attributes and conf_file then where there
is conflict the other attributes overwrite the file settings.

B<Default> nothing

B<Accepts:> a full file path to a config file with attribute settings

=back

=head2 Methods

These are methods used to adjust outcomes for the activities in the switchboard or to
leverage information held by the switchboard.

=head3 master_talk( $args_ref )

=over

B<Definition:> This is a way to directly call a report using the switchboard operator.  In a
real telephone situation this would be that cool handset that the telephone repairman brought
with him.  Like the Telephone repairman's phone it plugs in directly to the switchboard (or
in the repairmains case into a telephone line) and is a bit trickier to operate than absolutely
necessary.  For a nicer message sending interface see L<Log::Shiras::Telephone>.  When the
$args_ref message is received the switchboard will check the L<name_space_bounds
|/name_space_bounds> permissions.  If the message passes that test then it will attach metadata 
to to the $args_ref.  The metadata attached to the message is a follows;

	date_time => The date and time the message was sent in CLDR format of 'yyyy-MM-dd hh:mm:ss'

	package => The package name of the message source

	filename => The (full) file name of the message source

	line => The line number of the message sourceIf  and then test;
	
Any L<message buffering|/all_buffering> is then handled or the message is sent to the report 
name and each report in that name-space receives the $args_ref as the arguments to a call 
$report->add_line( $args_ref ).  When that is complete the message is checked to see if it 
is fatal;

	$args_ref->{level} =~ /fatal/i

I<If the message was buffered first the script will not die until the message was flushed into 
the report from the buffer.>

B<Returns:> The number of times the add_line call was made.  There are some special cases.

	-3 = The call was not allowed by name_space permissions set in the switchboard
	-2 = The message was buffered rather than sent to a report
	-1 = The message was blocked as risking deep recursion
	 0 = The call had permissions but found no report implementations to connect with
	 1(and greater) = This indicates how many report instances received the message

B<Accepts:> The passed args must be a HashRef and contain the following elements (any
others will be ignored by the switchboard but not stripped).

=over

B<name_space> the value is the caller name_space as used by L<name_space_bounds|/name_space_bounds>

B<level> value is the urgency level of the message sent.  It can either be an integer in the
set [0..11] or one of the L<defined logging level strings|/logging_levels>.

B<report> the value is the L<report|/reports> name (destination) for the message ref

B<message> the message key must have a value that is an array_ref.  It is assumed that
content can be parsed into somthing else at the report level including any ArrayRef
sub-elements that may be Objects or hashrefs.

B<carp_stack> if this key is passed and set to a true value then L<Carp> - longmess will
be run on the message and the results will be split on the newline and pushed onto the end
of the 'message' array_ref.

B<source_sub> this key is generally handled in the background by Log::Shiras but if you
write a new caller subroutine to lay over 'master_talk' then providing that name to this
key will make the metada added to the message stop at the correct caller level.

=over

B<example>

	{
		name_space => 'MyCoolScript::my_subroutine',
		level => 'warn',
		report => 'log_file',
		message =>[ 'Dont ignore these words' ],
	}

=back

B<carp_stack> [optional] This is a simple passed boolean value that will trigger a traditional
L<Carp> longmess stack to be split by /\n\s*/ and then pushed on the end of the message array ref.
Before the message is stored this key will be deleted whether it was positive or negative.

B<source_sub> [really optional] This is rarely used unless you are writing a replacement for
L<Log::Shiras::Telephone>.  If you are writing a replacement then a full method space string is
passed here.  This will be used to travel the L<caller|http://perldoc.perl.org/functions/caller.html>
stack to find where the message line originated.  The equivalent for Log::Shiras::Telephone is;

=over

B<example>

    { source_sub => 'Log::Shiras::Telephone::talk' }

=back

=back

=back

=head3 add_name_space_bounds( $ref )

=over

B<Definition:> This will L<graft|Data::Walk::Graft/graft_data( %argsE<verbar>$arg_ref )>
more name-space boundaries onto the existing name-space.  I<The passed ref will be treated
as the 'scion_ref' using Data::Walk::Graft.>

B<Accepts:> a data_ref (must start at the root of the main ref) of data to graft to the main
name_space_bounds ref

B<Returns:> The updated name-space data ref

=back

=head3 remove_name_space_bounds( $ref )

=over

B<Definition:> This will L<prune|Data::Walk::Prune/prune_data( %args )> the name-space
L<boundaries|/name_space_bounds> using the passed name-space ref. I<The passed ref will
be treated as the 'slice_ref' using Data::Walk::Prune.>

B<Accepts:> a data_ref (must start at the root of the main ref) of data used to prune the
main name_space_bounds ref

B<Returns:> The updated name-space data ref

=back

=head3 add_reports( %args )

=over

B<Definition:> This will add more L<report|/reports> output instances to the existing
named report registered instances.  If the items in the passed report list are not already
report object instances that -E<gt>can( 'add_line' ) there will be an attempt to build
them using L<MooseX::ShortCut::BuildInstance/build_instance( %argsE<verbar>\%args )>.
If (and only if) the report name does not exist then the report name will also be added to the
report registry.

B<Accepts:> a hash of arrays with the report objects as items in the array

B<Returns:> 1

=back

=head3 get_log_levels( $report_name )

=over

B<Definition:> This will return the L<log level names|/logging_levels> names for a given
report name in an array ref.  If no custom levels are defined it will return the default
level list.

B<Accepts:> a report name

B<Returns:> an array ref of the defined log levels for that report.

=back

=head3 send_buffer_to_output( $report_name )

=over

B<Definition:> This will flush the contents of the $report_name L<buffer|/buffering>
to all the associated report objects.

B<Accepts:>  a $report_name

B<Returns:> The number of times that $report_object->add_line( $message_ref ) was called to
complete the buffer flush.

=back

=head3 start_buffering( $report_name )

=over

B<Definition:> This will start L<buffering|/buffering> for the $report_name.  If the buffering is
already implemented then nothing new happens.  No equivalent report or name_space_bounds
are required to turn buffering on!

B<Accepts:>  a $report_name string

B<Returns:> 1

=back

=head3 clear_buffer( $report_name )

=over

B<Definition:> This will remove all messages currently in the L<buffer|/buffering>
without sending them to the report.

B<Accepts:>  a $report_name string

B<Returns:> 1

=back

=head1 SYNOPSIS

This is pretty long so I put it at the end

	#!perl
	use Modern::Perl;
	use lib 'lib', '../lib',;
	use Log::Shiras::Unhide qw( :debug :InternalSwitchboarD );#
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

	#######################################################################################
	# Synopsis Screen Output for the following condition
	# use Log::Shiras::Unhide;
	# 01: --->hello world 2<---
	# 02: !!!HELLO WORLD 4!!!
	#######################################################################################

	#######################################################################################
	# Synopsis Screen Output for the following condition
	# use Log::Shiras::Unhide qw( :debug );
	# 01: Using Log::Shiras::Unhide-v0.29_1 strip_match string: (LogSD) at ../lib/Log/Shiras/Unhide.pm line 88.
	# 02: lets get ready to rumble... at log_shiras_switchboard.pl line 7.
	# 03: sending the message 'Hello World 1' at log_shiras_switchboard.pl line 80.
	# 04: The name_space 'main' does not have destination 'log_file' permissions at log_shiras_switchboard.pl line 84.
	# 05: sending the message 'Hello World 2' to the report 'quiet' at log_shiras_switchboard.pl line 85.
	# 06: message went to the buffer - turning off buffering for the 'quiet' destination ... at log_shiras_switchboard.pl line 89.
	# 07: --->hello world 2<---
	# 08: should have printed what was in the 'quiet' buffer ... at log_shiras_switchboard.pl line 91.
	# 09: sending the message 'Hello World 4' to the report 'loud' at log_shiras_switchboard.pl line 95.
	# 10: !!!HELLO WORLD 4!!!
	# 11: sending the message 'Hello World 5' to the report 'run' at log_shiras_switchboard.pl line 99.
	# 12: message to 'run' at 'warn' level was approved at log_shiras_switchboard.pl line 104.
	# 13: ...but found -0- reporting destinations (None were set up) at log_shiras_switchboard.pl line 105.
	#######################################################################################

	#######################################################################################
	# Synopsis Screen Output for the following conditions
	# use Log::Shiras::Unhide qw( :debug :InternalSwitchboarD );
	# 01: Using Log::Shiras::Unhide-v0.29_1 strip_match string: (LogSD|InternalSwitchboarD) at ../lib/Log/Shiras/Unhide.pm line 88.
	# 02: You uncovered internal logging statements for Log::Shiras::Types-v0.29_1 at ..\lib\Log\Shiras\Types.pm line 5.
	# 03: You uncovered internal logging statements for Log::Shiras::Switchboard-v0.29_1 at ..\lib\Log\Shiras\Switchboard.pm line 5.
	# 04: lets get ready to rumble... at log_shiras_switchboard.pl line 7.
	# 05: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 06: | line  - 0704   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 07: 	:(	Arrived at _buffer_decision for report: log_file
	# 08: 		..with buffer setting:  ):
	# 09: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 10: | line  - 0715   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 11: 	:(	Current action for report -log_file- is: report ):
	# 12: | level - 2      | name_space - Log::Shiras::Switchboard::get_operator
	# 13: | line  - 0211   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 14: 	:(	Switchboard finished updating the following arguments:
	# 15: 		reports
	# 16: 		name_space_bounds
	# 17: 		all_buffering ):
	# 18: sending the message 'Hello World 1' at log_shiras_switchboard.pl line 80.
	# 19: The name_space 'main' does not have destination 'log_file' permissions at log_shiras_switchboard.pl line 84.
	# 20: sending the message 'Hello World 2' to the report 'quiet' at log_shiras_switchboard.pl line 85.
	# 21: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 22: | line  - 0704   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 23: 	:(	Arrived at _buffer_decision for report: quiet
	# 24: 		..with buffer setting: 1 ):
	# 25: | level - 1      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 26: | line  - 0709   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 27: 	# 01: 	:(	The buffer is active - sending the message to the buffer (not the report). ):
	# 28: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 29: | line  - 0715   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 30: 	:(	Current action for report -quiet- is: buffer ):
	# 31: message went to the buffer - turning off buffering for the 'quiet' destination ... at log_shiras_switchboard.pl line 89.
	# 32: --->hello world 2<---
	# 33: should have printed what was in the 'quiet' buffer ... at log_shiras_switchboard.pl line 91.
	# 34: sending the message 'Hello World 4' to the report 'loud' at log_shiras_switchboard.pl line 95.
	# 35: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 36: | line  - 0704   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 37: 	:(	Arrived at _buffer_decision for report: loud
	# 38: 		..with buffer setting:  ):
	# 39: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 40: | line  - 0715   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 41: 	:(	Current action for report -loud- is: report ):
	# 42: !!!HELLO WORLD 4!!!
	# 43: sending the message 'Hello World 5' to the report 'run' at log_shiras_switchboard.pl line 99.
	# 44: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 45: | line  - 0704   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 46: 	:(	Arrived at _buffer_decision for report: run
	# 47: 		..with buffer setting:  ):
	# 48: | level - 2      | name_space - Log::Shiras::Switchboard::master_talk::_buffer_decision
	# 49: | line  - 0715   | file_name  - ..\lib\Log\Shiras\Switchboard.pm
	# 50: 	:(	Current action for report -run- is: report ):
	# 51: message to 'run' at 'warn' level was approved at log_shiras_switchboard.pl line 104.
	# 52: ...but found -0- reporting destinations (None were set up) at log_shiras_switchboard.pl line 105.
	#######################################################################################

=head2 SYNOPSIS EXPLANATION

=over

	use Log::Shiras::Unhide qw( :debug :InternalSwitchboarD );
	..
	###LogSD warn "lets get ready to rumble...";

Log::Shiras::Unhide strips ###MyCoolTag tags - see L<Log::Shiras::Unhide> for more information.
It represents the only driver between the three example outputs (All run from the same basic
script).  For instance when the :debug tag is passed to Unhide then ###LogSD is stripped.
When :InternalSwitchboarD is passed it strips ###InternalSwitchboarD.

Each of the remaining functions is documented above but the difference between the three
outputs are based on what is unhid.  In all cases 'Hello World [1..5]' is sent to master_talk
in the switchboard.  All of the calls are valid syntax but not all calls have the necessary
target or urgency to be completed.

In the first output it is obvious that only 'Hello World 2' and 'Hello World 4' have the
necessary permissions to be completed.  Each one is sent to a different report object so it
will be obvious based on the output what path it took to be printed.

In the second output only the ###LogSD tags are removed and so comments associated with the
actions are exposed.  In this case these comments only exist in the script space so
warning messages are mostly the only thing exposed that is visible.  Since ~::Unhide is a
source filter it also provides a warning from the class showing that a source filter is
turned on and what is being scrubbed.  This includes scrubbing through the script and
all used modules.  (But not 'with' roles!).

In the final output the ###InternalSwitchboarD tags are also stripped.  Since there
are a lot of these in L<Log::Shiras::Switchboard> there is a number of things available to
see from that class.  However the operator only has released log_file messages for the
~::get_operator and ~::_buffer_decision name spaces.  A new class is also exposed that
can take advantage of message metadata and uses it to show where the message came from
as well has what urgency it was sent with.

=back

=head1 SUPPORT

=over

L<github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Add method to pull a full caller($x) stack and add it to message
metadata.  Probably should be triggered in the master_talk call args.

B<2.> Investigate the possibility of an ONLY keyword in addition to
of UNBLOCK - how would this be implemented? - Future uncertain

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DEPENDENCIES

=over

L<version>

L<5.010|http://perldoc.perl.org/perl5100delta.html>

L<utf8>

L<MooseX::Singleton>

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<DateTime>

L<Carp> - cluck confess

L<MooseX::Types::Moose> - HashRef ArrayRef Bool RegexpRef Str Int

L<Clone> - clone

L<Data::Dumper>

L<MooseX::ShortCut::BuildInstance> - v1.44 - build_instance should_re_use_classes

L<Data::Walk::Extracted> - v0.28

L<Data::Walk::Prune> - v0.028

L<Data::Walk::Graft> - v0.028

L<Data::Walk::Print> - v0.028

L<Data::Walk::Clone> - v0.024

L<Log::Shiras::Types>

=back

=head1 SEE ALSO

=over

L<Log::Shiras>

=back

=cut

#########1 main pod documentation end   4#########5#########6#########7#########8#########9
