package KelpX::AppBuilder::Utils;

use warnings;
use strict;
use File::ShareDir 'module_dir';

sub import {
    my ($class) = @_;
    my $target = caller;
    {
        no strict 'refs';
        *{"${target}::module_dir"} = \&module_dir;
    }
}

1;
