package Hash::Layout;
use strict;
use warnings;

# ABSTRACT: hashes with predefined layouts, composite keys and default values

our $VERSION = '1.02';

use Moo;
use Types::Standard qw(:all);
use Scalar::Util qw(blessed looks_like_number);
use Hash::Merge::Simple 'merge';
use Clone;

use Hash::Layout::Level;

has 'levels', is => 'ro', isa => ArrayRef[
  InstanceOf['Hash::Layout::Level']
], required => 1, coerce => \&_coerce_levels_param;

sub num_levels { scalar(@{(shift)->levels}) }

has 'default_value',     is => 'ro',              default => sub { 1 };
has 'default_key',       is => 'ro', isa => Str,  default => sub { '*' };
has 'allow_deep_values', is => 'ro', isa => Bool, default => sub { 1 };
has 'deep_delimiter',    is => 'ro', isa => Str,  default => sub { '.' };
has 'no_fill',           is => 'ro', isa => Bool, default => sub { 0 };
has 'no_pad',            is => 'ro', isa => Bool, default => sub { 0 };

has 'lookup_mode', is => 'rw', isa => Enum[qw(get fallback merge)], 
  default => sub { 'merge' };

has '_Hash', is => 'ro', isa => HashRef, default => sub {{}}, init_arg => undef;
has '_all_level_keys', is => 'ro', isa => HashRef, default => sub {{}}, init_arg => undef;

# List of bitmasks representing every key path which includes
# a default_key, with each bit representing the level and '1' toggled on
# where the key is the default
has '_def_key_bitmasks', is => 'ro', isa => HashRef, default => sub {{}}, init_arg => undef;

sub Data { Clone::clone( (shift)->_Hash ) }

sub level_keys {
  my ($self, $index) = @_;
  die 'level_keys() expects level index argument' 
    unless (looks_like_number $index);
    
  die "No such level index '$index'" 
    unless ($self->levels->[$index]);

  return $self->_all_level_keys->{$index} || {};
}

# Clears the Hash of any existing data
sub reset {
  my $self = shift;
  %{$self->_Hash}             = ();
  %{$self->_all_level_keys}   = ();
  %{$self->_def_key_bitmasks} = ();
  return $self;
}

sub clone { Clone::clone(shift) }


around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
  my %opt = (ref($args[0]) eq 'HASH') ? %{ $args[0] } : @args; # <-- arg as hash or hashref
  
  # Accept 'levels' as shorthand numeric value:
  if($opt{levels} && looks_like_number $opt{levels}) {
    my $num = $opt{levels} - 1;
    $opt{delimiter} ||= '/';
    my @levels = ({ delimiter => $opt{delimiter} }) x $num;
    $opt{levels} = [ @levels, {} ];
    delete $opt{delimiter};
  }

  return $self->$orig(%opt);
};


sub BUILD {
  my $self = shift;
  $self->_post_validate;
}

sub _post_validate {
  my $self = shift;

  if($self->allow_deep_values) {
    for my $Lvl (@{$self->levels}) {
      die join("",
        "Level delimiters must be different from the deep_delimiter ('",
          $self->deep_delimiter,"').\n",
        "Please specify a different level delimiter or change 'deep_delimiter'"
      ) if ($Lvl->delimiter && $Lvl->delimiter eq $self->deep_delimiter);
    }
  }

}

sub coercer {
  my $self = (shift)->clone;
  return sub { $self->coerce(@_) };
}

sub coerce { 
  my ($self, @args) = @_;
  die 'coerce() is not a class method' unless (blessed $self);
  if(scalar(@args) == 1){
    if(ref($args[0])) {
      return $args[0] if (blessed($args[0]) && blessed($args[0]) eq __PACKAGE__);
      @args = @{$args[0]} if (ref($args[0]) eq 'ARRAY');
    }
    elsif(! defined $args[0]) {
      return $self->clone->reset;
    }
  }
  my $new = $self->clone->reset;
  return scalar(@args) > 0 ? $new->load(@args) : $new;
}

