## -*- Mode: CPerl -*-
## File: DiaColloDB::Temp.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DiaColloDB: temporary data structures: common base class

package DiaColloDB::Temp;
use DiaColloDB::Logger;
use strict;

##======================================================================
## Gloabls
our @ISA = qw(DiaColloDB::Logger);

##======================================================================
## DiaColloDB::Temp API

## $tied = TIEHASH($classname, $filename, %opts)
## $tied = TIEARRAY($classname, $filename, %opts)
##  + should honor 'UNLINK' option in %opts to auto-unlink $filename on object destruction

## undef = $obj->cleanup()
##  + unlink underlying file(s) (only if created with 'UNLINK' option)
##  + call this from DESTROY()
sub cleanup {
  ;
}

1; ##-- be happy

__END__
