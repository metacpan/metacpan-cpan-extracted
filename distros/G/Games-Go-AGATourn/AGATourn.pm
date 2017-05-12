# $Id: AGATourn.pm,v 1.35 2005/01/24 04:32:17 reid Exp $

#   AGATourn
#
#   Copyright (C) 1999, 2004, 2005 Reid Augustin reid@netchip.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#
#   This library is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself, either Perl version 5.8.5 or, at your
#   option, any later version of Perl 5 you may have available.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#   or FITNESS FOR A PARTICULAR PURPOSE.
#

=head1 NAME

AGATourn - Perl extensions to ease the pain of using AGA tournament data files.

=head1 SYNOPSIS

use Games::Go::AGATourn;

my $agaTourn = B<Games::Go::AGATourn-E<gt>new> (options);

=head1 DESCRIPTION

An AGATourn object represents a round or several rounds of an American Go
Association tournament.  There are methods for parsing several type of AGA
file format:

=over 4

=item tdlist

The entire list of AGA members including playing strength, club affiliation,
and some other stuff.

=item register.tde

The starting point for a tournament.  All players in a tournament must be
entered in the register.tde file.

=item round results: 1.tde, 2.tde, etc.

Game results for each round of the tournament.

=back

A note on IDs: in general, hashes in an AGATourn object are keyed by the AGA
ID.  An AGA ID consists of a three letter country specifier (like USA or TMP
for temporary IDs) concatenated to an integer.  Here we specify the three
letter country specifier as the 'country' and the integer part as the
'agaNum'.  The country concatenated with the agaNum is the ID.  My ID for
example is USA2122.  IDs should be normalized (capitalize the country part and
remove preceding 0s from the agaNum part) with the B<NormalizeID> method
(below).

Note also that some programs may accept limited integers in the agaNum part of
the ID.  Accelerat, for example, seems to accept only up to 32K (someone used
a signed short somewhere?)

=cut

use strict;
require 5.001;

package Games::Go::AGATourn;
use Carp;
use IO::File;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use PackageName ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

BEGIN {
    our $VERSION = sprintf "%d.%03d", '$Revision: 1.35 $' =~ /(\d+)/g;
}

######################################################
#
#       Class Variables
#
#####################################################

use constant NOTARANK => -99.9;           # illegal rank or rating

######################################################
#
#       Public methods
#
#####################################################

=head1 METHODS

=over 4

=item my $agaTourn = B<Games::Go::AGATourn-E<gt>new> (options)

A B<new> AGATourn by default reads the B<register_tde> file to get the name,
rank, and AGA numbers for all the players in the tournament.  It then reads
all available game results (B<Round> files: 1.tde, 2.tde, etc.) and the game
data is incorporated into the AGATourn object.

=head2 Options:

=over 4

=item B<Round>

Round file number to read.  If B<Round> is 0, no round files are read.  If
B<Round> is 1 or greater, only the one round file will be read.  If B<round>
is undef (or not specified), all existing round files are read.  Round files
should be named I<1.tde>, I<2.tde>, etc.

Default: undef

=item B<register_tde>

Name of register.tde file.  Use undef to prevent reading the register.tde
file.  Changing the name of this file is probably a bad idea.

Default 'register.tde' (in the current directory)

=item B<nameLength>

Starting length of name field.  While reading the register file (see
B<ReadRegisterFile> below), B<nameLength> grows to reflect the longest name
seen so far (see B<NameLength> method below).

Default: 0

=item B<defaultCountry>

Default three-letter country name.

The tdlist file does not include country information in the ID, so the
B<ParseTdListLine> method returns country => B<defaultCountry>.

Default: 'USA'

=back

=cut

sub new {
    my ($proto, %args) = @_;

    my $self = {};
    bless($self, ref($proto) || $proto);
    $self->{defaultCountry} = 'USA';
    $self->Clear;
    # transfer user args
    foreach (keys(%args)) {
        $self->{$_} = $args{$_};
    }
    if (defined($self->{register_tde})) {
        return(undef) unless($self->ReadRegisterFile($self->{register_tde}));
    }
    if (defined($self->{register_tde})) {
        if (defined($self->{Round})) {
            if ($self->{Round} > 0) {
                $self->ReadRoundFile("$self->{Round}.tde");
            }
        } else {
            my $round = 1;
            while (-f "$round.tde") {
                $self->{Round} = $round;
                $self->ReadRoundFile("$self->{Round}.tde");
                $round++;
            }
        }
    }
    return($self);
}

=item $agaTourn-E<gt>B<Clear>

Clears AGATourn database.

=cut

sub Clear {
    my ($self) = @_;

    # set defaults
    $self->{Round} = undef;
    $self->{register_tde} = "register.tde";     # default
    $self->{Directive}{ROUNDS}[0] = 1;  # I hope there's at least one!
    $self->{Directive}{TOURNEY}[0] = "Unknown tournament";
    $self->{nameLength} = 0;
    $self->{Name} = {};                 # empty hash
    $self->{Rating} = {};
    $self->{Rank} = {};
    $self->{Comment} = {};
    $self->{Wins} = {};
    $self->{Losses} = {};
    $self->{NoResults} = {};
    $self->{Played} = {};
    $self->{gameAllList} = [];          # empty array
    $self->{error} = 0;
}

