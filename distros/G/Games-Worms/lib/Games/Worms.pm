#!/usr/bin/perl
package Games::Worms;

require 5;
use strict;
require Exporter;
use vars qw(%Options $VERSION $Debug @ISA @EXPORT @EXPORT_OK);
use Getopt::Std;
use Games::Worms::Board; # for _try_use

$VERSION = "0.65";
$Debug = 0;
@ISA = qw(Exporter);
@EXPORT = qw(worms);
@EXPORT_OK = qw(worms);
#--------------------------------------------------------------------------

=head1 NAME

Games::Worms -- alife simulator for Conway/Patterson/Beeler worms, etc.

=head1 SYNOPSIS

  perl -MGames::Worms -e worms -- -tPS 
  perl -MGames::Worms -e worms -- -tPS / / / / > foo1.ps
  perl -MGames::Worms -e worms -- -tTk
  perl -MGames::Worms -e worms -- -tTek4010 / / / Games::Worms::Random2

=head1 BUGS, WARNINGS, AND CAVEATS

This is an alpha release.  The documentation is incomplete, and the
interface is not yet finalized.

Occasionally I've seen Perl 5.004_02 for MSWin segfault at global
destruction time.

The Tk part, I've only tested under pTk.  This's my first hack at Tk,
so lets hope all the code I wrote is portable.  Suggestions welcome!

I've tested the PostScript part only under GhostScript.

I've tested the Tek interface under MSKermit.  I hear xterm has a Tek
emulator in it -- I'd be interested to hear if it works well with
Worms's Tek interface.

=head1 DESCRIPTION

[elaborate]

Worms is an implementation of an artificial-life game.  It can output
via Perl-Tk, Tek4010, and PostScript.  It is a game not in the sense
of checkers, but in the sense of Conway's Life.

In a Worms universe, worms crawl around an isometric grid of
triangles, leaving trails behind them, and turning in accordance to
simple rules that are based upon which way they can move at a each
junction.  From the simple rules emerges surprising complexity.

=head1 TO DO

Allow board-size specifications on the command line.

Better docs.

Maybe a GIF output mode?

More interactive interface in pTk mode?

Currently the interface is pretty much: specify things on the command
line, then sit back and watch the worms go, until they all die.
Hopefully I (or someone ambitious who knows Tk better than I do) may
add more interactivity to the interface.

=head1 INVOCATION

Start it up by making a Perl program called C<worms>, with the content:

  !/usr/bin/perl
  use Games::Worms;
  worms;

Then start up with the C<-t> switch specifying which interface to use:

  worms -tTk
    ...for Tk mode
  worms -tPS
    ...for PostScript mode
  worms -tTek4010
    ...for Tektronics mode

Command line arguments thereafter are interpreted as the names of
classes worms should come from.  (Currently, three are provided in
this distribution: L<Games::Worms::Random>, L<Games::Worms::Random2>,
and L<Games::Worms::Beeler>.)  If no arguments are provided, Worms
uses two Random2s and two Beelers.

For each name you specify, if it contains a slash, the rest of that
name is passed to the worm as an expression of its rules.

Example specifications:

  Games::Worms::Beeler
  Games::Worms::Random
  Games::Worms::Random2
  Games::Worms::Beeler/1a2d3caaa4b
  Games::Worms::Beeler/1A2B3ACAC4B
  Games::Worms::Beeler/1B2B3AAAB4A

(A Beeler worm with no rules specified makes up a random rule set when
it starts.  A Random worm obeys no rules.  A Random2 worm is random
but consistent.)

If you specify a name starting with '/', it's interpreted as short for
'Games::Worms::Beeler/'.  In other words,

  /1a2d3caaa4b   equals   Games::Worms::Beeler/1a2d3caaa4b
  /1A2B3ACAC4B   equals   Games::Worms::Beeler/1A2B3ACAC4B
  /1B2B3AAAB4A   equals   Games::Worms::Beeler/1B2B3AAAB4A

See the I<Scientific American> article on Beeler worms for the meaning
of these Beeler worm rule specifications.  I don't have the citation
for the first run of the article, but it's reproduced with nice
addenda in the book cited below.

If you don't want to bother making that little script called "worms",
you can just as well invoke Worms via:

  perl -MGames::Worms -e worms -- -tTk

  perl -MGames::Worms -e worms -- -tPS

  perl -MGames::Worms -e worms -- -tTek4010

  perl -MGames::Worms -e worms -- -tTek4010
    Games::Worms::Random  Games::Worms::Random2
    /1a2d3caaa4b /1A2B3ACAC4B /1B2B3AAAB4A

=head1 CONCEPTS

[to be written]

=head1 REFERENCES

"Worm Paths", chapter 17 in: Martin Gardner, 1986, I<Knotted Doughnuts
and Other Mathematical Entertainments>, W. H. Freeman and Company.

"Patterson's Worm", M. Beeler, MIT AI Memo #290.  (early 1970s?)

"Worms?" [sic], David Maynard, Electronic Arts, 1983.  (A game for the
Atari 400 (or 800?), the Commodore 64, and maybe other machines.
Games::Worms isn't based on EOA "Worms?", but "Worms?" is the best
known implementation of Beeler worms.  It uses them as the basis for
a very interesting and abstract interactive game.)

=head1 GUTS

Read the source.  It's OOPilicious!

=head1 COPYRIGHT

Copyright 1999-2006, Sean M. Burke C<sburke@netadventure.net>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Current maintainer Avi Finkel C<avi@finkel.org>; Original author Sean M. Burke C<sburke@cpan.org>

=cut

#--------------------------------------------------------------------------

%Options = ();

sub worms {
  getopts('t:vh', \%Options);
  if($Options{'v'}) {
    print "Worms v$VERSION\n";
    exit;
  }
  if($Options{'h'}) {
    print <<"EOHELP"; exit;
Worms v$VERSION
Switches:
  -t[Interface] -- set the interface
     examples:  -tTk  -tPS  -tTek4010
  -h            -- print this help message
  -v            -- print the version number
EOHELP

  }

  die "What interface?" unless $Options{'t'} =~ /\w/;
  my $interface = "Games::Worms:\:$Options{'t'}" ;
  die "Can't use interface $interface: $Games::Worms::Board::Use_Error\n"
    unless &Games::Worms::Board::_try_use($interface);

  # add further %Options logic here.

  # Now do it.
  die "Can't start up interface $interface!\n" unless $interface->can('main');
  return $interface->main;
}
#--------------------------------------------------------------------------
1;

__END__
