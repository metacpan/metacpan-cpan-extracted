package Image::DS9::PConsts;

use strict;
use warnings;

require Exporter;

our @ISA = qw( Exporter );

our @EXPORT = 
  qw( 
     %TypeCvt

     T_FLOAT
     T_INT
     T_BOOL
     T_COORD
     T_WCSS
     T_COORDSYS
     T_SKYFRAME
     T_SKYFORMAT
     T_SEXAGESIMAL_RA
     T_SEXAGESIMAL_DEC
     T_COLOR
     T_ARRAY
     T_HASH
     T_WCS_HASH
     T_WCS_ARRAY
     T_WCS_SCALARREF
     T_PDL
     T_OTHER
     T_EPHEMERAL
     T_REWRITE
     T_STRING
     T_STRING_STRIP
     T_STRING_NL
     T_ANGLE_UNIT

     BOOL
     FLOAT
     INT
     STRING
     STRING_STRIP
     STRING_NL
     HASH
     PDL
     ANGLE_UNIT
     SEXAGESIMAL_RA
     SEXAGESIMAL_DEC
     COORD_RA
     COORD_DEC
     WCSS
     COORDSYS
     SKYFRAME
     SKYFORMAT
     COLOR
     QNONE
     QATTR
     QARGS
     QONLY
     QYES
     WCS_HASH
     WCS_ARRAY
     WCS_SCALARREF
     SCALARREF

     type_cvt
     CvtSet
     CvtGet
     ENUM
     ARRAY
     EPHEMERAL
     REWRITE
    );


our $FLOAT;
our $SEXAGESIMAL_RA;
our $SEXAGESIMAL_DEC;
our $WCSS;
our $TRUE;
our $FALSE;

BEGIN {
  sub ENUM { my $pat = join( '|', @_ ); qr/^($pat)$/i };

  $FLOAT       = qr/[+-]?(?:\d+[.]?\d*|[.]\d+)(?:[eE][+-]?\d+)?/;
  $SEXAGESIMAL_DEC = qr/[+-]?\d{2}:\d{2}:\d{2}(?:.\d+)?/;
  $SEXAGESIMAL_RA = qr/\d{2}:\d{2}:\d{2}(?:.\d+)?/;
  $WCSS        = ENUM('wcs', map { 'wcs' . $_ } ('a'..'z'));

  $TRUE        = qr/1|yes|true/i;
  $FALSE       = qr/0|no|false/i;

};


use constant CvtSet	   => 0;
use constant CvtGet	   => 1;

# mustn't be 0
use constant T_FLOAT	   =>  1;
use constant T_INT	   =>  2;
use constant T_BOOL	   =>  3;
use constant T_COORD       =>  4;
use constant T_WCSS        =>  5;
use constant T_COORDSYS    =>  6;
use constant T_SKYFRAME    =>  7;
use constant T_SKYFORMAT   =>  8;
use constant T_COLOR       => 10;
use constant T_HASH	   => 11;
use constant T_STRING	   => 12;
use constant T_PDL	   => 13;
use constant T_SCALARREF   => 14;
use constant T_WCSARRAY    => 15;
use constant T_WCSHASH     => 16;
use constant T_EPHEMERAL   => 17;
use constant T_SEXAGESIMAL_RA => 18;
use constant T_SEXAGESIMAL_DEC => 19;
use constant T_REWRITE     => 20;
use constant T_STRING_NL   => 21;	# trailing \n added on output if necessary
use constant T_WCS_SCALARREF => 22;
use constant T_STRING_STRIP => 23;	# strip blanks from string on set
use constant T_ANGLE_UNIT   => 24;
use constant T_ARRAY	   => 1024;
use constant T_OTHER	   => 8192;


use constant BOOL	   => [ T_BOOL, qr/$TRUE|$FALSE/ ];
use constant FLOAT	   => [ T_FLOAT, $FLOAT ];
use constant INT	   => [ T_INT, qr/[+-]?\d+/ ];
use constant STRING	   => [ T_STRING, sub { ! ref $_[0] } ];
use constant STRING_STRIP  => [ T_STRING_STRIP, sub { ! ref $_[0] } ];
use constant STRING_NL	   => [ T_STRING_NL, sub { ! ref $_[0] || 'SCALAR' eq ref $_[0] } ];
use constant HASH	   => [ T_HASH, sub { 'HASH' eq ref $_[0] } ];
use constant SCALARREF	   => [ T_SCALARREF, sub { ! ref $_[0] || 'SCALAR' eq ref $_[0] } ];
use constant WCS_HASH	   => [ T_WCSHASH, sub { 'HASH' eq ref $_[0] } ];
use constant WCS_ARRAY	   => [ T_WCSARRAY, sub { 'ARRAY' eq ref $_[0] } ];
use constant WCS_SCALARREF  => [ T_WCS_SCALARREF, sub { ! ref $_[0] || 'SCALAR' eq ref $_[0] } ];

use constant PDL	   => [ T_PDL, sub { UNIVERSAL::isa( $_[0], 'PDL' ) } ];

use constant SEXAGESIMAL_RA   => [ T_SEXAGESIMAL_RA, $SEXAGESIMAL_RA ];
use constant SEXAGESIMAL_DEC   => [ T_SEXAGESIMAL_DEC, $SEXAGESIMAL_DEC ];