=item my $hash = $agaTourn-E<gt>B<ParseTdListLine> ($line)

Parses a single line from the TDLIST file (the latest TDLIST file
should be downloaded from the AGA at http://usgo.org shortly before
the tournament, and either the tab-delimited tdlista or the
space-delimited versions are accepted).  The return value is a
reference to a hash of the following values:
    agaNum      => the number part if the ID
    country     => the country part of the ID (always the default
                        country)
    name        => complains if there is no a comma
    memType     => membership type or '' if none
    agaRating   => rating in decimal form, or '' if none
    agaRank     => undef unless rating is a D/K style rank
    expire      => date membership expires or '' if none
    club        => club affiliation or '' if none
    state       => state or '' if none

If the line is not parsable, prints a warning and returns undef.

=cut

#   sadly, we need to deal with two formats
#   old tdlist input looks like this:
# name                         AGA# MmbrTyp Rank expires    Club State
#Abe, Shozo                    2443 L            8603            NJ
#Abe, Y.                       2043              8312            GA
#Abell, John                   3605         -1.4 9105       MHGA CO
#Abrahms, Judy                 1253 L            8012       MGA  MA
#Abrams, Michael               6779 L      -27.4 9411       MIAM FL
#Abramson, Allan                101          3.5 9504       NOVA VA
# the new format is like this:
#Abe, Shozo                    2443 Limit        03/28/1986      NJ
#Abe, Y.                       2043 Full         12/28/1983      GA
#Abell, John                   3605 Full    -1.4 05/28/1991 MHGA CO
#Abrahms, Judy                 1253 Limit        12/28/1980  MGA MA
#
# There's also a tab-delimited version

sub ParseTdListLine {
    my ($self, $string) = @_;

    $string =~ s/[\n\r]*$/\t/s;         # remove crlf, and tack on an extra tab
    my @fields = $string =~ m/(.*?)\t/g;  # is it the tab-delimited version?
    if (@fields == 9) {
        return {
            name       => $fields[0],   # return ref to hash
            agaNum     => $fields[1],
            memType    => $fields[2],
            agaRating  => $fields[3],
            expire     => $fields[4],
            club       => $fields[5],
            state      => $fields[6],
            sigma      => $fields[7],
            ratingDate => $fields[8],
            country    => $self->{defaultCountry},
            };
    }
    # else parse a space-delimited version:
    my ($name, $agaNum, $agaRank, $misc);
    my ($agaRating, $memType, $club, $state, $expire) = (-99, '', '', '', '');

    unless($string =~ m/^\s*(.*?)\s*(\d+) (.*)/) { # break into manageble groups
        carp("Error: can't extract AGA number from \"$string\"\n");
        return(undef);
    }
    $name = $1;                         # part before is name
    $agaNum = $2;                       # middle part is the AGA number
    $misc = $3;                         # part after match
    if ($misc =~ m/([\w ]{6}?) ([-\d\. ]{5}) ([\d\/ ]{10}) ([\w ]{4}) (.*?)\s*$/) {
        # parse by character positions (blanks lined up in the right places)
        $memType = _ws_clean($1);
        $agaRating = _ws_clean($2);
        $expire = _ws_clean($3);
        $club = _ws_clean($4);
        $state = _ws_clean($5);
        if ($agaRating =~ m/(\d+)([dk])/i) {
            $agaRank = uc($agaRating);
            $agaRating = $1 + 0.5;
            $agaRating = -$agaRating if (uc($2) eq 'K');
        }
    } else {    # try to parse free-form style
        if ($misc =~ s/^\s*([^\s\d-]+) //) {      # membership type, if any
            $memType = $1;
        } elsif (not $misc =~ s/^       //) {
            carp("Uh oh, no membership type space in: '$misc'");
        }
        if ($misc =~ s/^\s*(-?\d+\.\d) //) {      # find rank, if any
            $agaRating = $1;
        } elsif ($misc =~ s/^\s*(\d+)([dkDK]) //) { # 4D or 15k type rank
            $agaRank = uc("$1$2");
            $agaRating = $1 + 0.5;
            $agaRating = -$agaRating if (uc($2) eq 'K');
        } elsif ($misc =~ s/^\s*(-?\d\d?) //) {   # one or two digit number, no decimal point?
            $agaRating = $1;                        # it's another way of indicating rank
        } elsif (not $misc =~ s/^      //) {
            carp("Uh oh, no rating space in: '$misc'");
        }
        if ($misc =~ s/^\s*([\d\/]+) //) {    # expiration date, if any
            $expire = $1;
        } elsif (not $misc =~ s/           //) {
            carp("Uh oh, no expire space in: '$misc'");
        }
        unless(defined($expire) or defined($memType)) {
            carp "Uh oh";
        }
        if ($misc =~ s/^(\w+)\s*//) {       # club
            $club = $1;
            $club =~ s/\W//g;               # remove all non-word chars
        } elsif (not $misc =~ s/     //) {
            carp("Uh oh, no expire space in: '$misc'");
        }
        if ($misc =~ s/^\s*(.*?)\s*$//) {    # state
            $state = $1;
        }
        if ($misc ne '') {
            carp("Error: \"$misc\" was left over after parsing \"$string\"\n",
            "name=$name, id=$agaNum, mem=$memType, rating=$agaRating, ",
            "expire=$expire, club=$club, state=$state\n");
        }
    }
    return {
        agaNum    => $agaNum,       # return ref to hash
        country   => $self->{defaultCountry},
        name      => $name,
        memType   => $memType,
        agaRating => $agaRating,
        agaRank   => $agaRank,
        expire    => $expire,
        club      => $club,
        state     => $state,
        };
}

