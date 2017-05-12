use strict; use warnings;
package Devel::Local::PATH;

use Devel::Local();

sub import {
    Devel::Local::print_path('PATH', @ARGV);
    exit 0;
}

1;
