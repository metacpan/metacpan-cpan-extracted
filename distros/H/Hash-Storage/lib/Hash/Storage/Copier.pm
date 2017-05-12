package Hash::Storage::Copier;

our $VERSION = '0.03';

use strict;
use warnings;
use v5.10;

use Carp qw/croak/;

sub new {
    my ($class, %args) = @_;
    croak '"src" is required' unless $args{src};
    croak '"src" must be Hash::Storage object'
        unless ref($args{src})
        && $args{src}->isa('Hash::Storage');

    croak '"dst" is required' unless $args{dst};
    croak '"dst" must be Hash::Storage object'
        unless ref($args{dst})
        && $args{dst}->isa('Hash::Storage');

    return bless \%args, $class;
}

sub copy_all {
    my $self = shift;
    my $objects = $self->{src}->list();

    foreach my $obj (@$objects) {
        my $id = delete $obj->{_id};
        $self->{dst}->set($id, $obj);
    }
}

1;