sub _ws_clean {
    my $str = shift @_;
    $str =~ m/^\s*(.*?)\s*$/;
    return $1;
}

=item my $result = $agaTourn-E<gt>B<ReadRegisterFile> ($fileName)

Reads a register.tde file and calls B<AddRegisterLine> on each line of the file.

Returns 0 if $fileName couldn't be opened for reading, 1 otherwise.

=cut

sub ReadRegisterFile {
    my ($self, $fName) = @_;

    $self->{fileName} = $fName;         # set global name
    my $inFP = new IO::File("<$fName");
    unless ($inFP) {
        carp("Error: can't open $fName for reading\n"),
        $self->{error} = 1,
        return(0);
    }
    while(my $line = <$inFP>) {
        $self->AddRegisterLine($line);
    }
    $inFP->close();
    return(1);
}

=item $agaTourn-E<gt>B<AddRegisterLine> ($line)

Calls B<ParseRegisterLine> on $line.  Information extracted about players and
directives is added to the $agaTourn object.  Comments and blank lines are
ignored.

=cut

sub AddRegisterLine {
    my ($self, $line) = @_;

    my $fileMsg = (ref ($self) and exists ($self->{fileName})) ?
            " at line $. in $self->{fileName} " :
            '';
    my $h = $self->ParseRegisterLine($line);
    return unless(defined($h));
    if (exists($h->{directive})) {
        foreach (qw(HANDICAPS ROUNDS RULES TOURNEY)) {  # non-array directives
            if ($h->{directive} eq $_) {
                $self->{Directive}{$h->{directive}} = [$h->{value}]; # single value
                return;
            }
        }
        push(@{$self->{Directive}{$h->{directive}}}, $h->{value});
        return;
    }
    return unless(exists($h->{agaNum}));        # probably a comment
    my $id = "$h->{country}$h->{agaNum}";
    if (defined($self->{Name}{$id})) {
        carp("Error: Player ID $id is duplicated$fileMsg\n");
        $self->{error} = 1;
    }
    $self->{Name}{$id} = $h->{name};
    $self->{Rating}{$id} = $h->{agaRating};
    $self->{Rank}{$id} = $h->{agaRank};
    $self->{Comment}{$id} = $h->{comment};
    $self->{Club}{$id} = $h->{club};
    $self->{Flags}{$id} = $h->{flags};
    $self->{Played}{$id} = [] unless exists($self->{Played}{$id});
    foreach (qw(Wins Losses NoResults)) {
        $self->{$_}{$id} = 0 unless exists($self->{$_}{$id});
    }
    my $len = length($h->{name});
    $self->{nameLength} = $len if ($len > $self->{nameLength});
}

=item my $hash = $agaTourn-E<gt>B<ParseRegisterLine> ($line)

Parses a single line from the register.tde file (name lines).  Here are some
examples lines from register.tde file:

    # this line is a comment.  the following line is a directive:
    ## HANDICAPS MAX
    # the following line is a name line:
    USA02122 Augustin, Reid    5.0 CLUB=PALO    # 12/31/2004 CA

The return value is a reference to a hash of the following values:
    agaNum     => just the number part of the ID
    country    => just the country part of the ID (default ='USA')
    name       => complains if name doesn't contain a comma
    agaRating  => rating for the player
    agaRank    => undef if line contains a rating and not a rank
    club       => if there is a club association, '' if not
    flags      => anything left over (excluding comment)
    comment    => everything after the #, '' if none

If the line is a directive, the return hash reference contains only:
    directive  => the directive name
    value      => the directive value ('' if none)

If the line is a comment, leading and trailing whitespace is removed and the
hash contains only:
    comment    => comment contents (may be '')

If the line is empty, returns undef.

If the line is not parsable, prints a warning and returns undef.

=cut

sub ParseRegisterLine {
    my ($self, $line) = @_;

    $line =~ s/\s*$//s;                 # delete trailing spaces
    return undef if ($line eq '');      # nothing left? return undef

    if ($line =~ s/^\s*##\s*//) {
        $line =~ m/(\S+)\s*(.*?)\s*$/;
        return {
            directive => $1,
            value     => $2
        };
    }
    my $comment = '';
    if ($line =~ s/\s*#\s*(.*?)\s*$//) {
        $comment = $1;
    }
    if ($line eq '') {
        return {
            comment => $comment,
        };
    }

    my $fileMsg = (ref ($self) and exists ($self->{fileName})) ?
            " at line $. in $self->{fileName} " :
            '';
    my $club = '';
    if ($line =~ s/\s*CLUB=(\S*)\s*//) {
        $club = $1;
        $club =~ s/\W//g;               # remove all non-word chars
    }
    my ($agaRating, $agaRank);
    if($line =~ s/^\s*(\S*)\s+(.*?)\s+(\d+[dDkK])\s*//) {          # look for dan or kyu rank
        $agaRank = $3;
        $agaRating = $self->RankToRating($3);
    } elsif($line =~ s/^\s*(\S*)\s+(.*?)\s+(-*\d+\.\d+)\s*//) {    # look for 5.4 or -13.6 type of rank
        $agaRating = $3;           # ok as is
    } elsif($line =~ s/^\s*(\S*)\s+(.*?)\s+(-*\d+)\s*//) {         # look for 5 or -13 type of rank
        carp("Warning: rank is non-decimalized:\n$line\n");
        $agaRating = "$3.0";
    } else {
        carp("Error: Can't parse name$fileMsg:\n$line\n");
        $self->{error} = 1;
        return;
    }

    my $name = $2;
    my $agaNum = $self->NormalizeID($1);
    my $country = $self->{defaultCountry};
    if ($agaNum =~ s/^(\D+)//) {
        $country = uc($1);
    }
    unless ($name =~ m/,/) {
        carp("Warning: no comma in name \"$name\"$fileMsg\n");
    }
    return {    # return ref to hash of:
        agaNum    => $agaNum,
        name      => $name,
        agaRating => $agaRating,
        agaRank   => $agaRank,
        club      => $club,
        country   => $country,
        flags     => $line,     # whatever's left over
        comment   => $comment,
        };
}

