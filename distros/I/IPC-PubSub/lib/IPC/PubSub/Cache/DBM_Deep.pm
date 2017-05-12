package IPC::PubSub::Cache::DBM_Deep;
use strict;
use warnings;
use base 'IPC::PubSub::Cache';
use Storable qw/ nfreeze thaw /;
use DBM::Deep;
use File::Temp qw/ tempfile /;

sub new {
    my $class = shift;
    my $file  = shift;
    my $mem = DBM::Deep->new(
        file        => ((defined $file and length $file) ? $file : $class->default_config),
        locking     => 1,
        autoflush   => 1,
    );
    bless(\$mem, $class);
}

sub default_config {
    my (undef, $filename) = tempfile(UNLINK => 1);
    return $filename;
}

sub fetch {
    my $self = shift;
    return map { thaw($$self->get($_)) } @_;
}

sub store {
    my ($self, $key, $val, $time, $expiry) = @_;
    $$self->put($key => nfreeze([$time, $val]));
}

sub publisher_indices {
    my ($self, $chan) = @_;
    return { %{ $$self->get("pubs:$chan") || {} } };
}

sub add_publisher {
    my ($self, $chan, $pub) = @_;
    my $pubs = { %{ $$self->get("pubs:$chan") || {} } };
    $pubs->{$pub} = 0;
    $$self->put("pubs:$chan", $pubs);
}

sub remove_publisher {
    my ($self, $chan, $pub) = @_;
    my $pubs = { %{ $$self->get("pubs:$chan") || {} } };
    delete $pubs->{$pub};
    $$self->put("pubs:$chan", $pubs);
}

sub get_index {
    my ($self, $chan, $pub) = @_;
    ($$self->get("pubs:$chan") || {})->{$pub};
}

sub set_index {
    my ($self, $chan, $pub, $idx) = @_;
    my $pubs = { %{ $$self->get("pubs:$chan") || {} } };
    $pubs->{$pub} = $idx;
    $$self->put("pubs:$chan", $pubs);
}

1;
