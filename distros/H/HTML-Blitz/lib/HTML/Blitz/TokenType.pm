# This code can be redistributed and modified under the terms of the GNU
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::TokenType 0.1001;
use HTML::Blitz::pragma;
use Exporter qw(import);
use HTML::Blitz::Atom our @EXPORT_OK = qw(
    TT_TAG_OPEN
    TT_TAG_CLOSE
    TT_TEXT
    TT_COMMENT
    TT_DOCTYPE
);

1
