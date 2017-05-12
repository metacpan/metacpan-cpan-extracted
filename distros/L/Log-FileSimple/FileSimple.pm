package Log::FileSimple;
# questo componente utilizzando un file di log può essere usato per fare
# il debug di componenti


use 5.006;
use strict;
use warnings;
use Carp;

use FileHandle;
use Data::Dumper;

$Log::FileSimple::VERSION	= '0.02';


# Fields that can be set in new method, with defaults
my %fields =(	
	file 	=> '/tmp/log.log',
	name	=> undef,
	mask	=> 0xFFFF,
	autoflush => 0,
);

sub new
{            
    my ($proto,%options) = @_;
    my $class = ref($proto) || $proto;
    my $self = {
        %fields};
    while (my ($key,$value) = each(%options)) {
        if (exists($fields{$key})) {
            $self->{$key} = $value if (defined $value);
        } else {
            die ref($class) . "::new: invalid option '$key'\n";
        }
    }
    foreach (keys(%fields)) {
    	die ref($class) . "::new: must specify value for $_" 
    		if (!defined $self->{$_});
    }
	$self->{mask} = 0xFFFF if ($self->{mask} == -1);
    bless $self, $class;
    $self->_init;
    return $self;
}

sub _init {
	my $self = shift;
	$self->{fh} = new FileHandle ">>$self->{file}";
	$self->{fh}->autoflush($self->{autoflush});
	die "Unable to write to $self->{file}" if (!defined $self->{fh});
}

sub DESTROY {
	my $self = shift;
	$self->{fh}->close;
	undef $self->{fh};
	# Enter here your code
}

sub log {
	my $self 		= shift;
	my %log_data 	= @_;
	
	$log_data{'id'} = $self->{mask} 
		if (!exists $log_data{'id'});
	#$self->{fh}->print("Data :" . $log_data{'id'} . "-" . 
	#	$self->{mask} . "-" . ($log_data{'id'} & $self->{mask}) ."\n");
	return if (($log_data{'id'} & $self->{mask}) == 0);
	my $timestamp	= localtime;
	my $sep			= '-' x 80;
	my $log_data = $log_data{'message'} . "\n" 
			 if (exists $log_data{'message'});
	
	if (exists $log_data{'objects'}) {
		foreach (@{$log_data{'objects'}}) {
			$log_data .= Data::Dumper::Dumper($_) . "\n";
		}
	}

	my $print_data	=<<EOF;
[$timestamp] -> $self->{name}
$log_data
$sep
EOF
	$self->{fh}->print($print_data);
}

sub mask { my $s = shift; if (@_) { $s->{mask} = shift; } return $s->{mask}; }

