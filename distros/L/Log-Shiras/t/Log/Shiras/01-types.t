#!perl
#########1 Test File for Log::Shiras::Types       5#########6#########7#########8#########9
my ( $lib, $test_file );
BEGIN{
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	plan( 25 );
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
			$lib = $directory_ref->{$return} . 'lib';
			$test_file = $directory_ref->{$return} . 't/test_files/';
			#~ diag $lib;
			#~ diag $test_file;
			last;
		}
	}
	#~ use Carp 'longmess';
	#~ $SIG{__WARN__} = sub{ print longmess $_[0]; };
}
$| = 1;
use lib $lib;

#~ use Log::Shiras::Unhide qw( 
		#~ :debug :InternalSwitchboarD			
		#~ :InternalTypeSShirasFormat		:InternalTypeSFileHash			:InternalBuilDInstancE
		#~ :InternalTypeSReportObject		:InternalExtracteDGrafT			:InternalExtracteD				:InternalExtracteDClonE			:InternalExtracteDPrinT		:InternalExtracteDPrunE			:InternalExtracteDDispatcH			
	#~ );#
###LogSD	use Log::Shiras::Report::Test2Note;
###LogSD	use Log::Shiras::Switchboard;
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							main =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'trace',
###LogSD								},
###LogSD							},
###LogSD							Log =>{
###LogSD								Shiras =>{
###LogSD									Switchboard =>{
###LogSD										master_talk =>{
###LogSD											_can_communicate =>{
###LogSD												UNBLOCK =>{
###LogSD													log_file => 'warn',
###LogSD												},
###LogSD											},
###LogSD										},
###LogSD									},
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Log::Shiras::Report::Test2Note->new ],
###LogSD						},
###LogSD					);
use Log::Shiras::Types qw(
		ElevenArray			PosInt				NewModifier			ElevenInt
		ShirasFormat		TextFile			HeaderString		YamlFile
		FileHash			JsonFile			ArgsHash			
		NameSpace			CSVFile				XMLFile				XLSXFile
		XLSFile				IOFileType			HeaderArray
	);#ReportObject
###LogSD	$operator->master_talk({ name_space => 'main', level => 1, report => 'log_file',
###LogSD		message =>[	"testing PosInt ..." ] } );
my  		@PosIntArray = qw(
				1
				999999
				0
				-0
			);
my  		@NotPosIntArray = qw(
				-1
				-999999
				1.1
				999.00000000000000001
			);
map{									
ok			is_PosInt( $_ ),			"Correct -PosInt- test ( $_ )",
} 			@PosIntArray;
map{
ok			!is_PosInt( $_ ),			"Not a -PosInt- test ( $_ )",
} 			@NotPosIntArray;
###LogSD	$operator->master_talk({ name_space => 'main', level => 1, report => 'log_file',
###LogSD		message =>[	"testing ElevenArray" ] } );
my  		@ElevenArrayArray = (
				[ 0, 1, 2, 3, ],
				[ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ],
				[],
			);
my  		@NotElevenArrayArray = (
				[ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, ],
			);
map{									
ok			is_ElevenArray( $_ ),		"Correct -ElevenArray- test with -" . 
											scalar( @$_ ) . "- elements",
} 			@ElevenArrayArray;
map{
ok			!is_ElevenArray( $_ ),		"Bad -ElevenArray- test with -" .
											scalar( @$_ ) . "- elements",
} 			@NotElevenArrayArray;
###LogSD	$operator->master_talk({ name_space => 'main', level => 1, report => 'log_file',
###LogSD		message =>[	"testing ElevenInt" ] } );
my  		@ElevenIntArray = qw(
				1
				11
				0
			);
my  		@NotElevenIntArray = qw(
				-1
				12
				1.1
			);
map{									
ok			is_ElevenInt( $_ ),			"Correct -ElevenInt- test ( $_ )",
} 			@ElevenIntArray;
map{
ok			!is_ElevenInt( $_ ),		"Not an -ElevenInt- test ( $_ )",
} 			@NotElevenIntArray;
###LogSD	$operator->master_talk({ name_space => 'main', level => 1, report => 'log_file',
###LogSD		message =>[	"testing JsonFile" ] } );
my  		@JsonFileArray = (
				$test_file . 'config.json',
			);
my  		@NotJsonFileArray = (
				$test_file . 'other.json',
				$test_file . 'configII.yml',
			);
map{
ok			is_JsonFile( $_ ),
									"Correct -JsonFile- test ( $_ )" or
									map{ diag $_ } <*>
} 			@JsonFileArray;
map{
ok			!is_JsonFile( $_ ),
									"Not a -JsonFile- test ( $_ )",
} 			@NotJsonFileArray;
###LogSD	$operator->master_talk({ name_space => 'main', level => 1, report => 'log_file',
###LogSD		message =>[	"testing YamlFile" ] } );
my  		@YamlFileArray = (
				$test_file . 'config.yml',
				$test_file . 'configII.yml'
			);
my  		@NotYamlFileArray = (
				$test_file . 'other.yml',
				$test_file . 'config.json',
			);
map{
ok			is_YamlFile( $_ ),
									"Correct -YamlFile- test ( $_ )",
} 			@YamlFileArray;
map{
ok			!is_YamlFile( $_ ),
									"Not a -YamlFile- test ( $_ )",
} 			@NotYamlFileArray;
note									"... Done Testing";
done_testing;