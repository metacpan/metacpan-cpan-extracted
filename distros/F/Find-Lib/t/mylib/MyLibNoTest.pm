package MyLibNoTest;

use vars '%imported';

sub import {
    my $class = shift;
    %imported = @_;
}

1;
