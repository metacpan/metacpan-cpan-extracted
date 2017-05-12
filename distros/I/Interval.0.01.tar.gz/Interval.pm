#!perl -w
#------------------------------------------------------------------------------
#
# Copyright (C) 1997 by Kristian Torp, torp@cs.auc.dk
# 
#    This program is free software. You can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
# 
#    This program is distributed AS IS in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY. See the GNU General Public License for more 
#    details.
#
#------------------------------------------------------------------------------

package Interval;

require Exporter;
use strict;

use vars qw (@ISA @EXPORT @EXPORT_OK
	     $VERSION
	     $FALSE $TRUE $OPEN $CLOSED
	     $LEFT_CLOSED $RIGHT_CLOSED
	     $LEFT_OPEN $RIGHT_OPEN 
	     $CLOSED_INT $RIGHT_OPEN_INT $LEFT_OPEN_INT $OPEN_INT $SEP 
	     $BEFORE $MEETS $LEFT_OVERLAPS $RIGHT_OVERLAPS
	     $TOTALLY_OVERLAPS $DURING $EXTENDS $AFTER
	     $ALLEN_BEFORE $ALLEN_MEETS $ALLEN_LEFT_OVERLAPS $ALLEN_LEFT_COVERS
	     $ALLEN_COVERS $ALLEN_STARTS $ALLEN_EQUALS $ALLEN_RIGHT_COVERS 
	     $ALLEN_DURING $ALLEN_FINISHES $ALLEN_RIGHT_OVERLAPS
	     $ALLEN_EXTENDS $ALLEN_AFTER
	     $DisplayFormat $DefaultType); 

@ISA    = qw (Exporter);
@EXPORT = ();
@EXPORT_OK = qw ($CLOSED_INT $RIGHT_OPEN_INT $LEFT_OPEN_INT $OPEN_INT
		 $BEFORE $MEETS $LEFT_OVERLAPS $RIGHT_OVERLAPS
		 $TOTALLY_OVERLAPS $DURING $EXTENDS $AFTER
		 $ALLEN_BEFORE $ALLEN_MEETS $ALLEN_LEFT_OVERLAPS $ALLEN_LEFT_COVERS
		 $ALLEN_COVERS $ALLEN_STARTS $ALLEN_EQUALS $ALLEN_RIGHT_COVERS 
		 $ALLEN_DURING $ALLEN_FINISHES $ALLEN_RIGHT_OVERLAPS
		 $ALLEN_EXTENDS $ALLEN_AFTER);
use Date::Manip;
use Carp;

use overload
    '+' => \&_plus,
    '-' => \&_minus,
    qw("" stringify);

BEGIN {$Date::Manip::TZ = "CET"; &Date_Init ("DateFormat=non-US");}
$VERSION = 0.01;

##############################################################################
# Constants
##############################################################################

# Boolean values
$FALSE = 0;
$TRUE  = 1;

# For output
$LEFT_CLOSED  = '[';
$RIGHT_CLOSED = ']';
$LEFT_OPEN    = '(';
$RIGHT_OPEN   = ')';
$SEP          = ',';

# <interval type>
$CLOSED_INT     = 1;
$RIGHT_OPEN_INT = 2;
$LEFT_OPEN_INT  = 3;
$OPEN_INT       = 4;

# <interval end>
$OPEN   = 1;
$CLOSED = 2;

# <overlap type>
$BEFORE           = 1;
$MEETS            = 2;
$LEFT_OVERLAPS    = 3;
$RIGHT_OVERLAPS   = 4;
$TOTALLY_OVERLAPS = 5;
$DURING           = 6;
$EXTENDS          = 7;
$AFTER            = 8;

# <Allen overlap type>
$ALLEN_BEFORE         = 1;
$ALLEN_MEETS          = 2;
$ALLEN_LEFT_OVERLAPS  = 3;
$ALLEN_LEFT_COVERS    = 4;
$ALLEN_COVERS         = 5;
$ALLEN_STARTS         = 6;
$ALLEN_EQUALS         = 7;
$ALLEN_RIGHT_COVERS   = 8;
$ALLEN_DURING         = 9;
$ALLEN_FINISHES       = 10;
$ALLEN_RIGHT_OVERLAPS = 11;
$ALLEN_EXTENDS        = 12;
$ALLEN_AFTER          = 13;

