package Function::Interface::Info::Function::ReturnParam;

use v5.14.0;
use warnings;

our $VERSION = "0.01";

sub new {
    my ($class, %args) = @_;
    bless \%args => $class;
}

sub type() { $_[0]->{type} }
sub type_display_name() { $_[0]->type->display_name }

1;