=item my $result = $agaTourn-E<gt>B<ReadRoundFile> ($fileName)

Reads a round file and calls B<AddRoundLine> on each line of the file.
Complains if filename is not in the form I<1.tde>, I<2.tde>, etc.

Sets the current B<Round> number to the digit part of fileName.

Returns 0 if fileName couldn't be opened for reading, 1 otherwise.

=cut

sub ReadRoundFile {
    my ($self, $fName) = @_;

    if ($fName =~ m/^\d+$/) {   # no TDE extension?
        $fName .= '.tde';
    }
    $self->{fileName} = $fName;         # set global name
    if ($fName =~ m/(\d+).tde/) {
        $self->{Round} = $1;
    } else {
        carp "Round filename not in normal ('1.tde', '2.tde', etc) format\n";
    }
    my $inFP = new IO::File("<$fName");
    unless ($inFP) {
        carp("Error: can't open $fName for reading\n");
        $self->{error} = 1;
        return(0);
    }
    while (my $line = <$inFP>) {
        $self->AddRoundLine($line);
    }
    $inFP->close();
    return(1);
}

=item $agaTourn-E<gt>B<AddRoundLine> ($line)

Parses $line (by calling B<ParseRoundLine>) and adds the information to the
B<GamesList>.  Games without a result ('?') increment both players' NoResults
list scores, and games with a result ('b' or 'w') increment the two players'
Wins and Losses scores.  If the game result is 'b' or 'w', the black player is
added to the white player's B<Played> list and vica-versa.  Note that
B<Played> is not affected by games that are not complete.

Complains if either player, or both, are not registered via
B<AddRegisterLine>.

=cut

sub AddRoundLine {
    my ($self, $line) = @_;

    my $g = $self->ParseRoundLine($line);       # get game result
    return unless(defined($g) and exists($g->{result}));
    my $wId = $self->NormalizeID("$g->{wcountry}$g->{wagaNum}");
    my $bId = $self->NormalizeID("$g->{bcountry}$g->{bagaNum}");
    carp("Game $wId.vs.$bId, $wId is not registered\n") unless (exists($self->{Rating}{$wId}));
    carp("Game $wId.vs.$bId, $bId is not registered\n") unless (exists($self->{Rating}{$bId}));
    foreach (qw(Wins Losses NoResults)) {
        $self->{$_}{$wId} = 0 unless exists($self->{$_}{$wId});
        $self->{$_}{$bId} = 0 unless exists($self->{$_}{$bId});
    }
    if ($g->{result} eq 'w') {
        $self->{Wins}{$wId}++;
        $self->{Losses}{$bId}++;
        push(@{$self->{Played}{$bId}}, $wId);
        push(@{$self->{Played}{$wId}}, $bId);
    } elsif ($g->{result} eq 'b') {
        $self->{Wins}{$bId}++;
        $self->{Losses}{$wId}++;
        push(@{$self->{Played}{$bId}}, $wId);
        push(@{$self->{Played}{$wId}}, $bId);
    } elsif ($g->{result} eq '?') {
        $self->{NoResults}{$bId}++;
        $self->{NoResults}{$wId}++;
    } else {
        carp("Unknown game result:$g->{result}");       # probably can't happen
    }
    my $game = "$wId,$bId,$g->{result},$g->{handi},$g->{komi},$self->{Round}";
    push(@{$self->{gameAllList}}, $game);
    push(@{$self->{gameIDList}{$wId}}, $game);
    push(@{$self->{gameIDList}{$bId}}, $game);
}

=item my $hash = $agaTourn-E<gt>B<ParseRoundLine> ($line)

Parses a single line from a results file (I<1.tde>, I<2.tde>, etc).  Here's an
example line from a results file:

    TMP18  TMP10   b     0     7   # Lee, Ken -28.5 : Yang, John -28.5
  # wID    bID   result handi komi   comment

The return value is a reference to a hash of the following values:
    wcountry    => combine with wagaNum to get complete ID
    wagaNum     => the number part of white's AGA number
    bcountry    => combine with bagaNum to get complete ID
    bagaNum     => the number part of black's AGA number
    result      => winner: 'b', 'w' or '?'
    handi       => handicap game was played with
    komi        => komi game was played with
    comment     => everything after the #

