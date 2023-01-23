# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::SelectorType;
use HTML::Blitz::pragma;
use Exporter qw(import);
use HTML::Blitz::Atom our @EXPORT_OK = qw(
    ST_FALSE
    ST_TAG_NAME
    ST_ATTR_HAS
    ST_ATTR_EQ
    ST_ATTR_PREFIX
    ST_ATTR_SUFFIX
    ST_ATTR_INFIX
    ST_ATTR_LIST_HAS
    ST_ATTR_LANG_PREFIX
    ST_NTH_CHILD
    ST_NTH_CHILD_OF_TYPE

    LT_DESCENDANT
    LT_CHILD
    LT_SIBLING
    LT_ADJACENT_SIBLING
);

our $VERSION = '0.03';

1
