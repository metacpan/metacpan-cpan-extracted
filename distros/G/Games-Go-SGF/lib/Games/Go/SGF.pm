package Games::Go::SGF;

use 5.006;
use strict;
use warnings;
use Carp;
use IO::File;
use English;
use Parse::RecDescent;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.11';
our $AUTOLOAD;

{
  my %nodehash;
  my %onersfound;
  my %duplicates;

  # organise a node's property values and tags
  # drop leading [, and trailing ]

  sub store {
    my ($ident, $values) = @_;
    if (exists($nodehash{tags})) {
      if ($nodehash{tags} !~ /,$ident,/) {
        $nodehash{tags} .= $ident.',';
      }
    } else {
      $nodehash{tags} = ','.$ident.','
    }

    if (exists($nodehash{$ident})){
      $nodehash{$ident} = join (',', $nodehash{$ident}, map (substr($_,1,-1), @{$values}));
    } else {
      $nodehash{$ident} = join (',', map (substr($_,1,-1), @{$values}));
    }
  }

  # detect duplicate tags and mixed nodes

  sub isDuplicate {
    my $ident = shift;

    # bad sgf if more than one of these in a file
    my $oners = ',SZ,GM,ST,FF,CA,AP,RU,SZ,KM,';
    if (exists($onersfound{$ident}) and $oners =~ /,$ident,/) {
      print 'Duplicated ',$ident, ' property',"\n";
      return 1;
    }
    $onersfound{$ident} = undef;

    # bad sgf if any of these are duplicated in a node
    my $singletons = ',B,W,PL,MN,';
    if (exists($duplicates{$ident}) and $singletons =~ /,$ident,/) {
      print 'Duplicated ',$ident, ' property',"\n";
      return 1;
    }

    # bad sgf if both of these are in a node
    my $alones = ',B,W,';
    if ((grep (exists($duplicates{$_}),('B','W')) ) and $alones =~ /,$ident,/) {
      print $ident, ' property not allowed in this node',"\n";
      return 1;
    }

    # flag mixed nodes - if this is B or W, have we already got AB or AW or AE
    my $setup = ',AB,AW,AE,';
    if ((grep (exists($duplicates{$_}),('B','W')) ) and $setup =~ /,$ident,/) {
      print 'Setup and move in the same node',"\n";
      return 1;
    }

    # flag mixed nodes - if this is AB or AW or AE, have we already got B or W
    my $move = ',B,W,';
    if ((grep (exists($duplicates{$_}),('AB','AW','AE')) ) and $move =~ /,$ident,/) {
      print 'Setup and move in the same node',"\n";
      return 1;
    }

    $duplicates{$ident} = 0;

    return 0;
  }

  # return and clear the tags and values for a node

  sub unload {
    my %hash = %nodehash;
    %nodehash = ();
    %duplicates = ();
    return %hash
  }

  sub refresh {
    %onersfound = ();
    %nodehash = ();
    %duplicates = ();
  }

}

