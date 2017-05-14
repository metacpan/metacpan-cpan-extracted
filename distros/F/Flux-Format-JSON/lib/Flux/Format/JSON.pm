package Flux::Format::JSON;

# ABSTRACT: JSON format for flux storages

=head1 SYNOPSIS

    use Flux::Format::JSON;

    my $json_storage = Flux::Format::JSON->wrap($storage);
    $json_storage->write({ foo => "bar" }); # will be serialized correctly, even if underlying $storage can only store strings ending with \n

    my $in = $json_storage->in(...);
    $in->read; # { foo => "bar" }

=cut

use Moo;
with 'Flux::Format';

use JSON;

use Flux::Simple qw(mapper);

has 'json' => (
    is => 'lazy',
    default => sub {
        return JSON->new->utf8->allow_nonref;
    },
);

sub encoder {
    my $self = shift;

    return mapper {
        my $item = shift;
        return $self->json->encode($item)."\n";
    };
}

sub decoder {
    my $self = shift;

    return mapper {
        my $item = shift;

        return $self->json->decode($item);
    };
}

1;
