package Lab::XPRESS::Sweep::Dummy;

our $VERSION = '3.542';

use Lab::XPRESS::Sweep::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep::Sweep');

sub new {
    my $proto = shift;
    my $code  = shift;
    my @args  = @_;
    my $class = ref($proto) || $proto;
    my $self->{default_config} = { id => 'Dummy_sweep' };
    $self = $class->SUPER::new(
        $self->{default_config},
        $self->{default_config}
    );
    bless( $self, $class );

    $self->{code} = $code;

    return $self;
}

sub start {
    my $self = shift;
    return $self->{code}->($self);
}

1;