##############################################################################
# Class variables
##############################################################################

# Default<display format>
$DisplayFormat = "%Y-%m-%d";
# default <interval type>
$DefaultType   = $RIGHT_OPEN_INT; 

##############################################################################
# Class Methods
##############################################################################

sub setDefaultIntervalType
{
    my $class = shift;
    my ($nType) = @_;
    
    if (ref ($class))             { confess "Class method called as object method"; }
    if ($nType < 1 || $nType > 4) { confess "Unknown <interval type> $nType"; }
    $DefaultType  = $nType;
}

sub getDefaultIntervalType
{ 
    my $class = shift;
    if (ref ($class)) { confess "Class method called as object method"; }
    return $DefaultType;
}

sub setDisplayFormat
{
    my $class = shift;
    if (ref ($class)) { confess "Class method called as object method"; }
    unless (@_ == 1)  { confess "usage: Interval->setDisplayFormat(<string>)"; }
    $DisplayFormat = shift;
}

sub getDisplayFormat
{ 
    my $class = shift;
    if (ref ($class)) { confess "Class method called as object method"; }
    return $DisplayFormat;
}

#-----------------------------------------------------------------------------
# Instance variables
#-----------------------------------------------------------------------------

my %fields = (m_nStart => undef,
              m_nStop  => undef,
	      m_nLeft  => undef,
	      m_nRight => undef,
	      m_bEmpty => undef); # is the interval empty

#-----------------------------------------------------------------------------
# Initialization
# Input:  <start> <stop> [<interval type>]
#-----------------------------------------------------------------------------
   
sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->_initialize (@_);
    return $self;
}
 
sub _initialize
{
    my $self = shift;
    my($szStart, $szStop, $nType) = @_;

    $self->{m_bEmpty} = $FALSE;

    # Can use Dates or strings for start and stop
    if (ref $szStart) { $self->{m_nStart} = $szStart; }
    else              { $self->{m_nStart} = &ParseDate ($szStart); }
    if( !defined ($self->{m_nStart}) ) 
    { 
	print STDERR "Problems using $szStart\n"; 
	$self->{m_bError} = $TRUE;
    }

    if (ref $szStop) { $self->{m_nStop} = $szStop; }
    else             { $self->{m_nStop}  = &ParseDate ($szStop); }
    if( !defined ($self->{m_nStop}) ) 
    { 
	print STDERR "Problems using $szStart\n"; 
	$self->{m_bError} = $TRUE;
    }
    
    if ($self->{m_nStart} gt $self->{m_nStop}) 
    {
	die "Start date larger than stop date\n";
    }
    
    # Use the default <interval type>?
    if (!defined($nType)) { $nType = $DefaultType; }
    if (!$self->_setIntervalType ($nType)) 
    {
	print STDERR "Problems setting the <interval type> $nType\n";
    }
}

#-----------------------------------------------------------------------------
# Creates a new empty interval
# Input:  none
# Output: empty <interval>
#-----------------------------------------------------------------------------

sub _new_empty
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{m_bEmpty} = $TRUE;
    return $self;
}

#-----------------------------------------------------------------------------
# Sets the <interval type>
# Input:  <interval type>
# Output: boolean
#-----------------------------------------------------------------------------

sub _setIntervalType
{
    my $self = shift;
    my ($nType) = @_;
    
    if ($nType == $CLOSED_INT) 
    {
	$self->{m_nLeft}  = $CLOSED;
	$self->{m_nRight} = $CLOSED; 
    }
    elsif ($nType == $RIGHT_OPEN_INT) 
    {
	$self->{m_nLeft}  = $CLOSED;
	$self->{m_nRight} = $OPEN; 
    }
    elsif ($nType == $LEFT_OPEN_INT) 
    {
	$self->{m_nLeft}  = $OPEN;
	$self->{m_nRight} = $CLOSED; 
    }
    elsif ($nType == $OPEN_INT) 
    {
	$self->{m_nLeft}  = $OPEN;
	$self->{m_nRight} = $OPEN; 
    }
    else
    {
	return $FALSE;
    }
    return $TRUE;
}

