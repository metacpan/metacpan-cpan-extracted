#!perl
#########1 Test File for Log::Shiras::TapPrint    5#########6#########7#########8#########9
my ( $lib, $test_file, );
BEGIN{
	use Modern::Perl;
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	use Test::Moose;
	my $file = (caller(0))[1];
	my 	$directory_ref = {
			t		=> './',# repo level
			Log		=> '../',# t folder level
			$file	=> '../../../../',# test file level
		};
	for my $next ( <*> ){
		#~ diag $next;
		if( $next =~/^($file|t|Log)$/ ){
			my $return = $1;
			#~ diag $return;
			$lib 			= $directory_ref->{$return} . 'lib';
			$test_file 		= $directory_ref->{$return} . 't/test_files/';
			#~ diag $lib;
			#~ diag $test_file;
			last;
		}
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ note longmess $_[0]; };
	$ENV{hide_warn} = 1;
}
$| = 1;
use MooseX::ShortCut::BuildInstance qw( build_class );
use lib $lib,;
#~ use Log::Shiras::Unhide qw( :InternalReporTMetaMessagE	:InternalReporT );#
plan( 
###InternalReporTMetaMessagE	( 0 ?
		40 
###InternalReporTMetaMessagE	: 41 )
);
use Log::Shiras::Report;
use Log::Shiras::Report::MetaMessage;
use Data::Dumper;
my  		@attributes = qw(
				prepend					postpend				hashpend
				pre_sub					post_sub
			);
my  		@methods = qw(
				clear_prepend			has_prepend				get_all_prepend
				add_to_prepend			clear_postpend			has_postpend
				get_all_postpend		add_to_postpend			clear_hashpend
				has_hashpend			get_all_hashpend		add_to_hashpend
				remove_from_hashpend	manage_message			clear_pre_sub
				has_pre_sub				get_pre_sub				set_pre_sub
				clear_post_sub			has_post_sub			get_post_sub
				set_post_sub			
			);
my  (
			$message_class, $message_instance, $ella_peterson, $output, $master_store,
	);
note 									"easy question first ...";
###InternalReporTMetaMessagE	use Log::Shiras::Switchboard;
###InternalReporTMetaMessagE	use Log::Shiras::Telephone;
###InternalReporTMetaMessagE	use Log::Shiras::Report::Test2Note;
###InternalReporTMetaMessagE	ok( lives{	$ella_peterson = Log::Shiras::Switchboard->get_operator(
###InternalReporTMetaMessagE					name_space_bounds =>{
###InternalReporTMetaMessagE						UNBLOCK =>{
###InternalReporTMetaMessagE							log_file => 'trace',
###InternalReporTMetaMessagE						},
###InternalReporTMetaMessagE					},
###InternalReporTMetaMessagE	reports	=>{
###InternalReporTMetaMessagE		log_file =>[ Log::Shiras::Report::Test2Note->new ],
###InternalReporTMetaMessagE	}
###InternalReporTMetaMessagE				) },						"Get a switchboard operator (with settings)")
###InternalReporTMetaMessagE											or note($@);
ok( lives{	$message_class = build_class(
				package => 'Test',
				add_roles_in_sequence => [
					'Log::Shiras::Report',
					'Log::Shiras::Report::MetaMessage',
				],
				add_methods =>{
					add_line => sub{ 
						my( $self, $message ) = @_;
						$master_store = $message->{message};
						return 1;
					},
				}
			);
	},									"Build a MetaMessage class")
										or note($@);
map{
has_attribute_ok
			$message_class, $_,			"Check that the new instance has the -$_- attribute",
}			@attributes;
map{									#Check that all exported methods are available
can_ok		$message_class, $_,
}			@methods;
ok( lives{	$message_instance = $message_class->new( 
				prepend =>[qw( lets go )],
				postpend =>[qw( store package )]
			) },						"Build a Test instance with prepend and postpend")
										or note($@);
is			$message_instance->add_line({ message =>[qw( to the )], package => 'here', }), 1,
										"Run add_line";
is			$master_store, [qw( lets go to the store here )],
										"...and check for the correct message updates";
ok( lives{	$message_instance->set_post_sub( sub{
				my $message = $_[0];
				my $new_ref;
				for my $element ( @{$message->{message}} ){
					push @$new_ref, uc( $element );
				}
				$message->{message} = $new_ref;
			} ) },						"Add a post_sub closure");
is			$message_instance->add_line({ message =>[qw( from the )], package => 'here', }), 1,
										"Run add_line";
is			$master_store, [qw( LETS GO FROM THE STORE HERE )],
										"...and check for the correct message updates";
ok( lives{	$message_instance = $message_class->new( 
				hashpend => {
					locate_jenny => sub{
						my $message = $_[0];
						my $answer;
						for my $person ( keys %{$message->{message}->[0]} ){
							if( $person eq 'Jenny' ){
								$answer = "$person lives in: $message->{message}->[0]->{$person}" ;
								last;
							}
						}
						return $answer;
					}
				},
			) },						"Build a Test instance with a hashpend")
										or note($@);
is			$message_instance->add_line({ message =>[{ Frank => 'San Fransisco', Donna => 'Carbondale', Jenny => 'Portland' }], }), 1,
										"Run add_line";
is			$master_store, [ {
				locate_jenny => 'Jenny lives in: Portland',
				Frank => 'San Fransisco',
				Donna => 'Carbondale',
				Jenny => 'Portland'
			} ],					"...and check for the correct message updates";
ok( lives{	$message_instance->set_pre_sub( sub{
				my $message = $_[0];
				my $lookup = {
						'San Fransisco' => 'CA',
						'Carbondale' => 'IL',
						'Portland' => 'OR',
					};
				for my $element ( keys %{$message->{message}->[0]} ){
					$message->{message}->[0]->{$element} .= ', ' . $lookup->{$message->{message}->[0]->{$element}};
				}
			} ) },						"Add a pre_sub closure");
is			$message_instance->add_line({ message =>[{ Frank => 'San Fransisco', Donna => 'Carbondale', Jenny => 'Portland' }], }), 1,
										"Run add_line";
is			$master_store, [ {
				locate_jenny => 'Jenny lives in: Portland, OR',
				Frank => 'San Fransisco, CA',
				Donna => 'Carbondale, IL',
				Jenny => 'Portland, OR'
			} ],					"...and check for the correct message updates";
note								"... Test Done";
done_testing;