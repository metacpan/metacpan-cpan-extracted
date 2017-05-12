package Games::SGF;

use strict;
use warnings;
use Carp qw(carp croak confess);
use enum qw( 
         :C_=1 BLACK WHITE
         :DBL_=1 NORM EMPH
         :V_=1 NONE NUMBER REAL DOUBLE COLOR SIMPLE_TEXT TEXT POINT MOVE STONE
         BITMASK:VF_=0 NONE EMPTY LIST OPT_COMPOSE
         :T_=1 MOVE SETUP ROOT GAME_INFO NONE
         :A_=1 NONE INHERIT
         );
#use Clone::PP;

=head1 NAME

Games::SGF - A general SGF parser

=head1 VERSION

Version 0.993

=cut


our $VERSION = 0.993;
my( %ff4_properties ) = (
   # general move properties
   'B' => { 'type' => T_MOVE, 'value' => V_MOVE },
   'BL' => { 'type' => T_MOVE, 'value' => V_REAL },
   'BM' => { 'type' => T_MOVE, 'value' => V_DOUBLE },
   'DO' => { 'type' => T_MOVE, 'value' => V_NONE },
   'IT' => { 'type' => T_MOVE, 'value' => V_NONE },
   'KO' => { 'type' => T_MOVE, 'value' => V_NONE },
   'MN' => { 'type' => T_MOVE, 'value' => V_NUMBER },
   'OB' => { 'type' => T_MOVE, 'value' => V_NUMBER },
   'OW' => { 'type' => T_MOVE, 'value' => V_NUMBER },
   'TE' => { 'type' => T_MOVE, 'value' => V_DOUBLE },
   'W' => { 'type' => T_MOVE, 'value' => V_MOVE },
   'WL' => { 'type' => T_MOVE, 'value' => V_REAL },

   # general setup properties
   'AB' => { 'type' => T_SETUP, 'value' => V_STONE, 'value_flags' => VF_LIST },
   'AE' => { 'type' => T_SETUP, 'value' => V_POINT, 'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'AW' => { 'type' => T_SETUP, 'value' => V_STONE, 'value_flags' => VF_LIST },
   'PL' => { 'type' => T_SETUP, 'value' => V_COLOR },

   # genreal none inherited properties
   'DD' => { 'type' => T_NONE, 'value' => V_POINT, 
             'value_flags' => VF_EMPTY | VF_LIST | VF_OPT_COMPOSE,
             'attrib' => A_INHERIT },
   'PM' => { 'type' => T_NONE, 'value' => V_NUMBER, 'attrib' => A_INHERIT },
   'VW' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_EMPTY | VF_LIST | VF_OPT_COMPOSE, 
             'attrib' => A_INHERIT },

   # general none properties
   'AR' => { 'type' => T_NONE, 'value' => [V_POINT,V_POINT], 
             'value_flags' => VF_LIST },
   'C' => { 'type' => T_NONE, 'value' => V_TEXT },
   'CR' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'DM' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'FG' => { 'type' => T_NONE, 'value' => [V_NUMBER,V_SIMPLE_TEXT],
             'value_flags' => VF_EMPTY },
   'GB' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'GW' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'HO' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'LB' => { 'type' => T_NONE, 'value' => [V_POINT,V_SIMPLE_TEXT],
             'value_flags' => VF_LIST },
   'LN' => { 'type' => T_NONE, 'value' => [V_POINT,V_POINT],
             'value_flags' => VF_LIST },
   'MA' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_EMPTY | VF_LIST | VF_OPT_COMPOSE },
   'N' => { 'type' => T_NONE, 'value' => V_SIMPLE_TEXT },
   'SL' => { 'type' => T_NONE, 'value' => V_POINT, 
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'SQ' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'TR' => { 'type' => T_NONE, 'value' => V_POINT, 
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'UC' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'V' => { 'type' => T_NONE, 'value' => V_REAL },

   # general root properties
   'AP' => { 'type' => T_ROOT, 'value' => [V_SIMPLE_TEXT, V_SIMPLE_TEXT] },
   'CA' => { 'type' => T_ROOT, 'value' => V_SIMPLE_TEXT },
   'FF' => { 'type' => T_ROOT, 'value' => V_NUMBER },
   'GM' => { 'type' => T_ROOT, 'value' => V_NUMBER },
   'ST' => { 'type' => T_ROOT, 'value' => V_NUMBER },
   'SZ' => { 'type' => T_ROOT, 'value' => V_NUMBER, 
             'value_flags' => VF_OPT_COMPOSE},

   # general game-info properties
   'AN' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'BR' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'BT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'CP' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'DT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'EV' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'GC' => { 'type' => T_GAME_INFO, 'value' => V_TEXT },
   'GN' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'ON' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'OT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'PB' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'PC' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'PW' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'RE' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'RO' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'RU' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'SO' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'TM' => { 'type' => T_GAME_INFO, 'value' => V_REAL },
   'US' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'WR' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'WT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
);

=head1 SYNOPSIS

  use Games::SGF;

  my $sgf = new Games::SGF();

  $sgf->setStoneRead( sub { "something useful"} );
  $sgf->setMoveRead( sub { "something useful"} );
  $sgf->setPointRead( sub { "something useful"} );

  $sgf->addTag('KM', $sgf->T_GAME_INFO, $sgf->V_REAL );
  $sgf->readFile("015-01.sgf");
  $sgf->setProperty( "AP", $sgf->compose("MyApp", "Version 1.0") );

=head1 DISCRIPTION

Games::SGF is a general Smart Game Format Parser. It parses
the file, and checks the properties against the file format 4
standard. No game specific features are implemented, but can be
added on in inheriting classes.

It is designed so that the user can tell the parser how to handle new
tags. It also allows the user to set callbacks to parse Stone,
Point, and Move types. These are game specific types.

=head2 SGF Structure

SGF file contains 1 or more game trees. Each game tree consists of a sequence
of nodes followed by a sequence of variations. Each variation also consists a
sequence of nodes followed by a sequence of variations.

Each node contains a set of properties. Each property has a L</Type>, L</Value Type>,
L</Flags>, and an L</Attribute>. 

=head2 Interface

The interface is broken into 3 conceptal parts

=over

=item SGF Format

This is the straight SGF Format which is saved and read using L</IO> methods.

=item User Format

This is the format that the Games::SGF user will come in contact with. Various
methods will convert the Uwer Format into the Internal Format which Games::SGF
actually deals with.

These can take the form of Constants:

=over 

=item Double Values: DBL_NORM and DBL_EMPH

=item Color Values: C_BLACK and C_WHITE

=back

Or with converstion methods:

=over

=item L</compose>

=item L</move>

=item L</stone>

=item L</point>

=back

=item Internal Format

If this format differs from the others, you don't need to know.

=back

Also see: L<http://www.red-bean.com/sgf>

=head1 METHODS

=head2 new

  new Games::SGF(%options);

Creates a SGF object.

Options that new will look at.

=over

=item Fatal

=item Warn

=item Debug

These options operate in the same fashion. There are 3 value cases that it
will check. If the value is a code reference it will  ccall that subroutine
when the event occurs with the event strings passed to it. If the value is
true then it croak on Fatal, and carp on Warn or Debug. If the value is
false it will be silent. You will still be able to get the error strings
by calling L</Fatal>, L</Warn>, or L</Debug>.


=back

=cut

sub new {
   my $inv = shift;
   my $class = ref( $inv) || $inv;
   my( %opts ) = @_;
   my $self = {};
   # stores added tags
   $self->{'tags'} = {};
   # stores stone, point, move handling subroutines
   $self->{'game'} = undef; 
   $self->{'collection'} = undef; 
   $self->{'parents'} = undef;
   $self->{'address'} = undef; 
   $self->{'node'} = undef;


   # Default Warnings and Debug statments to silence

   $self->{'Fatal'} = exists $opts{'Fatal'} ? $opts{'Fatal'} : 1;
   $self->{'Warn'} = exists $opts{'Warn'} ? $opts{'Warn'} : 0;
   $self->{'Debug'} = exists $opts{'Debug'} ? $opts{'Debug'} : 0;
   $self->{'FatalErrors'} = [];
   $self->{'WarnErrors'} = [];
   $self->{'DebugErrors'} = [];
   return bless $self, $class;
}

=head2 clone

  $sgf_copy = $sgf->clone;

This will create a completely independent copy of the C<$sgf> object.

=cut

sub clone {
   my $self = shift;
   return Clone::PP::clone($self);
}

=head2 IO

=head3 readText

  $sgf->readText($text);

This takes in a SGF formated string and parses it.

=cut

sub readText {
   my $self = shift;
   my $text = shift;
   $self->_clear;
   $self->Debug("readText( <TEXT> )");
   $self->_read($text);
   if( $self->Fatal ) {
   $self->Debug("readText( <TEXT> ) FAILED ");
      return 0;
   } else {
      $self->{'game'} = 0; # first branch
      $self->gotoRoot;
   }
   return 1;
}

=head3 readFile

  $sgf->readFile($file);

This will open the passed file, read it in then parse it.

=cut

sub readFile {
   my $self = shift;
   my $filename = shift;
   $self->_clear;
   $self->Debug("readFile( '$filename' )" );
   my $text;
   my $fh;
   if( not open $fh, "<", $filename ) {
      $self->Fatal( "readFile( $filename ): FAILED on open\t\t$!" );
      return 0;
   }
   if(read( $fh, $text, -s $filename) == 0 ) {
      $self->Fatal( "readFile( $filename ): FAILED on read\t\t$!" );
      return 0;
   }
   close $fh;
   return $self->readText($text) ;
}

=head3 writeText

  $sgf->writeText;

Will return the current collection in SGF form;

=cut

sub writeText {
   my $self = shift;
   $self->_clear;
   $self->Debug("writeText( <TEXT> )");
   my $text = "";
   # foreach game
   foreach my $game ( @{$self->{'collection'}}) {
      # write branch
      $text .= $self->_write($game);
      if( $self->Fatal) {
         return 0;
      }
      $text .= "\n";
   }
   $self->Debug( "write Text:\t\t$text\n");
   return $text;
}

=head3 writeFile

  $sgf->writeFile($filename);

Will write the current game collection to $filename.

=cut

sub writeFile {
   my $self = shift;
   my $filename = shift;
   $self->_clear;
   $self->Debug("writeFile( '$filename' )" );
   my $text;
   my $fh;
   if( not open $fh, ">", $filename ) {
      $self->Fatal("writeFile( $filename ): FAILED on open\t\t$!");
      return 0;
   }
   print $fh $self->writeText;
   close $fh;
   if( $self->Fatal ) {
      return 0;
   }
   return 1;
}

=head2 Property Manipulation

=head3 addTag

  $sgf->addTag($tagname, $type, $value_type, $flags, $attribute);

This add a new tag to the parsing engine. This needs to called before the read
or write commands are called. This tag will not override the FF[4] standard
properties, or already defined properties.

The C<$tagname> is the name of the tag which will be read in, thus if you want
to be able to read AAA[...] from an SGF file the tagname needs to be "AAA".

The C<$type> needs to be choosen from the L</Type> list below. Defaults to
C<T_NONE>.

The C<$value_type> needs to be choosen from the L</Type> list below.
Defaults to C<V_TEXT>.

The C<$flags> are from the L</Flags> List. Defaults to C<VF_EMPTY | VF_LIST>.

The C<$attribute> is from the L</Attribute> List. Defaults to C<A_NONE>.

=cut

sub addTag {
   my $self = shift;
   my $tagname = shift;
   unless( $tagname =~ /^[a-zA-Z]+$/ ) {
      $self->Fatal("addTag( $tagname ): FAILED\t\t$tagname is of invalid format should pass /^[a-zA-Z]+\$/" );
      return 0;
   }
   $self->_clear;
   $self->Debug("addTag($tagname, " . join( ", ", @_ ) . " )" );
   if( exists $self->{'tags'}->{$tagname} or exists $ff4_properties{$tagname}) {
      $self->Fatal("addTag( $tagname ): FAILED\t\t$tagname already exists");
      return 0;
   }
   $self->{'tags'}->{$tagname}->{'type'} = shift;
   $self->{'tags'}->{$tagname}->{'value'} = shift;
   $self->{'tags'}->{$tagname}->{'value_flags'} = shift;
   $self->{'tags'}->{$tagname}->{'attrib'} = shift;

   return 1;
}

=head3 redefineTag

  $sgf->redefineTag($tag, $type, $value, $value_flags, $attribute);

This will overwrite the flags set for C<$tagname>. If one of the args is unset,
it will be unaltered. For example:

  $sgf->redefineTag($tag, , , $flags);

Will reset C<$tag>'s $flags leaving all other properties untouched.

The property fields are the same defined the same as L</addTag>.

=cut

sub redefineTag {
   my $self = shift;
   $self->_clear;
   {
      my(@args ) = @_;
      foreach(@args) {
         $_ = "undef" unless defined $_;
      }
      $self->Debug("redefineTag(" . join( ", ", @args ) . " )" );
   }
   my $tagname = shift;

   unless( $tagname =~ /^[a-zA-Z]+$/ ) {
      $self->Fatal("redefineTag($tagname, " . join( ", ", @_ ) . " )" .
            ": FAILED\t\t$tagname is of invalid format should pass /^[a-zA-Z]+\$/" );
      return 0;
   }
   my $type = shift;
   my $value = shift;
   my $value_flags = shift;
   my $attrib = shift;
   if(exists $ff4_properties{$tagname} ) {# ff4_properties
      $self->{'tags'}->{$tagname}->{'type'} = defined $type ? $type : $ff4_properties{$tagname}->{'type'};
      $self->{'tags'}->{$tagname}->{'value'} = defined $value ? $value :  $ff4_properties{$tagname}->{'value'};
      $self->{'tags'}->{$tagname}->{'value_flags'} = defined $value_flags ? $value_flags : $ff4_properties{$tagname}->{'value_flags'};
      $self->{'tags'}->{$tagname}->{'attrib'} = defined $attrib ? $attrib : $ff4_properties{$tagname}->{'attrib'};
      return 1;
   } elsif( exists $self->{'tags'}->{$tagname} ) {

      $self->{'tags'}->{$tagname}->{'type'} = $type if defined $type; 
      $self->{'tags'}->{$tagname}->{'value'} = $value if defined $value;
      $self->{'tags'}->{$tagname}->{'value_flags'} = $value_flags if defined $value_flags;
      $self->{'tags'}->{$tagname}->{'attrib'} = $attrib if defined $attrib;
      return 1;
   } else {
      $self->Fatal("redefineTag($tagname, " . join( ", ", @_ ) . " )" .
            ": FAILED\t\t$tagname does not exist" );
      return 0;
   }

   return 1;
}


=head3 setPointRead

=cut


sub setPointRead {
   my $self = shift;
   my $coderef = shift;
   $self->_clear;
   if( exists( $self->{'pointRead'} )) {
      $self->Fatal("setPointRead( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointRead'} = $coderef;
   } else {
      $self->Fatal("setPointRead( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 setMoveRead

=cut

sub setMoveRead {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'moveRead'} )) {
      $self->Fatal("setMoveRead( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveRead'} = $coderef;
   } else {
      $self->Fatal("setMoveRead( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 setStoneRead

  $sgf->setPointRead(\&coderef);
  $sgf->setMoveRead(\&coderef);
  $sgf->setStoneRead(\&coderef);

These call backs are called when a properties value needs to be parsed.
It takes in a string, and returns a structure of some type. Here is a
possible example for a Go point callback:

  sub parsepoint {
     my $value = shift;
     my( $x, $y) = split //, $value;
     return [ ord($x) - ord('a'), ord($y) - ord('a') ];
  }
  # then somewhere else
  $sgf->setPointParse( \&parsepoint );

Note: that you should do more then this in practice, but it gets the
across.

If the value is an empty string and VF_RMPTY is set then the call back will
not be called but return an empty string.

=cut

sub setStoneRead {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'stoneRead'} )) {
      $self->Fatal("setStoneRead( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneRead'} = $coderef;
   } else {
      $self->Fatal("setStoneRead( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}


=head3 setPointCheck

=cut


sub setPointCheck {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'pointCheck'} )) {
      $self->Fatal("setPointCheck( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointCheck'} = $coderef;
   } else {
      $self->Fatal("setPointCheck( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 setMoveCheck

=cut

sub setMoveCheck {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'moveCheck'} )) {
      $self->Fatal("setMoveCheck( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveCheck'} = $coderef;
   } else {
      $self->Fatal("setMoveCheck( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 setStoneCheck

  $sgf->setPointCheck(\&coderef);
  $sgf->setMoveCheck(\&coderef);
  $sgf->setStoneCheck(\&coderef);

This callback is called when a parameter is stored. The callback takes
the structure passed to setProperty, or component if composed, and returns
true if it is a valid structure.

An Example of a stone check for go is as follows:

  sub stoneCheck {
     my $stone = shift;
     if( ref $stone eq 'ARRAY' and @$stone == 2
            and $stone->[0] > 0 and $stone->[1] > 0 ) {
         return 1;
     } else {
         return 0;
     }
  }

If the value is an empty string it will be passed to the check callback
only if VF_EMPTY is not set.

=cut

sub setStoneCheck {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'stoneCheck'} )) {
      $self->Fatal("setStoneCheck( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneCheck'} = $coderef;
   } else {
      $self->Fatal("setStoneCheck( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 setPointWrite

=cut


sub setPointWrite {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'pointWrite'} )) {
      $self->Fatal("setPointWrite( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointWrite'} = $coderef;
   } else {
      $self->Fatal("setPointWrite( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 setMoveWrite

=cut

sub setMoveWrite {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'moveWrite'} )) {
      $self->Fatal("setMoveWrite( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveWrite'} = $coderef;
   } else {
      $self->Fatal("setMoveWrite( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 setStoneWrite

  $sgf->setPointWrite(\&coderef);
  $sgf->setMoveWrite(\&coderef);
  $sgf->setStoneWrite(\&coderef);

This callback is called when a parameter is written in text format. The callback takes
the structure passed to setProperty, or component if composed, and returns
the text string which will be stored.

An Example of a stone check for go is as follows:

  sub stoneWrite {
     my $stone = shift;
     my @list = ('a'..'Z','A'..'Z');
     return $list[$stone->[0] - 1] . $list[$stone->[1] - 1];
  }

If the tag value is an empty string it will not be sent to the write callback, but immedeitely be returned as an empty string.

=cut

sub setStoneWrite {
   my $self = shift;
   $self->_clear;
   my $coderef = shift;
   if( exists( $self->{'stoneWrite'} )) {
      $self->Fatal("setStoneWrite( <coderef> ): FAILED\t\t<coderef> already exists");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneWrite'} = $coderef;
   } else {
      $self->Fatal("setStoneWrite( <coderef> ): FAILED\t\t<coderef> is not a CODE Reference");
      return 0;
   }
   return 1;
}

=head3 getTagFlags

  $flags = getTagFlags($tag);
  if( $flags & VF_LIST ) {
     # do something about lists
  }

This will return the flags set on this tag.

=cut

sub getTagFlags {
   my $self = shift;
   my $tag = shift;
   if( exists( $self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'value_flags'} ) {
         return $self->{'tags'}->{$tag}->{'value_flags'};
      } else {
         return 0;
      }
   } elsif( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'value_flags'} ) {
         return $ff4_properties{$tag}->{'value_flags'};
      } else {
         return 0;
      }
   }
   # default flags
   return (VF_EMPTY | VF_LIST); # allow to be empty or list
}

=head3 getTagType

  $flags = getTagType($tag);
  if( $flags & T_NONE ) {
     # do something about T_NONE tags
  }

This will return the flags set on this tag.

=cut


sub getTagType {
   my $self = shift;
   my $tag = shift;
   if( exists( $self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'type'} ) {
         return $self->{'tags'}->{$tag}->{'type'};
      }
   } elsif( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'type'} ) {
         return $ff4_properties{$tag}->{'type'};
      }
   }
   # default Type
   return T_NONE; # allow to be anywhere
}

=head3 getTagAttribute

  $flags = getTagAttribute($tag);
  if( $flags & A_NONE ) {
     # do something about about no attributes
  }

This will return the flags set on this tag.

=cut


sub getTagAttribute {
   my $self = shift;
   my $tag = shift;
   if( exists($self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'attrib'} ) {
         return $self->{'tags'}->{$tag}->{'attrib'};
      }
   } elsif( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'attrib'} ) {
         return $ff4_properties{$tag}->{'attrib'};
      }
   }
   return A_NONE; # don't set inherit
}

=head3 getTagValueType

  $valuetype = getTagValueType($tag);
  if( $flags & V_TEXT ) {
     # do something about text
  }

This will return the flags set on this tag.

=cut


sub getTagValueType {
   my $self = shift;
   my $tag = shift;
   if( exists( $self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'value'} ) {
         return $self->{'tags'}->{$tag}->{'value'};
      }
   } elsif( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'value'} ) {
         return $ff4_properties{$tag}->{'value'};
      }
   }
   return V_TEXT; # allows and preserves any string
}


