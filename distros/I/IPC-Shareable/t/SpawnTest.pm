package SpawnTest;

use warnings;
use strict;

use IPC::Shareable;

system "perl t/_spawn_class";

tie my %h, 'IPC::Shareable', {
    key => 'bbbb',
};

sub new {
    my ($class) = @_;
    return bless { data => \%h }, $class;
}
sub add {
    my ($self, $num) = @_;
    die "need a num param\n" if ! defined $num;
    $self->data->{add} += $num;
}
sub push {
    my ($self, $value) = @_;
    die "need a value param\n" if ! defined $value;
    push @{ $self->data->{array} }, $value;
}
sub data {
    return $_[0]->{data};
}

sub clean {
    IPC::Shareable->unspawn('bbbb', 1);
}
1;