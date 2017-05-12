package Hash::AutoHash::Record;
our $VERSION='1.17';
$VERSION=eval $VERSION;		# I think this is the accepted idiom..

#################################################################################
#
# Author:  Nat Goodman
# Created: 09-03-05
# $Id: 
#
# Flat and hierarchical record structures of the type encountered in Data::Pipeline
#
#################################################################################
use strict;
use Carp;
use Hash::AutoHash;
use base qw(Hash::AutoHash);

our @NORMAL_EXPORT_OK=@Hash::AutoHash::EXPORT_OK;
my $helper_class=__PACKAGE__.'::helper';
our @EXPORT_OK=$helper_class->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=$helper_class->SUBCLASS_EXPORT_OK;

#################################################################################
# helper package exists to avoid polluting Hash::AutoHash::Args namespace with
#   subs that would mask accessor/mutator AUTOLOADs
# functions herein (except _new) are exportable by Hash::AutoHash::Args
#################################################################################
package Hash::AutoHash::Record::helper;
our $VERSION=$Hash::AutoHash::Record::VERSION;
use strict;
use Carp;
BEGIN {
  our @ISA=qw(Hash::AutoHash::helper);
}
use Hash::AutoHash qw(autohash_tie);

sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie Hash::AutoHash::Record::tie,@args;
  bless $self,$class;
}
# Override autohash_clear to allow clearing of specific keys
sub autohash_clear {
  my $record=shift;
  tied(%$record)->CLEAR(@_);
}

#################################################################################
# Tied hash which implements Hash::AutoHash::Record
#################################################################################
package Hash::AutoHash::Record::tie;
our $VERSION=$Hash::AutoHash::Record::VERSION;
use strict;
use Carp;
use Tie::Hash;
use Scalar::Util qw(reftype);
use List::MoreUtils qw(uniq);
use Storable qw(dclone);
use Hash::AutoHash qw(autohash_alias);
use Hash::AutoHash::AVPairsSingle;
use Hash::AutoHash::AVPairsMulti;
our @ISA=qw(Tie::ExtraHash);

my $i=0;
use constant STORAGE=>$i++;
use constant DEFAULTS=>$i++;
use constant DEFAULT_TYPE_SCALAR=>$i++;
use constant DEFAULT_TYPE_ARRAY=>$i++;
use constant DEFAULT_TYPE_HASH=>$i++;
use constant UNIQUE=>$i++;
use constant FILTER=>$i++;
# use constant FIELDS=>$i++;
# use constant TYPES=>$i++;

# # undef means no type conversion
# our $default_type_scalar;	# no type conversion
# our $default_type_array;	# no type conversion
# our $default_type_hash='Hash::AutoHash';
# our $default_type_refhash='Hash::AutoHash::AVPairsMulti';

sub TIEHASH {
  my($class,@hash)=@_;
  my $self=bless [],$class;
  # use initial values (possibly flattened) as defaults
  my $defaults=$self->defaults(_flatten(@hash));
  $self->[STORAGE]=$defaults? dclone($defaults): {};
  $self;
}
sub FETCH {
  my($self,$key)=@_;
  my $storage=$self->[STORAGE];
  my $value=$storage->{$key};
  if (wantarray) {
# NG 09-10-12: line below was holdover from MultiValued.  Not correct here
#    return () unless defined $value;
    return @$value if 'ARRAY' eq reftype($value);
    return %$value if 'HASH' eq reftype($value);
    return ($value);
  }
  $value;
}
# FUTURE possibility: check whether hash locked & key exists  

sub STORE {
  my($self,$key,@values)=@_;
  my $storage=$self->[STORAGE];
  $self->_store($storage,$key,@values);
  $self->FETCH($key);
}
sub CLEAR {
  my($self,@keys)=@_;
  my $defaults=$self->defaults;
  unless (@keys) {
    $self->[STORAGE]=$defaults? dclone($defaults): {}
  } else {				# clear specific keys
    my $storage=$self->[STORAGE];
    my $defaults=$self->[DEFAULTS];
    for my $key (@keys) {
      my $default=$defaults->{$key};
      my $new=$self->_convert_initial_value($default);
      $storage->{$key}=$default;
    }}
  my $unique=$self->unique;
  $self->_unique($unique) if $unique;
}
*clear=\&CLEAR;

# default values. 
# can be set from initial values suppled to TIEHASH, or explicitly
sub defaults {
  my $self=shift;
  my $defaults;
  if (@_) {			# set new value
    my @hash=(@_==1 && 'ARRAY' eq ref $_[0])? @{$_[0]}: (@_==1 && 'HASH' eq ref $_[0])? %{$_[0]}:
      @_;
    $defaults={};
    while (@hash>1) {		        # store initial values
      my($key,$value)=splice @hash,0,2; # shift 1st two elements
      $self->_store($defaults,$key,$value);
    }
    $self->[DEFAULTS]=$defaults; # set object attribute
  } else {			 # get defaults from object
    $defaults=$self->[DEFAULTS];
  }
  wantarray? %{$defaults || {}}: $defaults;
}

# forcibly assign value or set to undef
sub force {
  my($self,$key)=splice @_,0,2;	# shift 1st 2 elements
  my $storage=$self->[STORAGE];
  $storage->{$key}=undef;	# once field is undef, _store can do the rest
  $self->_store($storage,$key,@_) if @_;
  $self->FETCH($key);
}

