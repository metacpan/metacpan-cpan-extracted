package Exception::Backtrace;
use 5.018;
use warnings;
use XS::libpanda;
use XS::libdwarf;

use overload
    '""'     => sub { shift->{_value} },
    fallback => 1;

our $VERSION = '1.0.0';


require XS::Loader;
XS::Loader::load();


my $handler = sub {
    my $ex = shift;
    my $maybe_wrapped_ex = Exception::Backtrace::safe_wrap_exception($ex);
    die($maybe_wrapped_ex);
};

sub install {
    $SIG{__DIE__} = $handler;
};

sub new {
    my ($class, $value) = @_;
    my $obj = { _value => $value };
    return bless $obj => $class;
}


1;