=head2 Navigation

=head3 nextGame

  $sgf->nextGame;

Sets the node pointer to the next game in the Collection. If the current
game is the last game then returns 0 otherwise 1.

=cut

sub nextGame {
   my $self = shift;
   $self->_clear;
   $self->Debug("nextGame( )");
   my $lastGame = @{$self->{'collection'}} - 1;
   my $curGame = $self->{'game'}; # first element is the address game num
   if( $curGame >= $lastGame ) { # on last game
      $self->Warn("nextGame(  ): FAILED\t\tCurrently last game in collection");
      return 0;
   } else {
      $self->{'game'}++;
      $self->gotoRoot;
      return 1;
   }
}

=head3 prevGame;

  $sgf->prevGame;

Sets the node pointer to the prevoius game in the Collection. If the current
game is the first game then returns 0 otherwise 1.

=cut


sub prevGame {
   my $self = shift;
   $self->_clear;
   $self->Debug("prevGame( )");
   my $curGame = $self->{'game'}; # first element is the address game num
   if( $curGame <= 0 ) { # on first game
      $self->Warn("nextGame(  ): FAILED\t\tCurrently first game in collection");
      return 0;
   } else {
      $self->{'game'}--;
      $self->gotoRoot;
      return 1;
   }
}

=head3 game

  $sgf->game; # returns the game number
  $sgf->game($number); # sets the game to $number

