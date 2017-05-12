=head1 NAME

Games::Go::SGF::Grove - SGF the Perl way

=head1 SYNOPSIS

 use Games::Go::SGF::Grove;

 $game = load_sgf $path;
 save_sgf $path, $game;

 $game = decode_sgf $sgf_data;
 $sgf_data = encode_sgf $game;

=head1 DESCRIPTION

This module loads and saves Go SGF files. Unlike other modules, it doesn't
build a very fancy data structure with lot's of java-like accessors
but instead returns a simple Perl data structure you can inspect with
Data::Dumper and modify easily. The structure follows the SGF file format
very closely.

The SGF format is documented here: L<http://www.red-bean.com/sgf/>.

All the functions below use a common data format and throw exceptions on
any errors.

=over 4

=cut

package Games::Go::SGF::Grove;

use strict;
no warnings;

use Carp;

use base Exporter::;

our $VERSION = '1.01';
our @EXPORT = qw(load_sgf save_sgf encode_sgf decode_sgf);

=item $game = load_sgf $path

Tries to read the file given by C<$path> and parses it as an SGF file,
returning the parsed data structure.

=item save_sgf $path, $game

Saves the SGF data to the specified file.

=item $game = decode_sgf $sgf_data

Tries to parse the given string into a Pelr data structure and returns it.

=item $sgf_data = encode_sgf $game

Takes a Perl data structure and serialises it into an SGF file. Anything
stored in the structure that isn't understood by this module will be
silently ignored.

=cut

sub decode_sgf($) {
   my ($sgf_data) = @_;

   Games::Go::SGF::Grove::Parser::->new->decode_sgf ($sgf_data)
}

sub encode_sgf($) {
   my ($game) = @_;

   Games::Go::SGF::Grove::Parser::->new->encode_sgf ($game)
}

sub load_sgf($) {
   my ($path) = @_;

   open my $fh, "<:perlio", $path
      or Carp::croak "$path: $!";

   local $/;
   decode_sgf <$fh>
}

sub save_sgf($$) {
   my ($path, $game) = @_;

   open my $fh, ">:perlio", $path
      or Carp::croak "$path: $!";

   print $fh encode_sgf $game;
}

=back

=head2 The Game Data structure

The SGF game is represented by a linked Perl data structure consisting of
unblessed hashes and arrays.

SGF files are a forest of trees, called a collection (i.e. you can have
multiple games stored in a file). The C<load_sgf> and C<decode_sgf>
functions returns this collection as a reference to an array containing
the individual game trees (usually there is only one, though).

Each individual tree is again an array of nodes representing the main line
of play.