If $line is empty, returns undef.

If $line is a comment, returns only:
    comment     => everything after the #

If the line is not parsable, prints a warning and returns undef.

=cut

sub ParseRoundLine {
    my ($self, $line) = @_;

    $line =~ s/\s*$//s;                 # delete trailing spaces
    return undef if ($line eq '');      # nothing left? return undef

    if ($line =~ s/^\s*##\s*//) {
        $line =~ m/(\S+)\s*(.*?)\s*/;
        return {
            directive => $1,
            value     => $2
        };
    }
    my $comment = '';
    if ($line =~ s/\s*#\s*(.*?)\s*$//) {
        $comment = $1;
    }
    if ($line eq '') {
        return {
            comment => $comment,
        };
    }

    if ($line =~ m/^\s*(\w+)(\d+)\s+(\w+)(\d+)\s+([bwBW\?])\s+(\d+)\s+(-?\d+)$/) {
        return {
            wcountry  => uc($1),
            wagaNum   => $2,
            bcountry  => uc($3),
            bagaNum   => $4,
            result    => lc($5),
            handi     => $6,
            komi      => $7,
            comment   => $comment,
        };
    }
    my $fileMsg = (ref ($self) and exists ($self->{fileName})) ?
            " at line $. in $self->{fileName} " :
            '';
    carp("Can't parse round line $.$fileMsg:\n$line\n");
    $self->{error} = 1;
    return undef;
}

=item my $tourney = $agaTourn-E<gt>B<Tourney>

Returns the name of the tournament from a ##TOURNEY directive added via
B<AddRegisterLine>, or 'Unknown Tournament' if no TOURNEY directive has been
added.

=cut

sub Tourney {
    my ($self) = @_;
    return ($self->{Directive}{TOURNEY}[0]);    # last TOURNEY directive
}

=item my $directive = $agaTourn-E<gt>B<Directive> ($directive)

Returns a list (or a reference to the list in scalar context) of directives
added via calls to B<AddRegisterLine>.  Directive names are always turned into
upper case (but the case of the directive value, if any, is preserved).

Since some directives (like BAND) may occur several times, all directives are
stored as a list in the order added (either from B<ReadRegisterFile> or
B<AddRegisterLine>).  Certain directives (HANDICAPS ROUNDS RULES TOURNEY) keep
only the last directive added.

Some directives have no associated value.

B<Directive> returns undef if $directive has not been added, or a list
(possibly empty) if $directive has been added.

If called with no arguments (or $directive is undef), returns a reference to a
hash of all the current directives.

=cut

sub Directive {
    my ($self, $directive) = @_;

    if (defined($directive)) {
        $directive = uc($directive);                # force to upper case
        if (exists($self->{Directive}{$directive})) {
            return wantarray ? @{$self->{Directive}{$directive}} : $self->{Directive}{$directive};
        }
        return(undef);
    }
    return($self->{Directive});         # the whole shebang...
}

=item my $rounds = $agaTourn-E<gt>B<Rounds>

Returns the total number of rounds the $agaTourn object knows about.  If there
has been a ##ROUNDS directive in a call to B<AddRegisterLine> file, this will
return that number.  If not, it will return the number part of the last
I<round_number>.tde file read or undef.

=cut

sub Rounds {
    my ($self) = @_;

    return $self->{Directive}{ROUNDS}[0]        # fetch ROUNDS directive
        if(defined($self->{Directive}{ROUNDS}[0]));
    return($self->{Round});
}

=item my $round = $agaTourn-E<gt>B<Round>

Returns the number of the current round (based on the last I<round_number>.tde
file read).

=cut

sub Round {
    my ($self) = @_;
    return($self->{Round});
}

=item my $name = $agaTourn-E<gt>B<Name> ($id)

Returns the the name for $id.

If $id is undef, returns a reference to the entire B<Name> hash (keyed by ID).

=cut

sub Name {
    my ($self, $id) = @_;

    return ($self->{Name}{$id}) if (defined($id));
    return ($self->{Name});
}

=item my $name_length = $agaTourn-E<gt>B<NameLength>

Returns the length of the longest name.

=cut

sub NameLength {
    my ($self) = @_;
    return ($self->{nameLength});
}

=item my $rating = $agaTourn-E<gt>B<Rating> ($id, $newRating)

Sets (if $newRating is defined) or returns the rating for $id.  If $id is not
defined, returns a reference to the entire B<Rating> hash (keyed by IDs).

$id can also be a rank ('4d', or '5k'), or a rating (4.2 or -5.3, but not
between 1.0 and -1.0).  This form is simply a converter - $newRating is not
accepted.

If $id is defined but not registered (via B<AddRegisterLine>), complains and
returns undef.

=cut

sub Rating {
    my ($self, $id, $newRating) = @_;

    $self->{Rating}{$id} = $newRating if (defined($newRating));
    if (defined($id)) {
        return ($self->{Rating}{$id}) if (exists($self->{Rating}{$id}));
        if ($id =~ m/^(-?\d+\.\d)\s*/) {   # find rank
            return $1;  # rating format
        }
        if ($id =~ m/^\s*(\d+)([dkDK])\b/) {      # 4D or 15k type rank
            my $rating = $1;
            $rating = -$rating if (lc($2) eq 'k');
            return $rating;
        }
        if ($id =~ m/^\s*(-?\d\d?)\b/) { # one or two digit number, no decimal point?
            return $1;                  # it's another way of indicating rank
        }
        carp ("Invalid Rating argument:$id\n");
        return undef;                   # eh?
    }
    return ($self->{Rating});
}