sub lookup {
  my ($self, $key_str, @addl) = @_;
  return undef unless (defined $key_str);
  die join(' ',
    "lookup() expects a single composite key string argument",
    "(did you mean to use 'lookup_path'?)" 
  ) if (scalar(@addl) > 0);
  return $self->lookup_path( $self->resolve_key_path($key_str) );
}

sub lookup_path {
  my ($self, @path) = @_;
   # lookup_path() is the same as get_path() when lookup_mode is 'get':
  return $self->get_path(@path) if ($self->lookup_mode eq 'get');
  
  return undef unless (defined $path[0]);
  
  my $hash_val;

  # If the exact path is set and is NOT a hash (that may need merging),
  # return it outright:
  if($self->exists_path(@path)) {
    my $val = $self->get_path(@path);
    return $val unless (
      ref $val && ref($val) eq 'HASH'
      && $self->lookup_mode eq 'merge'
    );
    # Set the first hash_val:
    $hash_val = $val if(ref $val && ref($val) eq 'HASH');
  }
  
  my @set = $self->_enumerate_default_paths(@path);
  
  my @values = ();
  for my $dpath (@set) {
    $self->exists_path(@$dpath) or next;
    my $val = $self->get_path(@$dpath);
    return $val unless ($self->lookup_mode eq 'merge');
    if (ref $val && ref($val) eq 'HASH') {
      # Set/merge hashes:
      $hash_val = $hash_val ? merge($val,$hash_val) : $val;
    }
    else {
      # Return the first non-hash value unless a hash has already been
      # encountered, and if that is the case, we can't merge a non-hash,
      # return the hash we already had now
      return $hash_val ? $hash_val : $val;
    }
  }
  
  # If nothing was found, $hash_val will still be undef:
  return $hash_val;
}

# Only returns the lookup_path value if it is a "leaf" - 
#  any value that is NOT a populated HashRef
sub lookup_leaf_path {
  my ($self, @path) = @_;
  my $v = $self->lookup_path(@path);
  return (ref $v && ref($v) eq 'HASH' && scalar(keys %$v) > 0) ? undef : $v; 
}

sub get {
  my ($self, $key_str, @addl) = @_;
  return undef unless (defined $key_str);
  die join(' ',
    "get() expects a single composite key string argument",
    "(did you mean to use 'get_path'?)" 
  ) if (scalar(@addl) > 0);
  return $self->get_path( $self->resolve_key_path($key_str) );
}

sub get_path {
  my ($self, @path) = @_;
  return undef unless (defined $path[0]);

  my $value;
  my $ev_path = $self->_as_eval_path(@path);
  eval join('','$value = $self->Data->',$ev_path);
  
  return $value;
}

sub exists {
  my ($self, $key_str, @addl) = @_;
  return undef unless (defined $key_str);
  die join(' ',
    "exists() expects a single composite key string argument",
    "(did you mean to use 'exists_path'?)" 
  ) if (scalar(@addl) > 0);
  return $self->exists_path( $self->resolve_key_path($key_str) );
}

sub exists_path {
  my ($self, @path) = @_;
  return 0 unless (defined $path[0]);

  my $ev_path = $self->_as_eval_path(@path);
  return eval join('','exists $self->Data->',$ev_path);
}

sub delete {
  my ($self, $key_str, @addl) = @_;
  return undef unless (defined $key_str);
  die join(' ',
    "delete() expects a single composite key string argument",
    "(did you mean to use 'delete_path'?)" 
  ) if (scalar(@addl) > 0);
  return $self->delete_path( $self->resolve_key_path($key_str) );
}

sub delete_path {
  my ($self, @path) = @_;
  return 0 unless (defined $path[0]);
  
  # TODO: should this die?
  return undef unless ($self->exists_path(@path));
  
  my $data    = $self->Data; #<-- this is a *copy* of the data
  my $ev_path = $self->_as_eval_path(@path);
  
  # Delete teh value from our copy:
  my $ret; eval join('','$ret = delete $data->',$ev_path);
  
  # To delete safely, we actually have to reload all the data
  # (except what is being deleted), from scratch. This is to
  # make sure all the other indexes and counters remain in a
  # consistent state:
  $self->reset->load($data);
  
  # Return whatever was actually returned from the "real" delete:
  return $ret;
}

