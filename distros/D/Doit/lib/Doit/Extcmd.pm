# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2022 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Extcmd;

use strict;
use warnings;
our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(is_in_path);

require Doit;

no warnings 'once';
*is_in_path = \&Doit::Util::is_in_path;

1;

__END__
