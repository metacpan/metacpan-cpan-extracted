package Test::Emailesque;

use strict;
use warnings;
use Emailesque ();
use Email::Sender::Transport::Test;

sub new {
    return bless {}, shift;
}

sub test_function {
    my ($self, $data) = @_;

    my $result = Emailesque::email($data, 'Test');
    return ref($result) =~ /success/i;
}

sub test_method {
    my ($self, $data) = @_;

    my $result = Emailesque->new({})->send($data, 'Test');
    return ref($result) =~ /success/i;
}

sub test_construction {
    my ($self, $data) = @_;

    my $result = Emailesque->new($data)->send({}, 'Test');
    return ref($result) =~ /success/i;
}

1;