# code adapted from Hash::AutoHash::MultiValued
sub unique {
  my $self=shift;
  return $self->[UNIQUE] unless @_;
  my $unique=$self->[UNIQUE]=shift;
  $unique=$self->[UNIQUE]=sub {$_[0] eq $_[1]} if $unique && 'CODE' ne ref $unique;
  $self->_unique($unique) if $unique;
  $unique;
}
sub _unique {
  my($self,$unique)=@_;
  my $storage=$self->[STORAGE];
  my @values=grep {defined $_ && 'ARRAY' eq reftype($_)} values %$storage;
  for my $values (@values) {
    next unless @$values;
    # leave 1st value in @$values. put rest in @new_values
    my @new_values=splice(@$values,1);
    my($a,$b);
    for $a (@new_values) {
      push(@$values,$a) unless grep {$b=$_; &$unique($a,$b)} @$values;
    }}
}
# code adapted from Hash::AutoHash::MultiValued
sub filter {
  my $self=shift;
  my $filter=@_? $self->[FILTER]=shift: $self->[FILTER];
  if ($filter) {		# apply to existing values -- ARRAYs only
    $filter=$self->[FILTER]=\&uniq unless 'CODE' eq ref $filter;
    my $storage=$self->[STORAGE];
    my @values=grep {defined $_ && 'ARRAY' eq reftype($_)} values %$storage;
    map {@$_=&$filter(@$_)} @values; # updates each list in-place
  }
  $filter;
}

# sub _default_type_scalar  {shift->_default_type('scalar',@_);}
# sub _default_type_array   {shift->_default_type('array',@_);}
# sub _default_type_hash    {shift->_default_type('hash',@_);}
# sub _default_type_refhash {shift->_default_type('refhash',@_);}
# sub _default_type {
#   my($self,$type)=splice @_,0,2;
#   my $default;
#   if (@_) {			# set new value in object
#       $default=$self->[uc "default_type_$type"]=$_[0];
#     } else {			# get defaults from object if possible, else from class
#       $default=$self->[uc "default_type_$type"];
#       unless (defined $default) { # now look in class
# 	my $class=ref $self;
# 	no strict 'refs';
# 	my $class_var=$class."::default_type_$type";
# 	$default=${$class_var};
#       }}
#   $default;
# }
# sub _convert_initial_value {
#   my($self,$value)=@_;
#   my $type=
#     (!ref $value)? 'scalar':
#       ('ARRAY' eq ref $value)? 'array':
# 	('HASH' eq ref $value)? 'hash':
# 	  ('REF' eq ref $value && 'HASH' eq ref $$value)? 'refhash':
# 	  undef;
#   my $class=$self->_default_type($type) if $type;
#   $value=$class? new $class $value: $value;
#   $value;
# }
sub _convert_initial_value {
  my($self,$value)=@_;
  if ('HASH' eq ref $value) {
    # attribute-single-value pair if no refs
    # else attribute-multi-value pair if only refs are ARRAY
    # else use as is
    my @values=values %$value;
    # CAUTION: doing grep below w/o map seems to stringify refs to things like ARRAY(0x1163510)
    my @refs=grep {$_} map {ref $_} @values;
    if (!@refs) {
      $value=new Hash::AutoHash::AVPairsSingle $value;
    } elsif (!grep !/^ARRAY$/,@refs) {
      $value=new Hash::AutoHash::AVPairsMulti $value;
    } 
  } elsif ('REF' eq ref $value && 'HASH' eq ref $$value) {
    my @values=values %$$value;
    # CAUTION: doing grep below w/o map seems to stringify refs to things like ARRAY(0x1163510)
    my @refs=grep {$_} map {ref $_} @values;
    if (!grep !/^ARRAY$/,@refs) {
      $value=new Hash::AutoHash::AVPairsMulti $$value;
    }}
  $value;
}

# logic: check type of old value and new value
# old undef. anything goes. new value replaces old w/ initial value conversion
# old scalar && new scalar. new value replaces old
# old ARRAY && new any value. multi-valued field. new pushed onto old & possibly uniqued
# old Hash::AutoHash. new must be HASH or ARRAY or list of key=>value pairs.
#  new elements set in old using method notation
# old anything else.  new value replaces old