=cut

sub game {
   my $self = shift;
   my $game = shift;
   $self->_clear;
   $self->Debug("game( $game )");

   if( defined $game ) {
      unless($game >= 0 and $game < @{$self->{'collection'}} ) {
         $self->Warn( "game( $game ): FAILED\t\t$game does not exist");
         return 0;
      }
      $self->{'game'} = $game;
      $self->gotoRoot;
      return 1;
   } else {
      return scalar @{$self->{'collection'}};
   }
}


=head3 gotoRoot

  $sgf->gotoRoot;

This will move the pointer to the root node of the game tree.

=cut

sub gotoRoot {
   my $self = shift;
   $self->_clear;
   $self->Debug("gotoRoot( )");
   #$self->{'parents'} = [ $self->{'collection'}->[$self->{'game'}] ];
   $self->{'address'} = [$self->{'game'}];
   $self->{'node'} = $self->{'collection'}->[$self->{'game'}];
}

=head3 next

  $sgf->next;

Moves the node pointer ahead one node. If there are variations it will move
down the main tree path.

Returns 0 if it is the last node, otherwise 1

=cut

sub next {
   my $self = shift;
   $self->_clear;
   $self->Debug("next( )");
   return $self->gotoBranch(0);
}

=head3 prev

  $sgf->prev;

Moves the node pointer back one node. Will move back out of
variations.

Returns 0 if root node of tree

=cut

sub prev {
   my $self = shift;
   $self->_clear;
   $self->Debug("prev( )");
   if( $self->{'node'}->{'parent'} ) { # if parent exist
      $self->{'node'} = $self->{'node'}->{'parent'};
      pop @{$self->{'address'}};
      return 1;
   } else { # you are at the root
      $self->Warn("prev( ):\t\tYou are at the root");
      return 0;
   }
}

=head3 branches

  $sgf->branches;

Returns the number of variations for the next move. If there is only the
main game path then it will return 1, if there are no more moves left in the
branch it will return 0.