Each node is simply a hash reference. Each SGF property is stored with the
(uppercase) property name as the key, and a property-dependent value for
the contents (e.g., a black move is stored as C<< B => [3, 5] >>.

If there are any variations/branches/alternate lines of play, then these
are stored in the array reference in the C<variations> key (those again
are game trees, so array references themselves).

This module reserves all uppercase key names for SGF properties, the key
C<variations> and all keys starting with an underscore (C<_xxx>) as it's
own. Users of this module may store additional attributes that don't
conflict with these names in any node.

Unknown properties will be stored as scalars with the (binary) property
contents. Text nodes will always be decoded into Unicode text and encoded
into whatever the CA property of the root node says (default: C<UTF-8>).

When saving, all uppercase keys will be saved, lowercase keys will be
ignored.

For the actual encoding of other types, best decode some example game that
contains them and use Data::Dumper. Here is such an example:

  [ # list of game-trees, only one here
    [ # the main node sequence
      { # the root node, contains some variations
        DI => '7k',
        AP => undef,
        CO => '5',
        DP => '40',
        GE => 'tesuji',
        AW => [
                  [ 2, 16 ], [ 3, 15 ], [ 15, 9 ], [ 14, 13 ], ...
              ],
        C  => 'White just played a ladder block at h12.',
        variations => [ # list of variations, only one
                        [ # sequence of variation moves
                          { B => [  7,  5 ] }, # a black move
                          { W => [ 12, 12 ] }, # a white move
                          ... and so on
                        ]
                      ],
      }
    ]
  }

=cut

package Games::Go::SGF::Grove::Parser;

no warnings;
use strict 'vars';

use Encode ();
use Carp qw(croak);

my $ws = qr{[\x00-\x20]*}s;
my $property; # property => propertyinfo

sub new {
   my $class = shift;
   bless { @_ }, $class;
}

sub error {
   my ($self, $error) = @_;

   my $pos = pos $self->{sgf};

   my $tail = substr $self->{sgf}, $pos, 32;
   $tail =~ s/[\x00-\x1f]+/ /g;

   croak "$error (at octet $pos, '$tail')";
}

sub decode_sgf {
   my ($self, $sgf) = @_;

   # correct lines
   if ($sgf =~ /[^\015\012]\015/) {
      $sgf =~ s/\015\012?/\n/g;
   } else {
      $sgf =~ s/\012\015?/\n/g;
   }

   $self->{sgf} = $sgf;

   $self->{FF} = 1;
   $self->{CA} = 'WINDOWS-1252'; # too many files are
   $self->{GM} = 1;

   my @trees;

   eval {
      while ($self->{sgf} =~ /\G$ws(?=\()/sgoc) {
         push @trees, $self->decode_GameTree;
      }
   };

   croak $@ if $@;

   \@trees
}

sub decode_GameTree {
   my ($self) = @_;

   $self->{sgf} =~ /\G$ws\(/sgoc
      or $self->error ("GameTree does not start with '('");

   my $nodes = $self->decode_Sequence;

   while ($self->{sgf} =~ /\G$ws(?=\()/sgoc) {
      push @{$nodes->[-1]{variations}}, $self->decode_GameTree;
   }
   $self->{sgf} =~ /\G$ws\)/sgoc
      or $self->error ("GameTree does not end with ')'");

   $nodes
}

sub postprocess {
   my $self = shift;

   for (@_) {
      if ("ARRAY" eq ref) {
         $self->postprocess (@$_);
      } elsif ("HASH" eq ref) {
         if (exists $_->{_text}) {
            my $value = $_->{_text};
            $value =~ s/\\\n/ /g;
            $value =~ s/\\(.)/$1/g;
            $_ = eval { Encode::decode $self->{CA}, $value } || $value;
         } else {
            $self->postprocess (values %$_);
         }
      }
   }
}

sub decode_Sequence {
   my ($self) = @_;

   my (@nodes, $node, $name, $value, $prop, @val);

   while ($self->{sgf} =~ /\G$ws;/goc) {
      push @nodes, $node = {};
      # Node
      while ($self->{sgf} =~ /\G$ws([A-Za-z]+)/goc) {
         # Property
         $name = $1;
         $name =~ y/a-z//d; # believe me, they exist
         $prop = $property->{$name};

         while ($self->{sgf} =~
            /
               \G $ws
               \[
                  (
                     (?:
                        [^\\\]]+ # any sequence without \ or ]
                        | \\.    # any quoted char
                        | \]     # hack to allow ] followed by somehting that doesn't look like SGF
                          (?! \s* (?: [A-Z]+\[ | [\[;()] ) )
                     )*
                  )
               \]
            /sgocx
         ) {
            # PropValue
            $value = $1;
            if ($prop) {
               @val = $prop->{in}->($self, $value, $prop);

               if ($prop->{is_list}) {
                  push @{$node->{$name}}, @val
               } else {
                  $node->{$name} = $val[0];

                  $self->{CA} = $val[0] if $name eq "CA";
               }
            } else {
               #warn "unknown property '$name', will be saved unchanged.";#d#
               push @{$node->{$name}}, $value;
            }
         }
      }

      # postprocess nodes, currently only to decode text and simpletext
      $self->postprocess ($node);
   }

   \@nodes
}

sub encode_sgf($) {
   my ($self, $game) = @_;

   $self->{sgf} = "";

   $self->{FF} = 4;
   $self->{CA} = 'UTF-8';
   $self->{GM} = 1;
   $self->{AP} = ["Games::Go::SGF::Grove", $VERSION];

   $self->encode_GameTree ($_, 1) for @$game;

   $self->{sgf}
}

sub encode_GameTree {
   my ($self, $sequence, $is_root) = @_;

   if ($is_root) {
      my $root = $sequence->[0];

      $root->{CA} ||= $self->{CA};
      $root->{FF} ||= $self->{FF};
      $root->{GM} ||= $self->{GM};
      $root->{AP} ||= $self->{AP};

      $self->{CA} = $root->{CA};
   }

   $self->{sgf} .= "(";
   $self->encode_Sequence ($sequence);
   $self->{sgf} .= ")";
}

sub encode_Sequence {
   my ($self, $sequence) = @_;

   my ($value, $prop);

   for my $node (@$sequence) {
      $self->{sgf} .= ";";

      for my $name (sort keys %$node) {
         next unless $name eq uc $name;

         $value = $node->{$name};

         $self->{sgf} .= "$name\[";

         if ($prop = $property->{$name}) {
            if ($prop->{is_list}) {
               $self->{sgf} .= join "][", map $prop->{out}->($self, $_), @$value;
            } else {
               $self->{sgf} .= $prop->{out}->($self, $value);
            }
         } else {
            $self->{sgf} .=
               ref $value
                  ? join "][", @$value
                  : $value;
         }

         $self->{sgf} .= "]";
      }

      $self->encode_GameTree ($_) for @{ $node->{variations} };
   }
}

#############################################################################

=head2 Property Type Structure

A property type is a hash like this:

   {
     name => "SQ",
     group => {
                name => "Markup properties",
                restrictions => "CR, MA, SL, SQ and TR points must be unique, ...",
              },
     related => "TR, CR, LB, SL, AR, MA, LN",
     function => "Marks the given points with a square.\nPoints must be unique.",
     propertytype => "-",
     propvalue => "list of point"
     is_list => 1,
   }

=cut


{
   my ($group, $name, $value, $prop);

   my (%char2coord, %coord2char);

   {
      my @coord = ("a" .. "z", "A" .. "Z");

      for (0.. $#coord) {
         $char2coord{ $coord[$_] } = $_;
         $coord2char{ $_ } = $coord[$_];
      }
   }

   sub _parsetype($);
   sub _parsetype {
      for (shift) {
         if (s/e?list of //) {
            $prop->{is_list} = 1;
            return _parsetype $_;

         } elsif (s/composed (\S+)\s+(?:':'\s+)?(\S+)//) {
            $prop->{composed} = 1;
            my ($i, $o) = ($1, $2);
            my ($i1, $o1, $i2, $o2) = (_parsetype $i, _parsetype $o);
            return (
                  sub {
                     if ($_[1] =~ /^((?:[^\\:]+|\\.)*)(?::(.*))?$/s) {
                        # or $_[0]->error ("'Compose' ($i:$o) expected, got '$_[1]'");
                        my ($l, $r) = ($1, $2);

                        [
                           $i1->($_[0], $l),
                           defined $r ? $i2->($_[0], $r) : undef,
                        ]
                     }
                  },
                  sub {
                     $o1->($_[0], $_[1][0])
                     . ":"
                     . $o2->($_[0], $_[1][1])
                  },
               );

         } elsif (s/double//) {
            return (
                  sub {
                     $_[1] =~ /^[12]$/
                        or $_[0]->error ("'Double' (1|2) expected, got '$_[1]'");
                     $_[1]
                  },
                  sub {
                     $_[1]
                  },
               );
         } elsif (s/color//) {
            return (
                  sub {
                     # too many broken programs write this wrong
                     return "B" if $_[1] eq "1";
                     return "W" if $_[1] eq "2";

                     $_[1] =~ /^[BW]$/i
                        or $_[0]->error ("'Color' (B|W) expected, got '$_[1]'");
                     lc $_[1]
                  },
                  sub {
                     uc $_[1]
                  },
               );
         } elsif (s/none//) {
            return (
                  sub {
                     $_[1] =~ /^$/i
                        or $_[0]->error ("'None' expected, got '$_[1]'");
                     undef
                  },
                  sub {
                     "",
                  },
               );
         } elsif (s/point// || s/move// || s/stone//) {
            return (
                  sub {
                     if ($_[2]->{is_list}) {
                        if ($_[1] =~ /^([^:]+):(.*)$/) {
                           my ($ul, $dr) = ($1, $2);
                           my ($x1, $y1) = map $char2coord{$_}, split //, $ul; 
                           my ($x2, $y2) = map $char2coord{$_}, split //, $dr; 
                           my @stones;
                           for (my $d = $x1; $d <= $x2; $d++) {
                              for (my $i = $y1; $i <= $y2; $i++) {
                                 push @stones, [$d, $i];
                              }
                           }
                           return @stones;
                        }
                     }
                     $_[1] =~ /^(.)(.)$/
                        ? [ $char2coord{$1}, $char2coord{$2} ]
                        : []
                  },
                  sub {
                     $coord2char{$_[1][0]} . $coord2char{$_[1][1]}
                  },
               );
         } elsif (s/real// || s/number//) {
            return (
                  sub {
                     $_[1]
                  },
                  sub {
                     $_[1]
                  },
               );
         } elsif (s/text// || s/simpletext//i) {
            return (
                  sub {
                     { _text => $_[1] }
                  },
                  sub {
                     my $str = Encode::encode $_[0]{CA}, $_[1];
                     $str =~ s/([\:\]\\])/\\$1/g;
                     $str
                  },
               );
         } else {
            die "FATAL: garbled DATA section, unknown type '$_'";
         }
      }
   }

   while (<DATA>) {
      if (/^(\S+):\t(.*)/) {
         if ($name eq "Restrictions") {
            $group->{restrictions} = $value;
         } elsif ($name eq "Property") {
            $property->{$value} =
            $prop = {
               name  => $value,
               group => $group,
            };
         } elsif ($name ne "") {
            $prop->{lc $name} = $value;
            if ($name eq "Propvalue") {
               ($prop->{in}, $prop->{out}) = _parsetype $value;
            }
         }
         $name = $1;
         $value = $2;
      } elsif (/^\t\t(.*)/) {
         $value .= "\n$1";
      } elsif (/(\S.*)/) {
         $group = {
            name => $1,
         };
      } elsif (/^$/) {
         # nop
      } else {
         die "FATAL: DATA section garbled\n";
      }
   }
}

1;

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 Robin Redeker <elmex@ta-sa.org>

=cut

# now node descriptions follow

__DATA__
Move properties

Property:	B
Propvalue:	move
Propertytype:	move
Function:	Execute a black move. This is one of the most used properties
		in actual collections. As long as
		the given move is syntactically correct it should be executed.
		It doesn't matter if the move itself is illegal
		(e.g. recapturing a ko in a Go game).
		Have a look at how to execute a Go-move.
		B and W properties must not be mixed within a node.
Related:	W, KO

Property:	KO
Propvalue:	none
Propertytype:	move
Function:	Execute a given move (B or W) even it's illegal. This is
		an optional property, SGF viewers themselves should execute
		ALL moves. It's purpose is to make it easier for other
		applications (e.g. computer-players) to deal with illegal
		moves. A KO property without a black or white move within
		the same node is illegal.
Related:	W, B

Property:	MN
Propvalue:	number
Propertytype:	move
Function:	Sets the move number to the given value, i.e. a move
		specified in this node has exactly this move-number. This
		can be useful for variations or printing.
Related:	B, W, FG, PM

Property:	W
Propvalue:	move
Propertytype:	move
Function:	Execute a white move. This is one of the most used properties
		in actual collections. As long as
		the given move is syntactically correct it should be executed.
		It doesn't matter if the move itself is illegal
		(e.g. recapturing a ko in a Go game).
		Have a look at how to execute a Go-move.
		B and W properties must not be mixed within a node.
Related:	B, KO

Setup properties
Restrictions:	AB, AW and AE must have unique points, i.e. it is illegal to place different colors on the same point within one node.
		AB, AW and AE values which don't change the board, e.g. placing a black stone with AB[] over a black stone that's already there, is bad style. Applications may want to delete these values and issue a warning.

Property:	AB
Propvalue:	list of stone
Propertytype:	setup
Function:	Add black stones to the board. This can be used to set up
		positions or problems. Adding is done by 'overwriting' the
		given point with black stones. It doesn't matter what
		was there before. Adding a stone doesn't make any prisoners
		nor any other captures (e.g. suicide). Thus it's possible
		to create illegal board positions.
		Points used in stone type must be unique.
Related:	AW, AE, PL

Property:	AE
Propvalue:	list of point
Propertytype:	setup
Function:	Clear the given points on the board. This can be used
		to set up positions or problems. Clearing is done by
		'overwriting' the given points, so that they contain no
		stones. It doesn't matter what was there before.
		Clearing doesn't count as taking prisoners.
		Points must be unique.
Related:	AB, AW, PL

Property:	AW
Propvalue:	list of stone
Propertytype:	setup
Function:	Add white stones to the board. This can be used to set up
		positions or problems. Adding is done by 'overwriting' the
		given points with white stones. It doesn't matter what
		was there before. Adding a stone doesn't make any prisoners
		nor any other captures (e.g. suicide). Thus it's possible
		to create illegal board positions.
		Points used in stone type must be unique.
Related:	AB, AE, PL

Property:	PL
Propvalue:	color
Propertytype:	setup
Function:	PL tells whose turn it is to play. This can be used when
		setting up positions or problems.
Related:	AE, AB, AW

Node annotation properties

Property:	C
Propvalue:	text
Propertytype:	-
Function:	Provides a comment text for the given node. The purpose of
		providing both a node name and a comment is to have a short
		identifier like "doesn't work" or "Dia. 15" that can be
		displayed directly with the properties of the node, even if
		the comment is turned off or shown in a separate window.
		See text-type for more info.
Related:	N, ST, V, UC, DM, HO

Property:	DM
Propvalue:	double
Propertytype:	-
Function:	The position is even. SGF viewers should display a
		message. This property may indicate main variations in
		opening libraries (joseki) too. Thus DM[2] indicates an
		even result for both players and that this is a main
		variation of this joseki/opening.
		This property must not be mixed with UC, GB or GW
		within a node.
Related:	UC, GW, GB

Property:	GB
Propvalue:	double
Propertytype:	-
Function:	Something good for black. SGF viewers should display a
		message. The property is not related to any specific place
		on the board, but marks the whole node instead.
		GB must not be mixed with GW, DM or UC within a node.
Related:	GW, C, UC, DM

Property:	GW
Propvalue:	double
Propertytype:	-
Function:	Something good for white. SGF viewers should display a
		message. The property is not related to any specific place
		on the board, but marks the whole node instead.
		GW must not be mixed with GB, DM or UC within a node.
Related:	GB, C, UC, DM

Property:	HO
Propvalue:	double
Propertytype:	-
Function:	Node is a 'hotspot', i.e. something interesting (e.g.
		node contains a game-deciding move).
		SGF viewers should display a message.
		The property is not related to any specific place
		on the board, but marks the whole node instead.
		Sophisticated applications could implement the navigation
		command next/previous hotspot.
Related:	GB, GW, C, UC, DM

Property:	N
Propvalue:	simpletext
Propertytype:	-
Function:	Provides a name for the node. For more info have a look at
		the C-property.
Related:	C, ST, V

Property:	UC
Propvalue:	double
Propertytype:	-
Function:	The position is unclear. SGF viewers should display a
		message. This property must not be mixed with DM, GB or GW
		within a node.
Related:	DM, GW, GB

Property:	V
Propvalue:	real
Propertytype:	-
Function:	Define a value for the node.  Positive values are good for
		black, negative values are good for white.
		The interpretation of particular values is game-specific.
		In Go, this is the estimated score.
Related:	C, N, RE

Move annotation properties
Restrictions:	Move annotation properties without a move (B[] or W[]) within the same node are senseless and therefore illegal. Applications should delete such properties and issue a warning.
		BM, TE, DO and IT are mutual exclusive, i.e. they must not be mixed within a single node.

Property:	BM
Propvalue:	double
Propertytype:	move
Function:	The played move is bad.
		Viewers should display a message.
Related:	TE, DO, IT

Property:	DO
Propvalue:	none
Propertytype:	move
Function:	The played move is doubtful.
		Viewers should display a message.
Related:	BM, TE, IT

Property:	IT
Propvalue:	none
Propertytype:	move
Function:	The played move is interesting.
		Viewers should display a message.
Related:	BM, DO, TE

Property:	TE
Propvalue:	double
Propertytype:	move
Function:	The played move is a tesuji (good move).
		Viewers should display a message.
Related:	BM, DO, IT

Markup properties
Restrictions:	CR, MA, SL, SQ and TR points must be unique, i.e. it's illegal to have two or more of these markups on the same point within a node.

Property:	AR
Propvalue:	list of composed point point
Propertytype:	-
Function:	Viewers should draw an arrow pointing FROM the first point
		TO the second point.
		It's illegal to specify the same arrow twice,
		e.g. (Go) AR[aa:bb][aa:bb]. Different arrows may have the same
		starting or ending point though.
		It's illegal to specify a one point arrow, e.g. AR[cc:cc]
		as it's impossible to tell into which direction the
		arrow points.
Related:	TR, CR, LB, SL, MA, SQ, LN

Property:	CR
Propvalue:	list of point
Propertytype:	-
Function:	Marks the given points with a circle.
		Points must be unique.
Related:	TR, MA, LB, SL, AR, SQ, LN

Property:	DD
Propvalue:	elist of point
Propertytype:	inherit
Function:	Dim (grey out) the given points.
		DD[] clears any setting, i.e. it undims everything.
Related:	VW

Property:	LB
Propvalue:	list of composed point simpletext
Propertytype:	-
Function:	Writes the given text on the board. The text should be
		centered around the given point. Note: there's no longer
		a restriction to the length of the text to be displayed.
		Have a look at the FF4 example file on possibilities
		to display long labels (pictures five and six).
		Points must be unique.
Related:	TR, CR, MA, SL, AR, SQ, LN

Property:	LN
Propvalue:	list of composed point point
Propertytype:	-
Function:	Applications should draw a simple line form one point
		to the other.
		It's illegal to specify the same line twice,
		e.g. (Go) LN[aa:bb][aa:bb]. Different lines may have the same
		starting or ending point though.
		It's illegal to specify a one point line, e.g. LN[cc:cc].
Related:	TR, CR, MA, SL, AR, SQ, LB


Property:	MA
Propvalue:	list of point
Propertytype:	-
Function:	Marks the given points with an 'X'.
		Points must be unique.
Related:	TR, CR, LB, SL, AR, SQ, LN

Property:	SL
Propvalue:	list of point
Propertytype:	-
Function:	Selected points. Type of markup unknown
		(though SGB inverts the colors of the given points).
		Points must be unique.
Related:	TR, CR, LB, MA, AR, LN

Property:	SQ
Propvalue:	list of point
Propertytype:	-
Function:	Marks the given points with a square.
		Points must be unique.
Related:	TR, CR, LB, SL, AR, MA, LN

Property:	TR
Propvalue:	list of point
Propertytype:	-
Function:	Marks the given points with a triangle.
		Points must be unique.
Related:	MA, CR, LB, SL, AR, LN

Root properties

Property:	AP
Propvalue:	composed simpletext simpletext
Propertytype:	root
Function:	Provides the name and version number of the application used
		to create this gametree.
		The name should be unique and must not be changed for
		different versions of the same program.
		The version number itself may be of any kind, but the format
		used must ensure that by using an ordinary string-compare,
		one is able to tell if the version is lower or higher
		than another version number.
		Here's the list of known applications and their names:

		Application		     System	  Name
		---------------------------  -----------  --------------------
		[CGoban:1.6.2]		     Unix	  CGoban
		[Hibiscus:2.1]		     Windows 95   Hibiscus Go Editor
		[IGS:5.0]				  Internet Go Server
		[Many Faces of Go:10.0]      Windows 95   The Many Faces of Go
		[MGT:?]			     DOS/Unix	  MGT
		[NNGS:?]		     Unix	  No Name Go Server
		[Primiview:3.0]   	     Amiga OS3.0  Primiview
		[SGB:?]			     Macintosh	  Smart Game Board
		[SmartGo:1.0]		     Windows	  SmartGo

Related:	FF, GM, SZ, ST, CA

Property:	CA
Propvalue:	simpletext
Propertytype:	root
Function:	Provides the used charset for SimpleText and Text type.
		Default value is 'ISO-8859-1' aka 'Latin1'.
		Only charset names (or their aliases) as specified in RFC 1345
		(or updates thereof) are allowed.
		Basically this field uses the same names as MIME messages in
		their 'charset=' field (in Content-Type).
		RFC's can be obtained via FTP from DS.INTERNIC.NET,
		NIS.NSF.NET, WUARCHIVE.WUSTL.EDU, SRC.DOC.IC.AC.UK
		or FTP.IMAG.FR.
Related:	FF, C, text type

Property:	FF
Propvalue:	number (range: 1-4)
Propertytype:	root
Function:	Defines the used file format. For difference between those
		formats have a look at the history of SGF.
		Default value: 1
		Applications must be able to deal with different file formats
		within a collection.
Related:	GM, SZ, ST, AP, CA

Property:	GM
Propvalue:	number (range: 1-16)
Propertytype:	root
Function:	Defines the type of game, which is stored in the current
		gametree. The property should help applications
		to reject games, they cannot handle.
		Valid numbers are: Go = 1, Othello = 2, chess = 3,
		Gomoku+Renju = 4, Nine Men's Morris = 5, Backgammon = 6,
		Chinese chess = 7, Shogi = 8, Lines of Action = 9,
		Ataxx = 10, Hex = 11, Jungle = 12, Neutron = 13,
		Philosopher's Football = 14, Quadrature = 15, Trax = 16,
		Tantrix = 17, Amazons = 18, Octi = 19, Gess = 20.
		Default value: 1
		Different kind of games may appear within a collection.
Related:	FF, SZ, ST, AP, CA

Property:	ST
Propvalue:	number (range: 0-3)
Propertytype:	root
Function:	Defines how variations should be shown (this is needed to
		synchronize the comments with the variations). If ST is omitted
		viewers should offer the possibility to change the mode online.
		Basically most programs show variations in two ways:
		as markup on the board (if the variation contains a move)
		and/or as a list (in a separate window).
		The style number consists two options.
		1) show variations of successor node (children) (value: 0)
		   show variations of current node   (siblings) (value: 1)
		   affects markup & list
		2) do board markup         (value: 0)
		   no (auto-) board markup (value: 2)
		   affects markup only.
		   Using no board markup could be used in problem collections
		   or if variations are marked by subsequent properties.
		   Viewers should take care, that the automatic variation
		   board markup DOESN'T overwrite any markup of other
		   properties.
		The  final number is calculated by adding the values of each
		option.	Example: 3 = no board markup/variations of current node
				 1 = board markup/variations of current node
		Default value: 0
