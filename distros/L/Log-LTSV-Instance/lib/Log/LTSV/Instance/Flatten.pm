package Log::LTSV::Instance::Flatten;
use strict;
use warnings;
use Hash::Flatten;

sub new {
    my $class = shift;

    my $flatten = Hash::Flatten->new({
        HashDelimiter  => '.',
        ArrayDelimiter => '.',
    });
    my $self = bless {
        flatten => $flatten,
    }, $class;
    return $self;
}
sub flatten {
    my ($self, $prefix, $args) = @_;
    my $flat = $self->{flatten}->flatten({ $prefix => $args });
    return %{ $flat };
}

1;
