# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/Filter/Base.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::Filter::Base;
use strict;

sub filter { Carp::croak(__PACKAGE__ . '::filter() is not defined') }

1;