=item my $rank = $agaTourn-E<gt>B<Rank> ($id)

Returns the rank for $id.  This field is undef unless the B<AddRegisterLine>
contained a rank field of the form '4k' or '3d' as opposed to a rating of the
form '-4.5' or '3.4'.

If $id is not defined, returns a reference to the entire B<Rank> hash (keyed
by IDs).

=cut

sub Rank {
    my ($self, $id) = @_;

    return ($self->{Rank}{$id}) if(defined($id));
    return ($self->{Rank});
}

=item my $sigma = $agaTourn-E<gt>B<Sigma> ($id)

Returns the sigma for $id.  Sigma is determined by the rating/rank in the
B<AddRegisterLine>.  If the line contains a rank field of the form '4k' or '3d',
sigma is 1.2 for 7k and stronger, and

    (k - 0.3) / 6

for 8k and weaker.  If the line contains a rating of the form '-4.5' or '3.4',
    sigma is 0.6 for -8.0 and stronger, and

    (-rating - 4.4) / 6

for weaker than -8.0.

Complains and returns undef if $id is undefined or unregistered.

=cut

sub Sigma {
    my ($self, $id) = @_;

    if (defined($id)) {
        if (defined($self->{Rank}{$id})) {
            $self->{Rank}{$id} =~ m/^([\d]+)([kdKD])$/;
            my $r = $1;
            $r = -$r if (lc($2) eq 'k');
            my $sigma = (-$r - 0.3) / 6;
            return ($sigma > 1.2) ? $sigma : 1.2;
        } elsif (defined($self->{Rating}{$id})) {
            my $sigma = (-$self->{Rating}{$id} - 4.4) / 6;
            return ($sigma > 0.6) ? $sigma : 0.6;
        } else {
            carp("$id is not registered\n");
        }
    } else {
        carp("called Sigma(\$id) without a valid ID\n");
    }
    return(undef);
}

=item my $club = $agaTourn-E<gt>B<Club> ($id)

Returns the club for $id or '' if no club is known.  Returns undef if $id is
not registered (via B<AddRegisterLine>).

If no $id parameter is passed, returns a reference to the entire B<Club> hash
(keyed by IDs).

=cut

sub Club {
    my ($self, $id) = @_;

    return ($self->{Club}{$id}) if (defined($id));
    return($self->{Club});
}

=item my $flags = $agaTourn-E<gt>B<Flags> ($id)

Returns the flags for $id or '' if no flags are known.  Flags are anything
left over (excluding the comment) after the ID, name, rating, and club have
been parsed by B<AddRegisterLine>.  It might include (for example) BYE or
Drop.  The case is preserved from the original line parsed.

Returns undef if $id is not registered (via B<AddRegisterLine>).  If no $id
parameter is passed, returns a reference to the entire B<Flags> hash (keyed by
IDs).

=cut

sub Flags {
    my ($self, $id) = @_;

    if (defined($id)) {
        return ($self->{Flags}{$id}) if (exists($self->{Flags}{$id}));
        return ('') if exists($self->{Rating}{$id});
        return (undef)
    }
    return($self->{Flags});
}

=item $comment = $agaTourn-E<gt>B<Comment> ($id)

Returns the comment associated with $id line as added via B<AddRegisterLine>.

If no $id argument is passed, returns a reference to the entire B<Comments>
hash (keyed by IDs).

=cut

sub Comment {
    my ($self, $id) = @_;

    if (defined($id)) {
        return ($self->{Comment}{$id}) if (exists($self->{Comment}{$id}));
        return ('') if exists($self->{Rating}{$id});
        return (undef)
    }
    return ($self->{Comment});
}

=item my $error = $agaTourn-E<gt>B<Error>

If called with an argument, sets the error flag to the new value.
Returns the current (or new) value of the error flag.

=cut

sub Error {
    my ($self, $error) = @_;

    $self->{error} = $error if (defined($error));
    return ($self->{error});
}

=item my $gamesList = $agaTourn-E<gt>B<GamesList> ($id, ...)

Returns a list (or a reference to the list in scalar context) of games played
by B<player>(s).  If no B<player> argument is passed, returns the list of all
games.

Games are added via the B<ReadRoundFile> or the B<AddRoundLine> methods.

Entries in the returned list are comma separated strings.  They can be parsed
with:

    my ($whiteID, $blackID, $result,
        $handicap, $komi, $round) = split(',', $agaTourn->GamesList[$index]);

=cut

sub GamesList {
    my ($self, @arg) = @_;

    return($self->{gameAllList}) unless (@arg);
    my @games;
    foreach (@arg) {
        push(@games, @{$self->{gameIDList}{$_}});
    }
    return(wantarray ? @games : \@games);
}

=item my $wins = $agaTourn-E<gt>B<Wins> ($id)

Returns the number of winning games recorded for $id.  Wins are recorded
via the B<AddRoundLine> method.

If no $id argument is passed, returns a reference to the entire B<Wins> hash
(keyed by IDs).

=cut

sub Wins {
    my ($self, $id) = @_;

    return($self->{Wins}{$id}) if (defined($id));
    return($self->{Wins});
}

