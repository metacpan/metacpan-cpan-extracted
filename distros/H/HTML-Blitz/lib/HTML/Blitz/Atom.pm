# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::Atom;
use HTML::Blitz::pragma;
use constant ();

our $VERSION = '0.06';

method import($class: @names) {
    @_ = (
        $class,
        { map +($_ => ':' . tr/_/-/r), @names },
    );
    goto &{constant->can('import')};
}

1