#-----------------------------------------------------------------------------
# Sets the interval brackets
# Input:  <left> <right>
# Output: boolean
#-----------------------------------------------------------------------------

sub _setBrackets
{
    my $self = shift;
    my ($nLeft, $nRight) = @_;
    $self->{m_nLeft} = $nLeft;
    $self->{m_nRight} = $nRight;
    return $TRUE;
}

#-----------------------------------------------------------------------------
# Length of interval in Date::Manip format
# Input:  none
# Output: <delta>
#-----------------------------------------------------------------------------
 
sub length
{
    my $self = shift;
    if ($self->{m_bEmpty}) { return 0; }
    # in reverse order to make the length of the interval positive
    my $delta = &DateCalc ($self->{m_nStart}, $self->{m_nStop});
    return $delta;
}

#-----------------------------------------------------------------------------
# Returns the interval
# Input:   none
# Output:  string
#-----------------------------------------------------------------------------

sub get
{
    my $self = shift;
    my ($szResult) = '';
    if ($self->{m_bEmpty}) { return '<empty>'; }

    if ($self->{m_nLeft} == $CLOSED) { $szResult .= $LEFT_CLOSED; }
    else                             { $szResult .= $LEFT_OPEN; }

    $szResult .= &UnixDate ($self->{m_nStart}, $DisplayFormat);
    $szResult .= "$SEP ";
    $szResult .= &UnixDate ($self->{m_nStop}, $DisplayFormat);

    if ($self->{m_nRight} == $CLOSED) { $szResult .= $RIGHT_CLOSED; }
    else                              { $szResult .= $RIGHT_OPEN; }

    return $szResult;
}

#-----------------------------------------------------------------------------
# Checks if two intervals overlap
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub overlaps
{
    my $self  = shift;
    my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }

    if ($self->_overlaps ($other)) { return $TRUE; }
    else                           { return $FALSE; }
}

#-----------------------------------------------------------------------------
# Return the overlap of two intervals
# Input:  <interval>
# Output: <interval> | empty
#-----------------------------------------------------------------------------

sub getOverlap
{
    my $self = shift;
    my $other = shift;
    my ($nStart, $nStop, $nLeft, $nRight);

    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return _new_empty Interval; }
    
    # Meets
    if ($self->{m_nStop} eq $other->{m_nStart} &&
        ($self->{m_nRight} == $CLOSED  ||  $other->{m_nLeft} == $CLOSED))
    {
	$nStart = $nStop = $self->{m_nStop};
	$nLeft  = $self->{m_nRight};
	$nRight = $other->{m_nLeft};
    }
    # Extends
    elsif ($self->{m_nStart} eq $other->{m_nStop} &&
	   ($self->{m_nLeft} == $CLOSED || $other->{m_nRight} == $CLOSED))
    {
	$nStart = $nStop = $self->{m_nStart};
	$nLeft  = $self->{m_nLeft};
	$nRight = $other->{m_nRight};
    }
   # Overlaps
    elsif ($self->{m_nStart} le $other->{m_nStop} &&
	   $other->{m_nStart} le $self->{m_nStop})
    {
	# Max start time
	if ($other->{m_nStart} lt $self->{m_nStart}) { $nStart = $self->{m_nStart}; }
	else                                         { $nStart = $other->{m_nStart}; }
        # left bracket
	if ($self->{m_nLeft} == $OPEN || $other->{m_nLeft} == $OPEN) { $nLeft = $OPEN; }
	else                                                         { $nLeft = $CLOSED; }

	
	# Min stop time
	if ($other->{m_nStop} lt $self->{m_nStop}) { $nStop = $other->{m_nStop}; }
	else                                       { $nStop = $self->{m_nStop}; }

	# right bracket
	if ($self->{m_nRight} == $OPEN || $other->{m_nRight} == $OPEN) { $nRight = $OPEN; }
	else                                                           { $nRight = $CLOSED; }
	
	my $int = new Interval ($nStart, $nStop);
	$int->_setBrackets ($nLeft, $nRight);

	return $int;
    }
    else 
    {
	return _new_empty Interval;
    }
}

