#!/usr/bin/perl -w

# Copyright 2010, 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.


# This is an example of a self-uncompressing executable.  Run it with
#
#    ./self-gunzip.pl
#
# or
#
#    perl self-gunzip.pl
#
# This file begins with the plain text you're reading now but immediately
# after the "use Filter::gunzip" line there's raw gzipped bytes.  Of course
# there's no need for all this verbiage in a real script, it's enough to
# start with
#
#     #!/usr/bin/perl -w
#     use Filter::gunzip;
#
# The compressed bytes in this example come from the self-gunzip-part.pl
# file.  They can be updated here by truncating after the "use" line and
# gzipping and appending,
#
#     gzip -9 -c self-gunzip-part.pl >>self-gunzip.pl
#
# For a real program you'd probably automate that, or more likely treat the
# .pl as the master and build the self-uncompressor with something like
#
#     echo '#!/usr/bin/perl -w'      >my-self-expander
#     echo 'use Filter::gunzip;'     >>my-self-expander
#     gzip -9 -c self-gunzip-part.pl >>my-self-expander
#

use strict;
use warnings;
use Filter::gunzip;
���Kself-gunzip-part.pl ��O��0���O�eW�������"�E��B�
��L�Ǝl�4��U��jOIF/�yofF��v��n<^M_N��R#J���F:TR��
�a*,��d_ԝ�*�8��R�V��T���C!4,��y+��g�����X�L)����tI�!0��B�����4Y���JXɂ�#�*����"_p��n�0�^��$+,�d��l�^���´A���(�s��%�H%xv�}cZ��0�C�R)	���Sc��1���i�ϑ�xN�,]燄��1���J��VIs
+��<>γ������2?0�,��z��a�ɐb�f�r�_���l���c`G�Y2���GV�R�k�/б3U�g�E$��K����-)�k&��������ñ÷���ɤ����]ll=QW�����?�fF���w�g�܃�s���Z�{G���-1w'��p^�:�\�y�Z��%Qk���������)��PSz�N���'}�D�O`�D�  �j  
