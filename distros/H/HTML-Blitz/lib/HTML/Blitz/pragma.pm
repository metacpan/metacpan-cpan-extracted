# This code can be redistributed and modified under the terms of the GNU
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::pragma 0.1001;
use strict;
use warnings qw(all FATAL uninitialized);
use constant {
    PERL_VERSION    => '5.20',
    _HAVE_PERL_5_24 => $^V ge v5.24.0,
    _HAVE_PERL_5_32 => $^V ge v5.32.0,
};
use feature ':' . PERL_VERSION;
no if _HAVE_PERL_5_32, feature => 'indirect';
use Function::Parameters 2;

use Carp ();

method import($class: @items) {
    for my $item (@items) {
        Carp::croak qq("$item" is not exported by the $class module);
    }

    strict->import;
    warnings->import(qw(all FATAL uninitialized));
    warnings->unimport(qw(experimental::postderef)) unless _HAVE_PERL_5_24;
    feature->import(':' . PERL_VERSION, 'postderef');
    feature->unimport('indirect') if _HAVE_PERL_5_32;
    Function::Parameters->import;
}

1