my $grammar = q{
        File : GameTree { $return = $item[1]; Games::Go::SGF::refresh }
    GameTree : '(' Node(s) GameTree(s?) ')' {
                  $return = $item[2];
                  push @{$return} , bless( $item[3], 'Games::Go::SGF::Variation') if (@{$item[3]})
                }
        Node : ';' Property(s?) {
                  $return = bless({Games::Go::SGF::unload()}, 'Games::Go::SGF::Node')
                }
    Property : ...Validate Tag Value(s) {
                  Games::Go::SGF::store( $item[2], $item[3] );
                }
    Validate : (/B\[/|/W\[/) <commit> MovePoint
              |('AB'|'AW'|'AE'|'CR'|'MA'|'SL'|'SQ'|'TR') <commit> Point(s)
              |'PL' <commit> Colour
              |/C\[/ <commit> Comment
              |'AP'|'CA' <commit> Value
              |('SZ'|'FF'|'HA'|'OW'|'OB'|'ST'|'GM') <commit> Integer
              |('BL'|'WL') <commit> Real
              |'LB' <commit> Markup(s)
              |/[A-Z]+/ <commit> Value(s)
         Tag : /[A-Z]+/ <reject: Games::Go::SGF::isDuplicate( $item[1] )> { $return = $item[1] }
       Value : /\[.*?(?<!\\\)\]/s #matches minimally '['..anything up to '?]' where ? ne \
     Comment : /.*?(?<!\\\)\]/s
      Markup : /\[[a-zA-Z]{2}/ ':' /.*?(?<!\\\)\]/s
   MovePoint : /[a-zA-Z]{2}\][^\[]/ | /\]/
       Point : /\[[a-zA-Z]{2}\]/
     Integer : /\[\d+\]/
        Real :/\[\d+\.\d+\]|\[\d+\]/
      Colour : /\[[WB]\]/
};

sub new {
  my ($class, $file, $grammarflag) = @_;
  my $grammar = _choosegrammar($grammarflag);
  my $parser = new Parse::RecDescent $grammar or croak "Bad grammar!\n";
  my $fh = IO::File->new($file, '<') or croak $ERRNO;
  my $slurpfile = do { local $/; <$fh> };
  $fh->close or croak $ERRNO;
  my $a = $parser->File($slurpfile);
  defined $a or croak "Bad Go sgf\n";
  bless $a, 'Games::Go::SGF';
  _sew($a);
  return $a;
}

sub _sew {
  my $a = shift;
  $a->[0]->{moves_to_first_variation} = 0;
  for (0..@$a) {
    if (ref $a->[$_] eq 'Games::Go::SGF::Variation') {
      $a->[0]->{moves_to_first_variation} ||= $_;
      _sew($_) for $a->[$_]->variations;
    } else {
      $a->[$_]->{next} = $a->[$_+1];
    }
  }
}

sub _choosegrammar {
  my $grammarflag = shift;
  my $res;
  $grammarflag ||= 'lite';
  for ($grammarflag) {
    if ($_ eq 'lite')   { $res = $grammar;
                          $res =~ s/\.\.\.Validate//;
                          $res =~ s/\[2\], \$item\[3\]/\[1\], \$item\[2\]/;
                          $res =~ s/Validate.*Value\(s\)//s;
                          $res =~ s/Comment.*eofile/eofile/s;
                          last }
    if ($_ eq 'full')   { $res = $grammar; last }
    croak 'Unknown grammar type';
  }
  return $res
}

# Game info methods

sub date  {
  my ($self, $value) = @_;
  _setvalue($self, 'DT', $value) if ($value);
  return $self->[0]->{DT};
}

sub time  { date(@_) }

sub white {
  my ($self, $value) = @_;
  _setvalue($self, 'PW', $value) if ($value);
  return $self->[0]->{PW};
}

sub black {
  my ($self, $value) = @_;
  _setvalue($self, 'PB', $value) if ($value);
  return $self->[0]->{PB};
}

sub size  {
  my ($self, $value) = @_;
  _setvalue($self, 'SZ', $value) if ($value);
  return $self->[0]->{SZ};
}

sub komi  {
  my ($self, $value) = @_;
  _setvalue($self, 'KM', $value) if ($value);
  return $self->[0]->{KM};
}

sub delete{
  my ($self, $tag) = @_;
  if (exists $self->[0]->{$tag}) {
    delete $self->[0]->{$tag};
    $self->[0]->{tags} =~ s/$tag,?//;
  }
}

# change the value of a tag
# if a new tag is being created, add it to {tags}
sub _setvalue {
  my ($self, $tag, $value) = @_;
  $self->[0]->{tags} = join(',', $self->[0]->{tags}, $tag) unless (exists $self->[0]->{$tag});
  $self->[0]->{$tag} = $value;
}

sub move  { $_[0]->[$_[1]]; }

sub getsgf {
  my $self = shift;
  my $move_no = 0;
  my $startvar = 1; # used for formatting of output
  my $string = '(';

  while (my $walker = $self->move($move_no++)) {
    $string .= _donode($walker, $startvar);
    $startvar = 0;
  }

  $string .= ')'."\n";
  return $string
}

sub _iterate {
  my $startpoint = shift;
  my $v = 0;
  my $string;
  my @vars = $startpoint->variations;

  while (defined $vars[$v]){
    $string .= "\n".'(';
    my $startvar = 1;
    for (@{$vars[$v++]}){
      $string .= _donode($_, $startvar);
      $startvar = 0;
    }
    $string .= ')';
  }

  return $string
}

sub _donode {
  my ($node, $startvar) = @_;
  my $string = '';
  if (ref($node) eq 'Games::Go::SGF::Node'){
    $string .= "\n" unless $startvar;
    $string .= ';';
    if ($node->tags) {
      for (split (',', $node->tags)) {
        $string .= $_;
        my $property = $node->$_;
        if ($property) {
          for (split (',', $property)) {
            $string .= '['.$_.']';
          }
        } else {
          $string .= '[]';
        }
      }
    }
  } else {
    if (ref($node) eq 'Games::Go::SGF::Variation'){
      $string .= _iterate($node);
    }
  }
  return $string
}

sub AUTOLOAD {
  my ($self, $value) = @_;
  my $type = ref($self) or croak $self.' is not an object';
  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion
  _setvalue($self, $name, $value) if ($value);
  return $self->[0]->{$name};
}

package Games::Go::SGF::Variation; 
our $AUTOLOAD;
sub mainline   { return $_[0]->[0] }
sub variation  { return $_[0]->[$_[1]]}
sub variations { return @{$_[0]} }

# This is - as I shouldn't need to tell you - is a dirty hack.
# But I like it (Simon)
sub AUTOLOAD {
    $AUTOLOAD=~ s/Variation/Node/;
    &$AUTOLOAD($_[0]->mainline, @_[1..@_]);
}
sub DESTROY { }

package Games::Go::SGF::Node;
our $AUTOLOAD;

sub move { my $node = shift; $node->{B} || $node->{W} }

sub color { colour(shift) }

sub colour {
  my $node = shift;
  if (exists($node->{B})){'B'}
  else {
    if (exists($node->{W})){'W'}
    else {'None'}
  }
}

sub nodedump {
  my $node = shift;
  my $result;
  for (split(',',$node->{tags})) {$result .= join(' ', $_, $node->{$_}, "\n")}
  return $result
}

sub tags {
  my $node = shift;
  $node->{tags};
}

sub delete{
  my ($node, $tag) = @_;
  if (exists $node->{$tag}) {
    delete $node->{$tag};
    $node->{tags} =~ s/$tag,?//;
  }
}

sub AUTOLOAD {
  my ($node, $value) = @_;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion
  _nodesetvalue($node, $name, $value) if $value;
  return $node->{$name};
}

sub _nodesetvalue {
  my ($node, $tag, $value) = @_;
  if (exists $node->{tags}) {
    $node->{tags} = join(',', $node->{tags}, $tag) unless exists $node->{$tag};
  } else {
    $node->{tags} = $tag;
  }
  $node->{$tag} = $value;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Games::Go::SGF - Parse and dissect Standard Go Format files

=head1 SYNOPSIS

  use Games::Go::SGF;

  my $file = shift;
  my $sgf = new Games::Go::SGF($file);
  print $sgf->getsgf;
  print "Game played on ".$sgf->date."\n";
  print $sgf->white. " (W) vs. ".$sgf->black." (B)\n";
  print "Board size: ".$sgf->size.". Komi: ".$sgf->komi."\n";

=head1 DESCRIPTION

This is an SGF file parser. It can read, write and step through SGF files, follow
variations, and so on. It's good enough for getting simple
statistics about games of Go, and building up C<Games::Go::Board>
objects representing games stored as SGF.

C<< $sgf->move >> returns either a normal C<Games::Go::SGF::Node>
or a C<Games::Go::SGF::Variation> object. The variation object has the additional methods
C<mainline()> to get the main line of the game, C<variation($n)>
to get the first node in the n'th variation, and C<variations>
to retrieve an array of variations. C<< $variation->move >> will,
by default, follow the mainline.

The parser will report 'bad go sgf' with an explanation if:

=over 2

=item *

there are certain duplicated property identifiers (tags) within a file (eg SZ)

=item *

there are certain duplicated tags within a node (eg B)

=item *

there is a certain mixture of tags within a node eg ( (B or W) and (AB or AW or AE) )

=back

The parser will also quietly re-organise tags within a node if it is badly formed.
eg CR[aa]CR[ab] becomes CR[aa][ab]

Some property value validation checks are made, some of which are Go specific.
For example B[ab] is OK, but B[ab:ac] will not parse.

=head2 General use

The value of any property can be obtained by using its sgf tag.
For example, to get the value of 'RU';

    my $rules = $sgf->RU;

Similarly, the value of any property can be set by using its sgf tag.
For example, to set the value of 'RU';

    $sgf->RU('AGA');

Setting the value of a tag will create it, if necessary.


In addition, the following aliases are available:

    $sgf->date;  # equivalent to $sgf->DT
    $sgf->time;  # equivalent to $sgf->DT
    $sgf->white; # equivalent to $sgf->PW
    $sgf->black; # equivalent to $sgf->PB
    $sgf->size;  # equivalent to $sgf->SZ
    $sgf->komi;  # equivalent to $sgf->KM

These values can be also be set;

    $sgf->komi(5.5); # sets komi to 5.5

Properties found in the root of the sgf file (all those listed above for example)
are available to be read regardless of the current node, other properties are node
specific ($sgf->B for example)

=head1 PARAMETERS

A new SGF object can be created with one the following optional flags;

'lite'  - re-organise but don't validate
'full'  - validate and re-organise (slower)

If no parameter is specified, 'lite' is assumed.

For example

  my $sgf = new Games::Go::SGF($sgfdata, 'full');

=head1 METHODS

=head2 move

Move the parser on to the next node.

    $sgf($move_no++);

=head2 tags

The tags method returns an array containing the properties that were
found in the current node.

    print $sgf->tags;

=head2 colour (aka color)

The colour method returns 'B', 'W', or 'None', depending on whether the tag B, or W,
or neither of them was found in the current node.

    print $sgf->colour;
    print $sgf->color; # another way to spell colour

=head2 delete

To delete a tag in the current node;

    $sgf->delete('CR'); # delete the 'CR' tag

=head2 getsgf

To return the file in sgf;

    print $sgf->getsgf;

=head1 TODO

Make variations easier to navigate.
Make validation game specific.
Output to xml?

=head1 AUTHOR (version 0.01)

Simon Cozens

=head1 MODIFICATIONS (version 0.02+)

Daniel Gilder C<deg@cpan.org>

=head1

=head1 SEE ALSO

L<Games::Go::Board>, http://www.red-bean.com/sgf/

=cut