=item my $losses = $agaTourn-E<gt>B<Losses> ($id)

Returns the number of losing games recorded for $id.  Losses are
recorded via the B<AddRoundLine> method.

If no $id argument is passed, returns a reference to the entire B<Losses> hash
(keyed by IDs).

=cut

sub Losses {
    my ($self, $id) = @_;

    return($self->{Losses}{$id}) if (defined($id));
    return($self->{Losses});
}

=item my $no_results = $agaTourn-E<gt>B<NoResults> ($id)

Returns the number of no-result games recorded for $id.  No-results are
recorded via the B<AddRoundLine> method.

If no $id argument is passed, returns a reference to the entire B<NoResults>
hash (keyed by IDs).

=cut

sub NoResults {
    my ($self, $id) = @_;

    return($self->{NoResults}{$id}) if (defined($id));
    return($self->{NoResults});
}

=item my @played = $agaTourn-E<gt>B<Played> ($id)

Returns a list (or a reference to the list in scalar context) of $id's
opponents.  The list is ordered as they were added by B<AddRoundLine> method.

If no $id argument is passed, returns a reference to the entire B<Played> hash
(keyed by IDs).

=cut

sub Played {
    my ($self, $id) = @_;

    if (defined($id)) {
        return wantarray ? @{$self->{Played}{$id}} : $self->{Played}{$id};
    }
    return $self->{Played};
}

=item my $rating = $agaTourn-E<gt>B<RankToRating> ($rank | $rating)

Returns a value guaranteed to be in a correct AGA Rating format.  The format
is a number with a tenths decimal, where the number represents the dan rank
(if positive) or the kyu rank (if negative).  A rating of 3.5 represents
squarely in the middle of the 3 dan rank, and -1.9 represents a weak 1 kyu
rank.  The range from 1.0 to -1.0 is not used (see
B<CollapseRating>/B<ExpandRating> below).

=cut

sub RankToRating {
    my ($self, $rating) = @_;

    return (NOTARANK) if (not defined($rating) or ($rating eq ''));
    return "$rating.0" if ($rating =~ m/^-?\d+$/);  # not in decimalized format?
    unless ($rating =~ m/^-?\d+\.\d+$/) {       # not in rating format?
        return(NOTARANK) unless($rating =~ m/^(\d+)([dDkK])$/);        # not in rank format either?
        $rating = "$1.5";                       # it's in rank format (like 5D or 2k), convert to rating
        $rating = -$rating if (uc($2) eq "K");  # kyus are negative
    }
    return($rating);
}

=item my $band_idx = $agaTourn-E<gt>B<WhichBandIs> ($rank | $rating)

Returns the band index for a B<rank> or B<rating>.  Returns NOTARANK if
rank/rating is not in any bands.

See also B<BandName> below.

=cut

sub WhichBandIs {
    my ($self, $r) = @_;

    unless (exists($self->{bandTop})) {
        $self->_setBands();
    }
    $r = $self->RankToRating($r);
    my $ii;
    for ($ii = 0; $ii < @{$self->{bandTop}}; $ii++) {
        next if ($r > $self->{bandTop}[$ii]);
        if ($r >= $self->{bandBot}[$ii]) {
            return($ii);                        # this is it
        }
    }
    return(NOTARANK);
}

=item my $band_name = $agaTourn-E<gt>B<BandName> ($bandIndex)

Returns the name of a band specified by the B<bandIndex> or undef of not known.

Scoring bands are specified via B<AddRegisterLine> with ##BAND directives.

AGATourn complains if bands are specified with holes between them.