# Use bitwise math to enumerate all possible prefix, default key paths:
sub _enumerate_default_paths {
  my ($self, @path) = @_;

  my $def_val = $self->default_key;
  my $depth = $self->num_levels;

  my @set = ();
  my %seen_combo = ();

  ## enumerate every possible default path bitmask (slow with many levels):
  #my $bits = 2**$depth;
  #my @mask_sets = ();
  #push @mask_sets, $bits while(--$bits >= 0);
  
  # default path bitmasks only for paths we know are set (much faster):
  my @mask_sets = keys %{$self->_def_key_bitmasks};
  
  # Re-sort the mask sets as reversed *strings*, because we want
  # '011' to come before '110'
  @mask_sets = sort { 
    reverse(sprintf('%0'.$depth.'b',$a)) cmp 
    reverse(sprintf('%0'.$depth.'b',$b)) 
  } @mask_sets;
  
  for my $mask (@mask_sets) {
    my @combo = ();
    my $check_mask =  2**$depth >> 1;
    for my $k (@path) {
      # Use bitwise AND to decide whether or not to swap the
      # default value for the actual key:
      push @combo, $check_mask & $mask ? $def_val : $k;
      
      # Shift the check bit position by one for the next key:
      $check_mask = $check_mask >> 1;
    }
    push @set, \@combo unless ($seen_combo{join('/',@combo)}++);
  }

  return @set;
}

sub load {
  my $self = shift;
  return $self->_load(0,$self->_Hash,@_);
}

sub _load {
  my ($self, $index, $noderef, @args) = @_;
  
  my $Lvl = $self->levels->[$index] or die "Bad level index '$index'";
  my $last_level = ! $self->levels->[$index+1];
  
  for my $arg (@args) {
    die "Undef keys are not allowed" unless (defined $arg);
    
    my $force_composite = $self->{_force_composite} || 0;
    local $self->{_force_composite} = 0; #<-- clear if set to prevetn deep recursion
    unless (ref $arg) {
      # hanging string/scalar, convert using default value
      $arg = { $arg => $self->default_value };
      $force_composite = 1;
    }
    
    die "Cannot load non-hash reference!" unless (ref($arg) eq 'HASH');
    
    for my $key (keys %$arg) {
      die "Only scalar/string keys are allowed" 
        unless (defined $key && ! ref($key));
        
      my $val = $arg->{$key};
      my $is_hashval = ref $val && ref($val) eq 'HASH';
      
      if( $force_composite || $self->_is_composite_key($key,$index) ) {
        my $no_fill = $is_hashval;
        my @path = $self->resolve_key_path($key,$index,$no_fill);
        my $lkey = pop @path;
        my $hval = {};
        if(scalar(@path) > 0) {
          $self->_init_hash_path($hval,@path)->{$lkey} = $val;
        }
        else {
          $hval->{$lkey} = $val;
        }
        $self->_load($index,$noderef,$hval);
      }
      else {
      
        local $self->{_path_bitmask} = $self->{_path_bitmask};
        my $bm = 0; $self->{_path_bitmask} ||= \$bm;
        my $bmref = $self->{_path_bitmask};
        if($key eq $self->default_key) {
          my $depth = 2**($self->num_levels);
          $$bmref = $$bmref | ($depth >> $index+1);
        }
      
        $self->_all_level_keys->{$index}{$key} = 1;
        if($is_hashval) {
          $self->_init_hash_path($noderef,$key);
          if($last_level) {
            $noderef->{$key} = merge($noderef->{$key}, $val);
          }
          else {
            # Set via recursive:
            $self->_load($index+1,$noderef->{$key},$val);
          }
        }
        else {
          $noderef->{$key} = $val;
        }
        
        if($index == 0 && $$bmref) {
          $self->_def_key_bitmasks->{$$bmref} = 1;
        }
      }
    }
  }
  
  return $self;
}


