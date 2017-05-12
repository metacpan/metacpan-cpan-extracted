use 5.10.1;
use warnings;

package Dist::Iller::Config::DistIllerTestConfig;

our $VERSION = '0.0001';

use Moose;
use namespace::autoclean;
use Types::Standard qw/Str Bool/;
use Path::Tiny;

sub filepath { path('t/corpus/03-config-config.yaml') }

has no_manifest_skip => (
    is => 'ro',
    isa => Bool,
    default => 0,
);
has prompt => (
    is => 'ro',
    isa => Str,
    default => '>',
);
has is_task => (
    is => 'ro',
    isa => Bool,
    default => 0,
);
has homepage => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->has_distribution_name ? sprintf 'https://metacpan.org/release/%s', $self->distribution_name : undef;
    },
);

with 'Dist::Iller::Config';

__PACKAGE__->meta->make_immutable;

1;
