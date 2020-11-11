package Hash::DotPath;
$Hash::DotPath::VERSION = '0.004';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';
use Hash::Merge;
use Util::Medley::Hash;

with
  'Util::Medley::Roles::Attributes::Hash',
  'Util::Medley::Roles::Attributes::List',
  'Util::Medley::Roles::Attributes::Logger',
  'Util::Medley::Roles::Attributes::String';

########################################################

=head1 NAME

Hash::DotPath - Class for manipulating hashes via dot path notation.

=head1 VERSION

version 0.004

=cut

########################################################

=head1 SYNOPSIS

  $dot = Hash::DotPath->new;
  $dot = Hash::DotPath->new(\%myhash);
  $dot = Hash::DotPath->new(\%myhash, delimiter => '~');

  $val = $dot->get('foo.bar');
  $val = $dot->get('biz.baz.0.zoo');  

  $dot->set('foo', 'bar');
  $dot->set('cats.0', 'calico');
  
  $dot->delete('foo');
  
  $newObj = $dot->merge({ biz => 'baz' });
  $newObj = $dot->merge({ biz => 'other' }, 'RIGHT'); 

  %hash = $dot->toHash;
  $href = $dot->toHashRef;  
  
=cut

=head1 ARRAY vs HASH vivification

When assigning a value to a path where a non-existent segment of the path is 
an integer, an array reference will be vivified at that position.  If you wish 
to have a hash reference in its place, you must instantiate it manually in
advance.  For example:

  # Assuming biz isn't defined yet, this will set biz to an array reference.
  
  $dot = Hash::DotPath->new;
  $dot->set('biz.0', 'baz'); 
  Data::Printer::p($dot->toHashRef); 

  {
      biz   [
          [0] "baz"
      ]
  }
 
  # In order to set biz to a hash reference you must instantiate it first.
  
  $dot->set('biz', {});
  $dot->set('biz.0', 'baz');
  Data::Printer::p($dot->toHashRef); 
 
  {
      biz   {
          0   "baz"
      }
  }
    
=cut

##############################################################################
# PUBLIC ATTRIBUTES
##############################################################################

=head1 ATTRIBUTES

=cut

# this attrib is used indirectly.  therefore, it isn't documented.
has init => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { {} },
);

=head2 delimiter [Str] (optional)

The delimiter to use when analyzing a dot path.  

Default: "."

=cut

has delimiter => (
	is      => 'rw',
	isa     => 'Str',
	default => '.',
);

##############################################################################
# PRIVATE_ATTRIBUTES
##############################################################################

has _href => (
	is  => 'rw',
	isa => 'HashRef',
);

##############################################################################
# CONSTRUCTOR
##############################################################################

around BUILDARGS => sub {

	my $orig  = shift;
	my $class = shift;

	my $href;
	if (@_) {

		# TODO: is there a way to use the 'Hash' attrib instead?
		my $util = Util::Medley::Hash->new;
		if ( $util->isHash( $_[0] ) ) {
			$href = shift @_;
		}
	}

	my %args = @_;
	$args{init} = $href if $href;

	return $class->$orig(%args);
};

method BUILD {

	$self->_href( $self->init );
}

##############################################################################
# PUBLIC METHODS
##############################################################################

=head1 METHODS 

=head2 delete

Deletes an element at the specified path.  Returns the value of the element
that was deleted.

=over

=item usage:

 $val = $dot->delete('foo.bar');
 $val = $dot->delete('biz.0.baz');

=item args:

=over

=item path [Str]

Dot-path of the element you wish to delete.

=back

=back

=cut

method delete (Str $path!) {

	my $ptr     = $self->_href;
	my @keys    = $self->_splitKey($path);
	my $lastKey = pop @keys;
	
	if (@keys) {
		$ptr = $self->_get( $self->_href, \@keys );
	}
    
    my $val;
    if ( $self->List->isArray($ptr) ) {
        if ( $self->String->isInt($lastKey) ) {
        	$val = splice(@$ptr, $lastKey, 1);
        }
        else {
            confess "can't reference array index at $path by $lastKey";
        }
    }
    else {
        $val = $ptr->{$lastKey} ;
        delete $ptr->{$lastKey};
    }

	return $val; # --> Any
}

=head2 get

Gets an element at the specified path. Returns 'Any'.

=over

=item usage:

 $val = $dot->get('foo.bar');
 $val = $dot->get('biz.0.baz');

=item args:

=over

=item path [Str]

Dot-path of the element you wish to get.

=back

=back

=cut

method get (Str $path!) {

	my @keys = $self->_splitKey($path);

	return $self->_get( $self->_href, \@keys );    # --> Any
}

=head2 exists

Determines if an element exists at the given path.  Returns 'Bool'.

=over

=item usage:

 $bool = $dot->exists('foo.bar');
 $bool = $dot->exists('biz.0.baz');

=item args:

=over

=item path [Str]

Dot-path of the element you wish to get.

=back

=back

=cut

method exists (Str $path!) {

	my @keys = $self->_splitKey($path);

	return $self->_exists( $self->_href, \@keys );    # --> Bool
}

=head2 merge

Merges the provided dot-path object or hashref with the object.  You indicate 
which hash has precedence by providing the 'overwrite' arg.

=over

=item usage:

 $newDot = $dot->merge({foo => 'bar'}, [0|1]);

 $dot2 = Hash::DotPath->new(biz => 'baz');
 $newDot = $dot->merge($dot2, [0|1]);
  