#-----------------------------------------------------------------------------
# Examines if interval is before
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub before
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $BEFORE ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if interval meets
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub meets
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $MEETS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals left overlaps
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub leftOverlaps
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $LEFT_OVERLAPS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals right overlaps
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub rightOverlaps
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $RIGHT_OVERLAPS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals during overlaps
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub during
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $DURING ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals right overlaps
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub totallyOverlaps
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $TOTALLY_OVERLAPS ? return $TRUE :  return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals extends
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub extends
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $EXTENDS ? return $TRUE :  return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if interval after
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub after
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_overlaps ($other) == $EXTENDS ? return $TRUE :  return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines how intervals overlaps
# Input:  <interval>
# Output: <overlap type>
#-----------------------------------------------------------------------------

sub _overlaps
{
    my $self = shift;
    my $other = shift;
    my ($bHowOverlaps, $bLeft);
    $bHowOverlaps = $bLeft = $FALSE;

    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }

    # Meets
    if ($self->{m_nStop} eq $other->{m_nStart} &&
	($self->{m_nRight} == $CLOSED || $other->{m_nLeft} == $CLOSED))
    {
	$bHowOverlaps = $MEETS;
    }
    # Extends
    elsif ($self->{m_nStart} eq $other->{m_nStop} &&
	   ($self->{m_nLeft} == $CLOSED || $other->{m_nRight} == $CLOSED))
    {
	$bHowOverlaps = $EXTENDS;
    }
   # Overlaps
    elsif ($self->{m_nStart}  le $other->{m_nStop} &&
	   $other->{m_nStart} le $self->{m_nStop})
    {
	$bHowOverlaps = $TOTALLY_OVERLAPS; # A guess

	# Left overlap or inclusion
	if ($other->{m_nStart} le $self->{m_nStop} &&
	    $self->{m_nStop}   le $other->{m_nStop})
	{
	    $bHowOverlaps = $LEFT_OVERLAPS; # A guess
	    $bLeft = $TRUE;                 # Saved for inclusion
	}
	# Right overlap or inclusion
	if ($other->{m_nStart} le $self->{m_nStart} &&
	    $self->{m_nStart}  le $other->{m_nStop})
	{
	    $bHowOverlaps = $bLeft ? $DURING : $RIGHT_OVERLAPS;
	}
    }
    return $bHowOverlaps;
}

#-----------------------------------------------------------------------------
# Describes in text how intervals overlaps
# Input:  <interval>
# Output: to screen
#-----------------------------------------------------------------------------

sub howOverlaps
{
    my $self  = shift;
    my $other = shift;
    my ($szOverlap) = ' does not overlap ';
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) 
    { 
	print $self->get,  $szOverlap, $other->get, "\n";
    }
    else
    {
	my ($bOverlaps) = $self->_overlaps($other);
	
	if    ($bOverlaps == $MEETS)           { $szOverlap = ' meets '; }
	elsif ($bOverlaps == $LEFT_OVERLAPS)   { $szOverlap = ' left overlaps '; }
	elsif ($bOverlaps == $RIGHT_OVERLAPS)  { $szOverlap = ' right overlaps '; }
	elsif ($bOverlaps == $TOTALLY_OVERLAPS){ $szOverlap = ' totally overlaps '; }   
	elsif ($bOverlaps == $DURING)          { $szOverlap = ' inclusion overlaps '; }
	elsif ($bOverlaps == $EXTENDS)         { $szOverlap = ' extends '; }
	print $self->get,  $szOverlap, $other->get, "\n";
    }
}

