# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::pragma;
use strict;
use warnings qw(all FATAL uninitialized);
use constant PERL_VERSION => '5.20';
use feature ':' . PERL_VERSION;
use Function::Parameters 2;
no indirect ':fatal';

use Carp ();

our $VERSION = '0.06';

method import($class: @items) {
    for my $item (@items) {
        Carp::croak qq("$item" is not exported by the $class module);
    }

    strict->import;
    warnings->import(qw(all FATAL uninitialized));
    feature->import(':' . PERL_VERSION);
    Function::Parameters->import;
    indirect->unimport(':fatal');
}

1
