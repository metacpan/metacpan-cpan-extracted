# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

package VRML::Text;
require DynaLoader;
@ISA=DynaLoader;
bootstrap VRML::Text;

open_font(($VRML::ENV{FREEWRL_FONTS}||"fonts")."/baklava.ttf");

1;