Related:	C, FF, GM, SZ, AP, CA

Property:	SZ
Propvalue:	number
Propertytype:	root
Function:	Defines the size of the board. If only a single value
		is given, the board is a square; with two numbers given,
		rectangular boards are possible.
		If a rectangular board is specified, the first number specifies
		the number of columns, the second provides the number of rows.
		Square boards must not be defined using the compose type
		value: e.g. SZ[19:19] is illegal.
		The valid range for SZ is any size greater or equal to 1x1.
		For Go games the maximum size is limited to 52x52.
		Default value: game specific
			       for Go: 19 (square board)
			       for Chess: 8 (square board)
		Different board sizes may appear within a collection.
		See move-/point-type for more info.
Related:	FF, GM, ST, AP, CA

Game info properties

Property:	AN
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the name of the person, who made the annotations
		to the game.
Related:	US, SO, CP

Property:	BR
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the rank of the black player.
		For Go (GM[1]) the following format is recommended:
		"..k" or "..kyu" for kyu ranks and
		"..d" or "..dan" for dan ranks.
		Go servers may want to add '?' for an uncertain rating and
		'*' for an established rating.
Related:	PB, BT, WR

Property:	BT
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the name of the black team, if game was part of a
		team-match (e.g. China-Japan Supermatch).
