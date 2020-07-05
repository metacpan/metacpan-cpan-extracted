package Exception::Backtrace;
use 5.018;
use warnings;
use XS::libpanda;
use XS::libdwarf;
use XS::Framework;

use overload
    '""'     => sub { shift->{_value} },
    fallback => 1;

our $VERSION = '1.0.8';


require XS::Loader;
XS::Loader::load();


my $handler = sub {
    my $ex = shift;
    my $wrapped_ex = Exception::Backtrace::safe_wrap_exception($ex);
    die($wrapped_ex) if ($wrapped_ex)
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