sub _store {
  my($self,$storage,$key,@new)=@_;
  return unless @new;
  my $old=$storage->{$key};
  if (!defined $old) {	               # old undef. anything goes. new replaces old.
    if (@new==1 && 'ARRAY' eq ref $new[0]) { # new multi-valued field
      $storage->{$key}=[];	       # initialize to empty ARRAY. recursion will do the rest
    } else {
      my $new1=shift @new;
      $new1=$self->_convert_initial_value($new1);
      $storage->{$key}=$new1;
    }
    $self->_store($storage,$key,@new); # recurse
  } elsif (!ref $old) {	               # old scalar. new replaces old. must be scalar
    my $new=shift @new;
    $new=$self->_convert_initial_value($new);
    confess "Trying to store multiple values in single-valued field $key" if @new;
    confess "Trying to store reference in single-valued field $key" if ref $new;
    $storage->{$key}=$new;
  } elsif ('ARRAY' eq ref $old) {       # old ARRAY. push new onto old. must be scalar
#    $self->_store_multi($old,@new);
    # code adapted from Hash::AutoHash::MultiValued
    @new=@{$new[0]} if @new==1 && 'ARRAY' eq ref $new[0];
    confess "Trying to store reference in multi-valued field $key" if grep {ref($_)} @new;
    if (my $unique=$self->unique) {
      my($a,$b);
      for $a (@new) {
	push(@$old,$a) unless grep {$b=$_; &$unique($a,$b)} @$old;
      }} else {
	push(@$old,@new);
      }
  } elsif (UNIVERSAL::isa($old,'Hash::AutoHash')) { # old Hash::AutoHash
    @new=_flatten(@new);
    while (@new>1) {		        # store initial values
      my($key,$value)=splice @new,0,2;	# shift 1st two elements
      $old->$key($value);		# store using hash notation
    }
  } else {				# old anything else.
    $storage->{$key}=$new[0];		# new replaces old
  }
}
# # store into multi-valued field, or store multi-value into undef field
# sub _store_multi {
#   my($self,$old,@new)=@_;
#   # code adapted from Hash::AutoHash::MultiValued
#   @new=@{$new[0]} if @new==1 && 'ARRAY' eq ref $new[0];
#   if (my $unique=$self->unique) {
#     my($a,$b);
#     for $a (@new) {
#       push(@$old,$a) unless grep {$b=$_; &$unique($a,$b)} @$old;
#     }} else {
#       push(@$old,@new);
#     }
# }
sub _flatten {
  if (@_==1) {
    return ('ARRAY' eq ref $_[0])? @{$_[0]}: ('HASH' eq ref $_[0])? %{$_[0]}: @_;
  }
  @_;
}

1;

__END__

=head1 NAME

Hash::AutoHash::Record - Object-oriented access to hash with implicitly typed fields

=head1 VERSION

Version 1.17

=head1 SYNOPSIS

  use Hash::AutoHash::Record qw(autohash_set);

  # create object and define field-types
  #   name- single-valued, hobbies- multi-valued,
  #   favorites- attribute-single-value pairs, 
  #   family- attribute-multi-value pairs
  # note: when used as initial value, 
  #   {}  means empty attribute-single-value pairs
  #   \{} means empty attribute-multi-value pairs

  my $record=
    new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};

  # set fields
  autohash_set($record,
               name=>'Joe',hobbies=>['chess','cooking'],
               favorites=>{color=>'purple',food=>'pie'},
               family=>{wife=>'Mary',sons=>['Tom','Dick']});

  # update fields one-by-one
  $record->name('Joey');                      # change name to 'Joey'
  $record->hobbies('go');                     # add 'go' to hobbies
  $record->favorites(color=>'red');           # change favorite color to 'red'
  $record->family(daughters=>'Jane');         # add daughter 'Jane' to family

  # access fields one-by-one
  my $name=$record->name;                     # 'Joey'
  my $hobbies=$record->hobbies;               # ['chess','cooking','go']
  my @hobbies=$record->hobbies;               # ('chess','cooking','go')
  my $favorites=$record->favorites;           # Hash::AutoHash in scalar context
  my %favorites=$record->favorites;           # regular hash in array context
  my $family=$record->family;                 # Hash::AutoHash::AVPairsMulti
  my %family=$record->family;                 # regular hash

  # you can also use standard hash notation and functions
  $record->{name}='Joseph';                   # set name to 'Joseph'
  $record->{hobbies}='rowing';                # add 'rowing' to hobbies
  $record->{favorites}={holiday=>'Christmas'};# add favorite holiday
  $record->{family}={daughters=>'Sue'};       # add 2nd daughter 'Sue' to family

  # CAUTION: hash notation doesn't respect array context!
  $record->{hobbies}=('hiking','baking');     # adds last value only
  my @hobbies=$mvhash->{hobbies};             # list of ARRAY (['chess',...])

  my @keys=keys %$record;                     # list of all 4 keys
  my @values=values %$record;                 # list of all 4 values
  delete $record->{hobbies};                  # no more hobbies

  # clearing object restores initial values and preserves field-types
  %$record=();                             
 
  # alias $record to regular hash for more concise hash notation
  use Hash::AutoHash::Record qw(autohash_alias);
  my %hash;
  autohash_alias($record,%hash);
  # access or change hash elements without using ->
  $hash{name}='Joe';                          # set name to 'Joe'
  @hash{qw(hobbies favorites family)}=        # set remaining fields
    (['chess','cooking'],
     {color=>'purple',food=>'pie'},
     {wife=>'Mary',sons=>['Tom','Dick']});

  my $name=$hash{name};                       # get 1 field
  my($hobbies,$favorites,$family)=            # get remaining fields
    @hash{qw(hobbies favorites family)};

  # set 'unique' in tied object to eliminate duplicates in multi-valued fields
  use Hash::AutoHash::Record qw(autohash_tied);
  autohash_tied($record)->unique(1);
  $record->hobbies('chess','skiing');         # duplicate 'chess' not added

  # field can also be any Hash::AutoHash object, including Record (!!)
  my $address=new Hash::AutoHash::Record lines=>[],city=>'',state=>'',zip=>'';
  $record->address($address);                 # add empty address to record
  # set fields of nested record
  $record->address(lines=>['Suite 123','456 Main St'],city=>'Anytown',
                   state=>'WA',zip=>98765);
  my $state=$record->address->state;          # get field from nested record

=head1 DESCRIPTION

Hash::AutoHash::Record is a subclass of L<Hash::AutoHash> designed to
represent records parsed from flat files.  The fields of the records
can be single-valued, multi-valued, or a collection of attribute-value
pairs which, in turn, can allow single or multiple values per
attribute. A field can also be any L<Hash::AutoHash> object, including
a Hash::AutoHash::Record object, which makes it possible to represent
nested record structures.

