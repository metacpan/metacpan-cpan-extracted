# This code can be redistributed and modified under the terms of the GNU
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::ActionType;
use HTML::Blitz::pragma;
use Exporter qw(import);
use HTML::Blitz::Atom our @EXPORT_OK = qw(
    AT_REPLACE_OUTER
    AT_REPLACE_INNER
    AT_REPEAT_OUTER
    AT_REMOVE_IF

    AT_AS_REPLACE_ATTRS
    AT_AS_MODIFY_ATTRS

    AT_A_REMOVE_ATTR
    AT_A_SET_ATTR
    AT_A_MODIFY_ATTR

    AT_P_IMMEDIATE
    AT_P_VARIABLE
    AT_P_TRANSFORM
    AT_P_FRAGMENT
    AT_P_VARHTML
);

our $VERSION = '0.0901';

1
