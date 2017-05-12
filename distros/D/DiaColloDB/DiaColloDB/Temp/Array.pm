## -*- Mode: CPerl -*-
## File: DiaColloDB::Temp::Array.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB: temporary arrays

package DiaColloDB::Temp::Array;
use DiaColloDB::Temp;
use Tie::File::Indexed::JSON;
use strict;

##======================================================================
## Globals
our @ISA = qw(Tie::File::Indexed::JSON DiaColloDB::Temp);

##======================================================================
## DiaColloDB::Temp API

## $tied = TIEARRAY($classname, $filename, %opts)
##  + honors 'UNLINK' option in %opts to auto-unlink $filename on object destruction
sub TIEARRAY {
  my ($that,$file,%opts) = @_;
  return $that->SUPER::TIEARRAY($file,
				#%opts,
				mode=>'rw',
				temp=>(!exists($opts{UNLINK}) || $opts{UNLINK}),
				(map {exists($opts{$_}) ? ($_=>$opts{$_}) : qw()} qw(pack_o pack_l)),
			       );
}

## undef = $obj->cleanup()
##  + unlink temp files (only if created with 'UNLINK' option)
sub cleanup {
  $_[0]->unlink() if ($_[0]{temp});
}


1; ##-- be happy

__END__