sub path_to_composite_key {
  my ($self, @path) = @_;
  return $self->_path_to_composite_key(0,@path);
}

sub _path_to_composite_key {
  my ($self, $index, @path) = @_;

  my $Lvl = $self->levels->[$index] or die "Bad level index '$index'";
  my $last_level = ! $self->levels->[$index+1];
  
  if($last_level) {
    my $del = $self->deep_delimiter || '.';
    return join($del,@path);
  }
  else {
    my $key = shift @path;
    return scalar(@path) > 0 ? join(
      $Lvl->delimiter,$key,
      $self->_path_to_composite_key($index+1,@path)
    ) : join('',$key,$Lvl->delimiter);
  }
}


sub _init_hash_path {
  my ($self,$hash,@path) = @_;
  die "Not a hash" unless (ref $hash && ref($hash) eq 'HASH');
  die "No path supplied" unless (scalar(@path) > 0);
  
  my $ev_path = $self->_as_eval_path( @path );
  
  my $hval;
  eval join('','$hash->',$ev_path,' ||= {}');
  eval join('','$hval = $hash->',$ev_path);
  eval join('','$hash->',$ev_path,' = {}') unless (
    ref $hval && ref($hval) eq 'HASH'
  );
  
  return $hval;
}


sub set {
  my ($self,$key,$value) = @_;
  die "bad number of arguments passed to set" unless (scalar(@_) == 3);
  die '$key value is required' unless ($key && $key ne '');
  local $self->{_force_composite} = 1;
  $self->load({ $key => $value });
}


sub _as_eval_path {
  my ($self,@path) = @_;
  return (scalar(@path) > 0) ? join('',
    map { '{"'.$_.'"}' } @path
  ) : undef;
}

sub _eval_key_path {
  my ($self, $key, $index) = @_;
  return $self->_as_eval_path(
    $self->resolve_key_path($key,$index)
  );
}

# recursively scans the supplied key for any special delimiters defined
# by any of the levels, or the deep delimiter, if deep values are enabled
sub _is_composite_key {
  my ($self, $key, $index) = @_;
  $index ||= 0;
  
  my $Lvl = $self->levels->[$index];

  if ($Lvl) {
    return 0 if ($Lvl->registered_keys && $Lvl->registered_keys->{$key});
    return $Lvl->_peel_str_key($key) || $self->_is_composite_key($key,$index+1);
  }
  else {
    if($self->allow_deep_values) {
      my $del = $self->deep_delimiter;
      return $key =~ /\Q${del}\E/;
    }
    else {
      return 0;
    }
  }
}

sub resolve_key_path {
  my ($self, $key, $index, $no_fill) = @_;
  $index ||= 0;
  $no_fill ||= $self->no_fill;
  
  my $Lvl = $self->levels->[$index];
  my $last_level = ! $self->levels->[$index+1];
  
  if ($Lvl) {
    my ($peeled,$leftover) = $Lvl->_peel_str_key($key);
    if($peeled) {
      local $self->{_composite_key_peeled} = 1;
      # If a key was peeled, move on to the next level with leftovers:
      return ($peeled, $self->resolve_key_path($leftover,$index+1,$no_fill)) if ($leftover); 
      
      # If there were no leftovers, recurse again only for the last level,
      # otherwise, return now (this only makes a difference for deep values)
      return $last_level ? $self->resolve_key_path($peeled,$index+1,$no_fill) : $peeled;
    }
    else {
      # If a key was not peeled, add the default key at the top of the path
      # only if we're not already at the last level and 'no_fill' is not set
      # (and we've already peeled at least one key)
      my @path = $self->resolve_key_path($key,$index+1,$no_fill);
      my $as_is = $last_level || ($no_fill && $self->{_composite_key_peeled});
      return $self->no_pad || $as_is ? @path : ($self->default_key,@path);
    }
  }
  else {
    if($self->allow_deep_values) {
      my $del = $self->deep_delimiter;
      return split(/\Q${del}\E/,$key);
    }
    else {
      return $key;
    }
  }
}


