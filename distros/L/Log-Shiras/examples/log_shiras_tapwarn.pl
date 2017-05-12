use Modern::Perl;
use	lib 
		'../lib',;
#~ use Log::Shiras::Unhide qw( :InternalTaPWarN );# :InternalSwitchboarD
$ENV{hide_warn} = 0;
use Log::Shiras::Switchboard;
use Log::Shiras::TapWarn qw( re_route_warn restore_warn );
my	$ella_peterson = Log::Shiras::Switchboard->get_operator(
		name_space_bounds =>{
			UNBLOCK =>{
				log_file => 'trace',
			},
			main =>{
				34 =>{
					UNBLOCK =>{
						log_file => 'fatal',
					},
				},
				36 =>{
					UNBLOCK =>{
						log_file => 'fatal',
					},
				},
			},
		},
		reports	=>{ log_file =>[ Print::Log->new ] },
	);
re_route_warn(
	fail_over => 0,
	level => 'debug',
	report => 'log_file', 
);
warn "Hello World 1";
warn "Hello World 2";
restore_warn;
warn "Hello World 3";

package Print::Log;
use Data::Dumper;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? 
					@{$_[0]->{message}} : $_[0]->{message};
	my ( @print_list, @initial_list );
	no warnings 'uninitialized';
	for my $value ( @input ){
		push @initial_list, (( ref $value ) ? Dumper( $value ) : $value );
	}
	for my $line ( @initial_list ){
		$line =~ s/\n$//;
		$line =~ s/\n/\n\t\t/g;
		push @print_list, $line;
	}
	my $output = sprintf( "| level - %-6s | name_space - %-s\n| line  - %04d   | file_name  - %-s\n\t:(\t%s ):\n", 
				$_[0]->{level}, $_[0]->{name_space},
				$_[0]->{line}, $_[0]->{filename},
				join( "\n\t\t", @print_list ) 	);
	print $output;
	use warnings 'uninitialized';
}

1;