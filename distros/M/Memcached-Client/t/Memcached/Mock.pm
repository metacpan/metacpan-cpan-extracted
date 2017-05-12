package t::Memcached::Mock;

use strict;
use warnings;
use Memcached::Client::Log qw{DEBUG LOG};
use Module::Load;

sub new {
    my ($class, @args) = @_;
    my %args = 1 == scalar @args ? %{$args[0]} : @args;
    my $self = bless {}, $class;
    $self->{hash_namespace} = $args{hash_namespace} || 1;
    $self->{namespace} = $args{namespace} || "";
    $self->{selector} = __class_loader (Selector => $args{selector} || 'Traditional')->new;
    $self->{selector}->set_servers ($args{servers});
    $self->{version} = $args{version};
    map {$self->{servers}->{(ref $_ ? $_->[0] : $_)} = {}} @{$args{servers}};
    $self->log ("Mock cluster is %s", $self) if DEBUG;
    $self;
}

# This manages class loading for the sub-classes
sub __class_loader {
    my ($prefix, $class) = @_;
    # Add our prefixes if the class name isn't called out as absolute
    $class = join ('::', 'Memcached::Client', $prefix, $class) if ($class !~ s/^\+//);
    # Sanitize our class name
    $class =~ s/[^\w:_]//g;
    load $class;
    $class;
}

sub add {
    my ($self, $key, $value) = @_;
    return 0 unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " ") and defined $value);
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return 0 unless (defined $self->{servers}->{$server});
    $self->log ("add: %s - %s - %s", $server, $index, $value) if DEBUG;
    return 0 if (defined $self->{servers}->{$server}->{$index});
    $self->{servers}->{$server}->{$index} = $value;
    return 1;
}

sub add_multi {
    my ($self, @tuples) = @_;
    my (%rv);
    for my $tuple (@tuples) {
        my ($key) = @{$tuple};
        my $value = $self->add (@{$tuple});
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub append {
    my ($self, $key, $value) = @_;
    return 0 unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " ") and defined $value);
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return 0 unless (defined $self->{servers}->{$server});
    $self->log ("append: %s - %s - %s", $server, $index, $value) if DEBUG;
    return 0 unless (defined $self->{servers}->{$server}->{$index});
    $self->{servers}->{$server}->{$index} .= $value;
    return 1;
}

sub append_multi {
    my ($self, @tuples) = @_;
    my (%rv);
    for my $tuple (@tuples) {
        my ($key) = @{$tuple};
        my $value = $self->append (@{$tuple});
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub connect {
    return 1;
}

sub decr {
    my ($self, $key, $delta, $initial) = @_;
    $delta = 1 unless defined $delta;
    return unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " "));
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return unless (defined $self->{servers}->{$server});
    $self->log ("decr: %s - %s - %s", $server, $index, $delta) if DEBUG;
    if (defined $self->{servers}->{$server}->{$index}) {
        if ($self->{servers}->{$server}->{$index} =~ m/^\d+$/) {
            $delta = $self->{servers}->{$server}->{$index} if ($delta > $self->{servers}->{$server}->{$index});
            $self->{servers}->{$server}->{$index} -= $delta;
        } else {
            return "CLIENT_ERROR cannot increment or decrement non-numeric value";
        }
    } elsif (defined $initial) {
        $self->{servers}->{$server}->{$index} = $initial;
    }
    return $self->{servers}->{$server}->{$index};
}

sub decr_multi {
    my ($self, @tuples) = @_;
    my (%rv);
    for my $tuple (@tuples) {
        my ($key) = ref $tuple ? @{$tuple} : $tuple;
        my $value = $self->decr (ref $tuple ? @{$tuple} : $tuple);
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub delete {
    my ($self, $key) = @_;
    return 0 unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " "));
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return 0 unless (defined $self->{servers}->{$server});
    $self->log ("delete: %s - %s", $server, $index) if DEBUG;
    return 0 unless (defined $self->{servers}->{$server}->{$index});
    delete $self->{servers}->{$server}->{$index};
    return 1;
}

sub delete_multi {
    my ($self, @keys) = @_;
    my (%rv);
    for my $key (@keys) {
        my $value = $self->delete ($key);
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub flush_all {
    my ($self) = @_;
    map {
        $self->log ("flush_all: %s", $_) if DEBUG;
        $self->{servers}->{$_} = {};
    } keys %{$self->{servers}};
    return {map {$_ => 1} keys %{$self->{servers}}};
}

sub get {
    my ($self, $key) = @_;
    return unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " "));
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return unless (defined $self->{servers}->{$server});
    $self->log ("get: %s - %s", $server, $index) if DEBUG;
    if (length $index > 250) {
        return undef;
    } else {
        return $self->{servers}->{$server}->{$index};
    }
}