The bands are sorted (by strength) and indexed.  B<BandName> returns the
original name (as specified in the ##BAND directive) from a band index.

=cut

sub BandName {
    my ($self, $idx) = @_;

    my ($band, $top, $bot);
    foreach $band (@{$self->{Directive}{'BAND'}}) {
        ($top, $bot) = split(/\s+/, $band);
        $top = int($self->RankToRating($top));
        return undef unless defined($self->{bandTop}[$idx]);
        if ($top == int($self->{bandTop}[$idx])) {
            return($band);
        }
    }
    return(undef);
}

=item my ($handicap, $komi) = $agaTourn-E<gt>B<Handicap> ($player1, $player2)

Returns the appropriate handicap and komi for two players.  Players can be in
any form acceptable to B<Rating>.

If player1 is stronger than player two, the handicap is a
positive number.  If player1 is weaker than player2, (players need to be
swapped), the returned handicap is a negative number.  If the handicap would
normally be 0 and the players need to be swapped, the returned handicap is -1.

A handicap of 1 is never returned.  The returned handicap and komi are always
integers (you may assume that komi needs a additional half-point if you like).

If either player1 or player2 is invalid, B<Handicap> complains (during the
call to B<Rating> for the player) and returns (-1, -1).

B<Handicap> uses the following table (same as the AGA handicap practice):

  rating     handi Ing   AGA
  diff             Komi  Komi
 0.000-0.650   0     7     6    even, normal komi
 0.651-1.250   0    -1*    0    no komi  (* black wins ties under Ing)
 1.251-2.200   0    -7    -6    reverse komi
 2.201-3.300   2    -2     0    two stones
 3.301-4.400   3    -3     0    three stones ...

=cut

sub Handicap {
    my ($self, $p1, $p2) = @_;

    $p1 = $self->CollapseRating($self->Rating($p1));
    $p2 = $self->CollapseRating($self->Rating($p2));
    return (-1, -1) unless(defined($p1) and defined($p2));
    my $diff = $p1 - $p2;
    my $ing = $self->{Directive}{RULES}[0] eq 'ING';
    my $swap = 1;
    my ($handi, $komi) = (0, 0);
    if ($diff < 0) {
        $swap = $handi = -1;
        $diff = -$diff;
    }
    if ($diff <= .650) {
        $komi = $ing ? 7 : 6;   # normal komi game
    } elsif ($diff <= 1.25) {
        $komi = $ing ? -1 : 0;  # no komi game
    } elsif ($diff <= 2.2) {
        $komi = $ing ? -7 : -6; # reverse komi game
    } else {
        $handi = $swap * int($diff / 1.1);
        $komi = 0;
    }
    return (int($handi), int($komi));
}

=item my $collapsed_rating = $agaTourn-E<gt>B<CollapseRating> ($aga_rating)

AGA ratings have a hole between 1.0 and -1.0.  This method fills the hole by
adding 1 to kyu ratings and subtracting 1 from dan ratings.  If $aga_rating is
between 1.0 and -1.0, complains and returns the original $rating.

=cut

sub CollapseRating {
    my ($self, $rating) = @_;

    if ($rating >= 1) {
        $rating -= 1;          # pull dan ratings down to 0
    } elsif ($rating <= -1) {
        $rating += 1;          # pull kyu ratings up to 0
    } else {
        carp "CollapseRating called on a rating between -1 and +1: $rating\n";
    }
    return $rating;
}

=item my $AGA_rating = $agaTourn-E<gt>B<ExpandRating> ($collapsed_rating)

AGA ratings have a hole between 1.0 and -1.0.  This method converts a
continuous rating with no hole into a valid AGA rating by adding 1 to ratings
greater than 0 and subtracting 1 from ratings less than 0.

=cut

sub ExpandRating {
    my ($self, $rating) = @_;

    if ($rating >= 0) {
        $rating += 1;          # dan ratings are upwards from 1
    } else {
        $rating -= 1;          # kyu ratings are downwards from -1
    }
    return $rating;
}

=item my $normalized_id = $agaTourn-E<gt>B<NormalizeID> ($id)

Performs normalization of $id so the we can compare variations of $id without
considering them as different.  Normalization consists of turning the country
part of $id to all upper-case and removing leading zeros from the number part.

All $ids used as hash keys should be normalized.

=cut

sub NormalizeID {
    my ($self, $id) = @_;

    $id = uc ($id);                             # make all letters upper case
    $id =~ s/^([A-Z]*)0*([1-9].*)/$1$2/;        # remove leading zeros from number part
    return($id);
}

######################################################
#
#       Private methods
#
#####################################################

sub _setBands {
    my ($self) = @_;

    unless(exists($self->{Directive}{'BAND'})) {
        # carp("Note: no bands selected, assuming one band.\n");
        unshift(@{$self->{Directive}{'BAND'}}, '99D 99K');
    }
    $self->{bandTop} = [];                      # ref to empty array (to prevent infinite recursion)
    my ($band, $ovBand, $top, $bot);
    foreach $band (@{$self->{Directive}{'BAND'}}) {
        ($top, $bot) = split(/\s+/, $band);
        $top = int($self->RankToRating($top));
        $top += 0.99999 if ($top > 0);
        $bot = int($self->RankToRating($bot));
        $bot -= 0.99999 if ($bot < 0);
        if (($top > 9999) || ($bot < -9999) || ($bot >= $top)) {
            carp("Error: can't parse BAND directive at line $. in $self->{fileName}: $band\n");
            $self->{error} = 1;
            return
        }
        $ovBand = $self->WhichBandIs($top);            # check for overlapped bands
        $ovBand = $self->WhichBandIs($bot) unless ($ovBand eq NOTARANK);
        unless ($ovBand eq NOTARANK) {
            carp("Warning: band conflict: $band\n  (overlaps $self->{Directive}{'BAND'}[$ovBand])\n");
        }
        push(@{$self->{bandTop}}, $top);
        push(@{$self->{bandBot}}, $bot);
    }
    my (@tops) = sort({ $b <=> $a; } @{$self->{bandTop}});             # now check for holes
    my (@bots) = sort({ $b <=> $a; } @{$self->{bandBot}});
    my $ii;
    for ($ii = 0; $ii < @tops - 1; $ii++) {
        next if (($bots[$ii] == 1) && ($tops[$ii + 1] == -1));  # 1d to 1k is a legitimate hole
        if ($bots[$ii] - $tops[$ii + 1] > 0.001) {
            carp( "Warning: hole between bands\n");
        }
    }
    $self->{bandTop} = \@tops;          # use sorted bands
    $self->{bandBot} = \@bots;
}

1;

__END__

=back

=head1 SEE ALSO

=over 0

=item o tdfind(1)   - prepare register.tde for an AGA Go tournament

=item o aradjust(1) - adjust pairings and enter results for a round

=item o tscore(1)   - score a tournament

=item o send2AGA(1) - prepare tournament result for sending to AGA


=back

=head1 AUTHOR

Reid Augustin, E<lt>reid@netchip.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1999, 2004, 2005 by Reid Augustin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