sub _coerce_levels_param {
  my $val = shift;
  return $val unless (ref($val) && ref($val) eq 'ARRAY');
  
  my %seen = ();
  my $i = 0;
  my @new = ();
  for my $itm (@$val) {
    return $val if (blessed $itm);
  
    die "'levels' must be an arrayref of hashrefs" unless (
      ref($itm) && ref($itm) eq 'HASH'
    );
    
    die "duplicate level name '$itm->{name}'" if (
      $itm->{name} && $seen{$itm->{name}}++
    );
    
    die "the last level is not allowed to have a delimiter" if(
      scalar(@$val) == ++$i
      && $itm->{delimiter}
    );
    
    push @new, Hash::Layout::Level->new({
      %$itm,
      index => $i-1
    });
  }
  
  die "no levels specified" unless (scalar(@new) > 0);
  
  return \@new;
}


# debug method:
sub def_key_bitmask_strings {
  my $self = shift;
  my $depth = $self->num_levels;
  my @masks = keys %{$self->_def_key_bitmasks};
  map { sprintf('%0'.$depth.'b',$_) } @masks;
}

1;


__END__

=head1 NAME

Hash::Layout - hashes with predefined levels, composite keys and default values

=head1 SYNOPSIS

 use Hash::Layout;
 
 # Create new Hash::Layout object with 3 levels and unique delimiters:
 my $HL = Hash::Layout->new({
  levels => [
    { delimiter => ':' },
    { delimiter => '/' }, 
    {}, # <-- last level never has a delimiter
  ]
 });
 
 # load using actual hash structure:
 $HL->load({
   '*' => {
     '*' => {
       foo_rule => 'always deny',
       blah     => 'thing'
     },
     NewYork => {
       foo_rule => 'prompt'
     }
   }
 });
 
 # load using composite keys:
 $HL->load({
   'Office:NewYork/foo_rule' => 'allow',
   'Store:*/foo_rule'        => 'other',
   'Store:London/blah'       => 'purple'
 });
 
 # load composite keys w/o values (uses default_value):
 $HL->load(qw/baz:bool_key flag01/);
 
 # get a copy of the hash data:
 my $hash = $HL->Data;
 
 #  $hash now contains:
 #
 #    {
 #      "*" => {
 #        "*" => {
 #          blah => "thing",
 #          flag01 => 1,
 #          foo_rule => "always deny"
 #        },
 #        NewYork => {
 #          foo_rule => "prompt"
 #        }
 #      },
 #      Office => {
 #        NewYork => {
 #          foo_rule => "allow"
 #        }
 #      },
 #      Store => {
 #        "*" => {
 #          foo_rule => "other"
 #        },
 #        London => {
 #          blah => "purple"
 #        }
 #      },
 #      baz => {
 #        "*" => {
 #          bool_key => 1
 #        }
 #      }
 #    }
 #
 
 
 # lookup values by composite keys:
 $HL->lookup('*:*/foo_rule')              # 'always deny'
 $HL->lookup('foo_rule')                  # 'always deny'
 $HL->lookup('ABC:XYZ/foo_rule')          # 'always deny'  # (virtual/fallback)
 $HL->lookup('Lima/foo_rule')             # 'always deny'  # (virtual/fallback)
 $HL->lookup('NewYork/foo_rule')          # 'prompt'
 $HL->lookup('Office:NewYork/foo_rule')   # 'allow'
 $HL->lookup('Store:foo_rule')            # 'other'
 $HL->lookup('baz:Anything/bool_key')     # 1              # (virtual/fallback)
 
 # lookup values by full/absolute paths:
 $HL->lookup_path(qw/ABC XYZ foo_rule/)   # 'always deny'  # (virtual/fallback)
 $HL->lookup_path(qw/Store * foo_rule/)   # 'other'

=head1 DESCRIPTION

