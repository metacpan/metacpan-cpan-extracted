use strict;
use warnings;

package PackageChanger;

use Devel::ChangePackage;

sub import {
    change_package 'Moo::Kooh';
}

1;
