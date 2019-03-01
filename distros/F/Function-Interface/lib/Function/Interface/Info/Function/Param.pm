package Function::Interface::Info::Function::Param;

use v5.14.0;
use warnings;

our $VERSION = "0.01";

sub new {
    my ($class, %args) = @_;
    bless \%args => $class;
}

sub type() { $_[0]->{type} }
sub name() { $_[0]->{name} }
sub optional() { !!$_[0]->{optional} }
sub named() { !!$_[0]->{named} }

sub type_display_name() { $_[0]->type->display_name }

1;
