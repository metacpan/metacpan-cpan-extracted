package Grid::Request::DRM::SGE;

use strict;
use Log::Log4perl qw(get_logger);

our $VERSION = '0.11';

my $logger = get_logger(__PACKAGE__);

my %ARCH = ( solaris => "sol-sparc64",
             linux   => "lx24*",
             opteron => "lx24-amd64",
           );

sub new {
    my $class = shift;
    my $self = bless {}, $class || ref($class);
    return $self;
}

sub account {
    $logger->debug("In account.");
    my ($self, $account) = @_;
    my $spec = "-A $account";
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub hosts {
    $logger->debug("In hosts.");
    my ($self, $hosts) = @_;
    my @hosts = split(/,/, $hosts);
    my $host_list = join("|", @hosts);
    my $spec = "-l hostname=$host_list";
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub opsys {
    $logger->debug("In opsys.");
    my ($self, $opsys) = @_;
    if (! defined $opsys) {
        Grid::Request::InvalidArgumentException->throw(qq|"opsys" is not defined.|);
    }
    my @sys = split(/,/, lc($opsys));
    my @arch; # To hold the translated values.
    foreach my $sys (@sys) {
        if (exists($ARCH{$sys})) {
            push @arch , $ARCH{$sys}; 
        } else {
            Grid::Request::InvalidArgumentException->throw("$sys is not a valid opsys.");
        }
    }
    my $spec = "-l arch=";
    my $arch_translated = join('|', @arch);
    $spec .= $arch_translated;
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub evictable {
    $logger->debug("In evictable.");
    my $self = shift;
    my $spec = "-r y -ckpt rescheduled"; 
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub priority {
    $logger->debug("In priority.");
    my ($self, $priority) = @_;
    # TODO: Note that the -p priority, as of 6.0u7, is going to a GLOBAL priority
    # across ALL jobs from all users. Additionally, priority can only be set negatively
    # from the -1024 to 0 range unless the user is an SGE manager. This should probably
    # be revised to use -js instead of -p, to prevent confusion, as -p does not rank
    # jobs per user, but globally... What the user probably wants is to prioritize among
    # his/her own jobs...
    my $spec = "-p $priority";
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub memory {
    $logger->debug("In memory.");
    my ($self, $megabytes) = @_;
    my $spec = " -l mem_total=" . $megabytes . "M";
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub project {
    $logger->debug("In project.");
    my ($self, $project) = @_;
    if (! defined $project) {
        Grid::Request::InvalidArgumentException->throw("project is not defined.");
    }
    my $spec = "-P $project";
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub class {
    $logger->debug("In class.");
    my ($self, $class) = @_;
    $logger->warn(qq|'class' doesn't do anyting in this drm package.|);
    return "";
}

sub runtime {
    $logger->debug("In runtime.");
    my ($self, $min) = @_;
    if ($min !~ m/\d+/ ) {
        $logger->logcroak("Bad runtime value entered. Must be an integer number of minutes.");
    }
    # Convert the minutes to 'HH:mm" format by determining the
    # number of hours and minutes
    my $hours = sprintf("%02s", int($min/60));
    $logger->debug("Hours: $hours");

    # Get the remaining minutes
    my $minutes = sprintf("%02s", $min % 60);
    $logger->debug("Minutes: $minutes");

    # Build the time string. Seconds are always set to 00
    my $time = $hours . ":" . $minutes . ":00";
    $logger->debug("Converted $min in minutes to: $time.");

    my $spec = "-l h_rt=$time";
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

1;