In typical usage, we expect the application to create a
Hash::AutoHash::Record object at the outset with appropriate default
values, then reuse the object repeatedly as the program processes
input lines.  Another reasonable pattern is to use dclone from
L<Storable> to copy the original Hash::AutoHash::Record object for
each input line.  It is also possible to create a new
Hash::AutoHash::Record object for each input line, but this is likely
to be slower.

Hash::AutoHash::Record offers two main features over and above
L<Hash::AutoHash>.

=over 2

=item 1. Special update semantics for each type of field.

The class uses the field-type to process updates in a manner
appropriate for each type. For single-valued fields, the new value
overwrites the old, just as in a regular HASH. For multi-valued
fields, the new value or values are appended to the existing values,
as in L<Hash::AutoHash::MultiValued>. For fields that contain a
collection of attribute-value pairs, the new values (which must be
attribute-value pairs) modify the existing ones.  For fields that
contain a L<Hash::AutoHash> object, the new values (which must be
key=>value pairs) are interpreted as updates to the corresponding
elements of the object.  If the field contains any other kind of
value, the new value overwrites the old, just like a regular HASH.

=item 2. Default values restored when object is cleared.

Default values for each field are set when the object is created.
(Defaults can also be set or changed later).  Default values can be
anything but are often the natural 'empty' value for the field-type,
namely, the null string for single-valued fields, an empty ARRAY for
multi-valued fields, and an empty collection of attribute-value pairs
for a field of that type. Clearing the object restores the default
values of all fields.

=back

=head2 Example of typical usage

We use this class in a data pipeline that downloads files from many
sources, extracts relevant information, and stores the results in a
database. The files come in many different formats. An early step in
the pipeline converts the files into a simple, common format that
suits our needs.

Many of the files we download are tab-delimited text: each line is a
record and field consists of arbitrary text up to the next tab (or
end-of-line).  Some of these files allow fields to be multi-valued
using '|'(vertical-bar) to separate values, and to contain
attribute-value pairs using ':' to separate attributes from values.
Here is a simplified example line from a file that provides basic
information about genes.

HTT	HD|IT15	review:09-09-26|update:09-09-25	Entrez:3064|MIM:613004|MIM:143100

The first field is the official name of the gene. The next field shows
alternate names for the gene.  The third field provides dates for the
most recent actions on this record.  The final field lists databases
that contain further information about the gene along with keys for
retrieving the information.

The first field is single-valued. The second is multi-valued. The
third contains attribute-single-value pairs, ie, attributes cannot
be repeated. The fourth contains attribute-multi-value pairs, ie,
attributes may be repeated.

We convert this file into multiple tab-delimited files, one for each
field. Each line contains the current date (for tracking purposes),
and the official gene name (for linking information later).
Multi-valued fields are printed to multiple lines, with one value per
line.  Attribute-value pairs are printed as separate fields.

Here is a sketch of a program for doing this.

  use Hash::AutoHash::Record;
  my $now=localtime;                        # current datetime

  # create object and set initial values. initial values implicitly set defaults 
  # and field-types
  # note: when used to set initial values, 
  #   {}  denotes empty collection of attribute-single-value pairs
  #   \{} denotes empty collection of attribute-multi-value pairs

  my $record=
    new Hash::AutoHash::Record when=>$now,official_name=>'',alternate_names=>[],
                               actions=>{},more_info=>\{};
  while (<>) {            # assume input on STDIN
    parse($record);       # assume parse parses input line into $record
    emit($record);        # assume emit prints fields from $record to outputs
    %$record=();          # clear record to restore defaults for next input line                 
  }
 
=head2 Capabilities inherited from Hash::AutoHash

Like L<Hash::AutoHash>, this class lets you get or set hash
elements using hash notation or by invoking a method with the same
name as the key.  See L<SYNOPSIS> for examples.  

Also like L<Hash::AutoHash>, this class provides a full plate of
functions for performing hash operations on
Hash::AutoHash::Record objects.  These are useful if you want to
avoid hash notation all together. The following example uses
these functions to removes hash elements whose values are empty lists:

  use Hash::AutoHash::Record qw(autohash_keys autohash_delete);
  my $record=new Hash::AutoHash::Record name=>'',hobbies=>[];
  my @keys=autohash_keys($record);
  for my $key (@keys) {
    my $value=$record->$key;
    autohash_delete($record,$key) if 'ARRAY' eq ref $value && !@$value;
  }

And also like L<Hash::AutoHash>, you can alias the object to a regular
hash for more concise hash notation. See L<SYNOPSIS> for examples.
Admittedly, this is a minor convenience, but the reduction in
verbosity can be useful in some cases.

As in L<Hash::AutoHash>, the namespace is "clean"; any method invoked
on an object is interpreted as a request to access or change an
element of the underlying hash.  The software accomplishes this by
providing all its capabilities through class methods (these are
methods, such as 'new', that are invoked on the class rather than on
individual objects), functions that must be imported into the caller's
namespace, and methods invoked on the tied object implementing the
hash.

CAUTION: As of version 1.12, it is not possible to use method
notation for keys with the same names as methods inherited from
UNIVERSAL (the base class of everything). These are 'can', 'isa',
'DOES', and 'VERSION'.  The reason is that as of Perl 5.9.3, calling
UNIVERSAL methods as functions is deprecated and developers are
encouraged to use method form instead. Previous versions of AutoHash
are incompatible with CPAN modules that adopt this style.

