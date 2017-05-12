package Image::Signature::Vars;

use strict;
use Exporter;
our @ISA = qw(Exporter);

our @colorname = qw(R G B O);
our $IGNORE_OPACITY;

our @EXPORT = qw(
		 @colorname
		 $IGNORE_OPACITY
		 );



1;