#-----------------------------------------------------------------------------
# If two intervals overlaps the union is returned
# Input:  <interval> <interval>
# Output: <interval> || undefined
#-----------------------------------------------------------------------------

sub _plus 
{
    my ($i1, $i2, $regular) = @_;
    my ($nMin, $nMax);
    $nMin = $nMax = 0;
    if ($i2->{m_bEmpty}) { return (ref $i1)->new ($i1->{m_nStart}, $i1->{m_nStop}) } 
    if ($i1->{m_bEmpty}) { return (ref $i2)->new ($i2->{m_nStart}, $i2->{m_nStop}) } 

    if ($i1->overlaps ($i2))
    {
	$nMin = $i1->{m_nStart} lt $i2->{m_nStart} ? $i1->{m_nStart} : $i2->{m_nStart};
	$nMax = $i1->{m_nStop} gt $i2->{m_nStop}   ? $i1->{m_nStop}  : $i2->{m_nStop};
    }
    return (ref $i1)->new ($nMin, $nMax);
}

#-----------------------------------------------------------------------------
# If two intervals overlaps the union is returned
# Input:  <interval> <interval>
# Output: <interval> || undefined
#-----------------------------------------------------------------------------

sub _minus 
{
    my ($i1, $i2, $regular) = @_;
    my ($nStart, $nStop, $nLeft, $nRight);

    if ($i2->{m_bEmpty}) { return (ref $i1)->new ($i1->{m_nStart}, $i1->{m_nStop}); } 
    if ($i1->{m_bEmpty}) { return _new_empty Interval; } 

    my ($nOverlap) = $i1->_overlaps ($i2);
    $nStart = $nStop = 0;
    my ($bDefined) = $TRUE; # Used if temporal element should be returned

    if ($nOverlap == $MEETS)
    {
	$nStart = $i1->{m_nStart};
	$nStop  = $i1->{m_nStop};
	$nLeft = $i1->{m_nLeft};
	if ($i2->{m_nLeft} == $CLOSED) { $nRight = $OPEN; }
	else                           { $nRight = $i1->{m_nRight}; }
    }
    elsif ($nOverlap == $LEFT_OVERLAPS)
    {
	$nStart = $i1->{m_nStart};
	$nStop  = $i2->{m_nStart};
	$nLeft  = $i1->{m_nLeft};
	if ($i2->{m_nLeft} == $CLOSED) { $nRight = $OPEN; }
	else                           { $nRight = $CLOSED; }
    }
    elsif ($nOverlap == $RIGHT_OVERLAPS)
    {
	$nStart = $i2->{m_nStop};
	$nStop  = $i1->{m_nStop};
	if ($i2->{m_nRight} == $CLOSED) { $nLeft = $OPEN; }
	else                            { $nLeft = $CLOSED; }
	$nRight = $i1->{m_nRight};
    }
    elsif ($nOverlap == $TOTALLY_OVERLAPS)
    {
	print STDERR "Sorry minus and during overlap not implemented yet\n";
	$bDefined = $FALSE;
    }
    elsif ($nOverlap == $DURING)
    {
	$bDefined = $FALSE;
    }
    elsif ($nOverlap == $EXTENDS)
    {
	$nStart = $i1->{m_nStart};
	$nStop  = $i1->{m_nStop};
	if ($i2->{m_nRight} == $CLOSED) { $nLeft = $OPEN; }
	else                            { $nLeft = $i1->{m_nLeft}; }
	$nRight = $i1->{m_nRight};
    }

    else
    {
	# does not overlap
    }

    if ($bDefined)
    {
	my $int = new Interval ($nStart, $nStop);
	$int->_setBrackets ($nLeft, $nRight);
	return $int;
    }
    else 
    {
	return _new_empty Interval;
    }
}

#-----------------------------------------------------------------------------
# For strinifying an interval
# Input:  <interval>
# Output: string
#-----------------------------------------------------------------------------

sub stringify
{
    my $self = shift;
    return $self->get;
}