=head2 Field-types

The type of a field is determined implicitly by its value.  When you
create a Hash::AutoHash::Record object, you can specify initial values
for the fields.  These values implicitly set the type of each
field. Similarly, when you store a value into a new field (one whose
key does not yet exist in the object), that value implicitly sets the
type of the new field.  To change the type of a field, you can use the
'force' method on the B<tied object implementing the record> to
assign a new value to the field without regard to its current type.

Supported field-types are

=over 2

=item * Single-valued

Strings or numbers.  Not references. 

=item * Multi-valued

Multiple strings or numbers (not references).  Implemented as an ARRAY.

=item * Collection of attribute-single-valued pairs

Each attribute can have just a single value which must be a string or
number (not a reference).  This type is implemented as a
L<Hash::AutoHash::AVPairsSingle> object.

=item * Collection of attribute-multi-valued pairs

Each attribute can have multiple values, and for this reason, the type
is implemented as a L<Hash::AutoHash::AVPairsMulti> object. 

=item * Hash::AutoHash object

Any object derived from L<Hash::AutoHash>. The attribute-value pair
types are special cases of this.

=item * Anything else

Other types of data are allowed, but the class provides no special support. 

=back

=head2 Special handling of initial values

When setting the initial value of a field, the class interprets an
unblessed HASH or unblessed reference to an unblessed HASH as a collection of
attribute-value pairs if the HASH contains suitable data. This occurs
when setting initial values via 'new' as illustrated in the
L<SYNOPSIS> and other examples, when setting the value of a new field,
when forcibly changing the value and possibly type of a field via
'force', and when setting defaults via 'defaults'.

=over 2

=item * Initial unblessed HASH

If the HASH is empty or all elements are single-valued (strings or
numbers, not references), the class treats it as a collection of
attribute-single-value pairs and instantiates a
L<Hash::AutoHash::AVPairsSingle> object to represent the value.  Else, if
all elements are single- or multi-valued (strings or numbers, not
references), the class considers it to be a collection of
attribute-multi-value pairs and instantiates a
L<Hash::AutoHash::AVPairsMulti> object. Else, the class uses the value as
is.

  my $record=new Hash::AutoHash::Record
    avp_single=>{attr1=>'value1'},avp_multi=>{attr2=>['value21','value22']},
    hash=>{key3=>{key31=>'value31'}};

CAVEAT: This usage makes it difficult to set the initial value of a
field to a regular HASH. You can workaround the problem by a blessed
HASH. Here is an example.

  my $record=new Hash::AutoHash::Record hash=>bless {};

=item * Initial unblessed reference to unblessed HASH

If the referent HASH is empty or all elements are single- or
multi-valued (strings or numbers, not references), the class
interprets it as a collection of attribute-multi-value pairs and
instantiates a L<Hash::AutoHash::AVPairsMulti> object. Else, the class
uses the value as is.

  my $record=new Hash::AutoHash::Record
    avp_multi1=>\{attr1=>'value1'},avp_multi2=>{attr2=>['value21','value22']},
    hash=>{key3=>{key31=>'value31'}};

CAVEAT: This usage makes it difficult to set the initial value of a
field to a real reference to a HASH. Sorry. You can workaround the
problem by using a reference to any blessed HASH. Here is an example.

  my $record=new Hash::AutoHash::Record ref_to_hash=>\bless {};

=back

=head2 Field-update semantics

The field-type controls which updates are legal and how they are
processed.

=over 2

=item * Single-valued

The new value must also be single-valued and not a reference.  The new
value overwrites the old, just like a regular HASH.

  $record=new Hash::AutoHash::Record single=>'value1';
  $record->single('value2');                  # sets field to 'value2'
  $record->single('value3','value4');         # illegal - multiple new values

=item * Multi-valued

The new value or values are appended to the end of the existing
values, as in L<Hash::AutoHash::AVPairsMulti>.  The new values must be
strings or numbers, not references. It is okay to pass in an ARRAY
which the code flattens to a list.

  $record=new Hash::AutoHash::Record multi=>['value1'];
  $record->multi('value2');                  # appends 'value2' to old value
  $record->multi('value3','value4');         # appends 'value3','value4'
  $record->multi(['value4','value5']);       # appends 'value4','value5'
  $record->multi({key6=>'value6'});          # illegal - reference  

=item * Collection of attribute-single-value pairs

The new values must be attribute-value pairs. (A HASH will work as
will a list or ARRAY with an even number of elements). For each
attribute that already exists in the collection, the new value
overwrites the old.  For each new attribute, the pair is added to the
collection.

  $record=new Hash::AutoHash::Record avp_single=>{attr1=>'value1'};
  $record->avp_single(attr1=>'new_value1');  # sets attr1 to 'new_value1'
  $record->avp_single(attr2=>'value2');      # adds attr2=>'value2'
  $record->avp_single([attr3=>'value3']);    # adds attr3=>'value3'
  $record->avp_single({attr4=>'value4'});    # adds attr4=>'value4'
  $record->avp_single(attr5=>['value5']);    # illegal - value is reference
  $record->avp_single('attr6');              # ignored. no value
   
=item * Collection of attribute-multi-value pairs