=item args:

=over

=item merge [HashRef|Hash::DotPath]

Hashref you wish to merge into the dot-path object.

=item overwrite [Bool] (optional)

Indicates which hash has precedence over the other.  A true value means
the element passed in will overwrite any pre-existing elements.  A false value
will preserve existing elements and just merge the new ones in.

Default: 1

=back

=back

=cut

method merge (Object|HashRef $merge!,
              Bool           $overwrite = 1) {

    my $href; 
	if ( $self->Hash->isHash($merge) ) {
		$href = $merge;
	}
	else {
		my $ref = ref($merge);
		if ($ref eq 'Hash::DotPath') {
	       $href = $merge->toHashRef;
		}
		else {
		  confess "can't use $ref as a hashref";	
		}
	}

    my %args = (left => $self->_href, right => $href);
    $args{precedent} = 'RIGHT' if $overwrite;
    my $merged = $self->Hash->merge(%args);
     
	return __PACKAGE__->new( $merged, delimiter => $self->delimiter );
}

=head2 set

Sets an element at the specified path.  Returns the value that was passed in.

=over

=item usage:

 $val = $dot->set('foo.bar', 'abc');
 $val = $dot->set('biz.0.baz', 'def');

=item args:

=over

=item path [Str]

Dot-path of the element you wish to set.

=item value [Any]

Value you wish to set at the given path.

=back

=back

=cut

method set (Str $path!,
            Any $value!) {

	my @keys       = $self->_splitKey($path);
#	my $lastKey    = pop @keys;
#	my $parentPath = join $self->delimiter, @keys;

	my $ptr = $self->_buildParentPath( $self->_href, \@keys );
	
	my $lastKey = pop(@keys);
	if ( $self->List->isArray($ptr) ) {
		if ( $self->String->isInt($lastKey) ) {
			$ptr->[$lastKey] = $value;
		}
		else {
			my $parentPath = join($self->delimiter, @keys);
			confess "can't reference array index at $parentPath by $lastKey";
		}
	}
	else {
		$ptr->{$lastKey} = $value;
	}

	return $value;    # --> Any
}

=head2 toHash

Returns a hash version of the object.

=over

=item usage:

 %hash = $dot->toHash;

=back

=cut

method toHash {

	return %{ $self->_href };
}

=head2 toHashRef

Returns a hashref version of the object.

=over

=item usage:

 $href = $dot->toHashRef;

=back

=cut

method toHashRef {

	return $self->_href;
}

##############################################################################
# PRIVATE METHODS
##############################################################################

method _splitKey (Str $key) {

	my $regex = sprintf '\%s', $self->delimiter;
	my @split = split( /$regex/, $key );

	return @split;
}

method _exists (HashRef  $ptr,
                ArrayRef $keys) {

	my @remKeys = @$keys;           # make a copy
	my $currKey = shift @remKeys;

	if ( $self->List->isArray($ptr) ) {

		if ( $self->String->isInt($currKey) ) {
			if (@remKeys) {
				return $self->_get( $ptr->[$currKey], \@remKeys );
			}
			elsif ( exists $ptr->[$currKey] ) {
				return 1;
			}
		}
	}
	else {

		if ( exists $ptr->{$currKey} ) {
			if (@remKeys) {
				return $self->_get( $ptr->{$currKey}, \@remKeys );
			}
			else {
				return 1;
			}
		}
	}

	return 0;
}

method _get (HashRef|ArrayRef  $ptr,
             ArrayRef          $keys) {

	my @remKeys = @$keys;           # make a copy
	my $currKey = shift @remKeys;

	if ( $self->List->isArray($ptr) ) {

		if ( $self->String->isInt($currKey) ) {
			if (@remKeys) {
				return $self->_get( $ptr->[$currKey], \@remKeys );
			}
			else {
				return $ptr->[$currKey];
			}
		}
	}
	else {

		if ( exists $ptr->{$currKey} ) {
			if (@remKeys) {
				return $self->_get( $ptr->{$currKey}, \@remKeys );
			}
			else {
				return $ptr->{$currKey};
			}
		}
	}

	return;    # not found (undef)
}

method _buildParentPath (HashRef|ArrayRef $ptr,
                         ArrayRef         $keys) {

	my @remKeys = @$keys;

	if (@remKeys > 1) {
		my $currKey = shift @remKeys;
        my $nextKey = $remKeys[0];

        my $nextRef;
        if ($self->String->isInt($nextKey)) {
            $nextRef = [];	
        } 	
        else {
            $nextRef = {};	
        }
         
		if ( $self->List->isArray($ptr) ) {
			# deref by index
			if ( $self->String->isInt($currKey) ) {
				if ( !exists $ptr->[$currKey] ) {
					$ptr->[$currKey] = $nextRef;
				}

				return $self->_buildParentPath( $ptr->[$currKey], \@remKeys );
			}
			else {
				confess "can't reference an array index by $currKey";
			}
		}
		elsif ( $self->Hash->isHash($ptr) ) {
			# deref by hash key
			if ( !exists $ptr->{$currKey} ) {
				$ptr->{$currKey} = $nextRef;
			}

			return $self->_buildParentPath( $ptr->{$currKey}, \@remKeys );
		}
	}

	return $ptr;
}

__PACKAGE__->meta->make_immutable;

1;
