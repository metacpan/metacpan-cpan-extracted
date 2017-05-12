package t::lib::MyExceptions;
use strict;
use warnings;

package MyException1;
use parent 'Exception::Tiny';

package MyException2;
use parent -norequire, 'MyException1';

package MyException3;
use parent -norequire, 'MyException1';
use Class::Accessor::Lite (
    ro  => [qw/ my_exception3 /]
);

package MyException4;
use parent -norequire, 'MyException3';
use Class::Accessor::Lite (
    ro  => [qw/ my_exception4 /]
);

package OverwriteAsString;
use parent 'Exception::Tiny';

sub as_string {
    my $self = shift;
    'OverwriteAsString: ' . $self->message;
}

1;