#-----------------------------------------------------------------------------
# Finds how intervals overlap in Allen terminology
# Input:  none
# Output: <Allen overlap type> string
#-----------------------------------------------------------------------------

sub _AllenOverlaps
{
    my $self = shift;
    my $other = shift;
    my ($bHowOverlaps) = $FALSE;

    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }

    # before/meets/left overlaps/left covers/covers (note the order is important)
    if ($self->{m_nStart} lt $other->{m_nStart})
    {
	if    ($self->{m_nStop} lt $other->{m_nStart}) { $bHowOverlaps = $ALLEN_BEFORE; }
	elsif ($self->{m_nStop} eq $other->{m_nStart}) { $bHowOverlaps = $ALLEN_MEETS; }       
	elsif ($self->{m_nStop} lt $other->{m_nStop})  { $bHowOverlaps = $ALLEN_LEFT_OVERLAPS; }
	elsif ($self->{m_nStop} eq $other->{m_nStop})  { $bHowOverlaps = $ALLEN_LEFT_COVERS; }	
	elsif ($self->{m_nStop} gt $other->{m_nStop})  { $bHowOverlaps = $ALLEN_COVERS; }
	else                                           {} # do nothing
    }
    # starts/equals/right covers
    elsif ($self->{m_nStart} eq $other->{m_nStart})
    {
	if    ($self->{m_nStop} lt $other->{m_nStop}) { $bHowOverlaps = $ALLEN_STARTS; }
	elsif ($self->{m_nStop} eq $other->{m_nStop}) { $bHowOverlaps = $ALLEN_EQUALS; }
	elsif ($self->{m_nStop} gt $other->{m_nStop}) { $bHowOverlaps = $ALLEN_RIGHT_COVERS; }
	else                                          {} # do nothing
    }
    # extends/after/during/finishes/right overlaps (note the order is important)
    elsif ($self->{m_nStart} gt $other->{m_nStart})
    {
	if    ($self->{m_nStart} eq $other->{m_nStop}) { $bHowOverlaps = $ALLEN_EXTENDS; }
	elsif ($self->{m_nStart} gt $other->{m_nStop}) { $bHowOverlaps = $ALLEN_AFTER; }
	elsif ($self->{m_nStop}  lt $other->{m_nStop}) { $bHowOverlaps = $ALLEN_DURING; }
	elsif ($self->{m_nStop}  eq $other->{m_nStop}) { $bHowOverlaps = $ALLEN_FINISHES; }
	elsif ($self->{m_nStop}  gt $other->{m_nStop}) { $bHowOverlaps = $ALLEN_RIGHT_OVERLAPS; }
	else                                           {} # do nothing
    }  
    return $bHowOverlaps;
}

#-----------------------------------------------------------------------------
# Get how intervals overlap in Allen terminology
# Input:  <interval>
# Output: <Allen overlap type> string || false
#-----------------------------------------------------------------------------

sub AllenHowOverlaps
{ 
    my $self  = shift;
    my $other = shift;
    my ($szOverlap) = ' does not overlap ';
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) 
    { 
	print $self->get,  $szOverlap, $other->get, "\n";
	return;
    }

    my ($bOverlaps) = $self->_AllenOverlaps($other);

    if    ($bOverlaps == $ALLEN_BEFORE)         { $szOverlap = ' before '; }
    elsif ($bOverlaps == $ALLEN_MEETS)          { $szOverlap = ' meets '; }
    elsif ($bOverlaps == $ALLEN_LEFT_OVERLAPS)  { $szOverlap = ' left overlaps '; }
    elsif ($bOverlaps == $ALLEN_LEFT_COVERS)    { $szOverlap = ' left covers '; }
    elsif ($bOverlaps == $ALLEN_COVERS)         { $szOverlap = ' covers '; }
    elsif ($bOverlaps == $ALLEN_STARTS)         { $szOverlap = ' starts '; }
    elsif ($bOverlaps == $ALLEN_EQUALS)         { $szOverlap = ' equals '; }
    elsif ($bOverlaps == $ALLEN_RIGHT_COVERS)   { $szOverlap = ' right covers '; }
    elsif ($bOverlaps == $ALLEN_DURING)         { $szOverlap = ' during '; }
    elsif ($bOverlaps == $ALLEN_FINISHES)       { $szOverlap = ' finishes '; }
    elsif ($bOverlaps == $ALLEN_RIGHT_OVERLAPS) { $szOverlap = ' right overlaps '; }
    elsif ($bOverlaps == $ALLEN_EXTENDS)        { $szOverlap = ' extends '; }
    elsif ($bOverlaps == $ALLEN_AFTER)          { $szOverlap = ' after '; }
    print $self->get,  $szOverlap, $other->get, "\n";
}    

