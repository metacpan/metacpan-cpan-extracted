#!/usr/bin/perl -w

package Lingua::Phonology::Features;

=head1 NAME

Lingua::Phonology::Features - a module to handle a set of hierarchical
features.

=head1 SYNOPSIS

	use Lingua::Phonology;

	my $phono = new Lingua::Phonology;
	my $features = $phono->features;

    # Add features programmatically
    $features->add_feature(
        Node =>      { type => 'privative', children => ['Scalar', 'Binary', 'Privative'] },
        Scalar =>    { type => 'scalar' },
        Binary =>    { type => 'binary' },
        Privative => { type => 'privative' }
    );

    # Drop features
    $features->drop_feature('Privative');

    # Load feature definitions from a file
	$features->loadfile('phono.xml');

    # Load default features
    $features->loadfile;


=head1 DESCRIPTION

Lingua::Phonology::Features allows you to create a hierarchy of features of
various types, and includes methods for adding and deleting features and
changing the relationships between them.

By "heirarchical features" we mean that some features dominate some other
features, as in a tree. By having heirarchical features, it becomes possible to
set multiple features at once by assigning to a node, and to indicate
conceptually related features that are combined under the same node. This
module, however, does not instantiate values of features, but only establishes
the relationships between features.

Lingua::Phonology::Features recognizes multiple types of features.  Features
may be privative (which means that their legal values are either true or
C<undef>), binary (which means they may be true, false, or C<undef>), or scalar
(which means that their legal value may be anything). You can freely mix
different kinds of features into the same set of features.

Finally, while this module provides a full set of methods to add and delete
features programmatically, it also provides the option of reading feature
definitions from a file. This is usually faster and more convenient. The 
method to do this is L<"loadfile">. Lingua::Phonology::Features also comes
with an extensive default feature set.

=cut

use strict;
use warnings;
use warnings::register;
use Carp;
use Lingua::Phonology::Common;

sub err ($) { _err($_[0]) if warnings::enabled() };

our $VERSION = 0.2;

# %valid defines valid feature types
my %valid = (
    privative => 1,
    binary => 1,
    scalar => 1,
    node => 1
);

# Constructor
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	bless {}, $class;
}

# Add features to our set
sub add_feature {
	my $self = shift;
	my %hash = @_;
    my $err = 0;

	FEATURE: for (keys(%hash)) {
		unless (_is($hash{$_}, 'HASH')) {
			err("Bad value for $_");
            $err = 1;
			next FEATURE;
		}

        # Error checking--these invalidate the whole feature
        if (not $hash{$_} = _check_featureref($_, $hash{$_})) {
            $err = 1;
            next FEATURE;
        }

        # Drop any old feature
        $self->drop_feature($_) if $self->feature_exists($_);

        # Add the new feature
        $self->_add_featureref($_, $hash{$_}) or $err = 1;
    }

	return $err ? () : 1;
} 

# Change an existing feature. Same as add_feature(), but checks that the
# feature exists first
sub change_feature {
	my ($self, %hash) = @_;
	my $err = 0;

	FEATURE: for (keys(%hash)) {
		if (not $self->feature($_)) {
            $err = 1;
			next FEATURE;
		}

        if (not _is($hash{$_}, 'HASH')) {
            err "Bad value for $_";
            $err = 1;
            next FEATURE;
        }

        # Check the href
        if (not $hash{$_} = _check_featureref($_, $hash{$_})) {
            $err = 1;
            next FEATURE;
        }

        # Add the ref
        $self->_add_featureref($_, $hash{$_}) or $err = 1;

	} 
	return $err ? () : 1;
}

# Private -- check a hashref
sub _check_featureref {
    my ($name, $ref) = @_;

    # Check types
    $ref->{type} = lc $ref->{type};
    if (not $valid{$ref->{type}}) {
        return err("Invalid feature type '$ref->{type}' for feature $name");
    }
    $ref->{type} = 'privative' if $ref->{type} eq 'node';

    # Check children
    if ($ref->{child} && not _is($ref->{child}, 'ARRAY')) {
        return err("Bad value for child of $name");
    }
    $ref->{child} ||= [];

    # Check parents
    if ($ref->{parent} && not _is($ref->{parent}, 'ARRAY')) {
        return err("Bad value for parent of $name");
    }
    $ref->{parent} ||= [];

    # All OK
    return $ref;
}

