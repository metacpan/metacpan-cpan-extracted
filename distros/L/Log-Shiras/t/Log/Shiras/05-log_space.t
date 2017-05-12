#!perl
#########1 Test File for Log::Shiras::LogSpace    5#########6#########7#########8#########9
my ( $lib, $test_file );
BEGIN{
	use Modern::Perl;
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	use Test::Moose;
	plan( 12 );
	my $file = (caller(0))[1];
	my 	$directory_ref = {
			t		=> './',# repo level
			Log		=> '../',# t folder level
			$file	=> '../../../',# test file level
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
	$ENV{hide_warn_for_test} = 1;
}
$| = 1;
use lib $lib,;
use MooseX::ShortCut::BuildInstance qw( build_instance );
use Log::Shiras::LogSpace;
my  ( 
			$test_instance, $capture,
	);
my 			@class_attributes = qw(
				log_space
			);
my  		@class_methods = qw(
				get_log_space		set_log_space		has_log_space		get_all_space
				get_class_space
			);
my			$answer_ref = [
			];
note "easy question first ...";
ok( lives{
			$test_instance = build_instance(
				package => 'LogSpace::Instance',
				roles =>[ 'Log::Shiras::LogSpace' ],
				log_space => 'Test',
				add_methods =>{
					get_class_space => sub{ 'ClassSpace' },
				},
			); },						"Prep a test LogSpace instance" )
										or note($@);
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that Log::Shiras::LogSpace has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;

note "harder questions ...";
is			$test_instance->get_log_space, 'Test',
										"Check that the log_space can be retrieved";
is			$test_instance->get_all_space, 'Test::ClassSpace',
										"Check that all log_space (with class space) can be retrieved";
is			$test_instance->set_log_space( 'New::Space' ), 'New::Space',
										"Change the log_space";
is			$test_instance->get_log_space, 'New::Space',
										"Check that the new log_space can be retrieved";
is			$test_instance->get_all_space( 'sub' ), 'New::Space::ClassSpace::sub',
										"Check that the new 'all log_space' (with class space) can be retrieved";
note	 								"...Test Done";
done_testing();