Related:	PB, PW, WT

Property:	CP
Propvalue:	simpletext
Propertytype:	game-info
Function:	Any copyright information (e.g. for the annotations) should
		be included here.
Related:	US, SO, AN

Property:	DT
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the date when the game was played.
		It is MANDATORY to use the ISO-standard format for DT.
		Note: ISO format implies usage of the Gregorian calendar.
		Syntax:
		"YYYY-MM-DD" year (4 digits), month (2 digits), day (2 digits)
		Do not use other separators such as "/", " ", "," or ".".
		Partial dates are allowed:
		"YYYY" - game was played in YYYY
		"YYYY-MM" - game was played in YYYY, month MM
		For games that last more than one day: separate other dates
		by a comma (no spaces!); following shortcuts may be used:
		"MM-DD" - if preceded by YYYY-MM-DD, YYYY-MM, MM-DD, MM or DD
		"MM" - if preceded by YYYY-MM or MM
		"DD" - if preceded by YYYY-MM-DD, MM-DD or DD
		Shortcuts acquire the last preceding YYYY and MM (if
		necessary).
		Note: interpretation is done from left to right.
		Examples:
			1996-05,06 = played in May,June 1996
			1996-05-06,07,08 = played on 6th,7th,8th May 1996
			1996,1997 = played in 1996 and 1997
			1996-12-27,28,1997-01-03,04 = played on 27th,28th
			of December 1996 and on 3rd,4th January 1997
		Note: it's recommended to use shortcuts whenever possible,
		e.g. 1997-05-05,06 instead of 1997-05-05,1997-05-06
