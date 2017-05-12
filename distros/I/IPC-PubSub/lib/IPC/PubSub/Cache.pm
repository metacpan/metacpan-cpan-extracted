package IPC::PubSub::Cache;
use strict;
use warnings;
use File::Spec;
use Time::HiRes ();

#method fetch                (Str *@keys --> List of Pair)                   { ... }
#method store                (Str $key, Str $val, Num $time, Num $expiry)    { ... }

#method add_publisher        (Str $chan, Str $pub)                           { ... }
#method remove_publisher     (Str $chan, Str $pub)                           { ... }

#method get_index            (Str $chan, Str $pub --> Int)                   { ... }
#method set_index            (Str $chan, Str $pub, Int $index)               { ... }

#method publisher_indices    (Str $chan --> Hash of Int)                     { ... }

sub fetch_data {
    my $self = shift;
    my $key  = shift;
    return (($self->fetch("data:$key"))[0] || [])->[-1];
}

sub store_data {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    $self->store("data:$key" => $val, -1, 0);
}

sub modify {
    my $self = shift;
    my $key  = shift;
    return $self->fetch_data($key) unless @_;

    my $with = shift;

    if (ref($with) eq 'CODE') {
        $self->lock("data:$key");
        local $_ = $self->fetch_data($key);
        my $rv = $with->();
        $self->store_data($key => $_);
        $self->unlock("data:$key");
        return $rv;
    }
    else {
        $self->store_data($key => $with);
        return $with;
    }
}

sub get {
    my ($self, $chan, $orig, $curr) = @_;

    no warnings 'uninitialized';
    sort { $a->[0] <=> $b->[0] } $self->fetch(
        map {
            my $pub = $_;
            my $index = $curr->{$pub};
            map {
                "chan:$chan-$pub$_"
            } (($orig->{$pub}+1) .. $index);
        } keys(%$curr)
    );
}

sub put {
    my ($self, $chan, $pub, $index, $msg, $expiry) = @_;
    $self->store("chan:$chan-$pub$index", $msg, Time::HiRes::time(), $expiry);
    $self->set_index($chan, $pub, $index);
}


use constant LOCK => File::Spec->catdir(File::Spec->tmpdir, 'IPC-PubSub-lock-');

my %locks;
sub lock {
    my ($self, $chan) = @_;
    for my $i (1..10) {
        return if mkdir((LOCK . unpack("H*", $chan)), 0777);
        Time::HiRes::usleep(rand(250000)+250000);
    }
}

sub disconnect {
}

END {
    rmdir(LOCK . unpack("H*", $_)) for keys %locks;
}

sub unlock {
    my ($self, $chan) = @_;
    rmdir(LOCK . unpack("H*", $chan));
    delete $locks{$chan};
}

1;
