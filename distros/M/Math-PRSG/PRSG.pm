#! /usr/local/bin/perl -w -I/usr/local/lib/perl5

#
# Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.
#

package Math::PRSG;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default
@EXPORT = qw();

# Other items we are prepared to export if requested
@EXPORT_OK = qw();

bootstrap Math::PRSG;



package PRSG;

sub new { Math::PRSG::new(@_); }
sub seed { Math::PRSG::seed(@_); }
sub clock { Math::PRSG::clock(@_); }

1;
