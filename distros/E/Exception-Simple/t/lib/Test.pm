package Test;
sub new{
    bless({}, shift);
}
sub something{
    Exception::Simple->throw('something');
}
1;