=cut

sub branches {
   my $self = shift;
   $self->_clear;
   $self->Debug("branches( )");
   return scalar @{$self->{'node'}->{'branches'}};
}

=head3 gotoBranch

  $sgf->gotoBranch($n);

Goes to the first node of the specified Variation. If it returns 4
that means that there is variations C<0..3>,

Returns 1 on success and 0 on Failure.

=cut

sub gotoBranch {
   my $self = shift;
   my $n = shift;
   $self->_clear;
   $self->Debug("gotoBranch( $n )");
   if( not defined $n ) { return 0;}
   if( $n <  $self->branches and $n >= 0) {
      $self->{'node'} = $self->{'node'}->{'branches'}->[$n];
      push @{$self->{'address'}}, $n;
      return 1;
   } elsif( $n == 0 ) {
      $self->Warn("gotoBranch( $n ):\t\tNo more moves");
      return 0;
   } else {
      $self->Warn("gotoBranch( $n ):\t\tInvalid Branch");
      return 0;
   }
}

=head3 getAddress

  my $address = $sgf->getAddress;

  # some movement
  
  $sgf->goto($address);

This function returns an address of your location in the sgf object. It can then be latter
recalled by using the goto method.

=cut

sub getAddress {
   my $self = shift;
   $self->Debug("getAddress( ):\t(". join( ", ", @{$self->{'address'}}) . ")");
   return [@{$self->{'address'}}];
}

=head3 goto

   
goto will recall a position inside of an sgf object. Use getAddress returns an address.

=cut

sub goto {
   my $self = shift;
   $self->Debug("goto( " . join( ", ", @{$_[0]}) . " )");
   my( @add ) = @{shift @_};
   $self->game(shift @add);

   for(@add) {
      $self->gotoBranch($_);
   }
   return 1;
}

###
#
#  TODO: add getAddress and goto address
#        the address could be a sequence of variation numbers
#        followed by a node number.
#        [var_num ...] node_num


#######
#
#  SGF Manipulation needs restructuring so that it is easier to use, and can be
#     used in conjunction with navigation functions. 
#
#
#     The public functions should be as follows:
#        addGame
#        removeGame
#        addNode
#        removeNode
#        removeBranch
#        
#     The movement functions should be
#        nextGame
#        prevGame
#        next
#        prev
#        getVariations
#        gotoBranch
#
#        movement and manipulation functions should be independant of
#        internal storage structure.

=head2 SGF Manipulation

=head3 addGame

  $self->addGame;

This will add a new game to the collection with the root node added. The
current node pointer will be set to the root node of the new game.

Returns true on success.

=cut

sub addGame {
   my $self = shift;
   $self->_clear;
   $self->Debug("addGame( )");
   my $newGame = _newNode();
   push @{$self->{'collection'}}, $newGame;
   $self->{'game'} = @{$self->{'collection'}} - 1;
   $self->{'node'} = $newGame;
   $self->gotoRoot();
   if( $self->Fatal ) {
      return 0;
   } else {
      return 1;
   }
}

=head3 addNode

  $sgf->addNode;

Adds a node into the game tree. if there is already a continuation of
the branch, then it will add a variation at this point. The node pointer
will be set to the new node.

Returns 1 on success and 0 on Failure.

=cut

sub addNode {
   my $self = shift;
   $self->_clear;
   $self->Debug("addNode( )");
   my $node = _newNode($self->{'node'}); # use current node as parent
   # add new node to branches of current
   my $variations = $self->branches;
   $self->{'node'}->{'branches'}->[$variations] = $node;
   # move to new position
   return $self->gotoBranch($variations);
}


=head3 removeNode

  $sgf->removeNode;

Removes current node from tree if it has no sub nodes. If removed
calls C<$sgf->prev> node.

Returns 1 on success and 0 on Failure.

=cut

sub removeNode {
   my $self = shift;
   $self->_clear;
   $self->Debug("removeNode( )");
   if( @{$self->{'node'}->{'branches'}} ) { # 
      $self->Warn("removeNode(  ): FAILED\t\tCan not remove, since moves after which need to be removed.");
      return 0;
   } else {
      # remove current node and move to parent.\
      # save current node
      # goto prev
      # look at branches for saved node and remove
      my $rem = $self->{'node'};
      $self->prev;
      for( my $i = 0; $i < @{$self->{'node'}->{'branches'}};$i++) {
         if( $rem == $self->{'node'}->{'branches'}->[$i] ) {
            splice @{$self->{'node'}->{'branches'}}, $i, 1;
            return 1;
         }
      }
      $self->Fatal("removeNode( ):\t\tLogical failure. Node to be removed Does Not Exist");
      return 0;
   }
}

=head3 property

  my( @tags ) = $sgf->property;
  my $array_ref = $sgf->property( $value );
  my $didSave = $sgf->property( $value , @values );

This is used to read and set properties on the current node. Will prevent T_MOVE
and T_SETUP types from mixing. Will prevent writing T_ROOT tags to any location
other then the root node. Will Lists from being stored in non list tags. Will
prevent invalid structures from being stored.

If no options are given it will return all the tags set on this node. Inherited
tags will only be returned if they were set on this node.

=cut

#  returns 0 on error
#  returns 1 on successful set
#  returns $arrref on successful get
sub property {
   my $self = shift;
   $self->_clear;
   $self->Debug("property( " . join( ", ", @_) .")");
   my $tag = shift;
   my( @values ) = @_;
   if( not defined $tag ) {
      # return only tags on this node
      return keys %{$self->{'node'}->{'tags'}};
  } elsif( @values == 0 ) {
      #get
      return $self->getProperty($tag);
   } else {
      #set
      return $self->setProperty($tag,@values);
   }
}

=head3 getProperty

  my $array_ref = $sgf->getProperty($tag, $isStrict);
  if( $array_ref ) {
      # sucess
      foreach my $value( @$array_ref ) {
          # do something
      }
  } else {
      # failure
  }

Will fetch the the $tag value stored in the current node.

$isStrict is for fetching inherited tags, if set it will only return an
inherited tag if it is actually set on that node.

=cut

sub getProperty {
   my $self = shift;
   $self->_clear;
   $self->Debug("getProperty( " . join( ", ", @_) .")");
   my $tag = shift;
   my $isStrict = shift;
   my $attri = $self->getTagAttribute($tag);

   if( $attri == A_INHERIT and not $isStrict) {
      my $node = $self->{'node'};
      {
         if( exists $node->{'tags'}->{$tag} ) {
            return $node->{'tags'}->{$tag};
         } elsif($node->{'parent'}) {
            $node = $node->{'parent'};
            redo;
         }
      }
      $self->Warn( "getProperty( $tag ): FAILED\t\tInherited $tag is not set" );
      return 0;
  } else {
      if( exists $self->{'node'}->{'tags'}->{$tag} ) {
         return $self->{'node'}->{'tags'}->{$tag};
      } else {
         # non existent $tag
         $self->Warn( "getProperty( $tag ): FAILED\t\t$tag is not set" );
         return 0;
      }
   }
}

=head3 setProperty

  fail() unless $sgf->setProperty($tag,@values);

Sets the the $tag value of the current node to @values. This method does
a series of sanity checks before attempting to write. It will fail if any
of the following are true:

=over

=item @values > 0 and is not a list

=item $tag is of type T_ROOT but the current node is not the root node

=item $tag is a T_MOVE or T_SETUP and the other type is already present in the node

=item @values are invalid type values

=item unseting a value that is not set.

=back

If @values is not passed then it will remove the property from the node.
This is not the same as setting to a empty value.

  $sgf->setProperty($tag); # will unset the $tag
  $sgf->setProperty($tag, "" ); # will set to an empty value

=cut

