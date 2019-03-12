package Function::Interface::Info;

use v5.14.0;
use warnings;

our $VERSION = "0.02";

sub new {
    my ($class, %args) = @_;
    bless {
        package => $args{package},
        functions => $args{functions},
    } => $class;
}

sub package() { $_[0]->{package} }
sub functions() { $_[0]->{functions} }

1;