# Private -- apply a hashref
sub _add_featureref {
    my ($self, $name, $ref) = @_;
    my $err = 0;

    $self->{$name}->{type} = $ref->{type};
    $self->{$name}->{child} = {};
    $self->{$name}->{parent} = {};
    $self->add_child($name, @{$ref->{child}}) or $err = 1;
    $self->add_parent($name, @{$ref->{parent}}) or $err = 1;
    return $err ? () : 1;
}


# Get a feature or get warned
sub feature {
	my ($self, $feature) = @_;
	return $self->{$feature} if exists($self->{$feature});
	return err("No such feature '$feature'");
}

# Check if a feature exists (w/o warnings)
sub feature_exists {
	my $self = shift;
	exists $self->{$_[0]};
}

# Drop a feature
sub drop_feature {
	my $self = shift;
    my $err = 0;
    for my $drop (@_) {
        # Remove references to this feature
        $self->drop_child($drop, $self->children($drop)) or $err = 1;
        $self->drop_parent($drop, $self->parents($drop)) or $err = 1;

        # Remove the feature itself
        delete $self->{$drop};
    }
    return $err ? () : 1;
}

sub all_features {
	return %{$_[0]};
}

# Get array of children
sub children {
	my ($self, $feature) = @_; 
    return exists $self->{$feature} ?
           keys %{$self->{$feature}->{child}} :
           err "No such feature '$feature'";
}

# Add a new child to a parent
sub add_child {
	my ($self, $parent, @children) = @_;
	my $err = 0;

    # Check that parent exists
    $self->feature($parent) or return;

	CHILD: for my $child (@children) {
		# Check that the child feature exists
		if (not $self->feature($child)) {
			$err = 1;
			next CHILD;
		}

		# Mark relations on parents and children
        $self->{$parent}->{child}->{$child} = undef;
        $self->{$child}->{parent}->{$parent} = undef;
	}

	return $err ? (): 1;
}

# Get rid of a child
sub drop_child {
	my ($self, $parent, @children) = @_;
    my $err = 0;

    # Check that parent exists
    $self->feature($parent) or return;

	CHILD: for my $child (@children) {
        # Check that the child exists
        if (not $self->feature($child)) {
            $err = 1;
            next CHILD;
        }

        # Remove marks
        delete $self->{$parent}->{child}->{$child};
        delete $self->{$child}->{parent}->{$parent};
    }

	return $err ? () : 1;
}

# Get current parents
sub parents {
	my ($self, $feature) = @_;
    return exists $self->{$feature} ?
           keys %{$self->{$feature}->{parent}} :
           err "No such feature '$feature'";
}

# Add a parent
sub add_parent {
	my ($self, $child, @parents) = @_;
	my $err = 0;

    # Check that the child exists
    $self->feature($child) or return;

	# This action is identical to add_child, but with order of arguments switched
	# So just pass the buck
	for (@parents) {
		$self->add_child($_, $child) or $err = 1;
	}
	return $err ? () : 1;
}

# Get rid of a parent
sub drop_parent {
	my ($self, $child, @parents) = @_;
    my $err = 0;

    # Child exists?
    $self->feature($child) or return;

	# Once again, just pass to drop_child
	for (@parents) {
		$self->drop_child($_, $child) or $err = 1;
	}

	return $err ? () : 1;
}

# Get/set feature type
sub type {
	my ($self, $feature, $type) = @_;
	$self->feature($feature) or return;

	if ($type) {
		# Check for valid types
		return err("Invalid type $type") if (not $valid{$type});

		# Otherwise:
		$self->{$feature}->{type} = $type;
	}
	
	# Return the current type
	$self->{$feature}->{type};
}

