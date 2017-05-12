#!/usr/bin/perl
#
# This script shows one example of each general type.  Try calling it
# with -H (-?, --Hilfe) or -d (--debug) to play around with the
# interface.
#
# Try also to set environment variables like GMH_MANDATORY_STRING or
# GMH__.
#
# Author: Thomas Dorner
# Copyright: (C) 2007-2012 by Thomas Dorner (Artistic License)

use strict;
use warnings;

use File::Spec;

use constant DEFAULT_SECOND_MANDATORY_INT => 42;

BEGIN {
    # allow for usage in directory where archive got unpacked:
    my @split_path = File::Spec->splitpath($0);
    my $libpath = File::Spec->catpath(@split_path[0..1]);
    $libpath = File::Spec->catdir($libpath, '..', 'lib');
    $libpath = File::Spec->rel2abs($libpath);
    push @INC, $libpath if -d $libpath;
    require Getopt::Mixed::Help;
    import Getopt::Mixed::Help
	(
	 '<parameters>...'		    => 'additional parameters',
	 'ENV_'				    => 'GMH_',
	 '->help' => 'H>Hilfe',
	 'd>debug'			    => 'turn on debugging information',
	 's>mandatory-string=s text'	    => 'a mandatory string',
	 'i>mandatory-integer=i number'	    => 'a mandatory integer (1)',
	 'f>mandatory-float=f real number'  => 'a mandatory real number',
	 '2>second-mandatory-int=i number'  => 'another mandatory integer',
	 'S>optional-string:s text'	    => 'an optional string (2)',
	 'I>optional-integer:i value'	    => 'an optional integer',
	 'F>optional-float:f value'	    => 'an optional real number',
	 '(1)' => "(1)\tfootnote",
	 '(2)' => "(2)\tanother footnote\n\t(which is multi-line)"
	);
};
unless ($opt_debug)
{
    print <<EOT
Please call this script with -? (-H, --Hilfe) or -d (--debug) to test it and
to play around with the interface.

Try also to set environment variables like GMH_MANDATORY_STRING or GMH__.
EOT
}