Related:	EV, RO, PC, RU, RE, TM

Property:	EV
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the name of the event (e.g. tournament).
		Additional information (e.g. final, playoff, ..)
		shouldn't be included (see RO).
Related:	GC, RO, DT, PC, RU, RE, TM

Property:	GN
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides a name for the game. The name is used to
		easily find games within a collection.
		The name should therefore contain some helpful information
		for identifying the game. 'GameName' could also be used
		as the file-name, if a collection is split into
		single files.
Related:	GC, EV, DT, PC, RO, ID

Property:	GC
Propvalue:	text
Propertytype:	game-info
Function:	Provides some extra information about the following game.
		The intend of GC is to provide some background information
		and/or to summarize the game itself.
Related:	GN, ON, AN, CP

Property:	ON
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides some information about the opening played
		(e.g. san-ren-sei, Chinese fuseki, etc.).
Related:	GN, GC

Property:	OT
Propvalue:	simpletext
Propertytype:	game-info
Function:	Describes the method used for overtime (byo-yomi).
		Examples: "5 mins Japanese style, 1 move / min",
			  "25 moves / 10 min".
Related:	TM, BL, WL, OB, OW

Property:	PB
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the name of the black player.
Related:	PW, BT, WT

Property:	PC
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the place where the games was played.
Related:	EV, DT, RO, RU, RE, TM