# Load feature definitions from a file
sub loadfile {
	my ($self, $file) = @_;

    my $parse;
    # Load defaults when no file given
    if (not defined $file) {
        my $start = tell DATA;
        my $string = join '', <DATA>;
        eval { $parse = _parse_from_string($string, 'features') };
        return err($@) if $@;
        seek DATA, $start, 0;
    }

    # Load an actual file
    else {
        eval { $parse = _parse_from_file($file, 'features') };
        if (!$parse) {
            return $self->old_loadfile($file);
        }
    }

    $self->_load_from_struct($parse);
}

# The parser for the old deprecated format
sub old_loadfile {
    my ($self, $file) = @_;

    eval { $file = _to_handle($file, '<') };
    return err($@) if $@;

	my %children;
	while (<$file>) {
		s/\#.*$//; # Strip comments
		if (/^\s*(\w+)\t+(\w+)(\t+(.*))?/) {
			my ($name, $type, $children) = ($1, $2, $4);
			no warnings 'uninitialized';
			$self->add_feature($name => {type => $type});
			$children{$name} = [ split /\s+/, $children ] if $children;
		}

	}

	# Add kids
	$self->add_child($_, @{$children{$_}}) for keys %children;

	close $file;
	return 1;
}

# Actually apply a structure to the object. Private, called by loadfile() and
# Lingua::Phonology
sub _load_from_struct {
	my ($self, $parse) = @_;

    # This line is perhaps too clever for its own good
	my %children = map { $_ => delete($parse->{$_}->{child}) } keys %$parse;
    my %parents = map { $_ => delete($parse->{$_}->{parent}) } keys %$parse;

	$self->add_feature(%$parse);
	$self->add_child($_, keys %{$children{$_}}) for keys %children;
	$self->add_parent($_, keys %{$parents{$_}}) for keys %parents;
	1;
}

# Return an XML representation of yourself
sub _to_str {
	my $self = shift;

	# Construct an appropriate data structure
	my $struct = {};
	for (keys %$self) {
        # Only make child attrs, not parent attrs
		$struct->{$_}->{child} = [ map { { name => $_ } } keys %{$self->{$_}->{child}} ];
        $struct->{$_}->{type} = $self->{$_}->{type};
	}

    return eval { _string_from_struct({ features => { feature => $struct } }) };
}

# The following coderefs translate arbitrary data into numeric equivalents
# respecting common linguistic abbreviations like [+foo, -bar, *baz]
my %num_form = (
	privative => sub {
		return 1 if $_[0];
		return undef;
	},
	binary =>sub {
		my $value = shift;
		# Text values
		return 0 if ($value eq '-');
		return 1 if ($value eq '+');
		# Other values
		return 1 if ($value);
		return 0;
	},
	scalar => sub {
		return $_[0]; # Nothing happens to scalars
	}
);

# Translate our input (presumably text) into a number
sub number_form {
	my $self = shift;

	return err("Not enough arguments to number_form") if (@_ < 2);
	my ($feature, $value) = @_;
	
	my $ref = $self->feature($feature) or return;

	# undef is always valid
	# '*' is always a synonym for undef
	return undef if (not defined($value));
	return undef if ($value eq '*');

	# Otherwise, pass processing to the appropriate coderef
	return $num_form{$ref->{type}}->($value);
}

# These coderefs take numeric data and return their text equivs (inverse of
# %num_form)
my %text_form = (
	privative => sub {
		return '';
	},
	binary => sub {
		return '+' if shift;
		return '-';
	},
	scalar => sub {
		return shift;
	},
);

sub text_form {
	my $self = shift;

	return err("Not enough arguments to text_form") if (@_ < 2);
	my ($feature, $value) = @_;
	
	my $ref = $self->feature($feature) or return;

	# first mash through number_form
	$value = $self->number_form($feature, $value);

	# '*' is always a synonym for undef
	return '*' if (not defined($value));

	return $text_form{$ref->{type}}->($value);
}

1;

=head1 METHODS

=head2 new

    my $features = Lingua::Phonology::Features->new();

This method creates and returns a new Features object. It takes no arguments.

=head2 add_feature

