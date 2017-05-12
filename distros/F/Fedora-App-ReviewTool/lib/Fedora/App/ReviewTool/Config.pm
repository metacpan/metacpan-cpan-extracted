package Fedora::App::ReviewTool::Config;

use Moose::Role;

use Config::Tiny;
use MooseX::Types::Path::Class qw{ File };
use MooseX::Types::URI qw{ Uri };

use namespace::clean -except => 'meta';

# debug
#use Smart::Comments;

our $VERSION = '0.10';

##
## Base attributes
##

has test => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => q{Test only -- don't run against "real" bugs/components},
);

has yes => (
    traits        => [ 'Getopt' ],
    is            => 'ro',
    isa           => 'Bool',
    cmd_aliases   => 'y',
    default       => 0,
    documentation => q{Assume yes; don't prompt},
);

##
## Configuration bits
##

with 'MooseX::ConfigFromFile';

requires '_sections';

has '+configfile' => ( 
    default => "$ENV{HOME}/.reviewtool.ini",
    documentation => 'configuration file to use',
);

has _config => (
    is => 'ro',
    isa => 'Config::Tiny',
    lazy_build => 1,
);

sub _build__config { Config::Tiny->read(shift->configfile) }

sub get_config_from_file {
    my ($class, $file) = @_;

    my $config = Config::Tiny->read($file);

    ### hmm: $config

    my %c;
    CFG_LOOP:
    for my $key ($class->_sections) {
    
        # skip if we don't have that section
        next CFG_LOOP unless exists $config->{$key};

        ### $key
        %c = (%c, %{ $config->{$key} });
    };

    return \%c;
}

##
## Logging
##

use Log::Log4perl qw{ :easy };

with 'MooseX::Log::Log4perl';

# don't need this showing up in the help...
#sub add_traits {

#    has '+logger' => ( traits => [ 'NoGetopt' ] );
#}

has debug => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => 'Enable somewhat verbose logging',
);

sub enable_logging {
    my $self = shift @_;

    if ($self->debug) {
        Log::Log4perl->easy_init($DEBUG);
        return;
    }
    
    # otherwise we just want the informative bits
    Log::Log4perl->easy_init($INFO);

    return;
}

1;

__END__
