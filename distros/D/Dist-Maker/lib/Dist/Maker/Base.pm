package Dist::Maker::Base;
use Mouse;

use Dist::Maker::Config;

with 'Dist::Maker::Logger';

has config => (
    is      => 'ro',
    isa     => 'Dist::Maker::Config',
    lazy    => 1,
    default => sub { Dist::Maker::Config->new() },
    handles => {
        config_data => 'data',
        verbose     => 'verbose',
        load_class  => 'load_class',
    },
);

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Base - Base class for config handling

=cut