sub setProperty {
   my $self = shift;
   $self->_clear;
   $self->Debug("setProperty( " . join( ", ", @_) .")");
   my $tag = shift;
   my( @values ) = @_;
   my $isUnSet = (scalar @values == 0) ? 1 : 0; # is unset if empty

   my $ttype = $self->getTagType($tag);
   my $vtype = $self->getTagValueType($tag);
   my $flags = $self->getTagFlags($tag);
   my $attri = $self->getTagAttribute($tag);
   my $isComposable = $self->_maybeComposed($tag);


   if( $isUnSet ) {
      if( exists $self->{'node'}->{'tags'}->{$tag} ) {
         delete $self->{'node'}->{'tags'}->{$tag};
         return 1;
      } else {
         $self->Warn("setProperty( \"$tag\", \"". join('", "',@values) . "\" ): FAILED\t\tCan't unset inherited $tag when not set at this node\n");
         return 0;
      }
   }


   # reasons to not set the property
   # set list values only if VF_LIST
   # TODO: VF_LIST && VF_EMPTY????
   if( @values > 1 and not $flags & VF_LIST ) {
      $self->Warn("setProperty( \"$tag\", \"". join('", "',@values) . "\" ): FAILED\t\tCan't set list for non VF_LIST: ($tag, $flags : " . 
         join( ":", VF_EMPTY, VF_LIST, VF_OPT_COMPOSE) . ")");
      return 0;
   }
   # can set T_ROOT if you are at root

   if( $ttype == T_ROOT and (0 != $self->{'node'}->{'parent'}) ) {
      $self->Warn("setProperty( \"$tag\", \"". join('", "',@values) . "\" ): FAILED\t\tCan't set T_ROOT($tag) when not at root");
      return 0;
   }
   # don't set T_MOVE or T_SETUP if other is present
   #  ASSUMPTION: No Inherited property is a T_MOVE or T_SETUP
   my $tnode = undef;
   foreach( keys %{$self->{'node'}->{'tags'}} ) {
      my $tag_type = $self->getTagType($_);
      if( $tnode ) {
         if( ($tnode == T_SETUP and $tag_type == T_MOVE)
               or ($tnode == T_MOVE and $tag_type == T_SETUP) ) {
            $self->Warn("setProperty( \"$tag\", \"". join('", "',@values) . "\" ): FAILED\t\tCan't mix T_SETUP and T_MOVES" ); 
            return 0;
         }
      } elsif( ($tag_type == T_MOVE or $tag_type == T_SETUP) ) {
         $tnode = $tag_type;
      }
   }
   # don't set invalid structures
   if(not  $isUnSet ) {
      foreach( @values ) {
         # check compose
         if( $self->isComposed($_) and not $isComposable ) {
            $self->Warn("setProperty( \"$tag\", \"". join('", "',@values) . "\" ): FAILED\t\tFound Composed value when $tag does not allow it");
            return 0;
         }
         unless($self->_tagCheck($tag,0, $_)){
            $self->Warn("setProperty( \"$tag\", \"". join('", "',@values) . "\" ): FAILED\t\tCheck Failed");
            return 0;
         }
      }
   }
   # If I got here then it is safe to do some damage

   # if inherit use other tree

   $self->{'node'}->{'tags'}->{$tag} = [@values];
   return 1;
}

=head2 Value Type Functions

=head3 compose

  ($pt1, $pt2) = $sgf->compose($compose);
  $compose = $sgf->compose($pt1,$pt2);

Used for creating and breaking apart composed values. If you will be setting
or fetching a composed value you will be needing this function to breack it
apart.

=cut

sub compose {
   my $self = shift;
   $self->_clear;
   my $cop1 = shift;
   if( $self->isComposed($cop1) ) {
      return @$cop1;
   } else {
      my $cop2 = shift;
      return bless [$cop1,$cop2], 'Games::SGF::compose';
   }
}

=head3 isComposed

  if( $sgf->isComposed($compose) ) {
     ($val1, $val2) = $sgf->compose($compose);
  }


This returns true if the value passed in is a composed value, otherwise
false.

=cut

sub isComposed {
   my $self = shift;
   $self->_clear;
   my $val = shift;
   return ref $val eq 'Games::SGF::compose';
}

=head3 isPoint

=head3 isStone

=head3 isMove

=head3 isEmpty

  $self->isPoint($val);

Returns true if $val is a point, move or stone.

The determination for this is if it is blessing class matches
C<m/^Games::SGF::.*type$/> where type is point, stone, or move.
So as long as read,write,check methods work with it there is no
need for these methods to be overwritten.

isEmpty will detect an empty tag.

=cut

sub isPoint {
   my $self = shift;
   $self->_clear;
   my $val = ref shift;
   return scalar $val =~ m/^Games::SGF::.*point$/;
}
sub isStone {
   my $self = shift;
   $self->_clear;
   my $val = ref shift;
   return scalar $val =~ m/^Games::SGF::.*stone$/;
}
sub isMove {
   my $self = shift;
   my $val = ref shift;
   return scalar $val =~ m/^Games::SGF::.*move$/;
}
sub isEmpty {
   my $self = shift;
   my $val = ref shift;
   return scalar $val =~ m/^Games::SGF::.*empty$/;
}

=head3 point

=head3 stone

=head3 move

  $struct = $sgf->move(@cord);
  @cord = $sgf->move($struct);

If a point, stone, or move is passed in, it will be broken into it's parts
and returned. If the parts are passed in it will construct the internal
structure which the parser uses.

Will treat the outside format the same as the SGF value format. Thus will use 
the read and write callbacks for point,stone, and move.

If the SGF representation is not what you desire then override these.

=head3 empty

Will return a empty value, which can be tested with isEmpty.

=cut

sub point {
   my $self = shift;
   $self->_clear;
   if( $self->isPoint($_[0]) ) {
      return $self->_typeWrite(V_POINT,$_[0]);
   } else {
      return $self->_typeRead(V_POINT, $_[0]);
   }
}
sub stone {
   my $self = shift;
   $self->_clear;
   if( $self->isStone($_[0]) ) {
      return $self->_typeWrite(V_STONE, $_[0] );
   } else {
      return $self->_typeRead(V_STONE, $_[0]);
   }
}
sub move {
   my $self = shift;
   $self->_clear;
   if( $self->isMove($_[0]) ) {
      return $self->_typeWrite(V_MOVE,$_[0]);
   } else {
      return $self->_typeRead(V_MOVE, $_[0]);
   }
}
sub empty {
   my $self = shift;
   $self->_clear;
   my $a = "1";
   return bless \$a, 'Games::SGF::empty';
}

=head2 Error and Diagnostic Methods 

=head3 Fatal

=head3 Warn

=head3 Debug

  $self->Fatal( 'Failed to Parse Something');
  @errors = $self->Fatal;

  $self->Warn( 'Some recoverable Error Occured');
  @warnings = $self->Warn;

  $self->Debug('I am doing something here');
  @debug = $self->Debug;

These methods are used for storing human readable error messages, and
testing if an error has occured.

Fatal messages are set when there is a failure which can not be corrected,
such as trying to move passed the last node in a branch, or parsing a bad
SGF file.

Warn messages are set when a failure occurs and it can give a good guess
as to how to proceed. For example, a node can not have more then one a
given property set, but if the tag is for a list it will assume that you
ment to add that element onto the end of the list and spit out a warning.

Debug messages are saved at various points in the program, these are mainly
finding problems in module code (what is helpful for me to fix a bug).

If called with no arguments it will return a list of all event strings
currently on the stack.

Otherwise it will push the arguments onto the event stack.

=head3 Clear

  $self->Clear;

This will empty all events in the stack. This is only needed by extension modules,
which need to clear the stack.

Each time the public methods are called (outside of Games::SGF) the
event stacks will be cleared.

=cut


sub Fatal {
   my $self = shift;
   if( not @_ ) {
      return @{$self->{'FatalErrors'}};
   }
   push @{$self->{'FatalErrors'}}, @_; # save messages

   my $str = "FATAL:\t".join( "\nFATAL:\t\t",@_);
   if( ref $self->{'Fatal'} eq 'CODE') {
      return $self->{'Fatal'}->($str);
   } elsif( $self->{'Fatal'} ) {
      croak($str);
   }
}

sub Warn {
   my $self = shift;
   if( not @_ ) {
      return @{$self->{'WarnErrors'}};
   }
   push @{$self->{'WarnErrors'}}, @_; # save messages

   my $str = "WARN:\t" . join( "\nWARN:\t\t",@_);
   if( ref $self->{'Warn'} eq 'CODE') {
      return $self->{'Warn'}->($str);
   } elsif( $self->{'Warn'} ) {
      carp($str);
   }
}