Adds a new feature to the current list of features. Accepts a list of
arguments of the form "feature_name => { ... }", where the value assigned
to each feature name must be a hash reference with one or more of the
following keys:

=over 4

=item * type

The type must be one of 'privative', 'binary', 'scalar', or 'node'.
The feature created is of the type specified. This key must be defined for all
features. As of version 0.3, the 'node' type is deprecated, and is considered
synonymous with 'privative'.

=item * child

The value for this key is a reference to an array of feature names.
The features named will be assigned as the children of the feature being
defined. Note that any type of feature may have children, and children may be
of any type. (This is new in version 0.3.)

=item * parent

The inverse of C<child>. The value for this key must be a 
reference to an array of feature names that are assigned as the parents
of the feature being added.

=back

Note that the features named in C<parent> or C<child> must already be
defined when the new feature is added. Thus, trying to add parents and
children as part of the same call to C<add_feature()> will almost certainly
result in errors.

This method return true on success and false if any error occurred.

Example:

	$features->add_feature(
        anterior => { type => 'binary' },
        distributed => { type => 'binary' }
    );
	$features->add_feature( 
        Coronal => { type => 'privative', child => ['anterior', 'distributed']}
    );

Note that if you attempt to add a feature that already exists, the preexisting
feature will be dropped before the new feature is added.

B<WARNING>: The features C<SYLL, Rime, onset, nucleus, coda, SON> are used by
Lingua::Phonology::Syllable. They may be defined as part of a user feature set
if you insist, but their original definitions may be overwritten, since
Lingua::Phonology::Syllable will forcibly redefine those features when it is
used. You have been warned.

=head2 feature

    my $feature = $features->feature('name');

Given the name of a feature, returns a hash reference showing the current
settings for that feature. The hash reference will at least contain the key
C<type>, naming the feature type, and may contain the keys C<child> and/or
C<parent> if the feature has some children or parents. If you ask for a feature
that doesn't exist, this method will return undef and emit a warning.

=head2 feature_exists 

    my $bool = $features->feature_exists('name');

Given the name of the feature, returns a simple truth value indicating whether
or not any such feature with that name currently exists. Unlike C<feature()>,
this method never gives an error, and does not return the feature reference on
success. This can be used by programs that want to quickly check for the
existence of a feature without printing warnings.

=head2 all_features

    my %features = $features->all_features();

Takes no arguments. Returns a hash with feature names as its keys, and the
parameters for those features as its values. The values will be hash references
the same as those returned from C<feature()>;

=head2 drop_feature

    $features->drop_feature('name');
    $features->drop_feature(@names);

Given one or more feature names, deletes the given feature(s) from the current
list of features. Note that deleting a feature does not cause its children to
be deleted--it just causes them to revert to being undominated. This method
returns true on success, otherwise false with an error.

=head2 change_feature

This method works identically to add_feature(), but it first checks to see that
the feature being changed already exists. If it doesn't, it will give an error.
If there are no errors, the method returns true.

The C<add_feature()> method can also be used to change existing features. Using
C<change_feature()>, however, allows you to modify an existing feature without
losing existing settings for that feature. For example, consider the following:

    $features->add_feature(foo => { type => 'privative', child => ['bar', 'baz'] });
    $features->change_feature(foo => { type => 'scalar' });
    # foo is still the parent of bar and baz

If C<add_feature()> had been used in place of C<change_feature()>, C<foo> would
not be the parent of anything, because the original settings for its children
would have been lost.

=head2 children

    my @children = $features->children('name');

Takes one argument, the name of a feature. Returns a list of all of the
features that are children of the feature given.

=head2 add_child

    $features->add_child('parent', 'child');
    $features->add_child('parent', @children);

Takes two or more arguments. The first argument to this method should be the
name of a feature.  The remaining arguments are the names of features to be
assigned as children to the first feature. If all children are added without
errors, this function returns true, otherwise false with a warning.

=head2 drop_child

    $features->drop_child('parent', 'child');
    $features->drop_child('parent', @children);

Like add_child, the first argument to this function should be the name of a
feature, and the remaining arguments are the names of children of that feature.
The child features so named will be deleted from the list of children for that
node. This function returns true on success, false w/ a warning on any error.

