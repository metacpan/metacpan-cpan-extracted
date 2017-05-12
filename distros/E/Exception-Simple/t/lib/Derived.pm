package Derived;
use parent 'Exception::Simple';

sub error { 'Error=' . shift->{error} }
sub noclobber { 'original' }

1;
