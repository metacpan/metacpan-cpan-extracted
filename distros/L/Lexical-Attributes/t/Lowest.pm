package Lowest;

use strict;
use warnings;

use LA_Base;
our @ISA = qw /LA_Base/;

#
# Ordinary Perl OO module.
#

sub new {
    my $class = shift;

    bless {} => $class;
}

sub key1 {
    my $self = shift;
    $$self {key1};
}
sub set_key1 {
    my $self = shift;
    $$self {key1} = shift;
}

sub key2 {
    my $self = shift;
    reverse $self -> SUPER::key2;
}
sub set_key2 {
    my $self = shift;
    $self -> SUPER::set_key2 (shift);
}


1;

__END__
