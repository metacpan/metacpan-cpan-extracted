package EventStore::Tiny::Logger;
use Mo qw(default);

has print_target => sub {select}; # selected output file handle

sub log {
    my ($self, $event) = @_;

    # stringify
    use Data::Dump 'dump';
    my $output = $event->name . ': ' . dump $event->data;

    # print to given print handle
    $self->print_target->print("$output\n");
}

sub log_cb {
    my ($self, @args) = @_;

    # create a new logger if called as a package procedure
    $self = EventStore::Tiny::Logger->new(@args) unless ref $self;

    # create a logging callback function
    return sub {$self->log(shift)};
}

1;
__END__