#-----------------------------------------------------------------------------
# Examines if intervals Allen before
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenBefore
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_BEFORE ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen before
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenMeets
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_MEETS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen before
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenLeftOverlaps
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_LEFT_OVERLAPS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen left covers
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenLeftCovers
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_LEFT_COVERS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen covers
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenCovers
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_COVERS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen starts
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenStarts
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_STARTS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen equals
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenEquals
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_EQUALS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen right covers
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenRightCovers
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_RIGHT_COVERS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen during
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenDuring
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_DURING ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen finishes
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenFinishes
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_FINISHES ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen right overlaps
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenRightOverlaps
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_RIGHT_OVERLAPS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen extends
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenExtends
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_EXTENDS ? return $TRUE : return $FALSE;
}

#-----------------------------------------------------------------------------
# Examines if intervals Allen right overlaps
# Input:  <interval>
# Output: boolean
#-----------------------------------------------------------------------------

sub AllenAfter
{
    my $self = shift; my $other = shift;
    if ($self->{m_bEmpty} || $other->{m_bEmpty}) { return $FALSE; }
    $self->_AllenOverlaps ($other) == $ALLEN_AFTER ? return $TRUE : return $FALSE;
}

1;

__END__

##############################################################################
##############################################################################
# POD
##############################################################################
##############################################################################

=head1 NAME

Interval - handling of temporal intervals based on Date::Manip

