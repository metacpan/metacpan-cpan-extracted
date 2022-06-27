package Exception::Backtrace::Wrapper;
use 5.018;
use warnings;

use overload
    '""'     => sub { shift->{_value} },
    fallback => 1;

sub new {
    my ($class, $value) = @_;
    my $obj = { _value => $value };
    return bless $obj => $class;
}

sub set_message {
    my ($self, $value) = @_;
    $self->{_value} = $value;
}

1;