Property:	PW
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the name of the white player.
Related:	PB, BT, WT

Property:	RE
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the result of the game. It is MANDATORY to use the
		following format:
		"0" (zero) or "Draw" for a draw (jigo),
		"B+" ["score"] for a black win and
		"W+" ["score"] for a white win
		Score is optional (some games don't have a score e.g. chess).
		If the score is given it has to be given as a real value,
		e.g. "B+0.5", "W+64", "B+12.5"
		Use "B+R" or "B+Resign" and "W+R" or "W+Resign" for a win by
		resignation. Applications must not write "Black resigns".
		Use "B+T" or "B+Time" and "W+T" or "W+Time" for a win on time,
		"B+F" or "B+Forfeit" and "W+F" or "W+Forfeit" for a win by
		forfeit,
		"Void" for no result or suspended play and
		"?" for an unknown result.

Related:	EV, DT, PC, RO, RU, TM

Property:	RO
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides round-number and type of round. It should be
		written in the following way: RO[xx (tt)], where xx is the
		number of the round and (tt) the type:
		final, playoff, league, ...
Related:	EV, DT, PC, RU, RE, TM

Property:	RU
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the used rules for this game.
		Because there are many different rules, SGF requires
		mandatory names only for a small set of well known rule sets.
		Note: it's beyond the scope of this specification to give an
		exact specification of these rule sets.
		Mandatory names for Go (GM[1]):
			"AGA" (rules of the American Go Association)
			"GOE" (the Ing rules of Goe)
			"Japanese" (the Nihon-Kiin rule set)
			"NZ" (New Zealand rules)

Related:	EV, DT, PC, RO, RE, TM

Property:	SO
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the name of the source (e.g. book, journal, ...).
Related:	US, AN, CP

Property:	TM
Propvalue:	real
Propertytype:	game-info
Function:	Provides the time limits of the game.
		The time limit is given in seconds.
Related:	EV, DT, PC, RO, RU, RE

Property:	US
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the name of the user (or program), who entered
		the game.
Related:	SO, AN, CP

Property:	WR
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provides the rank of the white player. For recommended
		format see BR.
Related:	PW, WT, BR

Property:	WT
Propvalue:	simpletext
Propertytype:	game-info
Function:	Provide the name of the white team, if game was part of a
		team-match (e.g. China-Japan Supermatch).
Related:	PB, PW, BT

Timing properties

Property:	BL
Propvalue:	real
Propertytype:	move
Function:	Time left for black, after the move was made.
		Value is given in seconds.
Related:	TM, OT, WL, OB, OW

Property:	OB
Propvalue:	number
Propertytype:	move
Function:	Number of black moves left (after the move of this node was
		played) to play in this byo-yomi period.
Related:	TM, OT, BL, WL, OW

Property:	OW
Propvalue:	number
Propertytype:	move
Function:	Number of white moves left (after the move of this node was
		played) to play in this byo-yomi period.
Related:	TM, OT, BL, WL, OB

Property:	WL
Propvalue:	real
Propertytype:	move
Function:	Time left for white after the move was made.
		Value is given in seconds.
Related:	TM, OT, BL, OB, OW

Miscellaneous properties

Property:	FG
Propvalue:	composed number SimpleText
Propertytype:	-
Function:	The figure property is used to divide a game into
		different figures for printing: a new figure starts at the
		node containing a figure property.
		If the value is not empty then
		- Simpletext provides a name for the diagram
		- Number specifies some flags (for printing).
		  These flags are:
			- coordinates on/off (value: 0/1)
			- diagram name on/off (value: 0/2)
			- list moves not shown in figure on/off (value: 0/4)
			  Some moves can't be shown in a diagram (e.g. ko
			  captures in Go) - these moves may be listed as text.
			- remove captured stones on/off (value: 0/256)
			  'remove off' means: keep captured stones in the
			  diagram and don't overwrite stones played earlier -
			  this is the way diagrams are printed in books.
			  'remove on' means: capture and remove the stones from
			  the display - this is the usual viewer mode.
			  This flag is specific to Go (GM[1]).
			- hoshi dots on/off (value: 0/512)
			  This flag is specific to Go (GM[1]).
			- Ignore flags on/off (value: 32768)
			  If on, then all other flags should be ignored and
			  the application should use its own defaults.
		  The final number is calculated by summing up all flag values.
		  E.g. 515 = coordinates and diagram name off, remove captured
		  stones, list unshown moves, hoshi dots off;
		  257 = coordinates off, diagram name on, list unshown moves,
		  don't remove captured stones, hoshi dots on.
		  (this is how diagrams are printed in e.g. Go World)
		Note: FG combined with VW, MN and PM are mighty tools to print
		and compile diagrams.
