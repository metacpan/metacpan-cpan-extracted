package Grid::Request::DRM::PBS;

use strict;
use Log::Log4perl qw(get_logger);

our $VERSION = '0.11';

my $logger = get_logger(__PACKAGE__);

sub new {
    my $class = shift;
    my $self = bless {}, $class || ref($class);
    return $self;
}

sub account {
    $logger->debug("In account.");
    my ($self, $account) = @_;
    my $spec = "";
    return $spec;
}

sub hosts {
    $logger->debug("In hosts.");
    my ($self, $hosts) = @_;
    my $spec = "";
    return $spec;
}

sub opsys {
    $logger->debug("In opsys.");
    my $self = shift;
    my $spec = "";
    return $spec;
}

sub evictable {
    $logger->debug("In evictable.");
    my $self = shift;
    my $spec = "";
    return $spec;
}

sub priority {
    $logger->debug("In priority.");
    my ($self, $priority) = @_;
    my $spec = "";
    return $spec;
}

sub memory {
    $logger->debug("In memory.");
    my ($self, $megabytes) = @_;
    my $spec = "";
    return $spec;
}

sub length {
    $logger->debug("In length.");
    my ($self, $length) = @_;
    my $spec = "";
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
    my $spec = "";
    return $spec;
}

sub runtime {
    $logger->debug("In runtime.");
    my ($self, $min) = @_;
    my $spec = "";
    return $spec;
}

1;