sub get_multi {
    my ($self, @keys) = @_;
    return {} unless (@keys);
    my %rv;
    for my $key (@keys) {
        next unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " "));
        my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or next;
        my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
        next unless (defined $self->{servers}->{$server});
        $self->log ("get: %s - %s", $server, $index) if DEBUG;
        next unless (defined $self->{servers}->{$server}->{$index});
        $rv{ref $key ? $key->[1] : $key} = length $index > 250 ? undef : $self->{servers}->{$server}->{$index};
    }
    return \%rv;
}

sub incr {
    my ($self, $key, $delta, $initial) = @_;
    $delta = 1 unless defined $delta;
    return unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " "));
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return unless (defined $self->{servers}->{$server});
    $self->log ("incr: %s - %s - %s", $server, $index, $delta) if DEBUG;
    if (defined $self->{servers}->{$server}->{$index}) {
        if ($self->{servers}->{$server}->{$index} =~ m/^\d+$/) {
            $self->{servers}->{$server}->{$index} += $delta;
        } else {
            return "CLIENT_ERROR cannot increment or decrement non-numeric value";
        }
    } else {
        $self->{servers}->{$server}->{$index} = $initial;
    }
    return $self->{servers}->{$server}->{$index};
}

sub incr_multi {
    my ($self, @tuples) = @_;
    my (%rv);
    for my $tuple (@tuples) {
        my ($key) = ref $tuple ? @{$tuple} : $tuple;
        my $value = $self->incr (ref $tuple ? @{$tuple} : $tuple);
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub namespace {
    my ($self, $new) = @_;
    my $ret = $self->{namespace};
    $self->{namespace} = $new if (defined $new);
    return $ret;
}

sub prepend {
    my ($self, $key, $value) = @_;
    return 0 unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " ") and defined $value);
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return 0 unless (defined $self->{servers}->{$server});
    $self->log ("prepend: %s - %s - %s", $server, $index, $value) if DEBUG;
    return 0 unless (defined $self->{servers}->{$server}->{$index});
    $self->{servers}->{$server}->{$index} = $value . $self->{servers}->{$server}->{$index};
    return 1;
}

sub prepend_multi {
    my ($self, @tuples) = @_;
    my (%rv);
    for my $tuple (@tuples) {
        my ($key) = @{$tuple};
        my $value = $self->prepend (@{$tuple});
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub replace {
    my ($self, $key, $value) = @_;
    return 0 unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " ") and defined $value);
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return 0 unless (defined $self->{servers}->{$server});
    $self->log ("replace: %s - %s - %s", $server, $index, $value) if DEBUG;
    return 0 unless (defined $self->{servers}->{$server}->{$index});
    $self->{servers}->{$server}->{$index} = $value;
    return 1;
}

sub replace_multi {
    my ($self, @tuples) = @_;
    my (%rv);
    for my $tuple (@tuples) {
        my ($key) = @{$tuple};
        my $value = $self->replace (@{$tuple});
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub set {
    my ($self, $key, $value) = @_;
    return 0 unless (defined $key and (ref $key and $key->[0] and $key->[1]) || (length $key and -1 == index $key, " ") and defined $value);
    my $server = $self->{selector}->get_server ($key, $self->{hash_namespace} ? $self->{namespace} : "") or return;
    my $index = $self->{namespace} . (ref $key ? $key->[1] : $key);
    return 0 unless (defined $self->{servers}->{$server});
    $self->log ("set: %s - %s - %s", $server, $index, $value) if DEBUG;
    if (length $index > 250) {
        return 0;
    } else {
        $self->{servers}->{$server}->{$index} = $value;
        return 1;
    }
}

sub set_multi {
    my ($self, @tuples) = @_;
    my (%rv);
    for my $tuple (@tuples) {
        my ($key) = @{$tuple};
        my $value = $self->set (@{$tuple});
        $rv{$key} = $value if defined $value;
    }
    return \%rv;
}

sub set_servers {
    my ($self, $servers) = @_;
    $self->{selector}->set_servers ($servers);

    my $serverlist = {map {(ref $_ ? $_->[0] : $_), {}} @{$servers}};
    for my $server (keys %{$self->{servers} || {}}) {
        # Skip ones that will continue to exist
        next if $serverlist->{$server};
        my $deactivating = delete $self->{servers}->{$server};
    }
    for my $server (keys %{$serverlist}) {
        $self->{servers}->{$server} ||= {};
    }

    return 1;
}

sub start {
    my ($self, $server) = @_;
    $self->{servers}->{$server} ||= {};
}

sub stop {
    my ($self, $server) = @_;
    delete $self->{servers}->{$server};
    # $self->{servers}->{$server} = undef;
    $self->log ("Deleted %s, result %s", $server, $self) if DEBUG;
    return 1;
}

sub version {
    my ($self) = @_;
    return {map {
        $self->log ("version: %s", $_) if DEBUG;
        $_ => defined $self->{servers}->{$_} ? $self->{version} : undef
    } keys %{$self->{servers}}};
}

=method log

=cut

sub log {
    my ($self, $format, @args) = @_;
    LOG ("Mock> " . $format, @args);
}


1;