use constant COORD_RA     => [ T_COORD, qr/$FLOAT|$SEXAGESIMAL_RA/ ];
use constant COORD_DEC     => [ T_COORD, qr/$FLOAT|$SEXAGESIMAL_DEC/ ];

use constant WCSS      => [ T_WCSS, $WCSS ];

use constant COORDSYS  => [ T_COORDSYS, 
			       ENUM( qw ( physical image wcs ), $WCSS ) ];

use constant ANGLE_UNIT => [ T_ANGLE_UNIT,
                               ENUM( qw( degrees arcmin arcsec ) ) ];

use constant SKYFRAME  => [ T_SKYFRAME, 
			       ENUM( qw ( fk4 fk5 icrs galactic ecliptic ) ) ];

use constant SKYFORMAT => [ T_SKYFORMAT, ENUM( qw ( degrees sexagesimal ) ) ];

use constant COLOR     => [ T_COLOR, ENUM( qw ( black white red green blue
				     cyan magenta yellow ) ) ];

# can't do a query; if the arguments aren't present, it's an error
use constant QNONE => 0b0000;

# can do query; 
use constant QYES  => 0b0001;


# query may have attributes, otherwise must have no attributes
use constant QATTR => 0b0100;

# query only
use constant QONLY => 0b1000;

# query must have the specified args, otherwise must have no args
use constant QARGS => 0b0010 | QONLY;

# it's an array type, with the passed number of elements
sub ARRAY
{
  my ( $min, $max ) = @_;

  # no args, don't care about size
  if ( 0 == @_ )
  {
    [ T_ARRAY, sub { 'ARRAY' eq ref $_[0] } ]
  }

  # ($fixed_size)
  elsif( 1 == @_ )
  {
    [ T_ARRAY, sub { 'ARRAY' eq ref $_[0] 
		       && $min == @{$_[0]}
		   } ]
  }

  # (0,$max)
  elsif ( 0 == $min )
  {
    [ T_ARRAY, sub { 'ARRAY' eq ref $_[0] 
		       && @{$_[0]} <= $max 
		   } ]
  }


  # ($min, -1) => lower limit only
  elsif ( -1 == $max )
  {
    [ T_ARRAY, sub { 'ARRAY' eq ref $_[0] 
		       && $min <= @{$_[0]}
		   } ]
  }

  # ($min,$max) lower and upper
  else
  {
    [ T_ARRAY, sub { 'ARRAY' eq ref $_[0] 
		       && $min <= @{$_[0]}
		       && @{$_[0]} <= $max 
		   } ]
  }
}

sub EPHEMERAL {
  [ T_EPHEMERAL, $_[0] ]
}

sub REWRITE {
  [ T_REWRITE, $_[0], \( $_[1] ) ]
}

# these must return references!  $_[0] is always a reference;
# return $_[0] if no change
our %TypeCvt = (
	T_BOOL() => [
		   # outgoing
		   sub { \( ${$_[0]} =~ $TRUE ? 'yes' : 'no' ) },
		   # incoming
		   sub { \( ${$_[0]} =~ $TRUE ? 1 : 0 ) }
		  ],

  	T_WCSHASH() => [
		       # outgoing
		       sub 
		       {
			 my $wcs = '';
			 while( my ($key, $val ) = each %{$_[0]} )
			 {
			   # remove blank lines
			   next if $key eq '';

			   # aggressively remove surrounding apostrophes
			   $val =~ s/^'+//;
	                   $val =~ s/'+$//;

			   # remove unnecessary blanks
			   $val =~ s/^\s+//;
			   $val =~ s/\s+$//;

			   # surround all values with apostrophes
			   $wcs .= uc( $key ) . ($val ne '' ? " = '$val'\n" : "\n" );
			 }
			 $wcs;
		       }

		      ],

  	T_WCSARRAY() => [
		       # outgoing
		       sub{
			 $_[0] = \( join( "\n", @{$_[0]}) . "\n" );
		         ${$_[0]} =~ s/^\s+//gm;
			 ${$_[0]} =~ s/^\s*\n//gm;
		         $_[0];

		       },
		       ],

  	T_WCS_SCALARREF() => [
			  sub {
			        ${$_[0]} =~ s/^\s+//gm;
			        ${$_[0]} =~ s/^\s*\n//gm;
				$_[0] = \( ${$_[0]} . "\n" ) 
			         unless substr(${$_[0]},-1,1) eq '\n';
			       $_[0];
                             }
                         ],


  	T_ARRAY() => [
		      # outgoing
		      undef,
		
		      # incoming
		      sub {
			  ( my $s = ${$_[0]} ) =~ s/^\s+//;
			  $s =~ s/\s+$//;
			  $_[0] = [ split( / /, $s ) ];
		          $_[0];
			}
		     ],

  	T_STRING_NL() => [
			  sub {
			    $_[0] = \( ${$_[0]} . "\n" ) 
			         unless substr(${$_[0]},-1,1) eq '\n';
		            $_[0];
                             }
                         ],

  	T_STRING_STRIP() => [
			  sub {
			    ${$_[0]} =~ s/\s+//g;
		            $_[0];
                             }
                         ],

       );


sub type_cvt
{
  my $dir = shift;
  my $type = shift;

  defined $TypeCvt{$type}[$dir] ? $TypeCvt{$type}[$dir]->($_[0]) :
           ref( $_[0] ) ? $_[0] : \( $_[0] );
}

1;