The new values must be attribute-value pairs. (A HASH will work as
will a list or ARRAY with an even number of elements). For each
attribute that already exists in the collection, the new value or
values are appended to the existing ones. For each new attribute, the
pair is added to the collection.

  $record=new Hash::AutoHash::Record avp_multi=>\{attr1=>'value1'};
  $record->avp_multi(attr1=>'new_value1');   # appends 'new_value1' to attr1
  $record->avp_multi(attr2=>'value2');       # adds attr2=>'value2'
  $record->avp_multi([attr2=>'new_value2']); # appends 'new_value2 to attr2
  $record->avp_multi({attr3=>'value3'});     # adds attr3=>'value3'
  $record->avp_multi(attr3=>['new_value2']); # appends new_value3 to attr3
  $record->avp_multi(attr4=>{key=>value});   # illegal - value is reference
  $record->avp_multi('attr5');               # ignored. no value
   
=item * Hash::AutoHash object

Any object derived from L<Hash::AutoHash>. The attribute-value pair
types are special cases of this.

The new values must be key=>value pairs. (A HASH will work as will a
list or ARRAY with an even number of elements). The values are set in
the object using method notation.

  $autohash=new Hash::AutoHash key1=>'value1';
  $record=new Hash::AutoHash::Record autohash=>$autohash;
  $record->autohash(key1=>'new_value1');    # runs $autohash->key1('new_value1')
  $record->autohash(key2=>'value2');        # runs $autohash->key2('value2')
  $record->autohash('key3');                # ignored. no value

=item * Anything else

The new value overwrites the old, just like a regular HASH.  This
includes the case of setting the initial value for a nonexistent
key. Thereafter, the type of the new value determines the type of the
field , eg, if the new value is an ARRAY, the field becomes
multi-valued.

=back

=head2 Default values

Default values for each field are set when the object is created, and
can be set or changed later via the 'defaults' method.  Clearing the
object restores the default values.

=head2 Duplicate elimination and filtering (multi-valued fields only!!)

By default, multi-valued fields may contain duplicate values.  You can
change this behavior by setting 'unique' in the B<tied object
implementing the hash> to a true value.

  use Hash::AutoHash::Record qw(autohash_tied);
  my $record=new Hash::AutoHash::Record hobbies=>['chess','chess'];
  autohash_tied($record)->unique(1);        # hobbies now ['chess']
  $record->hobbies('chess');                # duplicate 'chess' not added
 
When 'unique' is given a true value, duplicate removal occurs
immediately by running all existing elements through the
duplicate-removal process. Thereafter, duplicate checking occurs on
every update including when default values are restored by clearing
the object. Continuing the above example:

  $record->hobbies('go');                   # hobbies now ['chess','go']
  %$record=();                              # hobbies now ['chess']

'unique' can be set to a boolean, as in the example, or to a
subroutine (technically, a CODE ref).  The subroutine should operate
on two values and return true if the values are considered to be
equal, and false otherwise.  

By default, 'unique' is sub {my($a,$b)=@_; $a eq $b}. The following
example shows how to set 'unique' to a subroutine that does
case-insensitive duplicate removal.

  my $record=new Hash::AutoHash::Record hobbies=>['CHESS','chess'];
  autohash_tied($record)->unique(sub {my($a,$b)=@_; lc($a) eq lc($b)});
  # hobbies now ['CHESS']

In many cases, it works fine and is more efficient to perform
duplicate removal on-demand rather than on every update.  You can
accomplish this by setting 'filter' in the B<tied object implementing
the hash> to a true value. By default, the filter function is 'uniq'
from L<List::MoreUtils>. You can change this by setting 'filter' to a
subroutine reference which takes a list of values as input and returns
a list of values as output. Though motivated by duplicate removal, the
'filter' function can transform the list in any way you choose.

The following contrived example shows sets 'filter' to a subroutine
that performs case-independent duplicate removal and sorts the
resulting values.

  sub uniq_nocase_sort {
    my %uniq;
    my @values_lc=map { lc($_) } @_;
    @uniq{@values_lc}=@_;
    sort values %uniq;  
  }

  my $record=new Hash::AutoHash::Record hobbies=>['CHESS','chess','go'];
  autohash_tied($record)->filter(\&uniq_nocase_sort);
  # hobbies now ('chess','go')

You can do the same thing more concisely with this cryptic one-liner.

  autohash_tied($record)->filter(sub {my %u; @u{map {lc $_} @_}=@_; sort values %u}); 

Filtering occurs when you run the 'filter' method. It does not occur on every update.

=head2 new

'new' is the constructor.

 Title   : new 
 Usage   : $record=new Hash::AutoHash::Record
                       name=>'',hobbies=>[],favorites=>{},family=>\{};
 Function: Create Hash::AutoHash::Record object and set initial values for each
           field.  This implicitly sets the fields' types and default values.
 Returns : Hash::AutoHash::Record object
 Args    : Optional list of key=>value pairs which are used to set initial
           values, types, and defaults for each field of the object.

=head2 defaults

