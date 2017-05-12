package b;

use Devel::Caller::IgnoreNamespaces;

Devel::Caller::IgnoreNamespaces::register(__PACKAGE__);

sub b_caller {
    return caller(shift()) if(@_);
    return caller();
}
sub b_caller_caller {
    b_caller(@_);
}
1;