C<Hash::Layout> provides deep hashes with a predefined number of levels which you can access using
special "composite keys". These are essentially string paths that inflate into actual hash keys according
to the defined levels and delimiter mappings, which can be the same or different for each level. 
This is useful both for shorter keys as well as merge/fallback to default values, such as when 
defining overlapping configs ranging from broad to narrowing scope (see example in SYNOPIS above).

This module is general-purpose, but was written specifically for the flexible 
L<filter()|DBIx::Class::Schema::Diff#filter> feature of L<DBIx::Class::Schema::Diff>, 
so refer to its documentation as well for a real-world example application. There are also lots of 
examples and use scenarios in the unit tests under C<t/>.

=head1 METHODS

=head2 new

Create a new Hash::Layout instance. The following build options are supported:

=over 4

=item levels

Required. ArrayRef of level config definitions, or a numeric number of levels for default level
configs. Each level can define its own C<delimiter> (except the last level) and list of 
C<registered_keys>, both of which are optional and determine how ambiguous/partial composite keys are resolved.

Level-specific delimiters provide a mechanism to supply partial paths in composite keys but resolve
to a specific level. The word/string to the left of a delimiter character that is specific to a given level
is resolved as the key of that level, however, the correct path order is required (keys are only tokenized
in order from left to right).

Specific strings can also be declared to belong to a particular level with C<registered_keys>. This
also only effects how ambiguity is resolved with partial composite keys. See also the C<no_fill> and 
C<no_pad> options.

See the unit tests for examples of exactly how this works.

Internally, the level configs are coerced into L<Hash::Layout::Level> objects.

For Hash::Layouts that don't need/want level-specific delimiters, or level-specific registered_keys,
a simple integer value can be supplied instead for default level configs all using C</> as the delimiter.

So, this:

 my $HL = Hash::Layout->new({ levels => 5 });

Is equivalent to:

 $HL = Hash::Layout->new({
  levels => [
    { delimiter => '/' }
    { delimiter => '/' }
    { delimiter => '/' }
    { delimiter => '/' }
    {} #<-- last level never has a delimiter
  ]
 });

C<levels> is the only required parameter.

=item default_value

Value to assign keys when supplied to C<load()> as simple strings instead of key/value pairs. 
Defaults to the standard bool/true value of C<1>.

=item default_key

Value to use for the key for levels which are not specified, as well as the key to use for default/fallback 
when looking up non-existant keys (see also C<lookup_mode>). Defaults to a single asterisk C<(*)>.

=item no_fill

If true, partial composite keys are not expanded with the default_key (in the middle) to fill to 
the last level.
Defaults to 0.

=item no_pad

If true, partial composite keys are not expanded with the default_key (at the front or middle) to 
fill to the last level. C<no_pad> implies C<no_fill>. Again, see the tests for a more complete 
explanation. Defaults to 0.

=item allow_deep_values

If true, values at the bottom level are allowed to be hashes, too, for the purposes of addressing
the deeper paths using composite keys (see C<deep_delimiter> below). Defaults to 1.

=item deep_delimiter

When C<allow_deep_values> is enabled, the deep_delimiter character is used to resolve composite key
mappings into the deep hash values (i.e. beyond the predefined levels). Must be different from the 
delimiter used by any of the levels. Defaults to a single dot C<(.)>.

For example:

  $HL->lookup('something/foo.deeper.hash.path')

=item lookup_mode

One of either C<get>, C<fallback> or C<merge>. In C<fallback> mode, when a non-existent composite 
key is looked up, the value of the first closest found key path using default keys is returned 
instead of C<undef> as is the case with C<get> mode. C<merge> mode is like C<fallback> mode, except 
hashref values are merged with matching default key paths which are also hashrefs. Defaults to C<merge>.

=back

=head2 clone

Returns a new/cloned C<Hash::Layout> instance

=head2 coerce

Dynamic method coerces supplied value into a new C<Hash::Layout> instance with a new set of loaded data. 
See unit tests for more info.

=head2 coercer

