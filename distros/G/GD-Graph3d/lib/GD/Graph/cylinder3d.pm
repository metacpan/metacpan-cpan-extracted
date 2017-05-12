############################################################
#
# Module: GD::Graph::cylinder3d
#
# Description: 
# This is merely a wrapper around GD::Graph::cylinder 
# to be used as an alias
#
# Created: 16 October 2002 by Jeremy Wadsack for Wadsack-Allen Digital Group
# 	Copyright (C) 2002 Wadsack-Allen. All rights reserved.
############################################################
# Date      Modification                              Author
# ----------------------------------------------------------
#                                                          #
############################################################
package GD::Graph::cylinder3d;

use strict;
use GD;
use GD::Graph;
use GD::Graph::cylinder;
use Carp;

@GD::Graph::cylinder3d::ISA = qw( GD::Graph::cylinder );
$GD::Graph::cylinder3d::VERSION = '0.63';

# Inherit everything from GD::Graph::cylinder


1;
