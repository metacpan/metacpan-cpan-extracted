use Modern::Perl;
use	lib 
		'../lib',;
#~ use Log::Shiras::Unhide qw( :InternalTaPPrinT );
$ENV{hide_warn} = 0;
use Log::Shiras::Switchboard;
use Log::Shiras::TapPrint qw( re_route_print restore_print );
my	$ella_peterson = Log::Shiras::Switchboard->get_operator(
		name_space_bounds =>{
			UNBLOCK =>{
				log_file => 'debug',
			},
			main =>{
				29 =>{
					UNBLOCK =>{
						log_file => 'info',
					},
				},
			},
		},
		reports	=>{ log_file =>[ Print::Log->new ] },
	);
re_route_print(
	fail_over => 0,
	level => 'debug',
	report => 'log_file', 
);
print "Hello World 1\n";
print "Hello World 2\n";
print STDOUT "Hello World 3\n";
restore_print;
print "Hello World 4\n";

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
	print STDOUT $output;
	use warnings 'uninitialized';
}

1;