Related:	MN, PM, VW

Property:	PM
Propvalue:	number
Propertytype:	inherit
Function:	This property is used for printing.
		It specifies how move numbers should be printed.
		0 ... don't print move numbers
		1 ... print move numbers as they are
		2 ... print 'modulo 100' move numbers
			This mode is usually used in books or magazines.
			Note: Only the first move number is calculated
			'modulo 100' and the obtained number is increased
			for each move in the diagram.
			E.g. A figure containing moves
				 32-78  is printed as moves 32-78
				102-177 is printed as moves  2-77
				 67-117 is printed as moves 67-117
				154-213 is printed as moves 54-113
		Default value: 1
Related:	MN, FG

Property:	VW
Propvalue:	elist of point
Propertytype:	inherit
Function:	View only part of the board. The points listed are
			visible, all other points are invisible.
			Note: usually the point list is given in compressed
			format (see 'point' type)!
			Points have to be unique.
			Have a look at the picture to get an idea.
			VW[] clears any setting, i.e. the whole board is
			visible again.
Related:	DD, PM, FG

Go properties
Restrictions:	TW and TB points must be unique, i.e. it's illegal to list the same point in TB and TW within the same node.
Gametype:	1

Property:	HA
Propvalue:	number
Propertytype:	game-info
Function:	Defines the number of handicap stones (>=2).
		If there is a handicap, the position should be set up with
		AB within the same node.
		HA itself doesn't add any stones to the board, nor does
		it imply any particular way of placing the handicap stones.
Related:	KM, RE, RU

Property:	KM
Propvalue:	real
Propertytype:	game-info
Function:	Defines the komi.
Related:	HA, RE, RU

Property:	TB
Propvalue:	elist of point
Propertytype:	-
Function:	Specifies the black territory or area (depends on
		rule set used).
		Points must be unique.
Related:	TW

Property:	TW
Propvalue:	elist of point
Propertytype:	-
Function:	Specifies the white territory or area (depends on
		rule set used).
		Points must be unique.
Related:	TB

Octi properties
Gametype:	19

Property:	RU (rules)
Propvalue:	simpletext
Propertytype:	game-info
Function:	Valid values are one major variation ("full", "fast",
		or "kids") followed by a colon and a comma separated
		elist of variations ("edgeless", "superprong", etc.).
		
		The colon may be omitted if either side is empty.
		The default is 2-player full, no variations.
		The 4-player game is not currently available.

Property:	BO (black octisquares)
Propvalue:	list of point
Propertytype:	game-info
Function:	The position of Black's octi squares.  Black will be
		setup with one empty pod on each of these points.
		It is illegal to list the same point twice.
		Traditionally, Black sits at the south end of the board.
Related:	WO

Property:	WO (white octisquares)
Propvalue:	list of point
Propertytype:	game-info
Function:	The position of White's octi squares.  White will be
		setup with one empty pod on each of these points.
		It is illegal to list the same point twice.
		Traditionally, White sits at the north end of the board.
Related:	BO

Property:	NP (number of prongs)
Propvalue:	number
Propertytype:	game-info
Function:	This is the number of prongs each players has at the
		start of the game.
		The default will be derived from the rules.
Related:	NR

Property:	NR (number of reserve)
Propvalue:	number
Propertytype:	game-info
Function:	This is the number of pods in each players reserve at
		the start of the game.
		The default will be derived from the rules.
Related:	NP, NS

Property:	NS (number of superprongs)
Propvalue:	number
Propertytype:	game-info
Function:	This is the number of superprongs each players has at
		the start of the game.
		The default will be derived from the rules.
Related:	NR

Property:	AS (arrow stone)
Propvalue:	list of composed stone ':' point
Propertytype:	-
Function:	Most of the same restriction from AR apply.
		The same arrow must not occur twice; however, two arrows
		from different stones at the same point may have arrows
		to the same destination.	Single point arrows are also
		illegal.
Related:	AR

Property:	CS (circle stone)
Propvalue:	list of stone
Propertytype:	-
Function:	Marks the given stones, each with a circle.
Related:	CR

Property:	MS (mark stone)
Propvalue:	list of stone
Propertytype:	-
Function:	Marks the given stones, each with an ex.
Related:	MA

