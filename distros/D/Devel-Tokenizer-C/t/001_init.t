################################################################################
#
# $Project: /Devel-Tokenizer-C $
# $Author: mhx $
# $Date: 2008/04/13 13:31:00 +0200 $
# $Revision: 3 $
# $Source: /t/001_init.t $
#
################################################################################
# 
# Copyright (c) 2002-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

use Test;

$^W = 1;

BEGIN { plan tests => 1 }

eval { require Devel::Tokenizer::C };
ok($@,'',"failed to require Devel::Tokenizer::C");

