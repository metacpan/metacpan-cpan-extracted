package Device::Inverter::KOSTAL::PIKO::LogdataRecord;

use 5.01;
use strict;
use utf8;
use warnings;

our $VERSION = '0.02';

use Mouse;
use Device::Inverter::KOSTAL::PIKO::Timestamp;
use namespace::clean -except => 'meta';
use overload '""' => sub { shift->logdata_joined('') };

has inverter => (
    is       => 'ro',
    isa      => 'Device::Inverter::KOSTAL::PIKO',
    required => 1,
);

has logdata => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    traits   => ['Array'],
    handles  => {
        logdata_joined => 'join',
        logdata_lines  => 'elements',
    }
);

has timestamp => (
    is  => 'rw',
    isa => 'Device::Inverter::KOSTAL::PIKO::Timestamp',
);

sub print {
    my ( $self, $fh ) = @_;
    $fh //= \*STDIN;
    print $fh $self->logdata_lines;
}

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