=head2 parents

    my @parents = $features->parents('name');

Takes one argument, the name of a feature. Returns a list of the current
parent features of that feature.

=head2 add_parent

    $features->add_parent('child', 'parent');
    $features->add_parent('child', @parents);

Takes two or more arguments. The first argument is the name of a feature, and
the remaining arguments are the names of features that should be parents of
that feature. Returns true if all of the attempted operations succeeded,
otherwise returns false. 

=head2 drop_parent

    $features->drop_parent('child', 'parent');
    $features->drop_parent('child', @parents);

Takes two or more arguments. The first is a feature name, and the remaining
arguments are the names of features that are currently parents of that feature.
Those features will cease to be parents of the first feature. Returns true on
success, false on error.

=head2 type

    # Get a feature type
    $features->type('name');
    # Set a feature's type to 'binary', for example
    $features->type('name', 'binary');

Takes one or two arguments. The first argument must be the name of a 
feature. If there is only one argument, the type for that feature is
return. If there are two arguments, the type is set to the second 
argument and returned.

=head2 loadfile

    # Load defaults
    $features->loadfile();
    
    # Load from a file
    $features->loadfile('phono.xml');

Takes one argument, the path and name of a file. Reads the lines of the file
and adds all of the features defined therein. The file should be an XML file
following the format described in L<Lingua::Phonology::FileFormatPOD>. Consult
that module if you need to write an appropriate file by hand.

You can also call this method with no arguments, in which case the default
feature set is loaded. The default set is described in L<"THE DEFAULT FEATURE
SET">.

If this method is unable to parse its input as an XML file, it will then pass
the file off to C<old_loadfile()>, where it will attempt to parse the the file
according to the old, deprecated file format. If you have an existing script
that loads a file in the old file format with C<loadfile()>, there's nothing
that needs to be done immediately since the file will still be parsed
correctly. However, you will get warnings telling you that the format you're
using is deprecated.

=head2 old_loadfile

    $features->old_loadfile('filename');

Loads a file in the old (pre-version 0.2) and currently deprecated file format.
This format is described below.

Feature definition lines should be in this format:

	feature_name   [1 or more tabs]   type   [1 or more tabs]   children (separated by spaces)

You can order your features any way you want in the file. The method will
take care of ensuring that parents are defined before their children are
added and make sure no conflicts result.

Lines beginning with a '#' are assumed to be comments and are skipped.

This method does NOT load the default features any more. Only C<loadfile()>
does that.

=head2 number_form

    my $num = $features->number_form('name', $text);

Takes two arguments. The first argument is the name of a feature, and the
second is a value to be converted into the appropriate numeric format for that
feature. This function is provided for convenience, to allow Lingua::Phonology
to convert between common textual linguistic notation and its internal numeric
representation.

The conversion from input value to numeric value depends on what type of
feature the feature given in the first argument is. A few general text
conventions are recognized to make text parsing easier and to ensure that
number_form and L<"text_form"> can be used as inverses of each other. The
conversions are as follows:

=over 4

=item * privatives

The string '*' is recognized as a synonym for C<undef> in all circumstances.
It always returns C<undef>.

=item *

B<privative> features return 1 if given any true true value (other than '*'),
otherwise C<undef>.

=item *

B<binary> features return 1 in the case of a true value, 0 in case of a 
defined false value, and otherwise C<undef>. The string '+' is a synonym for
1, and '-' is a synonym for 0. Thus, the following two lines both return
0:

	print $features->number_form('binary_feature', 0); # prints 0
	print $features->number_form('binary_feature', '-'); # prints 0

Note, however, if the feature given is a privative feature, the first returns
C<undef> and the second returns 1.

=item *

B<scalar> features return the value that they're given unchanged (unless 
that value is '*', which is translated to C<undef>).

=item *

=back


=head2 text_form

    my $text = $features->text_form('name', $number);

This function is the inverse of number_form. It takes two arguments, a 
feature name and a numeric value, and returns a text equivalent for the
numeric value given. The exact translation depends on the type of the 
feature given in the first argument. The translations are:

=over 4

=item *

Any undefined value or the string '*' returns '*'.

=item *

B<privative> features return '*' for undef or logically false values, otherwise
'' (an empty string).

=item *

B<binary> features return '+' if true, '-' if false or equal to '-', and '*' if
undefined.

=item *

B<scalar> features return their values unchanged, except if they're undefined,
in which case they return '*'.

=item *

=back

=head1 THE DEFAULT FEATURE SET

If you call the method C<L<"loadfile">> without any arguments, like this:

	$features->loadfile

then the default feature set is loaded. The default feature set is a
feature geometry tree based on Clements and Hume (1995), with some
modifications. This set gratuitously mixes privative, binary, and scalar
features, and may or may not be actually useful to you.

Within this feature set, we use the convention of putting top-level
(undominated) nodes in ALL CAPS, putting intermediate nodes in Initial Caps,
and putting terminal features in lowercase. The following shows the feature
tree created, with the types of each feature in parenthesis:

	# True features
	ROOT (privative)
	 |
	 +-sonorant (privative)
	 +-approximant (privative)
	 +-vocoid (privative)
	 +-nasal (privative)
	 +-lateral (privative)
	 +-continuant (binary)
	 +-Laryngeal
	 |  |
	 |  +-spread (privative)
	 |  +-constricted (privative)
	 |  +-voice (privative)
	 |  +-ATR (binary)
	 |
	 +-Place
	    |
	    +-pharyngeal (privative)
		+-Oral
		   |
		   +-labial (privative)
		   +-Lingual
		   |  |
		   |  +-dorsal (privative)
		   |  +-Coronal
		   |     |
		   |     +-anterior (binary)
		   |     +-distributed (binary)
		   |
		   +-Vocalic
		      |
		      +-aperture (scalar)
			  +-tense (privative)
			  +-Vplace
			     |
			     +-labial (same as above)
				 +-Lingual (same as above)
	
	# Features dealing with syllable structure
	SYLL (privative)
     |
     +-onset (privative)
     +-Rime (privative)
        |
        +-nucleus (privative)
        +-coda (privative)
    SON (scalar)

This feature set is created from the following XML file, which can be treated
as an example for creating your own feature sets.

    <phonology>
      <features>

        <!-- True Features -->

        <feature name="ROOT" type="privative">
          <child name="sonorant" />
          <child name="approximant" />
          <child name="vocoid" />
          <child name="nasal" />
          <child name="lateral" />
          <child name="continuant" />
          <child name="Laryngeal" />
          <child name="Place" />
        </feature>
        <feature name="sonorant" type="privative" />
        <feature name="approximant" type="privative" />
        <feature name="vocoid" type="privative" />
        <feature name="nasal" type="privative" />
        <feature name="lateral" type="privative" />
        <feature name="continuant" type="binary" />

        <feature name="Laryngeal" type="privative">
          <child name="spread" />
          <child name="constricted" />
          <child name="voice" />
          <child name="ATR" />
        </feature>
        <feature name="spread" type="privative" />
        <feature name="constricted" type="privative" />
        <feature name="voice" type="privative" />
        <feature name="ATR" type="binary" />

        <feature name="Place" type="privative">
          <child name="pharyngeal" />
          <child name="Oral" />
        </feature>
        <feature name="pharyngeal" type="privative" />

        <feature name="Oral" type="privative">
          <child name="labial" />
          <child name="Lingual" />
          <child name="Vocalic" />
        </feature>
        <feature name="labial" type="privative" />

        <feature name="Lingual" type="privative">
          <child name="Coronal" />
          <child name="dorsal" />
        </feature>
        <feature name="dorsal" type="privative" />

        <feature name="Coronal" type="privative">
          <child name="anterior" />
          <child name="distributed" />
        </feature>
        <feature name="anterior" type="binary" />
        <feature name="distributed" type="binary" />

        <feature name="Vocalic" type="privative">
          <child name="Vplace" />
          <child name="aperture" />
          <child name="tense" />
        </feature>
        <feature name="aperture" type="scalar" />
        <feature name="tense" type="binary" />

        <feature name="Vplace" type="privative">
          <child name="labial" />
          <child name="Lingual" />
        </feature>

        <!-- Syllabification Features -->

        <feature name="SYLL" type="scalar">
          <child name="onset" />
          <child name="Rime" />
        </feature>

        <feature name="onset" type="privative" />
        <feature name="Rime" type="privative">
          <child name="nucleus" />
          <child name="coda" />
        </feature>
        <feature name="nucleus" type="privative" />
        <feature name="coda" type="privative" />

        <feature name="SON" type="scalar" />

      </features>
    </phonology>