CodeRef wrapper around C<coerce()>, suitable for use in a L<Moo|Moo#has>-compatible attribute declaration

=head2 load

Loads new data into the hash.

Data can be supplied as hashrefs with normal/local keys or composite keys, or both. Composite keys can 
also be supplied as sub-keys and are resolved relative to the location in which they appear as one would 
expect.

Composite keys can also be supplied as simple strings w/o corresponding values in which case their value
is set to whatever C<default_value> is set to (which defaults to 1).

See the unit tests for more details and lots of examples of using C<load()>.

=head2 set

Simpler alternative to C<load()>. Expects exactly two arguments as standard key/values.

=head2 resolve_key_path

Converts a composite key string into its full path and returns it as a list. Called internally wherever
composite keys are resolved.

=head2 path_to_composite_key

Inverse of C<resolve_key_path>; takes a path as a list and returns a single composite key string (i.e. joins using the
delimiters for each level). Obviously, it only returns fully-qualified, non-ambiguous (not partial) composite keys.

=head2 exists

Returns true if the supplied composite key exists and false if it doesn't. Does not consider default/fallback
key paths.

=head2 exists_path

Like C<exists()>, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by C<exists()>.

=head2 get

Retrieves the I<real> value of the supplied composite key, or undef if it does not exist. Use C<exists()> to 
distinguish undef values. Does not consider default/fallback key paths (that is what C<lookup()> is for).

=head2 get_path

Like C<get()>, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by C<get()>.

=head2 lookup

Returns the value of the supplied composite key, falling back to default key paths if it does not exist, 
depending on the value of C<lookup_mode>.

If the lookup_mode is set to C<'get'>, lookup() behaves exactly the same as get().

If the lookup_mode is set to C<'fallback'> and the supplied key does not exist, lookup() will search the 
hierarchy of matching default key paths, returning the first value that exists.

If the lookup_mode is set to C<'merge'>, lookup() behaves the same as it does in C<'fallback'> mode for
all non-hashref values. For hashref values, the hierarchy of default key paths is searched and all
matches (that are themselves hashrefs), including the exact/lowest value itself, are merged and returned. 

=head2 lookup_path

Like C<lookup()>, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by C<lookup()>.

=head2 lookup_leaf_path

Like C<lookup_path()>, but only returns the value if it is a I<"leaf"> (i.e. not a hashref with deeper sub-values).
Empty hashrefs (C<{}>) are also considered leaf values.

=head2 delete

Deletes the supplied composite key and returns the deleted value, or undef if it does not exist. 
Does not consider default/fallback key paths, or delete multiple items at once (e.g. like the Linux C<rm> 
command does with shell globs).

=head2 delete_path

Like C<delete()>, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by C<delete()>.

=head2 Data

Returns a read-only (i.e. cloned) copy of the full loaded hash structure.

=head2 num_levels

Returns the number of levels defined for this C<Hash::Layout> instance.

=head2 level_keys

Returns a hashref of all the keys that have been loaded/exist for the supplied level index (the first level
is at index C<0>).

=head2 def_key_bitmask_strings

Debug method. Returns a list of all the default key paths as a list of bitmasks (in binary/string form).
Any key path which has at least one default key at any level is considered a default path and is indexed
as a bitmask, with '1' values representing the default key position(s). For instance, the key 
path C<{*}{*}{foo_rule}> from the 3-level example from the SYNOPSIS is indexed as the bitmask C<110> (C<6> in decimal).

These bitmasks are used internally to efficiently search for and properly order default key values 
for quick fallback/merge lookups, even when there are a very large number of levels (and thus very, 
VERY large number of possible default paths). That is why they are tracked and indexed ahead of time.

This is a debug method which should not be needed to be used for any production code. I decided to leave
it in just to help document some of the internal workings of this module.

=head2 reset

Clears and removes all loaded data and resets internal key indexes and counters.

=head1 EXAMPLES

For more examples, see the following:

=over

=item *

The SYNOPSIS

=item *

The unit tests in C<t/>

=item *

L<DBIx::Class::Schema::Diff#filter>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

