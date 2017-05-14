package Grid::Request::DRM::CONDOR;

use strict;
use Log::Log4perl qw(get_logger);

our $VERSION = '0.11';

my $logger = get_logger(__PACKAGE__);

sub new {
    my $class = shift;
    my $self = bless {}, $class || ref($class);
    return $self;
}

sub class {
    $logger->debug("In class.");
    my ($self, $class) = @_;
    $logger->warn(qq|'class' doesn't do anyting in this drm package.|);
    return "";
}

sub hosts {
    $logger->debug("In hosts.");
    my ($self, $hosts) = @_;
    my @hosts = split(/,/, $hosts);

    my @requirements = ();
    foreach my $host (@hosts) {
        push (@requirements, "Machine == \"$host\"");
    }
    # Should look like this:
    # (Machine == "machineA" || Machine == "machine")
    #my $expression = "( " . join(" || ", @requirements) . " )";
    my $expression = join(" || ", @requirements);
    

    my $spec = "Requirements = $expression";
    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

sub opsys {
}

sub evictable {
}

sub priority {
}

sub runtime {
    my ($self, $min) = @_;
    $logger->debug("In runtime.");

    if ($min !~ m/\d+/ or $min == 0) {
        $logger->logcroak("Bad runtime value entered. Must be a positive integer number of minutes.");
    }

    my $seconds = $min * 60;
    my $spec = "periodic_remove = ((RemoteWallClockTime - CumulativeSuspensionTime) >= $seconds)";

    $logger->debug(qq|Returning "$spec".|);
    return $spec;
}

1;