=head1 TO DO

Improve the default feature set. As it is, it cannot handle uvulars or
pharyngeals, and has some quirks in its relationships that lead to strange
results. Though some of this is the fault of phonologists who can't make up
their minds about how things are supposed to go together.

=head1 SEE ALSO

L<Lingua::Phonology::Segment>

L<Lingua::Phonology::Rules>

=head1 REFERENCES

Clements, G.N and E. Hume. "The Internal Organization of Speech Sounds."
Handbook of Phonological Theory. Ed. John A. Goldsmith. Cambridge,
Massachusetts: Blackwell, 2001. 245-306.

This article is a terrific introduction to the concept of feature geometry,
and also describes ways to write rules in a feature-geometric system.

=head1 AUTHOR

Jesse S. Bangs <F<jaspax@cpan.org>>

=head1 LICENSE

This module is free software. You can distribute and/or modify it under the
same terms as Perl itself.

=cut

__DATA__

<phonology>
  <features>

	<!-- True Features -->

    <feature name="ROOT" type="privative">
      <child name="sonorant" />
      <child name="approximant" />
      <child name="vocoid" />
      <child name="nasal" />
      <child name="lateral" />
      <child name="continuant" />
      <child name="Laryngeal" />
      <child name="Place" />
    </feature>
    <feature name="sonorant" type="privative" />
    <feature name="approximant" type="privative" />
    <feature name="vocoid" type="privative" />
    <feature name="nasal" type="privative" />
    <feature name="lateral" type="privative" />
    <feature name="continuant" type="binary" />

    <feature name="Laryngeal" type="privative">
      <child name="spread" />
      <child name="constricted" />
      <child name="voice" />
      <child name="ATR" />
    </feature>
    <feature name="spread" type="privative" />
    <feature name="constricted" type="privative" />
    <feature name="voice" type="privative" />
    <feature name="ATR" type="binary" />

    <feature name="Place" type="privative">
      <child name="pharyngeal" />
      <child name="Oral" />
    </feature>
    <feature name="pharyngeal" type="privative" />

    <feature name="Oral" type="privative">
      <child name="labial" />
      <child name="Lingual" />
      <child name="Vocalic" />
    </feature>
    <feature name="labial" type="privative" />

    <feature name="Lingual" type="privative">
      <child name="Coronal" />
      <child name="dorsal" />
    </feature>
    <feature name="dorsal" type="privative" />

    <feature name="Coronal" type="privative">
      <child name="anterior" />
	  <child name="distributed" />
    </feature>
    <feature name="anterior" type="binary" />
    <feature name="distributed" type="binary" />

    <feature name="Vocalic" type="privative">
      <child name="Vplace" />
      <child name="aperture" />
      <child name="tense" />
    </feature>
    <feature name="aperture" type="scalar" />
    <feature name="tense" type="binary" />

    <feature name="Vplace" type="privative">
      <child name="labial" />
      <child name="Lingual" />
    </feature>

	<!-- Syllabification Features -->

    <feature name="SYLL" type="scalar">
	  <child name="onset" />
	  <child name="Rime" />
	</feature>

    <feature name="onset" type="privative" />
    <feature name="Rime" type="privative">
	  <child name="nucleus" />
	  <child name="coda" />
	</feature>
    <feature name="nucleus" type="privative" />
    <feature name="coda" type="privative" />

    <feature name="SON" type="scalar" />

  </features>
</phonology>
