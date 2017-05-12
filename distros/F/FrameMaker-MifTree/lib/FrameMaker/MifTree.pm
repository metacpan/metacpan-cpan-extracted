package FrameMaker::MifTree;
# $Id: MifTree.pm 2 2006-05-02 11:15:26Z roel $
use 5.008_001;              # minimum version for Unicode support
use strict;
use warnings;
use warnings::register;
use Carp;
use File::Temp;
use IO::Tokenized ':parse'; # These are...
use IO::Tokenized::File;    # ... from CPAN.
use IO::Tokenized::Scalar;  # Subclass in IO::Tokenized::File style,
                            # uses IO::Scalar from the IO::Stringy bundle.
use Tree::DAG_Node 1.04;    # Get this module from CPAN.

=head1 NAME

FrameMaker::MifTree - A MIF Parser

=head1 VERSION

This document describes version 0.075, released 2 May 2006.

=head1 SYNOPSIS

  use FrameMaker::MifTree;
  my $mif = FrameMaker::MifTree->new;
  $mif->parse_miffile('filename.mif');
  @strings = $mif->daughters_by_name('String', recurse => 1);
  print $strings[0]->string;
  $strings[3]->string('Just another new string.');
  $mif->dump_miffile('newmif.mif');

=head1 DESCRIPTION

The FrameMaker::MifTree class is implemented as a Tree::DAG_Node subclass, and
thus inherits all the methods of that class. Two methods are overridden. Please
read L<Tree::DAG_Node> to see what other methods are available.

MIF (Maker Interchange Format) is an Adobe FrameMaker file format in ASCII,
consisting of statements that create an easily parsed, readable text file of
all the text, graphics, formatting, and layout constructs that FrameMaker
understands. Because MIF is an alternative representation of a FrameMaker
document, it allows FrameMaker and other applications to exchange information
while preserving graphics, document content, and format.

This document does not tell you what the syntax of a MIF file is, nor does it
document the meaning of the MIF statements. For this, please read (and re-read)
the MIF_Reference.pdf, provided by Adobe.

MifTree not only knows the MIF syntax, but it also has some understanding of
the allowed structures (within their contexts) and attribute types. The file
FrameMaker/MifTree/MifTreeTags holds all the valid MIF statements and the
attribute type for every statement. This file may need some improvement, as it
is created by analyzing a large collection of MIF files written by FrameMaker
(and an automatic analysis of the I<MIF Reference>, which showed several typos
and inconsistencies in that manual). The current file is for MIF version 7.00.

=head2 Dependencies

This class implementation depends on the following modules, all available from
CPAN:

=over 4

=item *

Tree::DAG_Node

=item *

IO::Tokenized and IO::Tokenized::File and the custom-made IO::Tokenized::Scalar

=item *

IO::Stringy (only IO::Scalar is needed)

=back

=cut

BEGIN {
  use Exporter ();
  our $VERSION     = 0.075;
  our @ISA         = qw(Tree::DAG_Node Exporter);
  our @EXPORT      = qw(&quote &unquote &encode_path &decode_path &convert);
  our @EXPORT_OK   = qw(%fmcharset %fmnamedchars);
  our %EXPORT_TAGS = ();
}
our @EXPORT_OK;

our (%mifnodes, %mifleaves, %attribute_types, %fmcharset, %fmnamedchars);

our $use_unicode;

for my $do (qw(FrameMaker/MifTree/MifTreeTags FrameMaker/MifTree/FmCharset)) {
  do $do or croak $! || $@;
}
our $fm_to_unicode = '$s =~ tr/' .
  join('', map { sprintf '\x%02x',   ord } keys   %fmcharset) . '/' .
  join('', map { sprintf '\x{%04x}', ord } values %fmcharset) . '/';
our $unicode_to_fm = '$s =~ tr/' .
  join('', map { sprintf '\x{%04x}', ord } values %fmcharset) . '/' .
  join('', map { sprintf '\x%02x',   ord } keys   %fmcharset) . '/';