This method must be invoked on the B<tied object implementing the hash>.

 Title   : defaults 
 Usage   : %defaults=tied(%$record)->defaults
           -- OR --
           $defaults=tied(%$record)->defaults
           -- OR --
           tied(%$record)->defaults(name=>'Joe',hobbies=>['chess'])
           -- OR --
           tied(%$record)->defaults([name=>'Joe',hobbies=>['chess']])
          -- OR --
           tied(%$record)->defaults({name=>'Joe',hobbies=>['chess']})
            -- OR --
           %defaults=autohash_tied($record)->defaults
           -- OR --
           $defaults=autohash_tied($record)->defaults
           -- OR --
           autohash_tied($record)->defaults(name=>'Joe',hobbies=>['chess'])
           -- OR --
           autohash_tied($record)->defaults([name=>'Joe',hobbies=>['chess']])
          -- OR --
           autohash_tied($record)->defaults({name=>'Joe',hobbies=>['chess']})
 Function: Get or set option default values.
           Forms 1&2 get the current defaults as a hash or HASH respectively.
           Forms 3-5. Set defaults. The new value replaces the old.
           Forms 6-10 are functionally equivalent to the first three but use the
           autohash_tied function to get the tied object instead of Perl's
           built-in tied function.
           Note the '%' in front of $record in the first five forms and its
           absence in the next five forms.
 Returns : defaults as a list or ARRAY depending on context 
 Args    : key=>value pairs.

=head2 force

