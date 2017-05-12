use strict; use warnings;
package Devel::Local::PERL5LIB;

use Devel::Local();

sub import {
    Devel::Local::print_path('PERL5LIB', @ARGV);
    exit 0;
}

1;
