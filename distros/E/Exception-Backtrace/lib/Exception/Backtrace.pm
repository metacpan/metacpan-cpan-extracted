package Exception::Backtrace;
use 5.018;
use warnings;

use XS::libpanda::backtrace;
use Exception::Backtrace::Wrapper;

our $VERSION = '1.1.4';


require XS::Loader;
XS::Loader::load();


my $handler = sub {
    my $ex = shift;
    my $wrapped_ex = Exception::Backtrace::safe_wrap_exception($ex);
    die($wrapped_ex) if ($wrapped_ex);
};

our $decorator = \&default_decorator;

sub install {
    $decorator = (shift) // \&default_decorator;
    $SIG{__DIE__} = $handler;
};

sub default_decorator {
    my $args = shift;
    my $r = join(', ', map { defined($_) ? overload::StrVal($_) : 'undef' } @$args);
    return "($r)";
}


1;