our $default_unit = '';
our @parserdefinition = (
  [ COMMENT => qr/#.*/ ],
  [ RANGLE  => qr/>/, sub{''} ],
  [ MIFTAG  => qr/<\s*[a-z][a-z0-9]*/i, sub {(my $m = shift) =~ s/^<//; $m;} ],
  [ ATTRIBS => qr/`.*?'|[^=&>#]+/ ],
  [ FACET   => qr/[=&].+/ ],
  [ MACRO   => qr/define\s*\(.*?\)/ ]
);
our %unit_to_factor = (
  ''         => 1 / 72,
  pt         => 1 / 72,
  point      => 1 / 72,
  q(")       => 1,
  in         => 1,
  mm         => 1 / 25.4,
  millimeter => 1 / 25.4,
  cm         => 1 / 2.54,
  centimeter => 1 / 2.54,
  pc         => 1 / 6,
  pica       => 1 / 6,
  dd         => 0.01483,
  didot      => 0.01483,
  cc         => 12 * 0.01483,
  cicero     => 12 * 0.01483
);

=head2 Overridden Methods

=over 4

=item C<add_daughters(LIST)>

Adds a list of daughter object to a node. The difference with the DAG_Node
method is that it checks for a valid MIF construct. Only the mother/daughter
relationship is checked.

=cut

sub add_daughters {
  # extends functionality of Tree::DAG_Node's sub
  my($mother, @daughters) = @_;

  if (ref $mother && $mother->name) { # only when called on object and if
                                      # we know the name of the mother
    # check for allowed daughters
    if (warnings::enabled || $^W) {
      for my $daughter (@daughters) {
        warnings::warn 'Node "' . ($mother->name || '') .
          '" does not allow daughter "' . ($daughter->name || '') . '"'
          unless $mother->allows_daughter($daughter);
      }
    }
  }

  $mother->SUPER::add_daughters(@daughters);
}

=item C<attributes(VALUE)>

The attributes method of the FrameMaker::MifTree class does not require a
reference as an attribute, as does the DAG_Node equivalent. As an extra, the
method checks if the method is called on a leaf, since the MIF structure does
not allow attributes on non-ending nodes. The method reads/sets the raw
attribute, no string conversion, path encoding/decoding or value extraction is
done. To obtain or set one of those values, use the specific L<Attribute
Methods> mentioned below.

=cut

sub attributes { # read/write attribute-method
  # overrides Tree::DAG_Node's sub -- doesn't carp that 'attributes' needs
  # to be a ref
  my $this = shift;
  croak 'Must be called on object' unless ref $this;
  $this->{attributes} = $_[0] if (@_);

  # check if the attribute is valid
  if ((warnings::enabled || $^W) && ! $this->check_attribute) {
    warnings::warn $this->get_attribute_error;
  }

  return $this->{attributes};
}

=back

=head2 Quick Creators

The following methods can be used instead of the DAG_Node standard methods to
build your MIF structure. It's just a lazy way of adding daughters, but it
improves readability of your code if you create something like:

  my $mif = FrameMaker::MifTree->new->add_node(
    AFrames => FrameMaker::MifTree->add_node(
      Frame => FrameMaker::MifTree->add_node(
        ImportObject => FrameMaker::MifTree->add_leaf(
          ImportObFileDI => encode_path('c:\bar\foo.eps'))
      ),
      FrameMaker::MifTree->add_node(
        ImportObject => FrameMaker::MifTree->add_leaf(
          ImportObFileDI => encode_path('../../foo/boo.eps'))
      )
    )
  );

=over 4

=item C<add_leaf(MIFSTATEMENT, ATTRIBUTE or GRANDDAUGHTERLIST)>

Adds a new daughter to the object. The first argument specifies the name, all
the following arguments are taken either as the attribute for the leaf, or as a
list of granddaughter objects to add to the newly created daughter. (In MIFTree
world, newly born daughters mature in split seconds.)

=cut

sub add_leaf {
  # same sub to add either a leaf (2nd argument is a scalar) or a node (2nd
  # argument is a FrameMaker::MifTree object)
  my ($this, $name, @that) = @_;

  my $class = ref($this) || $this;
  my $daughter = $class->new();
  $daughter->name($name);
  if ( ref $that[0] && $that[0]->isa('FrameMaker::MifTree') ) {
    # assume list of nodes
    $daughter->add_daughters(@that);
  } else {               # probably dealing with an attribute for the leaf
    $daughter->attributes($that[0]);
  }

  $this->add_daughters($daughter) if (ref $this) ; # called on object

  return $daughter;
}

=item C<add_node(MIFSTATEMENT, ATTRIBUTE or GRANDDAUGHTERLIST)>

An exact synonym for the C<add_leaf> method.

=cut

sub add_node { # alias
  my ($it, @them) = @_;
  $it->add_leaf(@them);
}

=item C<add_facet()>

Adds a facet to the object. In DAG_Node tree terms, this is implemented as a
leaf with the name "_facet" and a filehandle to a temp file as its attribute.

=cut

sub add_facet {
  my $this = $_[0];

  my $class = ref($this) || $this;
  my $daughter = $class->new();

  $daughter->name('_facet');

  my $fh = File::Temp::tempfile();
  $daughter->attributes($fh);

  $this->add_daughters($daughter) if (ref $this) ; # called on object

  return $daughter;
}

=back

=head2 Search in Tree

=over 4

=item C<$OBJ-E<gt>daughters_by_name(NAMESTRING, recurse =E<gt> BOOLEAN)>

Find all daughters that listen to the name NAMESTRING, either walking the tree
("recurse" is true), or only on the mother's daughters ("recurse" false or
omitted; the latter throws a warning that it will not recurse -- I've spent too
much time debugging code where I forgot to add the "recurse" parameter). Returns
the first object in scalar context, or a list of all found objects in list
context.

Maybe one day I'll add magic to this function so you get the next item if you
call the method on the same object without arguments.

Note that "daughter_by_name" is an exact alias for this method.

=cut

sub daughters_by_name {
  my ($obj, $name, $recurse, $rec_val) = @_[0 .. 3];
  my $wantsarray = wantarray;
  $rec_val = $recurse, $recurse = 'recurse' if @_ == 3; # backward compatible
  if ((warnings::enabled || $^W) && ! defined $recurse) {
    warnings::warn 'daughters_by_name will NOT recurse';
  }
  $rec_val ||= 0;
  my @found = ();
  for my $daughter ($obj->daughters) {
    $daughter->walk_down({
      callback => sub {
        push @found, $_[0] if (defined $_[0]->name && $_[0]->name eq $name);
        $rec_val = 0 if ($rec_val && @found && ! $wantsarray); # stop searching
        return $rec_val;
      }
    });
  }
  return $wantsarray ? @found : $found[0];
}

=item C<$OBJ-E<gt>daughter_by_name(NAMESTRING, recurse =E<gt> BOOLEAN)>

Alias for "daughters_by_name".

=cut

sub daughter_by_name { # alias
  my ($it, @them) = @_;
  $it->daughters_by_name(@them);
}

=item C<$OBJ-E<gt>daughters_by_name_and_attr(NAMESTRING, ATTRIBUTE, recurse
=E<gt> BOOLEAN)>

Find all daughters that listen to the name NAMESTRING and have the raw
attribute ATTRIBUTE, either walking the tree ("recurse" is true), or only on
the mother's daughters ("recurse" false or omitted). Returns the first object
in scalar context, or a list of all found objects in list context. ATTRIBUTE
must be raw data, so use C<quote>, C<unquote>, C<encode_path> and 
C<decode_path> as appropriate.

If you specify an empty string or undef as the NAMESTRING, this method will
just look for ATTRIBUTE.

Note that "daughters_by_name_and_attr" is an exact alias for this method.

=cut

sub daughters_by_name_and_attr {
  my ($obj, $name, $attr, $recurse, $rec_val) = @_[0 .. 4];
  my $wantsarray = wantarray;
  $rec_val = $recurse, $recurse = 'recurse' if @_ == 4; # backward compatible
  if ((warnings::enabled || $^W) && ! defined $recurse) {
    warnings::warn 'daughters_by_name will NOT recurse';
  }
  $rec_val ||= 0;
  my @found = ();
  for my $daughter ($obj->daughters) {
    $daughter->walk_down({
      callback => sub {
        if ( $_[0]->is_leaf ) {
          if (   (!$name || (defined $_[0]->name && $_[0]->name eq $name))
              && (defined $_[0]->attributes && $_[0]->attributes eq $attr) ) {
            push @found, $_[0];
          }
        }
        $rec_val = 0 if ($rec_val && @found && ! $wantsarray); # stop searching
        return $rec_val;
      }
    });
  }
  return $wantsarray ? @found : $found[0];
}

=item C<$OBJ-E<gt>daughter_by_name_and_attr(NAMESTRING, ATTRIBUTE, recurse
=E<gt> BOOLEAN)>

Alias for "daughters_by_name_and_attr".

=cut

sub daughter_by_name_and_attr { # alias
  my ($it, @them) = @_;
  $it->daughters_by_name_and_attr(@them);
}

=item C<$OBJ-E<gt>find_string(QUOTED_REGEX)>

Returns a list of all strings that match QUOTED_REGEX under $OBJ. When called
in scalar context, only the first match is returned. The string is in Unicode
if the global modifier C<FrameMaker::MifTree-E<gt>use_unicode> is set (off by
default.)

=cut

sub find_string {
  my ($obj, $re, $use_unicode_deprecated) = @_[0 .. 2];
  my $wantsarray = wantarray;
  my @found = ();
  for my $str_obj ($obj->daughters_by_name('String', recurse => 1)) {
    my $string = $str_obj->string(undef, $use_unicode_deprecated);
    push @found, $string if $string =~ /$re/;
    last if @found && ! $wantsarray;
  }
  return $wantsarray ? @found : $found[0];
}

=item C<$OBJ-E<gt>charleaves_to_strings()>

Changes all the leaves with the name "Char" below $OBJ to their equivalent
String leaves. This has no effect on the content of the MIF file; it just makes
the file less ambiguous. Returns undef.

=cut

#TODO I intend to move these two methods to a separate class later
sub charleaves_to_strings {
  my $obj = $_[0];
  local $use_unicode = 1;
  for ($obj->daughters_by_name('Char', recurse => 1)) {
    my $new_att_string = $fmnamedchars{$_->attribute};
    $_->name('String');
    $_->string($new_att_string);
  }
}

=item C<$OBJ-E<gt>fold_strings()>

This method folds all subsequent paragraph lines in a paragraph into one
paragraph line. If you want to do operations on text, you should first use this
method on (part of) the tree. In MIF, the flow of text over the lines is
maintained, but since this information is not used while FrameMaker parses the
MIF file, it is safe to remove this information. Returns undef.

All "Char" leaves except a "HardReturn" are transformed to their string
equivalents. A "HardReturn" character forces a new paragraph line.

=cut

sub fold_strings {
  my $obj = $_[0];
  local $use_unicode = 0;
  for my $para ($obj->daughters_by_name('Para', recurse => 1)) {

    $para->charleaves_to_strings;

    my $first_paraline;
    for my $daughter ($para->daughters) {
      if ($daughter->name ne 'ParaLine') {
        $first_paraline = undef;
      } elsif ( ! defined $first_paraline ) {
          $first_paraline = $daughter;
      } else {
        my @strobj = $first_paraline->daughters_by_name('String', recurse => 0);
        if (@strobj && $strobj[-1]->string =~ /\x09$/) { # character HardReturn
          $first_paraline = $daughter;                   # forces new ParaLine
        } else {
          $first_paraline->add_daughters(
            grep {$_->name ne 'TextRectID'} $daughter->daughters
          );
          $para->remove_daughter($daughter);
        }
      }
    }

    for my $paraline ($para->daughters_by_name('ParaLine', recurse => 0)) {
      my $first_str;
      for my $daughter ($paraline->daughters) {
        if ($daughter->name ne 'String') {
          $first_str = undef;
        } elsif ( ! defined $first_str ) {
          $first_str = $daughter;
        } else {
          (my $str = $daughter->string) =~ tr/\x06//d;
          $first_str->string($first_str->string . $str);
          $paraline->remove_daughter($daughter);
        }
      }
    }

  }
}

=back

=head2 Attribute Methods

=over 4

=item C<$OBJ-E<gt>string(STRING)>

Reads or sets the object's attribute as a MIF string. The method just calls
C<quote> and C<unquote> as appropriate.

If the global modifier C<FrameMaker::MifTree-E<gt>use_unicode> is set to true,
the string will be converted from Unicode to the FrameMaker character set
first. (The method now throws a warning when you specify USE_UNICODE as the
second argument.)

=cut

sub string { # read/write attribute-method
  my ($this, $new_val, $unicode_deprecated) = @_[0 .. 2];
  $this->attributes(quote($new_val, $unicode_deprecated)) if defined $new_val;
  return unquote($this->attributes, $unicode_deprecated);
}

=item C<$OBJ-E<gt>pathname(PATHSTRING)>

Returns the object's attribute as local pathname, or sets it to the device
independent pathname. The method just calls C<encode_path> and C<decode_path>
as appropriate. PATHSTRING must also be a local pathname.

=cut

sub pathname { # read/write attribute-method
  my $this = shift;
  croak 'Must be called on object' unless ref $this;
  $this->attributes(encode_path($_[0])) if (@_);
  return decode_path($this->attributes);
}

=item C<$OBJ-E<gt>abs_pathname(FROMROOT)>

Returns the object's attribute as a local pathname. The method just calls
C<decode_path>, passing on the FROMROOT argument. Use this method if you want
to make sure that you always receive absolute pathnames, independently from
what is stored in the attribute.

=cut

sub abs_pathname { # read/write attribute-method
  my ($this, $root) = @_[0, 1];
  croak 'Must be called on object' unless ref $this;
  return decode_path($this->attributes, $root);
}

=item C<$OBJ-E<gt>boolean(BOOLEAN)>

Returns or sets the object's TRUE or FALSE value.

=cut

sub boolean { # read/write attribute-method
  my $this = shift;
  croak 'Must be called on object' unless ref $this;
  $this->attributes($_[0] ? 'Yes' : 'No') if (@_);
  return $this->attributes eq 'Yes' ? 1 : $this->attributes eq 'No' ? 0 : undef;
}

=item C<$OBJ-E<gt>measurements(LIST)>

Returns or sets a list of measurements. When called in scalar context, only the
first measurement is returned. Everything is in the default unit of
measurement. (Can be set using C<FrameMaker::MifTree-E<gt>default_unit>. If this
variable is set to the empty string (which also happens to be the default),
points are output.) You always get the values without the unit specifier, so
calculations can be made directly on this. To get a value from the list, do
something like:

  my $q;
  $q = FrameMaker::MifTree->new->add_leaf(
    PgfCellMargins => "0.0 pt 1.0 pt 2.0 pt 3.0 pt"
  );
  my $k = ($q->measurements)[1];
  print "k is now: $k\n"            # prints "k is now: 1"

In MIF, a maximum of four values can be supplied, but this is never checked by
this method.

=cut

sub measurements { # read/write attribute-method
  my $this = shift;
  croak 'Must be called on object' unless ref $this;
  $this->attributes( join(' ', map { convert($_, 'pt') } @_) ) if @_;
  my @mlist = ();
  my $attribute = $this->attributes;
  while ( $attribute =~ /\G(\d*\.?\d+\D*)/gi ) {
    push @mlist, $1;
  }
  @mlist = map { convert($_, undef, 1) } @mlist;
  return wantarray ? @mlist : $mlist[0];
}

=item C<$OBJ-E<gt>percentage(FRACTION)>

Returns or sets the object's percentage value as a fraction (1 = 100%).

=cut

sub percentage { # read/write attribute-method
  my $this = shift;
  croak 'Must be called on object' unless ref $this;
  $this->attributes($_[0] * 100 . '%') if @_;
  my ($value) = $this->attributes =~ /\d*\.?\d+/;
  return $value / 100;
}

=item C<$OBJ-E<gt>facet_data()>

Returns the object's facet data as a list of lines. (Use a C<syswrite> to
C<facet_handle> to set the objects data. Not a very elegant implementation, but
I consider a facet to be rather esoteric, and we have to be efficient on memory
usage as well...)

=cut

sub facet_data { # read-only attribute-method
  my $this = shift;
  croak 'Must be called on object' unless ref $this;
  my $fh = $this->facet_handle;
  if ($fh) {
    sysseek $fh, 0, Fcntl::SEEK_SET;
    my @list = <$fh>;
    return @list;
  } else {
    warnings::warn 'No facet data available' if warnings::enabled || $^W;
  }
}

=item C<$OBJ-E<gt>facet_handle()>

Returns the filehandle to the object's facet data. Since the temporary file is
sysopened, you should use C<syswrite> instead of C<print> to respect the
buffering considerations.

=cut

sub facet_handle { # read-only attribute-method
  my $this = shift;
  croak 'Must be called on object' unless ref $this;
  $this = $this->daughters_by_name(
    '_facet',
    recurse => 0,
  ) unless $this->name eq '_facet';
  croak 'Must be called on facet' unless $this->name eq '_facet';
  return fileno($this->attributes) ? $this->attributes : undef;
}

=item C<FrameMaker::MifTree-E<gt>default_unit(UNIT)>

This class method returns or sets the global default units of measurement. See
C<convert> for a list of valid assignments.

FrameMaker::MifTree's default units of measurement can (and probably will)
differ from the default <Units> that are specified in the MIF file.

The default for C<default_unit> is an empty string, which means that no unit
specifier will be output, and all values are in "points".

=cut

sub default_unit { # read/write attribute-method
  my ($this, $value) = @_[0, 1];
  croak 'This does not seem to be a valid unit of measurement'
    if (defined $value && ! defined $unit_to_factor{$value});
  $default_unit = $value;
  return $default_unit;
}

=item C<FrameMaker::MifTree-E<gt>use_unicode(BOOLEAN)>

This class global method returns or sets if strings are in Unicode or not.

B<Note on Unicode mapping:> Most FrameMaker characters map easily to a Unicode
equivalent. This is not true however, for the discretionary hyphen (hexadecimal
04, E<lt>Char DiscHyphenE<gt>), the FrameMaker "soft hyphen" (hexadecimal 06
E<lt>Char SoftHyphenE<gt>), and the "do not hyphenate" character (hexadecimal
05, E<lt>Char NoHyphenE<gt>).

The discretionary hyphen has a null default appearance in the middle of a line.
At any intraword break that is used for a line break a hyphen glyph will be
shown. Oddly enough this is defined in Unicode as a I<soft hyphen>, and so it
maps to the soft hyphen (U+00AD) character.

The I<soft hyphen> in FrameMaker is used for automatically inserted hyphens by
the FrameMaker hyphenation algorithm. It has no meaning in the MIF, since
FrameMaker will reflow a document upon import. But to preserve it in the
Unicode string, it is mapped to the Unicode hyphen character (U+2010). You
should remove it with C<tr/\x{2010}//d> if you don't want it.

The NoHyphen is a real control character that just prevents a word from being
hyphenated automatically by FrameMaker. To preserve this character when doing
a to and fro conversion, I decided to map it to the Unicode zero-width joiner
(U+200D). 

Everything is controlled from the C<MifTree/FmCharset> file, so make changes
there if you don't like my choices. Or better, override the %fmcharset hash.

=cut

sub use_unicode {
  $use_unicode = $_[1] if exists $_[1];
  return $use_unicode;
}

=back

=head2 Tests on Tree Object

=over 4

=item C<$OBJ-E<gt>is_node()>

Tests if the object is a valid MIF node statement. That is, if its name occurs
in the %mifnodes hash. Returns a list of valid daughters when a match is found.
(In my terminology, "nodes" can have daughters, whereas leaves don't.)

=cut

sub is_node {
  my $this = shift;
  $this = $this->name if ref $this;
  return @{$mifnodes{$this}} if defined $mifnodes{$this};
}

=item C<$OBJ-E<gt>is_leaf()>

Tests if the object is a valid MIF leaf statement and thus can have an
attribute value. The name is just looked up in the %mifleaves hash.

=cut

sub is_leaf {
  my $this = shift;
  $this = $this->name if ref $this;
  return $this if exists $mifleaves{$this};
}

=item C<$OBJ-E<gt>allows_daughter(DAUGHTEROBJECT)>

Checks if a mother object can have a specific daughter object. I just thought
this could come in handy when you want to bind one object tree to another.

=cut

sub allows_daughter {
  my ($mother, $daughter) = @_[0, 1];
  croak 'Must be called on object' unless ref $mother;
  croak 'Mother "' . $mother->name . '" must be called with daughter object'
    unless $daughter->isa('FrameMaker::MifTree');
  if (defined $daughter->name) {
    return grep { $_ eq $daughter->name } $mother->is_node;
  }
}

=item C<$OBJ-E<gt>check_attribute>

Checks if the attribute conforms to the type. Currently the following types are
defined:

  0xnnn
  ID
  L_T_R_B
  L_T_W_H
  W_H
  W_W
  X_Y
  X_Y_W_H
  boolean
  data
  degrees
  dimension
  empty *)
  integer
  keyword
  number
  pathname
  percentage
  seconds_microseconds
  string
  tagstring
  *) no attribute allowed; some leaves and all non-ending nodes have this

The function returns TRUE if the attribute seems valid, and FALSE if there is
an error. Use L<get_attribute_error> to see the error.

=cut

sub check_attribute {
  my $it = shift;
  return $it->get_attribute_error ? undef : 1;
}

=item C<$OBJ-E<gt>get_attribute_error>

Returns a meaningful text string if the attribute appears to be invalid.

=cut

sub get_attribute_error {
  my $it = shift;
  my $errVal;
  if ( defined $it->{attributes} ) {
    unless ( $it->is_leaf ) {
      $errVal = 'Node "' . $it->name . '" is not a leaf. ' .
                'Only leaves can have meaningful attributes';
    } else {
      my $attrType = $mifleaves{$it->name};
      # must access 'attributes' key directly; sorry
      unless ( $it->{attributes} =~ $attribute_types{$attrType} ) {
        $errVal = 'Attribute on leaf "' . $it->name . '" seems invalid. ' .
                  qq(Expected "$attrType" for ") . $it->{attributes} . '"';
      }
    }
  }
  return $errVal;
}

=item C<$OBJ-E<gt>validate(FROMROOT)>

Not yet implemented.

Validates a MIF tree object. If you set FROMROOT to true, the validation starts
from $OBJ->root, and special checking is done on the root object. This special
behaviour is needed because the method cannot know if a FrameMaker::MifTree
object is to represent a complete MIF file, and not just a fragment. So please
remember always to set FROMROOT if you want to validate a complete MIF tree,
even if $OBJ already points to the root object.

=cut

sub validate {
  my ($it, $from_root) = @_[0, 1];
  $it = $it->root if $from_root;
  croak 'Method not yet implemented.'
  # 1. hard-coded checking on root object
  # 2. walk_down, checking allows_daughter and is_leaf for every node
  # 3. if is_leaf: check_attribute
}

=back

=head2 From/to MIF Syntax

=over 4

=item C<LIST = $obj-E<gt>dump_mif()>

Dumps out the current tree as a list of MIF statements in valid MIF file
syntax. You can write the resulting list to a file. The method tries to mimic
the Adobe MIF parser file layout as closely as possible. Please note that this
method can be memory intensive, since it creates a whole new copy of your MIF
tree in memory. If you just want to write the MIF tree to a file, you may want
to use L<dump_miffile> instead.

=cut

sub dump_mif {
  my $obj = $_[0];
  my @list = ();
  $obj->walk_down({
    callback => sub {
      my $this = $_[0];
      if (defined $this->mother) { # don't print root element
        if ((warnings::enabled || $^W) && ! $this->name) {
          warnings::warn 'Missing name on node ' . $this->address;
        }
        if ( ! $this->is_node && ! defined $this->attributes ) {
          if (warnings::enabled || $^W) {
            warnings::warn 'Undefined attribute on leaf "'. $this->name . '"';
          }
          $this->attributes('');
        }
        if ($this->name eq '_facet') {
          push @list, $this->facet_data;
        } else {
          push @list,
            ' ' x (scalar $this->ancestors - 1) .
            '<' . $this->name .
            ($this->name eq 'DocFileInfo' ? "\n"
                                          : ' ' ) . # not very elegant huh?
            ($this->is_node ? "\n"
                            : $this->attributes . ">\n");
        }
      }
      1; # continue recursion
    },
    callbackback => sub {
      my $this = $_[0];
      if (defined $this->mother) { # don't print anything for root...
        if ($this->is_node) {      # ... or for leaves
          push @list, ' ' x (scalar $this->ancestors - 1) .
            '> # End of ' . $this->name . "\n";
        }
      } else {
        push @list, "# End of MIFFile\n";
      }
    }
  });
  return @list;
}

=item C<LIST = $obj-E<gt>dump_miffile(FILENAME)>

Dumps out the current tree of MIF statements into a valid MIF file syntax. The
method returns with a FALSE result if the file cannot be written.

=cut

sub dump_miffile {
  my ($obj, $filename) = @_[0, 1];
  open(my $MIF, ">$filename") || return undef;
  $obj->walk_down({
    callback => sub {
      my $this = $_[0];
      if (defined $this->mother) { # don't print root element
        if ((warnings::enabled || $^W) && ! $this->name) {
          warnings::warn 'Missing name on node ' . $this->address;
        }
        if ( ! $this->is_node && ! defined $this->attributes ) {
          if (warnings::enabled || $^W) {
            warnings::warn 'Undefined attribute on leaf "' . $this->name . '"';
          }
          $this->attributes('');
        }
        if ($this->name eq '_facet') {
          print $MIF $this->facet_data;
        } else {
          print $MIF
            ' ' x (scalar $this->ancestors - 1) .
            '<' . $this->name .
            ($this->name eq 'DocFileInfo' ? "\n"
                                          : ' ' ) . # not very elegant huh?
            ($this->is_node ? "\n"
                            : $this->attributes . ">\n");
        }
      }
      1; # continue recursion
    },
    callbackback => sub {
      my $this = $_[0];
      if (defined $this->mother) { # don't print anything for root...
        if ($this->is_node) {      # ... or for leaves
          print $MIF ' ' x (scalar $this->ancestors - 1) .
            '> # End of ' . $this->name . "\n";
        }
      } else {
        print $MIF "# End of MIFFile\n";
      }
    }
  });
  return 1;
}

=item C<$OBJ-E<gt>parse_mif(STRING)>

Parses a string of MIF statements into the object. This is also a very quick
way to set up an object tree:

  my $new_obj = FrameMaker::MifTree->new();
  $new_obj->parse_mif(<<ENDMIF);
  <MIFFile 7.00># The only required statement
  <Para # Begin a paragraph
  <ParaLine# Begin a line within the paragraph
  <String `Hello World'># The actual text of this document
  > # end of Paraline #End of ParaLine statement
  > # end of Para #End of Para statement
  ENDMIF

Implemented by tying the scalar to a filehandle and calling IO::Tokenizer on
the resulting handle.

The parser currently has the following limitations:

=over 8

=item *

All comments are lost.

=item *

Macro statements are not (yet) implemented.

=item *

Include statements are not (yet) implemented.

=back

Maybe I'll do something about it. Someday.

=cut

sub parse_mif {
  my ($obj, $string) = @_[0, 1];
  my $class = ref($obj) || croak 'Must be called on object';
  my $facet_handle = 0;

  my $fh = IO::Tokenized::Scalar->new();
  $fh->setparser(@parserdefinition);
  $fh->open(\$string);

  my $cur_obj = $obj;
  while ( my ($tok, $val) = $fh->gettoken ) {
    if ( $tok eq 'FACET' ) {
      unless ($facet_handle) {
        $cur_obj->add_facet;
        $facet_handle = $cur_obj->facet_handle;
      }
      syswrite $facet_handle, "$val\n";
    } else {
      $facet_handle = 0;
      if ( $tok eq 'MIFTAG' ) {
        $cur_obj = $cur_obj->add_node($val);
      } elsif ( $tok eq 'RANGLE' ) {
        $cur_obj = $cur_obj->mother;
      } elsif ( $tok eq 'ATTRIBS' ) {
        if (defined $cur_obj->attributes) {
          $cur_obj->attributes($cur_obj->attributes . $val)
        } else {
          $cur_obj->attributes($val)
        }
      }
    }
  }
  $fh->close;
}

=item C<$OBJ-E<gt>parse_miffile(FILENAME)>

Parses a file from disk into a DAG_Node tree structure. See L<parse_mif> for
details.

=cut

sub parse_miffile {
  my ($obj, $filename) = @_[0, 1];
  croak qq(File "$filename" not found) unless -f $filename;
  my $class = ref($obj) || croak 'Must be called on object';
  my $facet_handle = 0;

  my $fh = IO::Tokenized::File->new();
  $fh->setparser(@parserdefinition);
  $fh->buffer_space(524_288);
  $fh->open($filename);

  my $cur_obj = $obj;
  while ( my ($tok, $val) = $fh->gettoken ) {
    if ( $tok eq 'FACET' ) {
      unless ($facet_handle) {
        $cur_obj->add_facet;
        $facet_handle = $cur_obj->facet_handle;
      }
      syswrite $facet_handle, "$val\n";
    } else {
      $facet_handle = 0;
      if ( $tok eq 'MIFTAG' ) {
        $cur_obj = $cur_obj->add_node($val);
      } elsif ( $tok eq 'RANGLE' ) {
        $cur_obj = $cur_obj->mother;
      } elsif ( $tok eq 'ATTRIBS' ) {
        if (defined $cur_obj->attributes) {
          $cur_obj->attributes($cur_obj->attributes . $val)
        } else {
          $cur_obj->attributes($val)
        }
      }
    }
  }
  $fh->close;
}

=back

=head2 Old-style Functions

All these functions are exported by default.

=over 4

=item C<quote(STRING)>

Quotes a string with MIF style quotes, and escapes forbidden characters.
Backslashes, backticks, single quotes, greater-than and tabs are escaped,
non-ASCII values are written in their hexadecimal representation. So:

Some `symbols': E<gt> \E<216>E<191>!>

is written as

  `Some \Qsymbols\q: \> \\\xaf \xc0 !'

As a special case, escaped hexadecimals are preserved in the input string. If
you want a literal \x00 string, precede it with an extra backslash.

  print quote("\x09 ");     # prints `\x09 ', a forced return in FrameMaker
  print quote("\\x09 ");    # prints `\\x09 '; this will show up literally
                            # as \x09 in FrameMaker

(Note that after emitting a forced return, you I<must> start a new ParaLine.)

If the global modifier $FrameMaker::MifTree::use_unicode is true, the string
will be converted from Unicode to the FrameMaker character set.


=cut

sub quote {
  my ($s, $use_unicode_deprecated) = @_;
  return unless defined $s;
  if ((warnings::enabled || $^W) && defined $use_unicode_deprecated) {
    warnings::warn 'USE_UNICODE as 2nd argument is now deprecated';
  }

  if ($use_unicode_deprecated || $use_unicode) {
    my $s_orig = $s;
    eval($unicode_to_fm);
    warnings::warn qq(Error in "quote" while converting $s_orig\n$@) if $@;
  }

  $s =~ s/\\(?!x[a-f0-9]{2})/\\\\/g;   # single backslash to escaped backslash
                                       # except when followed by hex sequence
  $s =~ s/\\\\\\(?=x[a-f0-9]{2})/\\/g; # correct double backslash case
  $s =~ s/`/\\Q/g;                     # backtick
  $s =~ s/'/\\q/g;                     # single straight quote
  $s =~ s/>/\\>/g;                     # escape 'greater than'

  # control and high chars
  $s =~ s/([\x00-\x1a\x80-\xff])/'\x' . sprintf('%02x ', ord $1)/ge;

  return "`$s'";
}

=item C<unquote(STRING)>

The opposite action. Surrounding quotes are removed and all escaped sequences
are transliterated into their original character.

If the global modifier $FrameMaker::MifTree::use_unicode is true, the string
will be converted from the FrameMaker character set to Unicode.

$FrameMaker::MifTree::use_unicode can be exported on request.

=cut

sub unquote {
  my ($s, $use_unicode_deprecated) = @_;
  return unless defined $s;
  if ((warnings::enabled || $^W) && defined $use_unicode_deprecated) {
    warnings::warn 'USE_UNICODE as 2nd argument is now deprecated';
  }

  $s =~ s/^`// && $s =~ s/'$//;  # unquote
  $s =~ s/\\x([a-f0-9]{1,2}) ?/chr hex $1/ge; # escaped non-ASCII chars
  $s =~ s/\\>/>/g;               # greater than
  $s =~ s/\\q/'/g;               # single quote
  $s =~ s/\\Q/`/g;               # backtick
  $s =~ s/\\\\/\\/g;             # backslash

  if ($use_unicode_deprecated || $use_unicode) {
    my $s_orig = $s;
    eval($fm_to_unicode);
    warnings::warn qq(Error in "unquote" while converting $s_orig\n$@) if $@;
  }

  return $s;
}

=item C<encode_path(STRING)>

Encodes path names to the MIF path syntax. Usage:

   $mifPathString = encode_path('D:\Dos\Path\With\Backslashes\Filename');
   $mifPathString = encode_path('..\..\Also\Relative\Path\Is\Allowed\Filename');

The path name must not be in a MIF quoted style. It returns the device
independent path name I<with> the quotes.

=cut

sub encode_path {
  my $s = shift;
  return unless defined $s;

  $s =~ s{^`}{} && $s =~ s{'$}{};       # Remove quotes, just in case...
  $s =~ s{\\}{/}g;                      # All backslashes to forward slashes

  $s =~ s{^([a-z]:)}{<v\\>$1}i;         # drive letter <v\>
  $s =~ s{^//}{<h\\>};                  # unc path <h\>
  $s =~ s{\.\./}{<u\\>}g;               # .. 'up' in hierarchy to <u\>
  $s =~ s{<u\\>([^<])}{<u\\><c\\>$1}g;  # correct last <u\> to <u\><c\>
  $s =~ s{/}{<c\\>}g;                   # 'component' separators <c\>
  $s =~ s{^([^<])}{<c\\>$1};            # start relative path with <c\>
  $s =~ s{`}{\\Q}g;                     # backtick
  $s =~ s{'}{\\q}g;                     # single straight quote
  $s =~ s{([\x81-\xff])}{'\x' . sprintf('%lx', ord $1) . ' '}ge; # high chars

  return "`$s'";
}

=item C<decode_path(STRING, [ROOTPATH])>

Usage:

   print decode_path ('<v\>C:<c\>Mydir<c\>Subdir<c\>Filename');
   # prints C:/Mydir/Subdir/Filename
   print decode_path ('<u\><u\><c\>Subdir<c\>Filename');
   # prints ../../Subdir/Filename

Currently only Windows path names are supported (meaning that Unix and MacOS
style paths remain untested). MIF string quotes are removed. ROOTPATH, if
specified, is the path that is prepended if STRING happens to be a relative
path.

=cut

sub decode_path {
  my ($s, $root) = @_[0, 1];
  return unless defined $s;
  ($root ||= '') =~ s{([^\\/])$}{$1/};  # add slash if necessary

  $s =~ s{^`}{} && $s =~ s{'$}{};

  $root = '' unless $s =~ m{^<[cu]\\>}; # only use $root when
                                        # relative path is found
  $s =~ s{<v\\>}{};
  $s =~ s{<h\\>}{//};
  $s =~ s{<u\\>(<c\\>)?}{../}g;
  $s =~ s{^<c\\>}{}g;    # path starting with <c\> indicates relative path name
  $s =~ s{<c\\>}{/}g;
  $s =~ s{\\q}{'}g;                     # single quote
  $s =~ s{\\Q}{`}g;                     # backtick
  $s =~ s{\\x([a-f0-9]{2}) ?}{chr hex $1}ge; # escaped non-ASCII chars

  return "$root$s";
}

=item C<convert(VALUE_AND_OLDUNIT, NEWUNIT, SUPPRESSUNIT)>

Converts a value in one unit of measurement into another. If you leave out the
unit of measurement it defaults to FrameMaker::MifTree->default_unit (not to the
MIF document's default unit of measurement!). Other measurements are:

  {
    pt         => 1 / 72,
    point      => 1 / 72,
    "          => 1,
    in         => 1,
    mm         => 1 / 25.4,
    millimeter => 1 / 25.4,
    cm         => 1 / 2.54,
    centimeter => 1 / 2.54,
    pc         => 1 / 6,
    pica       => 1 / 6,
    dd         => 0.01483,
    didot      => 0.01483,
    cc         => 12 * 0.01483,
    cicero     => 12 * 0.01483
  }

The optional argument SUPPRESSUNIT determines if the unit of measurement needs
to be written in the result. Note that you won't get a unit of measurement
included in your result when you leave out NEWUNIT and specify
C<FrameMaker::MifTree-E<gt>default_unit> to be the empty string, even if you set
SUPPRESSUNIT to be false. In that case the returned value is in points. So

  FrameMaker::MifTree->default_unit('');
  print convert('12.0 didot');            # prints the value in points: 12.8131
  FrameMaker::MifTree->default_unit('mm');
  print convert('12.0 didot', 'pt', 1);   # also prints 12.8131
  FrameMaker::MifTree->default_unit('pt');
  print convert('12.0 didot', '', 1);     # also prints 12.8131

All values are rounded to 4 decimals.

=cut

sub convert {
  my ($num_val, $old_unit) = shift =~ /(-?\d*\.?\d+)\s*(\D*)/;
  my $new_unit = shift || $default_unit;
  my $suppress_unit = shift;
  $old_unit ||= $default_unit;
  $old_unit =~ s/\s//g;
  $new_unit =~ s/\s//g;
  my $new_value = sprintf '%.4f',
                          $num_val * $unit_to_factor{$old_unit} /
                                     $unit_to_factor{$new_unit};
  $new_unit = " $new_unit" unless $new_unit eq q(") || $new_unit eq '';
  return $new_value . ($suppress_unit ? '' : $new_unit);
}

END {} # Global destructor

1;

__END__

=back

=head1 SEE ALSO

=over 4

=item *

Adobe's I<MIF_Reference.pdf>, included in FrameMaker's online documentation.

=item *

L<http://www.miffy.com>, as this module was formerly called Miffy.pm

=back

=head1 AUTHOR

Roel van der Steen, roel-perl@st2x.net

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by ITP and Roel van der Steen

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
