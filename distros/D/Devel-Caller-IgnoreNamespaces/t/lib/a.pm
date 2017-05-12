package a;

sub a_caller {
    return caller(shift()) if(@_);
    return caller();
}
sub a_caller_caller {
    a_caller(@_);
}
1;
