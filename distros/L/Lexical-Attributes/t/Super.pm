package Super;

use strict;
use warnings;

#
# Ordinary Perl OO module.
#

sub new {
    my $class = shift;

    bless {} => $class;
}

sub name {
    my $self = shift;
    $$self {name};
}
sub set_name {
    my $self = shift;
    $$self {name} = shift;
}

sub colour {
    my $self = shift;
    $$self {colour};
}
sub set_colour {
    my $self = shift;
    $$self {colour} = shift;
}

sub address {
    my $self = shift;
    $$self {address};
}
sub set_address {
    my $self = shift;
    $$self {address} = shift;
}


1;

__END__