sub Debug {
   my $self = shift;
   if( not @_ ) {
      return @{$self->{'DebugErrors'}};
   }
   push @{$self->{'DebugErrors'}}, @_; # save messages

   my $str = "Debug:\t " . join( "\nDebug:\t\t",@_);
   if( ref $self->{'Debug'} eq 'CODE') {
      return $self->{'Debug'}->($str);
   } elsif( $self->{'Debug'} ) {
      carp($str);
   }
}

sub Clear {
   my $self = shift;
   $self->{'FatalErrors'} = [];
   $self->{'WarnErrors'} = [];
   $self->{'DebugErrors'} = [];
}

#######################################
#
#      INTERNAL METHODS BELOW
#
#######################################

# removeVariation
#
#  $sgf->removeVariation($n);
#
# This will remove the C<$n> variation from the branch. If you have 
# variations C<0..4> and ask it to remove variation C<1> then the 
# indexs will be C<0..3>.
#
# Returns 1 on sucess 0 on Failure.

sub _newNode {
   my $parent = shift;
   $parent ||= 0;
   return { 
      'parent' => $parent, 
      'branches' => [], 
      'tags' => {}
   };
}

# if the parents caller is not from Games::SGF* then call clear
sub _clear {
   my $self = shift;
   my $package = caller(1);
   if( $package =~ m/^Games::SGF/ ) {
      return 0;
   } else {
      $self->Clear;
      return 1;
   }
}


sub _tagRead {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my( @values ) = @_;
   $self->Debug("_tagRead($tag, $isSecond," . join(", ",@values). ")");

   # composed
   if( @values > 1 ) {
      $values[0] = $self->_tagRead($tag,0,$values[0]);
      $values[1] = $self->_tagRead($tag,1,$values[1]);
      return $self->compose(@values);
   }
   my $type = $self->getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }

   # if empty just return empty
   if( $values[0] eq "" ) {
      if( $type == 1 ) {
         return $self->empty();
      } elsif( $self->getTagFlags($tag) & VF_EMPTY ) {
         return $self->empty();
      } elsif( not($type == V_POINT or $type == V_MOVE or $type == V_STONE ) ) {
         $self->Fatal("_tagRead($tag, $isSecond," . join(", ",@values). "): FAILED\t\tEmpty tag found where one should not be.");
         return 0;
      }
   }
   return $self->_typeRead($type,$values[0]);

}

sub _typeRead {
   my $self = shift;
   my $type = shift;
   my $text = shift;

   $self->Debug( "_typeRead($type,$text)");
   #return $text unless $type;
   if($type == V_COLOR) {
      if( $text eq "B" ) {
         return C_BLACK;
      } elsif( $text eq "W" ) {
         return C_WHITE;
      } else {
         $self->Fatal("_typeRead( $type, '$text' ): FAILED\t\tInvalid COLOR: '$text'");
         return undef;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $text eq "1" ) {
         return DBL_NORM;
      } elsif( $text eq "2" ) {
         return DBL_EMPH;
      } else {
         $self->Fatal("_typeRead( $type, '$text' ): FAILED\t\tInvalid Double: '$text'");
         return undef;
      }
   } elsif( $type == V_NUMBER) {
      if( $text =~ m/^[+-]?[0-9]+$/ ) {
         return $text;
      } else {
         $self->Fatal("_typeRead( $type, '$text' ): FAILED\t\tInvalid NUMBER: '$text'");
         return undef;
      }
   } elsif( $type == V_REAL ) {
      if( $text =~ m/^[+-]?[0-9]+(\.[0-9]+)?$/ ) {
         return $text;
      } else {
         $self->Fatal("_typeRead( $type, '$text' ): FAILED\t\tInvalid REAL: '$text'");
         return undef;
      }
   } elsif( $type == V_TEXT ) {
      return $text;
   } elsif( $type == V_SIMPLE_TEXT ) {
      #TODO do some final processing 
      #  compact all whitespace
      return $text;
   } elsif( $type == V_NONE ) {
      if( $text ) {
         $self->Fatal("_typeRead( $type, '$text' ): FAILED\t\tInvalid NONE: '$text'");
      } else {
         return $self->empty();
      }
   # game specific
   } elsif( $type == V_POINT ) {
      #if sub then call it and pass $text in
      if($self->{'pointRead'}) {
         return $self->{'pointRead'}->($text);
      } else {
        return bless [$text], 'Games::SGF::point';
      }
   } elsif( $type == V_STONE ) {
      if($self->{'stoneRead'}) {
         return $self->{'stoneRead'}->($text);
      } else {
        return bless [$text], 'Games::SGF::stone';
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveRead'}) {
         return $self->{'moveRead'}->($text);
      } else {
         return bless [$text], 'Games::SGF::move';
      }
   } else {
      $self->Fatal("_typeRead( $type, '$text' ): FAILED\t\tInvalid type: '$type'");
      return undef;
   }
}
# on V_TEXT and V_SIMPLE_TEXT auto escapes :, ], and \
# there should be no need to worry abour composed escaping
#
# adjust to check composed values?
sub _tagCheck {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my $struct = shift;
   $self->Debug("_tagCheck( $tag, $isSecond, $struct )");

   # composed
   if( $self->isComposed($struct) ) {
      my( @val ) = $self->compose($struct);
      $val[0] = $self->_tagCheck($tag,0,$val[0]);
      $val[1] = $self->_tagCheck($tag,1,$val[1]);
      return $val[0] && $val[1];
   }

   my $type = $self->getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }
   # if empty and VF_EMPTY return true unless point, move, or stone
   if( $self->isEmpty($struct) ) {
      if( $type == V_NONE ) {
         return 1;
      } elsif( $self->getTagFlags($tag) & VF_EMPTY ) {
         # return empty if not move stone or point
         return 1;
      } elsif(not( $type == V_POINT or $type == V_MOVE or $type == V_STONE ) ) {
         $self->Fatal("_tagCheck( $tag, $isSecond, $struct ): FAILED\t\tCheck failed with invalid string($tag, $struct)");
         return 0;
      }
   }
   return $self->_typeCheck($type,$struct);
}

sub _typeCheck {
   my $self = shift;
   my $type = shift;
   my $struct = shift;

   $self->Debug( "_typeCheck($type,$struct)");

   if($type == V_COLOR) {
      if( $struct == C_BLACK or $struct == C_WHITE ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $struct == DBL_NORM or $struct == DBL_EMPH ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_NUMBER) {
      if( $struct =~ m/^[+-]?[0-9]+$/ ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_REAL ) {
      if( $struct =~ m/^[+-]?[0-9]+(\.[0-9]+)?$/ ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_TEXT ) {
      #TODO update
      return 1;
   } elsif( $type == V_SIMPLE_TEXT ) {
      #TODO update
      return 1;
   } elsif( $type == V_NONE ) {
      if( $struct ) {
         return 0;
      } else {
         return 1;
      }
   } elsif( $type == V_POINT ) {
      if($self->{'pointCheck'}) {
         return $self->{'pointCheck'}->($struct);
      }
   } elsif( $type == V_STONE ) {
      if($self->{'stoneCheck'}) {
         return $self->{'stoneCheck'}->($struct);
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveCheck'}) {
         return $self->{'moveCheck'}->($struct);
      }
   } else {
      $self->Fatal( "_typeCheck($type,$struct): FAILED\t\tInvalid type: $type");
      return undef;
   }
   # maybe game specific stuff shouldn't be pass through
   return 1;
}
sub _tagWrite {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my $struct = shift;

   $self->Debug("tagWrite($tag, $isSecond, '$struct')");
   # composed
   if( $self->isComposed($struct) ) {
      my( @val ) = $self->compose($struct);
      $val[0] = $self->_tagWrite($tag,0,$val[0]);
      $val[1] = $self->_tagWrite($tag,1,$val[1]);
      return join ':', @val;
   }

   my $type = $self->getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }
   # if empty just return empty
   if( $self->isEmpty($struct) and ($self->getTagFlags($tag) & VF_EMPTY 
            or $type == V_NONE) ) {
      # if still empty it is ment to be empty
      return "";
   }
   return $self->_typeWrite($type,$struct);
} 
sub _typeWrite {
   my $self = shift;
   my $type = shift;
   my $struct = shift;
   my $text;
   $self->Debug("typeWrite($type,'$struct')");
   if($type == V_COLOR) {
      if( $struct == C_BLACK ) {
         return "B";
      } elsif( $struct == C_WHITE ) {
         return "W";
      } else {
         $self->Fatal("typeWrite($type,'$struct'): FAILED\t\tInvalid V_COLOR '$struct'");
         return undef;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $struct == DBL_NORM ) {
         return "1";
      } elsif( $struct == DBL_EMPH ) {
         return "2";
      } else {
         $self->Fatal("typeWrite($type,'$struct'): FAILED\t\tInvalid V_DOUBLE '$struct'");
         return undef;
      }
   } elsif( $type == V_NUMBER) {
      return sprintf( "%d", $struct);
   } elsif( $type == V_REAL ) {
      return sprintf( "%f", $struct);
   } elsif( $type == V_TEXT ) {
      $struct =~ s/([:\]\\])/\\$1/sg;
      return $struct;
   } elsif( $type == V_SIMPLE_TEXT ) {
      $struct =~ s/([:\]\\])/\\$1/sg;
      return $struct;
   } elsif( $type == V_NONE ) {
      return "";
   } elsif( $type == V_POINT ) {
      if($self->{'pointWrite'}) {
         return $self->{'pointWrite'}->($struct);
      } else {
         return $struct->[0];
      }
   } elsif( $type == V_STONE ) {
      if($self->{'stoneWrite'}) {
         return $self->{'stoneWrite'}->($struct);
      } else {
         return $struct->[0];
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveWrite'}) {
         return $self->{'moveWrite'}->($struct);
      } else {
         return $struct->[0];
      }
   } else {
      $self->Fatal("typeWrite($type,'$struct'): FAILED\t\tInvalid type '$type'");
      return undef;
   }
   # return $struct;
}