=head1 SYNOPSIS

    use Interval;

    ### class methods ###
    Interval->setDefaultIntervalType ($OPEN_INT); 
    $int_open = new Interval ("10/10/97", "20/10/97"); 
    print "$int_open\n"        # prints  '(1997-10-10, 1997-10-20)'

    $nDefaultType = Interval->getDefaultIntervalType;

    ### constructor ###
    $i1 = new Interval ("30/10/97", "01/12/98");
    $i2 = new Interval ("20/01/96", "01/11/97", $RIGHT_OPEN_INT);

    use Date::Manip;
    $date1 = &ParseDate ("10/10/97");
    $date2 = &ParseDate ("15/10/97");
    $int = new Interval ($d1, $d2);

    ### Overload operators ###
    $i3 = $i1 + $i2;          # + gives the sum of intervals if the overlap
    print "$i3\n";            # prints '[1997-01-20, 1998-12-01)'

    $i4 = $i1 - $i2;          # - gives difference of intervals of intervals
    print "$i4\n";            # prints '[1997-11-01, 1998-12-01)'
   
    $i5 = $i1 - $i1; 
    print "$i5\n";            # prints '<empty>'

    ### <Allen overlap type> ### 
    $X = new Interval (<parameters>);
    $Y = new Interval (<parameters>);
                              ###  relationship between intervals ###
    $Y->AllenBefore ($X);             YYYYYY XXXXXX

    $Y->AllenMeets ($X);              YYYYYYXXXXXX

    $Y->AllenLeftOverlaps ($X);          XXXXXX
                                      YYYYYY

    $Y->AllenLeftCovers ($X);            XXXXXX
                                      YYYYYYYYY

    $Y->AllenCovers ($X);                XXXXXX
                                      YYYYYYYYYYYY

    $Y->AllenStarts ($X);             XXXXXX
                                      YYY

    $Y->AllenEquals ($X);             XXXXXX
                                      YYYYYY
    
    $Y->AllenRightCovers ($X);        XXXXXX
                                      YYYYYYYYY

    $Y->AllenDuring ($X);             XXXXXX
                                       YYYY

    $Y->AllenFinishes ($X);           XXXXXX
				        YYYY 

    $Y->AllenRightOverlaps ($X);      XXXXXX
                                         YYYYYY

    $Y->AllenExtends ($X);            XXXXXXYYYYYY

    $Y->AllenAfter ($X):              XXXXXX YYYYYY

    ### <overlap type> ###
    $Y->before ($X)         same as  $Y->AllenBefore ($X)
    $Y->meets  ($X)         same as  $Y->AllenMeets ($X)

    $Y->leftOverlaps ($X)   same as  $Y->AllenLeftOverlaps ($X)  or
                                     $Y->AllenStarts ($X)

    $Y->totalOverlaps ($X)  same as  $Y->AllenCovers ($X)        or
                                     $Y->AllenLeftCovers ($X)    or
                                     $Y->AllenRightCovers ($X)   or
                                     $Y->AllenEquals ($X)

    $Y->rightOverlaps ($X)  same as  $Y->AllenFinishes ($X)      or
                                     $Y->AllenRightCovers

    $Y->during ($X)         same as  $Y->AllenDuring ($X)
    $Y->extends ($X)        same as  $Y->AllenExtends ($X)
    $Y->after ($X)          same as  $Y->AllenAfter ($X)

    ### <interval type> ###
    $closed_int = new Interval ("10/10/97", "20/10/97", $CLOSED_INT); 
    print "$closed_int\n";      # prints [1997-10-10, 1997-10-20]

    $left_open_int = new Interval ("10/10/97", "20/10/97", $LEFT_OPEN_INT); 
    print "$left_open_int\n";   # prints (1997-10-10, 1997-10-20]

    $right_open_int = new Interval ("10/10/97", "20/10/97", $RIGHT_OPEN_INT); 
    print "$right_open_int\n";  # prints [1997-10-10, 1997-10-20)

   $open_int = new Interval ("10/10/97", "20/10/97", $OPEN_INT); 
   print "$open_int\n";         # prints (1997-10-10, 1997-10-20)

   ### check and get overlapping interval ###
    $i1 = new Interval ("30/10/97", "01/12/98");
    $i2 = new Interval ("20/01/96", "01/11/97");
    $i3 = new Interval ("01/01/95", "30/04/95");

    if ($i1->overlaps ($i2)) {
        $i4 = $i1->getOverlap($i2);
        print "$i4\n";              # prints [1997-10-30, 1997-11-01)
    }
    if ($i1->overlaps ($i3)){       # tests fails, does not print anything
        $i5 = $i1->getOverlap($i2);
        print "$i5\n";
    }

=head1 DESCRIPTION

    All strings which can be used to create a Date::Manip can be used
    to create an Interval. However, the start date must be larger than
    the stop date.

    The comparison of intervals is based on the 13 ways intervals can
    overlap as defined by J.F. Allen (See litteratur). Further, I have
    included a small number of interval comparison which are handy if
    you are only interested in getting the overlapping interval of two
    intervals.

=head2 Defaults 

    The default input format is non-us date format "10/12/97" is the
    10th of December 1997, not the 12 of October 1997. It can be
    changed by calling Date::Manip::DateInit().

    The default output format is YYYY-MM-DD. Can be changed by calling
    Interval->setDisplayFormat(<string>).

=head1 BUGS

    Tried my best to avoid them send me an email if you are bitten by
    a bug 

=head1 TODO 

    - Cannot take references to dates as input parameters for the
      constructors

    - Cannot subtract intervals which overlap with "during" overlaps,
      this results in two intervals (currently results in an empty interval)

=head1 LITTERATURE

    Allen, J. F., "An Interval-Based Representation of Temporal Knowledge",
    Communication of the ACM, 26(11) pp. 832-843, November 1983.

=head1 AUTHOR

Kristian Torp <F<torp@cs.auc.dk>>

=cut

# eof
