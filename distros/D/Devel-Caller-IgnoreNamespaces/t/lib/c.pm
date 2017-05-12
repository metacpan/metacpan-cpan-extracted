package c;

use Devel::Caller::IgnoreNamespaces;

Devel::Caller::IgnoreNamespaces::register(__PACKAGE__);

sub c_caller {
    return caller(shift()) if(@_);
    return caller();
}
sub c_caller_caller {
    c_caller(@_);
}
1;