sub _maybeComposed {
   my $self = shift;
   my $prop = shift;
   if( ref $self->getTagValueType($prop) eq 'ARRAY'
         or $self->getTagFlags($prop) & VF_OPT_COMPOSE ) {
      return 1;
   } else {
      return 0;
   }
}
sub _isSimpleText {
   my $self = shift;
   my $prop = shift;
   my $part = shift;
   my $type = $self->getTagValueType($prop);
   if( $self->_maybeComposed($prop) ) {
      if( ref $type eq 'ARRAY' ) {
         if( $type->[$part] == V_SIMPLE_TEXT ) {
            #carp "Return 1?";
            return 1;
         }
      } elsif( $type == V_SIMPLE_TEXT ) {
         #carp "Return 1?";
         return 1;
      }
   } elsif( $type == V_SIMPLE_TEXT ) {
      #carp "Return 1?";
      return 1;
   }
   return 0;
}
sub _isText {
   my $self = shift;
   my $prop = shift;
   my $part = shift;
   my $type = $self->getTagValueType($prop);
   if( $self->_maybeComposed($prop) ) {
      if( ref $type eq 'ARRAY' ) {
         if( $type->[$part] == V_TEXT ) {
            #carp "Return 1?";
            return 1;
         }
      } elsif( $type == V_TEXT ) {
         #carp "Return 1?";
         return 1;
      }
   } elsif( $type == V_TEXT ) {
      #carp "Return 1?";
      return 1;
   }
   return 0;
}