This method must be invoked on the B<tied object implementing the hash>.

 Title   : force 
 Usage   : tied(%$record)->force('favorites',{colors=>['red','blue'])
           -- OR --
            tied(%$record)->force('favorites')
           -- OR --
           autohash_tied($record)->force('favorites',{colors=>['red','blue'])
           -- OR --
           autohash_tied($record)->force('favorites')
 Function: Ignore the current value and type of the field and forcibly assign a
           new value, or, if no new value is given, set the value to undef.
 Returns : new value, if any, or undef 
 Args    : key and optional new value

=head2 unique

This method must be invoked on the B<tied object implementing the hash>.

 Title   : unique 
 Usage   : $unique=tied(%$record)->unique
           -- OR --
           tied(%$record)->unique($boolean)
           -- OR --
           tied(%$record)->unique(\&function)
           -- OR --
           $unique=autohash_tied($record)->unique
           -- OR --
           autohash_tied($record)->unique($boolean)
           -- OR --
           autohash_tied($record)->unique(\&function)
 Function: Get or set option that controls duplicate elimination for
           multi-valued fields.
           Form 1 gets the current value of the control.  
           Form 2. If the argument is true, duplicate-removal is turned on using 
           'eq' to determine which values are equal. 
           If the argument is false, duplicate-removal is turned off.  
           Form 3 turns on duplicate removal using the given function. 
           Forms 4-6 are functionally equivalent to the first three but use the
           autohash_tied function to get the tied object instead of Perl's
           built-in tied function.
           Note the '%' in front of $record in the first three forms and its
           absence in the next three forms.
 Returns : value of the control 
 Args    : Forms 2&5. Usually a boolean value, but can be any value which is not
           a CODE reference.  
           Forms 3&6. CODE reference for a function that takes two values and 
           returns true or false.
 Notes   : When unique is given a true value (including a CODE ref in forms 3&6)
           duplicate removal occurs immediately by running all existing elements
           through the duplicate-removal process. Thereafter, duplicate checking
           occurs on every update including when default values are restored by 
           clearing the object.

=head2 filter

This method must be invoked on the B<tied object implementing the hash>.

 Title   : filter 
 Usage   : $filter=tied(%$record)->filter
           -- OR --
           tied(%$record)->filter($boolean)
           -- OR --
           tied(%$record)->filter(\&function)
            -- OR --
           $filter=autohash_tied($record)->filter
           -- OR --
           autohash_tied($record)->filter($boolean)
           -- OR --
           autohash_tied($record)->filter(\&function)
Function:  Set function used for filtering and perform filtering if true.
           Form 1 filters elements using filter function previously set.
           Form 2. If true, sets the filter function to its default, which is 
           'uniq' from L<List::MoreUtils> and performs filtering.
           If false, turns filtering off.  
           Form 3 sets the filter function to the given function and performs
           filtering.
           Forms 4-6 are functionally equivalent to the first three but use the 
           autohash_tied function to get the tied object instead of Perl's 
           built-in tied function.
           Note the '%' in front of $record in the first three forms and its
           absence in the last three forms.
 Returns : value of the control 
 Args    : Forms 2&5. Usually a boolean value, but can be any value which is not 
           a CODE reference.  
           Forms 3&6. CODE reference for a function that takes a list and 
           returns a list. The input list is passed in @_.
 Notes   : When filter is given a true value (including a CODE ref in forms 3&6)
           filtering occurs immediately by running all existing elements through
           the filter function.

=head2 Functions inherited from Hash::AutoHash

The following functions are inherited from L<Hash::AutoHash> and,
except for autohash_clear, operate exactly as there. You must import
them into your namespace before use.

 use Hash::AutoHash::Record
    qw(autohash_alias autohash_tied autohash_get autohash_set
       autohash_clear autohash_delete autohash_each autohash_exists 
       autohash_keys autohash_values 
       autohash_count autohash_empty autohash_notempty)

=head3 autohash_alias

Aliasing a Hash::AutoHash object to a regular hash avoids the need to
dereference the variable when using hash notation.  As a convenience,
the autoahash_alias functions can link in either direction depending
on whether the given object exists.

 Title   : autohash_alias
 Usage   : autohash_alias($record,%hash)
 Function: Link $record to %hash such that they will have exactly the same value.
 Args    : Hash::AutoHash::Record object and hash 
 Returns : Hash::AutoHash::Record object

=head3 autohash_tied

You can access the object implementing the tied hash using Perl's
built-in tied function or the autohash_tied function inherited from
L<Hash::AutoHash>.  Advantages of autohash_tied are (1) it operates
directly on the Hash::AutoHash::Record object without requiring a
leading '%', and (2) it provide an arguably simpler syntax for
invoking methods on the tied object.

 Title   : autohash_tied 
 Usage   : $tied=autohash_tied($record)
           -- OR --
           $tied=autohash_tied(%hash)
           -- OR --
           $result=autohash_tied($record,'some_method',@parameters)
           -- OR --
           $result=autohash_tied(%hash,'some_method',@parameters)
 Function: The first two forms return the object implementing the tied hash. The
           latter two forms invoke a method on the tied object. 
           In forms 1 and 3, the first argument is the 
           Hash::AutoHash::Record object.
           In forms 2 and 4, the first argument is a hash to which a 
           Hash::AutoHash::Record object has been aliased
 Returns : In forms 1&2, object implementing tied hash or undef.
           In forms 3&4, result of invoking method (which can be anything or
           nothing), or undef.
 Args    : Form 1. Hash::AutoHash::Record object
           Form 2. hash to which Hash::AutoHash::Record object is aliased
           Form 3. Hash::AutoHash::Record object, method name, optional 
             list of parameters for method
           Form 4. hash to which Hash::AutoHash::Record object is aliased, 
             method name, optional list of parameters for method

=head3 autohash_get

 Title   : autohash_get
 Usage   : ($name,$hobbies)=autohash_get($record,qw(name hobbies))
 Function: Get values for multiple keys.
 Args    : Hash::AutoHash::Record object and list of keys
 Returns : list of argument values

=head3 autohash_set

 Title   : autohash_set
 Usage   : autohash_set($record,name=>'Joe Plumber',first_name=>'Joe')
           -- OR --
           autohash_set($record,['name','first_name'],['Joe Plumber','Joe'])
 Function: Set multiple arguments in existing object.
 Args    : Form 1. Hash::AutoHash::Record object and list of key=>value pairs
           Form 2. Hash::AutoHash::Record object, ARRAY of keys, ARRAY of values
 Returns : Hash::AutoHash::Record object

=head3 Functions for hash-like operations

The remaining functions provide hash-like operations on
Hash::AutoHash::Record objects. These are useful if you want to
avoid hash notation all together.

=head4 autohash_clear

 Title   : autohash_clear
 Usage   : autohash_clear($record,@keys)
 Function: Delete entire contents of $record or specified keys. Restore default
           values for those deleted keys that have default values and set the
           others to undef
 Args    : Hash::AutoHash::Record object, optional list of keys
 Returns : nothing

=head4 autohash_delete

 Title   : autohash_delete
 Usage   : autohash_delete($record,@keys)
 Function: Delete keys and their values from $record.
 Args    : Hash::AutoHash::Record object, list of keys
 Returns : nothing

=head4 autohash_exists

 Title   : autohash_exists
 Usage   : if (autohash_exists($record,$key)) { ... }
 Function: Test whether key is present in $record.
 Args    : Hash::AutoHash::Record object, key
 Returns : boolean

=head4 autohash_each

 Title   : autohash_each
 Usage   : while (my($key,$value)=autohash_each($record)) { ... }
           -- OR --
           while (my $key=autohash_each($record)) { ... }
 Function: Iterate over all key=>value pairs or all keys present in $record
 Args    : Hash::AutoHash::Record object
 Returns : list context: next key=>value pair in $record or empty list at end
           scalar context: next key in $record or undef at end

=head4 autohash_keys

 Title   : autohash_keys
 Usage   : @keys=autohash_keys($record)
 Function: Get all keys that are present in $record
 Args    : Hash::AutoHash::Record object
 Returns : list of keys

=head4 autohash_values

 Title   : autohash_values
 Usage   : @values=autohash_values($record)
 Function: Get the values of all keys that are present in $record
 Args    : Hash::AutoHash::Record object
 Returns : list of values

=head4 autohash_count

 Title   : autohash_count
 Usage   : $count=autohash_count($record)
 Function: Get the number keys that are present in $record
 Args    : Hash::AutoHash::Record object
 Returns : number

=head4 autohash_empty

 Title   : autohash_empty
 Usage   : if (autohash_empty($record)) { ... }
 Function: Test whether $record is empty
 Args    : Hash::AutoHash::Record object
 Returns : boolean

=head4 autohash_notempty

 Title   : autohash_notempty
 Usage   : if (autohash_notempty($record)) { ... }
 Function: Test whether $record is not empty. Complement of autohash_empty
 Args    : Hash::AutoHash::Record object
 Returns : boolean

=head1 SEE ALSO

L<perltie> and L<Tie::Hash> present background on tied hashes.

L<Hash::AutoHash> provides the object wrapping machinery. The
documentation of that class includes a detailed list of caveats and
cautions. L<Hash::AutoHash::Args>, L<Hash::AutoHash::MultiValued>,
L<Hash::AutoHash::AVPairsSingle>, L<Hash::AutoHash::AVPairsMulti> are other
subclasses of L<Hash::AutoHash>.

This class uses L<Hash::AutoHash::AVPairsSingle> and
L<Hash::AutoHash::AVPairsMulti> to represent attribute-value pairs.

=head1 AUTHOR

Nat Goodman, C<< <natg at shore.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-autohash-record at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-AutoHash-Record>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::AutoHash::Record


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-AutoHash-Record>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-AutoHash-Record>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-AutoHash-Record>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-AutoHash-Record/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Nat Goodman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hash::AutoHash::Record
