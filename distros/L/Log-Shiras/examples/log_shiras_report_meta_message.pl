use lib '../lib';
use MooseX::ShortCut::BuildInstance qw( build_class );
use Log::Shiras::Report;
use Log::Shiras::Report::MetaMessage;
use Data::Dumper;
$|=1;
my	$message_class = build_class(
		package => 'Test',
		add_roles_in_sequence => [
			'Log::Shiras::Report',
			'Log::Shiras::Report::MetaMessage',
		],
		add_methods =>{
			add_line => sub{ 
				my( $self, $message ) = @_;
				print Dumper( $message->{message} );
				return 1;
			},
		}
	);
my	$message_instance = $message_class->new( 
		prepend =>[qw( lets go )],
		postpend =>[qw( store package )],
	); 
$message_instance->add_line({ message =>[qw( to the )], package => 'here', });
$message_instance->set_post_sub(
	sub{
		my $message = $_[0];
		my $new_ref;
		for my $element ( @{$message->{message}} ){
			push @$new_ref, uc( $element );
		}
		$message->{message} = $new_ref;
	}
);
$message_instance->add_line({ message =>[qw( from the )], package => 'here', });
$message_instance = $message_class->new(
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
);
$message_instance->add_line({ message =>[{ 
	Frank => 'San Fransisco',
	Donna => 'Carbondale',
	Jenny => 'Portland' }], });
my $wait =<>;
$message_instance->set_pre_sub(
	sub{
		my $message = $_[0];
		my $lookup = {
				'San Fransisco' => 'CA',
				'Carbondale' => 'IL',
				'Portland' => 'OR',
			};
		for my $element ( keys %{$message->{message}->[0]} ){
			$message->{message}->[0]->{$element} .=
				', ' . $lookup->{$message->{message}->[0]->{$element}};
		}
	} 
);
$message_instance->add_line({ message =>[{
	Frank => 'San Fransisco',
	Donna => 'Carbondale',
	Jenny => 'Portland' }], });