# property is added at start of new tag, variation, or end of variation
sub _read {
   my $self = shift;
   my $text = shift;
   # Parse state
   my $lastChar = '';
   my $propertyName = '';
   my( @propertyValue ); # for current value 
   my $propI = 0;
   my $lastName = '';
   my( @values ) = (); # composed entries are array refs
   my( @variations ) = ();
   # Parse flags
   my $inValue = 0;
   my $isEscape = 0;
   my $isFinal = 0;
   my $isStart = 0;
   my $isFirst = 0;
   my $inTree = 0;
   $self->Debug( "_read( <SGF> ): SGF Dump\n\n$text\n\nEnd SGF Dump");
   # each gametree is a [\@sequence,\@gametress]
   for( my $i = 0; $i < length $text;$i++) {
      # ( start the game tree
      # ) end the game tree
      # ; start new node
      # [ start prop-value
      # ] end prop-value
      # a-Z not in [] are labels
      my $char = substr($text,$i,1);
      if( $inValue ) {
         if( $char eq ']' and not $isEscape) {
            # error if not invalue
            unless( $inValue ) {
               $self->Fatal("_read(<SGF>): FAILED\t\t Mismatched ']'");
            }
            $self->Debug("_read( <SGF> ):\t\t\tAdding Property: '$propertyName' "
               ."=> '$propertyValue[$propI]'");
   
            my $val =  $self->_tagRead($propertyName, 0, @propertyValue);
            if( defined $val ) {
               push @values, $val;
            } else {
               return 0;
            }
            $lastName = $propertyName;
            $propertyName = '';
            @propertyValue = ("");
            $propI = 0;
            $inValue = 0;
            next;
         } elsif( $char eq ':' and $self->_maybeComposed($propertyName)) {
            if($propI >= 1 ) {
               $self->Fatal("_read( <SGF> ): FAILED\t\tToo Many Compose components in value" );
               return undef;
            }
            $propI++;
            $propertyValue[$propI] = ""; # should be redundent
            next;
         } elsif( $self->_isText($propertyName, $propI) ) {
            if( $isEscape ) {
               if( $char eq "\n" ) {
                  $char = ""; # no space
               } elsif( $char =~ /\s/ ) {
                  $char = " "; # single space
               }
               $isEscape = 0;
            } elsif( $char eq '\\' ) {
               $isEscape = 1;
               $char = "";
            } elsif( $char =~ /\n/ ) {
               # makes sure newlines are saved when they are supposed to
               $char = "\n";
            } elsif( $char =~ /\s/ ) { # all other whitespace to a space
               $char = " ";
            }
         } elsif( $self->_isSimpleText($propertyName, $propI ) ) {
            if( $isEscape ) {
               if( $char eq "\n" ) {
                  $char = ""; # no space
               } elsif( $char =~ /\s/ ) {
                  $char = " "; # single space
               }
               $isEscape = 0;
            } elsif( $char eq '\\' ) {
               $isEscape = 1;
               $char = "";
            } elsif( $char =~ /\n/ ) {
               $char = " "; # remove all unescaped newlines
            } elsif( $char =~ /\s/ ) { # all whitespace to a space
               $char = " ";
            }
         }
         $propertyValue[$propI] .= $char;
      # outside of a value 
      } elsif( $char eq '(' ) {
         if( @values ) {
            # TODO this should only be done if attribute is LIST
            # GETSTRICT
            my $old = $self->getProperty($lastName, 1);
            @values = (@$old, @values) if $old;
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if($inTree) {
            $self->Debug("_read(<SGF>)\t\t\t#### Starting GameTree ####");
            push @variations, $self->getAddress;
            if( not $self->addNode ) {
               return undef;
            }
         } else {
            $self->Debug("_read(<SGF>)\t\t\t#### Adding game to collection ####");
            $inTree = 1;
            if( not $self->addGame ) {
               return undef;
            }
         }
         $isStart = 1;
      } elsif( $char eq ')' ) {
         if( @values ) {
            my $old = $self->getProperty($lastName, 1);
            @values = (@$old, @values) if $old;
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if( not @variations ) {
            $inTree = 0;
         } else {
            $self->Debug("_read(<SGF>)\t\t\t#### Ending Game Tree ####");
            $self->goto(pop @variations);
         }
      } elsif( $char eq ';' ) {
         # $self->Message('DEBUG',"Adding Node\n");
         if( @values ) {
            # GETSTRICT
            my $old = $self->getProperty($lastName,1 );
            @values = (@$old, @values) if $old;
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         # may be able to remove( addnode )
         if( not $inTree ) {
            $self->Fatal('Parse',"Attempted to start node outside"
               . "of GameTree: Failed");
            return undef;
         }
         if( $isStart ) {
            $isStart = 0;
         } elsif( not $self->addNode ) {
            return undef;
         }
      } elsif( $char eq '[' ) {
         $inValue = 1;
         $isFinal = 0;
         # handle tag types here
         # T_ROOT only when $current = $node
         $isFirst = 1;
         unless( $propertyName ) {
            $isFirst = 0;
            $propertyName = $lastName;
         }
      } elsif( $char =~ /\s/ ) {
         # catch all whitespace
         # to make sure it doesn't come in the middle of a
         # property name
         $isFinal = 1 if $propertyName;
      } elsif( $char =~ /[a-zA-Z]/ ) {
         # error if final
         if( @values ) {
            # GETSTRICT
            my $old = $self->getProperty($lastName,1);
            @values = (@$old, @values) if $old;
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if( $isFinal ) {
            $self->Fatal( "_read( <SGF> ): FAILED\t\tTag must have no spaces and must have a value" );
         }
         $propertyName .= $char;
         $lastName = "";
      } else {
         $self->Fatal("_read( <SGF> ): FAILED\t\tUnknown condition with char '$char': FAILED" );
         # error
      }
      $lastChar = $char;
   }
   return 1;
}

sub _write_tags {
   my $self = shift;
   my $hash = shift;
   my $text = "";
   foreach my $tag ( keys %$hash ) {
      my( @values ) = @{$hash->{$tag}};
      $text .= $tag;
      if( @values == 0 ) {
         $text .= "[]";
      } else {
         foreach my $val( @values ) {
            $text .= "[";
            # _type* take care of composed values now
            # add value
            $val = $self->_tagWrite($tag,0,$val);
            return undef if not defined $val;
            $text .= $val;
            $text .= "]"
         }
         $text .= "\n"; # add some white space to make it easier to read
      }
   }
   return $text;
}


sub _write {
   my $self = shift;
   my $node = shift;
   return "" unless $node;
   my $text = "(";
   
   # write all linear nodes
   # drops the leafs you need to handle 0 branchs
   #
   # if branches = 0 you are at a leave out and done
   #
   # if branches = 1 out and move to next node
   #
   # if branches > 1 out and recurse
   #
   #
   {
      if( $node  ) {
         $text .= ";";
         $text .= $self->_write_tags($node->{'tags'});
      } else {
         last;
      }
      if( not $node->{'branches'} ) {
         last;
      } elsif( @{$node->{'branches'}} == 1 ) {
         $node = $node->{'branches'}->[0];
         redo;
      } else {
         # recurse for each branch
         foreach(@{$node->{'branches'}}) {
            $text .= $self->_write($_);
         }
         last;
      }
   }

   $text .= ")"; # finish branch
   $text .= "\n"; # white space for readablity

   return $text;
}

1;

__END__

=head1 CONSTANTS

=head2 Type

These are the defined property types. They tell the engine where the tag is allowed
to be. 

=over

=item T_MOVE

This is used for properties discribing a move. T_MOVE and T_SETUP tags may not
be present in the same node.

=item T_SETUP

These properties are used for setting up a position on the board. Such as
placing stones on the board.

=item T_ROOT

These properties must be in the root node. This is the root of the collection,
not the root of a variation tree.

=item T_GAME_INFO

These are used for discribing the game. They should be on the earliest node,
that the game is evident. For example if the SGF file is a fuseki, the Game_info
should be when the game becomes unique in the collection.

=item T_NONE

There is no placement restrictions placed on tags of this type.

=back

These can be in any node. There is no resrictions placed on these nodes.

=head2 Value Type

These discribe the types of data contained in a tag.

=over

=item V_NONE

These properties have no tag content.

=item V_NUMBER

This is a number which satifisies the regex:  C<[+-]?[0-9]+>

=item V_REAL

This is a number which satifisies the regex: C<[+-]?[0-9]+(\.[0-9]+)?>

=item V_DOUBLE

This is used for emphasies. For example GB move the good for black
property. GB[1] would mean "Good for Black" GB[2] would mean "Very Good
for Black."

=over

=item DBL_NORM

Used for normal emphasis. When 1 is passed into a V_DOUBLE.

=item DBL_EMPH

Used for emphasis. When 2 is passed into a V_DOUBLE.

=back

=item V_COLOR

This is used to specify a color, such as which color starts.

=over

=item C_BLACK

Used when B is passed into a V_COLOR tag.

=item C_WHITE

Used when W is passed into a V_COLOR tag.

=back

=item V_TEXT

Can take pretty much any text.

=item V_SIMPLE_TEXT

Same as V_TEXT except all spaces are reduced down to a single space.

=item V_POINT

This is used to specify a point on the board. Used for marking positions.
This is a Game Specific property type and will be handled as V_TEXT unless
a parsing callback is specified.

=item V_STONE

This is used to specify a stone or placement of a stone on the board on the
board. Used for stone placement. This is a Game Specific property type and
will be handled as V_TEXT unless a parsing callback is specified.

=item V_MOVE

This is used to specify a move on the board. Used making moves on the board.
This is a Game Specific property type and will be handled as V_TEXT unless
a parsing callback is specified.

=back

=head2 Flags

These are various flags that can be given to a property tag. Since these are
bit flags, in order to set more then one flag use the bitwise C<|> operator.
For example to set both the C<VF_EMPTY> and C<VF_LIST> flag use 
C<VF_EMPTY | VF_LIST>.

=over

=item VF_NONE

Used to specify that no flags are set.

=item VF_EMPTY

This also's the property to the tag to be empty. For Example MA uses this
flag:

  MA[]

  or

  MA[ff][gg]

=item VF_LIST

This allows you to list properties together. The second example above
demstrates this behavior.  Used in conjunction with VF_EMPTY allows you
to have a empty list, otherwise it must have at least one property
given.

=item VF_OPT_COMPOSE

This tag allows a property to be composed with itself. For example in the
specification any List of Points can be used as a List of Point composed with
point, in order to specify a rectangular region of points. As an Example:

  MA[aa][ab][ba][bb]

  is equavalent to:

  MA[aa:bb]

=back

=head2 Attribute

=over

=item A_NONE

Used to specify no Attribute is set.

=item A_INHERIT

Currently the only Attribute defined in the specs. This property value will
be passed down to all subsequient nodes, untill a new value is set.

=back

=head1 EXTENDING Games::SGF

This is done by inheritance. You use the engine, but override the game
specific features related to point, stone, and move.

A Simple template is shown below:

  package MySGFGame;
  require Games::SGF;
  no warnings 'redefine';

  our( @ISA ) = ('Games::SGF');

  sub new {
     my $inv = shift;
     my $class = ref $inv || $inv;
     my $self = $class->SUPER::new(@_);

     # Add Tags
     $self->addTag('TB', $self->T_NONE, $self->V_POINT,
         $self->VF_EMPTY | $self->VF_LIST | $self->VF_OPT_COMPOSE);

     # more tags
     
     # Add Callbacks

     $self->addPointRead(\&pointRead);
     $self->addStoneRead(\&stoneRead);
     $self->addMoveRead(\&moveRead);


     $self->addPointCheck(\&pointCheck);
     $self->addStoneCheck(\&stoneCheck);
     $self->addMoveCheck(\&moveCheck);

     $self->addPointWrite(\&pointWrite);
     $self->addStoneWrite(\&stoneWrite);
     $self->addMoveWrite(\&moveWrite);

     return bless $self, $class; # Makes $self your class
  }
  # define the Callbacks
  # ...
  #
  # define move, point, stone
  # ...

=head1 ASSUMPTIONS

=over

=item All Inherited properties are T_NONE

This holds true for standard FF4 and I believe it would cause a conflict
if it was not true.

=back

=head1 KNOWN PROBLEMS

=head2 Documentation

The Documentation needs to be reviewed for accuracy

=head2 Some Errors not handled

The internal methods _get*(branch,node) do not currently check any errors, and the methods
using them don't check for errors. When this is fixed a few error handling
portions of the _read method can be removed.

=head1 ALSO SEE

L<http://www.red-bean.com/sgf>

L<Games::Goban>

L<Games::Go::SGF>

=head1 AUTHOR

David Whitcomb, C<< <whitcode at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

=head2 Robin Redeker 

For pointing out that AW[aa]AW[ab] should be read in and corrected to AW[aa][ab].

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-sgf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-SGF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::SGF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-SGF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-SGF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-SGF>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-SGF>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Whitcomb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

