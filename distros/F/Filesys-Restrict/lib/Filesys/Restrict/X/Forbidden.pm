package Filesys::Restrict::X::Forbidden;

use strict;
use warnings;

use parent 'Filesys::Restrict::X::Base';

sub _new {
    my ($class, $opdesc, $path) = @_;

    if (0 != rindex($opdesc, '-', 0)) {
        $opdesc .= '()';
    }

    return $class->SUPER::_new("Forbidden $opdesc of “$path”");
}

1;
