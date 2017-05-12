package Gfsm;

use 5.008004;
use strict;
use warnings;
use Carp;
use AutoLoader;
use Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.0407';

require XSLoader;
XSLoader::load('Gfsm', $VERSION);

# Preloaded methods go here.
require Gfsm::Alphabet;
require Gfsm::Automaton;
require Gfsm::Automaton::Indexed;

# Autoload methods go after =cut, and are processed by the autosplit program.

##======================================================================
## Exports
##======================================================================
our @EXPORT = qw();
our %EXPORT_TAGS = qw();

##======================================================================
## Constants
##======================================================================

##------------------------------------------------------------
## Constants: arc labels
our $epsilon  = epsilon();
our $epsilon1 = epsilon1();
our $epsilon2 = epsilon2();
our $noLabel  = noLabel();
$EXPORT_TAGS{labels} = [qw(epsilon $epsilon $epsilon1 $epsilon2 noLabel $noLabel)];

##------------------------------------------------------------
## Constants: State IDs
our $noState = noState();
$EXPORT_TAGS{states} = [qw(noState $noState)];

##--------------------------------------------------------------
## Constants: Semiring types
our $SRTUnknown  = SRTUnknown();
our $SRTBoolean  = SRTBoolean();
our $SRTLog      = SRTLog();
our $SRTReal     = SRTReal();
our $SRTTrivial  = SRTTrivial();
our $SRTTropical = SRTTropical();
our $SRTPLog     = SRTPLog();
our $SRTUser     = SRTUser();
$EXPORT_TAGS{srtypes} = [
			 qw($SRTUnknown   SRTUnknown),
			 qw($SRTBoolean   SRTBoolean),
			 qw($SRTLog       SRTLog),
			 qw($SRTReal      SRTReal),
			 qw($SRTTrivial   SRTTrivial),
			 qw($SRTTropical  SRTTropical),
			 qw($SRTPLog      SRTPLog),
			 qw($SRTUser      SRTUser),
			];

##--------------------------------------------------------------
## Constants: Automaton arc-sort modes
our $ASMNone   = ASMNone();
our $ASMLower  = ASMLower();
our $ASMUpper  = ASMUpper();
our $ASMWeight = ASMWeight();

##-- new-style: pseudo
our $ACNone    = ACNone();
our $ACReverse = ACReverse();
our $ACAll     = ACAll();

##-- new-style: forward
our $ACLower   = ACLower();
our $ACUpper   = ACUpper();
our $ACWeight  = ACWeight();
our $ACSource  = ACSource();
our $ACTarget  = ACTarget();
our $ACUser    = ACUser();

##-- new-style: reverse
our $ACLowerR  = ACLowerR();
our $ACUpperR  = ACUpperR();
our $ACWeightR = ACWeightR();
our $ACSourceR = ACSourceR();
our $ACTargetR = ACTargetR();
our $ACUserR   = ACUserR();

##-- new-style: sizes
our $ACShift   = ACShift();
our $ACMaxN    = ACMaxN();

$EXPORT_TAGS{sortmodes} = [
			   ##-- old-style
			   qw($ASMNone   ASMNone),
			   qw($ASMLower  ASMLower),
			   qw($ASMUpper  ASMUpper),
			   qw($ASMWeight ASMWeight),
			   ##
			   ##-- new-style: pseudo
			   qw($ACNone    ACNone()),
			   qw($ACReverse ACReverse()),
			   qw($ACAll     ACAll()),
			   ##
			   ##-- new-style: forward
			   qw($ACLower   ACLower()),
			   qw($ACUpper   ACUpper()),
			   qw($ACWeight  ACWeight()),
			   qw($ACSource  ACSource()),
			   qw($ACTarget  ACTarget()),
			   qw($ACUser    ACUser()),
			   ##
			   ##-- new-style: reverse
			   qw($ACLowerR  ACLowerR()),
			   qw($ACUpperR  ACUpperR()),
			   qw($ACWeightR ACWeightR()),
			   qw($ACSourceR ACSourceR()),
			   qw($ACTargetR ACTargetR()),
			   qw($ACUserR   ACUserR()),
			   ##
			   ##-- new-style: sizes
			   qw($ACShift ACShift()),
			   qw($ACMaxN  ACMaxN()),
			  ];

##--------------------------------------------------------------
## Constants: Sort Modes (new-style): functions

## $str = Gfsm::acmask_to_chars($acmask)
sub acmask_to_chars {
  return join('', map { acmask_nth_char($_[0],$_) } (0..($ACMaxN-1)));
}

## $mask = Gfsm::acmask_from_args($cmp0, ...)
sub acmask_from_args {
  my $m = 0;
  my ($i);
  foreach $i (0..$#_) {
    $m |= acmask_new($_[$i], $i);
  }
  return $m;
}


##--------------------------------------------------------------
## Constants: Label sides
our $LSBoth  = LSBoth();
our $LSLower = LSLower();
our $LSUpper = LSUpper();

$EXPORT_TAGS{labelsides} = [
			    qw($LSBoth  LSBoth),
			    qw($LSLower LSLower),
			    qw($LSUpper LSUpper),
			   ];

##--------------------------------------------------------------
## Constants: lookup limits
our $LookupMaxResultStates = LookupMaxResultStates();
$EXPORT_TAGS{limits} = [
			qw($LookupMaxResultStates LookupMaxResultStates),
		       ];


##======================================================================
## Utilities: arcpaths
##======================================================================

## $fmt = $Gfsm::arc_packas
our $arc_packas = 'LLSSf';

## $nbytes = $Gfsm::arc_size
our $arc_size = length(pack($arc_packas,0,0,0,0,0));

## ($src,$dst,$lo,$hi,$w) = Gfsm::unpack_arc($arc_packed)
sub unpack_arc {
  return unpack($arc_packas,$_[0]);
}

## $arc_packed = Gfsm::pack_arc($src,$dst,$lo,$hi,$w)
sub pack_arc {
  return pack($arc_packas,@_);
}

## @arcs_packed = unpack_arcpath($arcpath_packed)
sub unpack_arcpath {
  return map {[unpack($arc_packas,$_)]} unpack("(a${arc_size})*", $_[0]);
}

## @arcs_packed = pack_arcpath([$src,$dst,$lo,$hi,$w],...)
sub pack_arcpath {
  return pack("($arc_packas)*", map {ref($_) ? @$_: $_} @_);
}

$EXPORT_TAGS{pack} = [
		      qw($arc_packas $arc_size),
		      qw(unpack_arc pack_arc),
		      qw(unpack_arcpath pack_arcpath),
		     ];

##======================================================================
## Exports: finish
##======================================================================
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{constants} = \@EXPORT_OK;


1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=pod

=head1 NAME

Gfsm - Perl interface to the libgfsm finite-state library

=head1 SYNOPSIS

  use Gfsm;
 
  ##... stuff happens

=head1 DESCRIPTION

The Gfsm module provides an object-oriented interface to the libgfsm library
for finite-state machine operations.

=head1 SEE ALSO

Gfsm::constants(3perl),
Gfsm::Alphabet(3perl),
Gfsm::Automaton(3perl),
Gfsm::Automaton::Indexed(3perl),
Gfsm::Semiring(3perl),
perl(1),
gfsmutils(1),
fsm(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
