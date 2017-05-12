use Modern::Perl;
use MooseX::ShortCut::BuildInstance qw( build_class );
use	lib 
		'../lib',;
use Log::Shiras::LogSpace;
my $test_instance = build_class(
		package => 'Generic',
		roles =>[ 'Log::Shiras::LogSpace' ],
		add_methods =>{
			get_class_space => sub{ 'ExchangeStudent' },
			i_am => sub{
				my( $self )= @_;
				print "I identify as a: " . $self->get_all_space( 'individual' ) . "\n";
			}
		},
	);
my $Generic = $test_instance->new;
my $French = $test_instance->new( log_space => 'French' );
my $Spanish = $test_instance->new( log_space => 'Spanish' );
$Generic->i_am;
$French->i_am;
$Spanish->i_am;