Property:	SS (square stone)
Propvalue:	list of stone
Propertytype:	-
Function:	Marks the given stones, each with a square.
Related:	SQ

Property:	TS (triangle stone)
Propvalue:	list of stone
Propertytype:	-
Function:	Marks the given stones, each with a triangle.
Related:	TR

Property:	RP (remove pod)
Propvalue:	list of stone
Propertytype:	setup
Function:	Removes a stone from the board.
		More selective than AddEmpty.
Related:	AE

Backgammon properties
Gametype:       6

Property:       CO
Propvalue:      simpletext
Propertytype:   setup
Function:       Set the position of the doubling cube.  The value
                should be `b' (black), `w' (white), `c' (centred), or `n'
                (none -- for cubeless or Crawford games).
Related:        CV

Property:       CV
Propvalue:      number
Propertytype:   setup
Function:       Set the value of the doubling cube.  This value
                defaults to 1 at the beginning of the game, but a CV property
                should be added when setting up a position where a double has
                been made, or at the beginning of a money game if automatic
                doubles occur.
Related:        CP

Property:       DI
Propvalue:      number
Propertytype:   setup
Function:       Set the dice without moving (this could be useful for
                creating problem positions, e.g. DI[31])
Related:        CO

Property:       MI
Propvalue:      list of composed simpletext ':' simpletext
Propertytype:   game-info
Function:       Specifies information about the match the game belongs to.
                This property should specify a list of tag/value pairs, where
                the allowable tags are case-insensitive, and include:

                  length - the match length (number of points); value should
                           be a number
                  game   - the number of this game within the match (the
                           first game is 1); value should be a number
                  bs     - the score for Black at the start of the game;
                           value should be a number
                  ws     - the score for White at the start of the game;
                           value should be a number

                Unknown tags should be ignored (a warning may be produced).
                The order of tags in the list is not significant.  An example
                MI property is:
                                  MI[length:7][game:3][ws:2][bs:1]
Related:        EV, GN, RE, RO

Property:       RE
Propvalue:      simpletext
Propertytype:   game-info
Function:       The general RE property has the following
                modification in backgammon games: in the case of a
                resignation, the value should also specify the number of
                points before the R(esign).  Here are three example RE
                properties:

                        RE[B+6R]      -- White resigns a backgammon on a 2
                                         cube (worth 6 points).
                        RE[W+2Resign] -- Black resigns a gammon on a 1 cube
                                         (worth 2 points).
                        RE[W+4]       -- Black drops a redouble to 8 (note
                                         this is considered a normal loss, not
                                         a resignation).
Related:        RE

Property:       RU
Propvalue:      simpletext
Propertytype:   game-info
Function:       Backgammon-specific values for the general RU property
                include the following:

                  [Crawford] -- the Crawford rule is being used in this match,
                    although this is not the Crawford game.
                  [Crawford:CrawfordGame] -- this IS the Crawford game.
                  [Jacoby] -- the Jacoby rule is in use for this game.
Related:        RU

Lines of Action properties
Gametype:	9

Property:	AS
Propvalue:	SimpleText
Propertytype:	-
Function:	Adding stones - the color of the player who is adding
		stones to the board. The valid strings are 'Black', 'White'
		or 'None'. The puropse of this property is to define a
		board position where the human is expected to continue placing
		stones on the board through some user interface.

Property:	IP
Propvalue:	SimpleText
Propertytype:	game-info
Function:	Designates the initial position in the game to be
		displayed by the viewer.
		The only value currently supported is 'End', which causes
		the viewer to initially display the final position of the game.
		The default is to display the position after setup but before
		any moves.

Property:	IY
Propvalue:	SimpleText
Propertytype:	game-info
Function:	Invert Y axis.  Values are 'true' or 'false'.
		If 'true', the board should be displayed with numbers
		increasing in value from bottom to top of the screen.
		Default: 'false'

Property:	SE
Propvalue:	point
Propertytype:	-
Function:	Mark the given point and up to 8 additional points,
		depending on where the provided point (stone) could legally
		move.

Property:	SU
Propvalue:	SimpleText
Propertytype:	game-info
Function:	Setup type - designates the intial placement of pieces,
		and also the implicitly the variation on the basic rules to be
		employed. The currently valid values include the following
		strings:
		'Standard', 'Scrambled-eggs', 'Parachute', 'Gemma' and 'Custom'
		(the initial board is empty, AB and AW properties
		will be used to establish the starting position).
		Default: 'Standard'
                For details on the setups and rule variations, consult the
		LOA home pages.

Hex properties
Gametype:	11

Property:	IS
Propvalue:	list of composed SimpleText ':' SimpleText
Propertytype:	root
Function:	This property allows applications to store and read
		an initial viewer setting. The property value is a list of
		"keyword followed by ':' followed by either 'on' or 'off'".
		Valid keywords are:
		  'tried' - identify future moves that have been tried?
		  'marked' - show good/bad move markings?
		  'lastmove' - identify the last cell played?
		  'headings' - display column/row headings (a b.., 1 2..)?
		  'lock' - lock the game against new moves (for analysis)?
		This property is allowed in the root node only.
		Example: IS[tried:on][lock:off][marked:off]

Property:	IP
Propvalue:	SimpleText
Propertytype:	game-info
Function:	Designates the initial position that the viewer
		should display. It will most frequently indicate the
		current position of play in the game. This is necessary 
		because future possible moves may have been explored,
		and the user must be able to distinguish real moves
		actually made from exploratory moves. More than one IP[]
		property in a game is illegal, and the behaviour undefined.
		The property value should be empty (""); it is specified
		as SimpleText for compatibility.

Amazons properties
Gametype:	18

Property:	AA
Propvalue:	list of point
Propertytype:	setup
Function:	Adding arrows to the board. This can be used to set up
		positions or problems.

End:	this marks the end

