package Games::Object;

use strict;
use Exporter;

use Carp qw(carp croak confess);
use POSIX;
use IO::File;
use IO::String 1.02;
use Games::Object::Common qw(ANAME_MANAGER FetchParams LoadData SaveData);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);

$VERSION = "0.11";
@ISA = qw(Exporter);
@EXPORT_OK = qw(ProcessList
		OBJ_CHANGED OBJ_AUTOALLOCATED OBJ_PLACEHOLDER OBJ_DESTROYED
		ATTR_STATIC ATTR_DONTSAVE ATTR_AUTOCREATE ATTR_NO_INHERIT
		ATTR_NO_ACCESSOR
		FLAG_NO_INHERIT
		ACT_MISSING_OK
		$CompareFunction $AccessorMethod $ActionMethod);
%EXPORT_TAGS = (
    functions		=> [qw(ProcessList)],
    objflags		=> [qw(OBJ_CHANGED OBJ_AUTOALLOCATED
			       OBJ_PLACEHOLDER OBJ_DESTROYED)],
    attrflags		=> [qw(ATTR_STATIC ATTR_DONTSAVE ATTR_AUTOCREATE
			       ATTR_NO_INHERIT ATTR_NO_ACCESSOR)],
    flagflags		=> [qw(FLAG_NO_INHERIT)],
    actionflags		=> [qw(ACT_MISSING_OK)],
    variables		=> [qw($CompareFunction $AccessorMethod $ActionMethod)],
);

use vars qw($CompareFunction $AccessorMethod $ActionMethod);

# Overload operations to allow simple comparisons to be performed easily.
#
# ALL operations can be overridden with no effect to this class. These operators
# are not used internally.
use overload 
    '<=>'	=> '_compare_pri',
    'cmp'	=> '_compare_ids',
    'bool'	=> '_do_nothing',
    '""'	=> 'id';

# Define some attribute flags.
use constant ATTR_STATIC	=> 0x00000001;
use constant ATTR_DONTSAVE	=> 0x00000002;
use constant ATTR_AUTOCREATE	=> 0x00000004;
use constant ATTR_NO_INHERIT	=> 0x00000008;
use constant ATTR_NO_ACCESSOR	=> 0x00000010;

# Define some flag flags (i.e. internal flags on user-defined flag structures)
use constant FLAG_NO_INHERIT	=> 0x00000008;

# Define object flags (internal)
use constant OBJ_CHANGED        => 0x00000001;
use constant OBJ_AUTOALLOCATED  => 0x00000002;
use constant OBJ_PLACEHOLDER    => 0x00000004;
use constant OBJ_DESTROYED      => 0x00000008;

# Define action flags. Make sure these do not overlap with other flags
# so they can be used in combination with them.
use constant ACT_MISSING_OK	=> 0x00001000;

# Define default global options
$AccessorMethod = 0;
$ActionMethod = 0;

# Define the comparison function to use for processing order.
$CompareFunction = '_CompareDefault';

# Track the highest priority object so that we can insure the global object
# is higher.
my $highest_pri = 0;

# Define a table that shows what order process() is supposed to do things
# by default.
my @process_list = (
    'process_queue',
    'process_pmod',
    'process_tend_to',
);

# Define a limit to how many times the same item can be processed in a queue
# (see process_queue() for details)
my $process_limit = 100;

####
## INTERNAL FUNCTIONS

# Round function provided for the -on_fractional option

sub round { int($_[0] + 0.5); }

# Check to see if a variable holds a reference to a Games::Object object

sub _IsObject
{
	my $obj = shift;
	ref($obj) && UNIVERSAL::isa($obj, 'Games::Object');
}

# Create an accessor method

sub _CreateAccessorMethod
{
	my ($name, $type) = @_;
	no strict 'refs';

	if ($type eq 'attr') {

	    # Don't do anything if already defined.
	    my $simple = $name;
	    my $modify = "mod_$name";
	    return 1 if (defined(&$simple));

	    # Create it.
	    *$simple = sub {
	        my $obj = shift;
	        @_ == 0 ? $obj->attr($name) :
	        @_ == 1 ? $obj->mod_attr(-name => $name, -value => $_[0]) :
		@_ == 2 && _IsObject($_[1]) ?
		          $obj->mod_attr(-name => $name,
					 -value => $_[0],
					 -other => $_[1]) :
		@_ == 3 && _IsObject($_[1]) && _IsObject($_[2]) ?
		          $obj->mod_attr(-name => $name,
					 -value => $_[0],
					 -other => $_[1],
					 -object => $_[2])
		:
	        	  $obj->mod_attr(-name => $name, '-value', @_);
	    };
	    *$modify = sub {
	        my $obj = shift;
		@_ == 1 ? $obj->mod_attr(-name => $name, -modify => $_[0]) :
		@_ == 2 && _IsObject($_[1]) ?
		          $obj->mod_attr(-name => $name,
					 -modify => $_[0],
					 -other => $_[1]) :
		@_ == 3 && _IsObject($_[1]) && _IsObject($_[2]) ?
		          $obj->mod_attr(-name => $name,
					 -modify => $_[0],
					 -other => $_[1],
					 -object => $_[2])
		:
	        	  $obj->mod_attr(-name => $name, '-modify', @_);
	    };

	} elsif ($type eq 'flag') {

	    # Don't do anything if already defined.
	    return 1 if (defined(&$name));

	    # Create it.
	    *$name = sub {
		my $obj = shift;
		my ($val, $other) = @_;
		$val ? $obj->set($name, $other) :
		       $obj->clear($name, $other);
	    };

	}

	1;
}

# Create an action method.

sub _CreateActionMethod
{
	my $action = shift;
	$action =~ /^on_(.+)$/;
	my $verb = $1;

	no strict 'refs';

	# This form of the action method acts as a "verb". The first object is
	# considered to be instigating the action and is thus other, self is
	# is the object being acted upon, and object is an optional other
	# item involved in the transaction. Examples:
	#
	#   $player->use($camera);
	#	other = $player self = $camera
	#	Player snaps a picture
	#
	#   $player->use($camera, $plant);
	#	other = $player self = $camera object = $plant
	#	Player snaps picture of plant
	#
	#   $creature->give($player, $apple);
	#	other = $creature self = $player object = $apple
	#	Creature gives player the apple
	*$verb = sub {
	    my $other = shift;
	    my $args = ( ref($_[$#_]) eq 'HASH' ? pop @_ : undef );
	    my ($self, $object) = (
		@_ == 0 ? croak "Not enough arguments to $verb!" :
		@_ == 1 ? ($_[0], undef ) :
		@_ == 2 ? ( @_ ) :
		    croak "Too many arguments to $verb!" );
	    $self->action(action => "object:${action}",
			  other  => $other,
			  object => $object,
			  args   => $args);
	} if (defined($verb) && !defined(&$verb));

	# The passive form is simply the original action triggered from self
	# rather than other. Designed largely for peripheral actions or
	# side-effect actions. For example, extending the "give" action above,
	# you may want to call "on_given" on the $apple object.
	#
	# This is also used for actions that have neither other nor object
	# parameters.
	*$action = sub {
	    my $self = shift;
	    my $args = ( ref($_[$#_]) eq 'HASH' ? pop @_ : undef );
	    my $flags = ( !_IsObject($_[$#_]) ? pop @_ : 0 );
	    my ($other, $object) = (
		@_ == 0 ? ( undef, undef ) :
		@_ == 1 ? ( $_[0], undef ) :
		@_ == 2 ? ( @_ ) :
		    croak "Too many arguments to $verb!" );
	    $self->action(action => "object:${action}",
			  other  => $other,
			  object => $object,
			  flags	 => $flags,
			  args   => $args);
	} if (!defined(&$action));
}

# Default comparison function when determining the order of processing of
# two objects.

sub _CompareDefault { $b->{priority} <=> $a->{priority} }

# Comparison function when using the creation order option

sub _CompareCreationOrder {
    my $cmp = $b->{priority} <=> $a->{priority};
    $cmp == 0 ? $a->{order} <=> $b->{order} : $cmp;
}

####
## FUNCTIONS

# Fetch/set the process list for the process() function. Note that the user is
# not limited to the methods found here. The methods can be in the subclass
# if desired. Note that we have no way to validate the method names here,
# so we take it on good faith that they exist.

sub ProcessList { if (@_) { @process_list = @_ } else { @process_list } }

####
## INTERNAL METHODS

# Do absolutely nothing successfully.

sub _do_nothing { 1; }

# Do absolutely nothing, but fail at it.

sub _do_nothing_fail { 0; }

# Set an internal flag on object.

sub _set
{
	my ($obj, $flag) = @_;

	$obj->{_flags} |= $flag;
}

# Clear an internal flag on object.

sub _clear
{
	my ($obj, $flag) = @_;

	$obj->{_flags} &= (0xffffffff ^ $flag);
}

# Check if an internal flag is set.

sub _is
{
	my ($obj, $flag) = @_;

	($obj->{_flags} & $flag) == $flag;
}

# Wipe all values from object except for the ID and DONTSAVE attributes.

sub _wipe
{
	my $obj = shift;

	foreach my $key (keys %$obj) {
	    next if ($key eq 'id');
	    if ($key eq 'attr') {
		foreach my $aname (keys %{$obj->{attr}}) {
		    my $attr = $obj->{attr}{$aname};
		    delete $obj->{attr}{$aname}
			if ( !($attr->{flags} & ATTR_DONTSAVE) );
		}
	    } else {
	        delete $obj->{$key};
	    }
	}
	$obj;
}

# "Lock" a method call so that it cannot be called again, thus practioning
# recursion. If it is already locked, then this is a fatal error, indicating
# that recursion has occurred.

sub _lock_method
{
	my ($obj, $meth) = @_;
	my $lock = "__" . $meth;

	if (defined($obj->{$lock})) {
	    croak("Attempt to call '$meth' on '$obj->{id}' recursively");
	} else {
	    $obj->{$lock} = 1;
	}
}

# Unlock a method

sub _unlock_method
{
	my ($obj, $meth) = @_;
	my $lock = "__" . $meth;

	delete $obj->{$lock};
}

# Compare the IDs of two objects.

sub _compare_ids
{
	my ($obj1, $obj2, $swapped) = @_;
	my $id1 = $obj1->id();
	my $id2 = ref($obj2) ? $obj2->id() : $obj2;

	$swapped ? $id2 cmp $id1 : $id1 cmp $id2;
}

# Compare the priorities of two objects.

sub _compare_pri
{
	my ($obj1, $obj2, $swapped) = @_;
	my $pri1 = $obj1->priority();
	my $pri2 = ref($obj2) ? $obj2->priority() : $obj2;

	$swapped ? $pri2 <=> $pri1 : $pri1 <=> $pri2;
}

####
## CONSTRUCTOR

# Basic constructor.

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $obj = {};
	my %args = ();

	# Fetch optional parameters.
	FetchParams(\@_, \%args, [
	    [ 'opt', 'id', undef, 'string' ],
	    [ 'opt', '^on_', undef, 'callback' ],
	    [ 'opt', '^try_', undef, 'callback' ],
	    [ 'opt', 'class', undef, 'object' ],
	    [ 'opt', 'priority', 0, 'int' ],
	] );

	# Bless object and set user-provided values, if defined.
	bless $obj, $class;
	$obj->{id} = $args{id} if (defined($args{id}));
	$obj->{priority} = $args{priority};

	# Initialize internal data structures.
	$obj->{_flags} = 0;
	$obj->{attr} = {};
	$obj->{flag} = {};
	$obj->{queue} = [];
	$obj->{priority} = 0;
	$obj->{pmod} = {};
	$obj->{pmod_next} = 0;
	$obj->{pmod_active} = 0;

	# For each on_* action, create a matching attribute to store the
	# actual callback data and delete the original parameter. This way
	# we can use simple inheritance and don't have to write seperate code
	# to handle it.
	foreach my $action (grep { /^(on|try)_/ } keys %args) {
	    my $callbk = delete $args{$action};
	    $obj->del_attr($action);
	    $obj->new_attr(
		-name		=> "_ACT_${action}",
		-type		=> "any",
		-value		=> $callbk,
		-flags		=> ATTR_NO_ACCESSOR,
	    );
	    _CreateActionMethod($action) if ($ActionMethod);
	}

	# Done.
	$obj;
}

# Load an object from an open file. You can call this in one of several ways:
#
# - As a class method, which generates a totally new object.
# - As an object method, which loads the object "in place" (i.e. overriting
#   the current object, except for the ID, which is preserved if defined)
#
# You can also call this with a "file" arg (which is an open file), or
# "filename" (which is a filename that is opened and closed for you)

sub load
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = ();

	# Check for occurrence of single parameter and turn into appropriate
	# named parameter if found.
	unshift @_, "file" if (@_ == 1 && ref($_[0]));
	unshift @_, "filename" if (@_ == 1 && !ref($_[0]));

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'opt', 'file', undef, 'file' ],
	    [ 'opt', 'filename', undef, 'string' ],
	    [ 'opt', 'id', undef, 'string' ],
	    [ 'opt', 'other', undef, 'object' ],
	]);

	# Check the file args.
	croak "Cannot define both 'filename' and 'file' args to object " .
	      "constructor"
	    if (defined($args{file}) && defined($args{filename}));
	if (defined($args{filename})) {
	    $args{file} = IO::File->new();
	    $args{file}->open("<$args{filename}")
		or croak "Unable to open filename '$args{filename}' for read";
	} elsif (!defined($args{file})) {
	    croak "One of 'file' or 'filename' must be specified to load()"
	}

	# First check that the file really contains an object definition at
	# this point. We need to do this anyway since we need the ID stored
	# there. NOTE: The assignment to $file is necessary, as <$args{file}>
	# will not parse.
	my $file = $args{file};
	my $line = <$file>;
	croak("Attempt to read object data past EOF") if (!defined($line));
	croak("File does not contain object data at present position")
	    if ($line !~ /^OBJ:(.+)$/);
	my $id = $1;

	# Now fetch the saved class of the object, so we can re-bless it into
	# the user's subclass.
	$line = <$file>;
	croak("Attempt to read object data past EOF") if (!defined($line));
	croak("File does not contain class data at present position")
	    if ($line !~ /^CL:(.+)$/);
	my $subclass = $1;

	# How were we called?
	my $obj;
	if (_IsObject($proto)) {
	    # As an object method, so we do a "load in place". Clear out
	    # everything except the ID, if defined.
	    $obj->_wipe();
	} else {
	    # Create a totally new object from this.
	    $obj = Games::Object->new();
	}

	# If the user overrides the ID, or the ID exists in the object already,
	# then we set that here.
	if (defined($args{id}))		{ $id = $args{id}; }
	elsif (defined($obj->{id}))	{ $id = $obj->{id}; }

	# We now have an object ready to load into, so perform the load.
	$obj->_protect_attrs(\&LoadData, $file, $obj);

	# Close the file if we opened it.
	$file->close() if (defined($args{filename}));

	# Look for snapshots of attributes that had been created with the
	# AUTOCREATE option and instantiate these, but ONLY if they do not
	# already exist (thus a load-in-place will not clobber them)
	foreach my $aname (keys %{$obj->{snapshots}}) {
	    if (!defined($obj->{attr}{$aname})) {
		my $attr = {};
		my $snapshot = $obj->{snapshots}{$aname};
		foreach my $key (keys %$snapshot) {
		    $attr->{$key} = (
			$key =~ /^(value|real_value)$/ ? (
			    ref($snapshot->{$key}) eq 'ARRAY' ? [ ] :
			    ref($snapshot->{$key}) eq 'HASH'  ? { } :
				$snapshot->{$key}
			) :
			$snapshot->{$key}
		    );
		}
		$obj->{attr}{$aname} = $attr;
	    }
	}

	# (Re)create accessors if user wants it.
	if ($AccessorMethod) {
	    foreach my $aname (keys %{$obj->{attr}}) {
		_CreateAccessorMethod($aname, 'attr')
		  unless ($obj->{attr}{$aname}{flags} & ATTR_NO_ACCESSOR);
	    }
	}
	if ($ActionMethod) {
	    foreach my $aname (grep { /^_ACT_/ } keys %{$obj->{attr}}) {
		$aname =~ /^_ACT_(.+)$/;
		my $action = $1;
		_CreateActionMethod($action);
	    }
	}

	# Make sure the ID is what we expect.
	$obj->{id} = $id;

	# Done. Rebless into this subclass and invoke any action binding
	# on the object:load action.
	bless $obj, $subclass if ($subclass ne 'Games::Object');
	$obj->action(
	    other	=> $args{other},
	    action	=> 'object:on_load',
	    args	=> { file => $file },
	);
	$obj;
}

####
## OBJECT DATA METHODS

# Save an object to a file at the present position. At the moment, everything
# is saved in clear ASCII. This makes the file portable across architectures
# while sacrificing space and security. Later versions of this module will
# include other formats.

sub save
{
	my ($obj) = shift;
	my %args = ();

	# Check for occurrence of single parameter and turn into appropriate
	# named parameter if found.
	unshift @_, "file" if (@_ == 1 && ref($_[0]));
	unshift @_, "filename" if (@_ == 1 && !ref($_[0]));

	# Fetch parameters
	FetchParams(\@_, \%args, [
	    [ 'opt', 'file', undef, 'file' ],
	    [ 'opt', 'filename', undef, 'string' ],
	    [ 'opt', 'other', undef, 'object' ],
	]);

	# Check the file args.
	croak "Cannot define both 'filename' and 'file' args to save()"
	    if (defined($args{file}) && defined($args{filename}));
	if (defined($args{filename})) {
	    $args{file} = IO::File->new();
	    $args{file}->open(">$args{filename}")
		or croak "Unable to open filename '$args{filename}' for write";
	} elsif (!defined($args{file})) {
	    croak "One of 'file' or 'filename' must be specified to save()"
	}
	my $file = $args{file};

	# Save the ID
	print $file "OBJ:$obj->{id}\n";

	# Save the object class.
	print $file "CL:" . ref($obj) . "\n";

	# Now all we need to do is call SaveData() on ourself. However, if
	# we use $obj directly, SaveData will simply call save() all over
	# again and we have ourselves an infinite loop, which is bad. We need to
	# fool it into thinking its a hash. So we assign %$obj to an ordinary
	# hash and pass the ref to it. This forces the reference to lose its
	# magic. Even better, no duplicate of the hash is made. %hash internally
	# contains the same reference, but without the blessing magic on it.
	#
	# Note that we do not want to save DONTSAVE attributes, so we run it
	# through the special wrapper.
	my %hash = %$obj;
	$obj->_protect_attrs(\&SaveData, $file, \%hash);

	# Close the file if we opened it.
	$file->close() if ($args{filename});

	# Invoke any action bindings.
	$obj->action(
	    other	=> $args{other},
	    action	=> 'object:on_save',
	    args	=> { file => $file },
	);

}

# This is an interface to the object's manager's find() method. This is
# essentially shorthand for "do a find() for an ID in the manager of this
# other object". Note that we do not treat the lack of a manager as an error,
# but simply report the same as not finding the object.

sub find
{
	my ($obj, $id) = @_;
	my $man = $obj->manager();

	$man ? $man->find($id) : undef;
}

# Ditto to the manager's order() method

sub order
{
	my $obj = shift;
	my $man = $obj->manager();

	$man ? $man->order($obj) : undef;
}

###
## FLAG METHODS

# Create a flag on an object.

sub new_flag
{
	my $obj = shift;
	my $flag = {};

	# Fetch parameters
	FetchParams(\@_, $flag, [
	    [ 'req', 'name', undef, 'string' ],
	    [ 'opt', 'value', 0, 'boolean' ],
	    [ 'opt', 'flags', 0, 'int' ],
	    [ 'opt', 'on_set', undef, 'callback' ],
	    [ 'opt', 'on_clear', undef, 'callback' ],
	] );

	# Set on object and done.
	my $fname = delete $flag->{name};
	$obj->{flag}{$fname} = $flag;
	1;
}

# Set flag on object.

sub set
{
	my ($obj, $fname, $other) = @_;

	# Check for multiple flags.
	if (ref($fname) eq 'ARRAY') {
	    # Call myself multiple times.
	    foreach (@$fname) { $obj->set($_, $other); }
	    return $obj;
	}

	# Find the flag.
	my ($flag, $inherited) = $obj->_find_flag($fname);
	croak("Attempt to set undefined user flag '$fname' on '$obj->{id}'")
	    unless (defined($flag));

	# If we inherited this flag, then clone it so that we have
	# our own copy. We do this via a clever trick: Using IO::String
	# to create a stringified version of the data.
	if ($inherited) {
	    $obj->{flag}{$fname} = {};
	    my $iostr = IO::String->new();
	    SaveData($iostr, $flag);
	    seek $iostr, 0, 0;
	    LoadData($iostr, $obj->{flag}{$fname});
	    $flag = $obj->{flag}{$fname};
	}

	# Do it.
	if ($flag->{value} != 1) {
	    $flag->{value} = 1;
	    $obj->action(
		other	=> $other,
		action	=> "flag:${fname}:on_set",
		args	=> { name => $fname },
	    );
	}
	$obj;
}

# Clear flag on object.

sub clear
{
	my ($obj, $fname, $other) = @_;

	if (ref($fname) eq 'ARRAY') {
	    # Call myself multiple times.
	    foreach (@$fname) { $obj->clear($_, $other); }
	    return $obj;
	}

	# Find flag.
	my ($flag, $inherited) = $obj->_find_flag($fname);
	croak("Attempt to clear undefined user flag '$fname' on '$obj->{id}'")
	    unless (defined($flag));

	# If we inherited this flag, then clone it so that we have
	# our own copy. We do this via a clever trick: Using IO::String
	# to create a stringified version of the data.
	if ($inherited) {
	    $obj->{flag}{$fname} = {};
	    my $iostr = IO::String->new();
	    SaveData($iostr, $flag);
	    seek $iostr, 0, 0;
	    LoadData($iostr, $obj->{flag}{$fname});
	    $flag = $obj->{flag}{$fname};
	}

	# Do it.
	if ($flag->{value} != 0) {
	    $flag->{value} = 0;
	    $obj->action(
		other	=> $other,
		action	=> "flag:${fname}:on_clear",
		args	=> { name => $fname },
	    );
	}
	$obj;
}

# Check to see if one or more flags are set on an object (all must be set
# to be true).

sub is
{
	my ($obj, @fnames) = @_;
	my $total = 0;

	foreach my $fname (@fnames) {
	    my $flag = $obj->_find_flag($fname);
	    $total++ if (defined($flag) && $flag->{value});
	}
	$total == scalar(@fnames);
}

# Same as above, but returns true so long as at least one flag is present.

sub maybe
{
	my ($obj, @fnames) = @_;
	my $total = 0;

	foreach my $fname (@fnames) {
	    my $flag = $obj->_find_flag($fname);
	    croak("User flag '$fname' on '$obj->{id}' is undefined in maybe()")
	        unless (defined($flag));
	    $total++ if ($flag->{value});
	    last if $total;
	}
	$total;
}

####
## INTERNAL ATTRIBUTE METHODS

# Adjust integer attribute to get rid of fractionals.

sub _adjust_int_attr
{
	my ($obj, $aname) = @_;
	my $attr = $obj->{attr}{$aname};

	my $expr1 = '$attr->{value} = ' .
		    $attr->{on_fractional} .
		    '($attr->{value})';
	my $expr2 = '$attr->{real_value} = ' .
		    $attr->{on_fractional} .
		    '($attr->{real_value})';
	eval($expr1);
	eval($expr2) if (defined($attr->{real_value}));
}

# Set an attribute to a new value, taking into account limitations on the
# attribute's value, plus adjustments for fractionals and so on.

sub _set_attr
{
	my ($obj, $aname, %args) = @_;
	my $attr = $obj->{attr}{$aname};

	foreach my $key (qw(real_value value)) {

	    # Fetch old and new values.
	    next if (!defined($args{$key}));
	    my $old = $attr->{$key};
	    my $new = $args{$key};

	    # If this is a non-numeric data type, then set it, call action
	    # if needed, and done.
	    if ($attr->{type} !~ /^(int|number)$/) {
		croak "Non-numeric attributes cannot have split values"
		    if ($key eq 'real_value');
		if ($attr->{type} eq 'object') {
		    # This must be an object reference, but NOT a
		    # Games::Object-derived object.
		    croak "Value to store in 'object' attribute must be " .
			  "a real object reference, not a simple scalar"
			if (!ref($new));
		    croak "Value to store in 'object' attribute must be " .
			  "a real object reference not a " . ref($new) .
			  "reference"
			if (ref($new) =~ /SCALAR|ARRAY|HASH|CODE|LVALUE|GLOB/);
		    croak "Cannot store a Games::Object-derived object in ".
			  "an 'object' attribute (use object relationships " .
			  "in the manager for that)" if (_IsObject($new));
		}
		$attr->{$key} = $new;
		$obj->action(
		    other	=> $args{other},
		    object	=> $args{object},
		    flags	=> $attr->{flags},
		    action	=> "attr:${aname}:on_change",
		    args	=> {
			name	=> $aname,
			old	=> $old,
			new	=> $new,
		    },
		) if (!$args{no_action} && $old ne $new && $key eq 'value');
		next;
	    }

	    # Find out if the new value is out of bounds. Note that for the
	    # purposes of this code, we consider being right on the bounds
	    # as OOB (perhaps this should be called OOOAB - Out Of Or At Bounds)
	    my $too_small = ( defined($attr->{minimum}) &&
				$new <= $attr->{minimum} );
	    my $too_big   = ( defined($attr->{maximum}) &&
				$new >= $attr->{maximum} );
	    my $oob = ( $too_small || $too_big );
	    my $excess;
	    if ($oob) {

		# Yes. Do we force it?
		if (!$args{force}) {

		    # No, don't force it. But what do we do with the
		    # modification?
		    my $oob_what = $attr->{out_of_bounds};
		    if ($oob_what eq 'ignore') {

			# Ignore this change.
			next;

		    } else {

			# Either use up what we can up to limit, or track the
			# excess. In either case, we need to calculate the
			# amount of excess. Note that 'track' is kind of like
			# an implied force option.
			if ($too_small) {
			    $excess = $attr->{minimum} - $new;
			    $new = $attr->{minimum} if ($oob_what eq 'use_up');
			} else {
			    $excess = $new - $attr->{maximum};
			    $new = $attr->{maximum} if ($oob_what eq 'use_up');
			}

		    }

		}  # if !$args{force}

	    }  # if $oob;

	    # Set the new value.
	    $attr->{$key} = $new;

	    # Adjust it if fractional and we're not handling those.
	    $obj->_adjust_int_attr($aname)
		if ($attr->{type} eq 'int' && !$attr->{track_fractional});
	    $new = $attr->{$key};

	    # Invoke modified action, but ONLY if it was modified.
	    $obj->action(
		other	=> $args{other},
		object	=> $args{object},
		flags	=> $attr->{flags},
		action	=> "attr:${aname}:on_change",
		args	=> {
		    name	=> $aname,
		    old		=> $old,
		    new		=> $new,
		    change	=> ( $new - $old ),
		},
	    ) if (!$args{no_action} && $old != $new && $key eq 'value');

	    # Invoke OOB actions
	    $obj->action(
		other	=> $args{other},
		object	=> $args{object},
		flags	=> $attr->{flags},
		action	=> "attr:${aname}:on_minimum",
		args	=> {
		    name	=> $aname,
		    old		=> $old,
		    new		=> $new,
		    excess	=> $excess,
		    change	=> ( $new - $old ),
		},
	    ) if (!$args{no_action} && $too_small && $old != $new
		&& $key eq 'value');
	    $obj->action(
		other	=> $args{other},
		object	=> $args{object},
		flags	=> $attr->{flags},
		action	=> "attr:${aname}:on_maximum",
		args	=> {
		    name	=> $aname,
		    old		=> $old,
		    new		=> $new,
		    excess	=> $excess,
		    change	=> ( $new - $old ),
		},
	    ) if (!$args{no_action} && $too_big && $old != $new
		&& $key eq 'value');

	}  # foreach $key

	# Done.
	1;
}

# Run code with a wrapper designed to protect the DONTSAVE attributes.

sub _protect_attrs
{
	my ($obj, $code, @args) = @_;

	# Save off the DONTSAVE attributes and delete from object.
	my %temp = ();
	foreach my $aname (keys %{$obj->{attr}}) {
	    my $attr = $obj->{attr}{$aname};
	    if ($attr->{flags} & ATTR_DONTSAVE) {
		$temp{$aname} = $attr;
		delete $obj->{attr}{$aname};
	    }
	}

	# Run the indicated code.
	&$code(@args);

	# Put back the attributes that we temporarily nixed.
	foreach my $aname (keys %temp) {
	    $obj->{attr}{$aname} = $temp{$aname};
	}
}

# Find an attribute. This performs inheritance logic to find a viable attribute
# no matter where it resides.
#
# In a scalar context, it simply returns the hash ref of the attribute. In
# an array context, it returns a list consisting of the hash ref and a flag
# indicating whether this was inherited or not.
#
# Note that inheritance requires that the object manager be set up with
# the inherit relationship or it only looks on the current object.

sub _find_attr
{
	my ($obj, $aname) = @_;
	my $attr;
	my $inherited = 0;

	# Fetch the manager of this object, unless we're accessing the manager
	# attribute itself, in which case we act as if there is no manager.
	# This is to prevent infinite loops with manager(). Anyway, this
	# attribute is not allowed to be inherited, so it works out.
	my $man = ( $aname eq ANAME_MANAGER ? undef : $obj->manager() );

	# Check for no inheritance relation
	if (!$man || !$man->has_relation('inherit')) {

	    if (defined($obj->{attr}{$aname})) {
		wantarray ? ( $obj->{attr}{$aname}, 0 ) : $obj->{attr}{$aname};
	    } else {
		wantarray ? ( undef, 0 ) : undef;
	    }

	} else {

	    # Do it
	    my $aobj = $obj;
	    while (!$attr && $aobj) {
	        if (defined($aobj->{attr}{$aname})) {
		    # Found attribute.
		    $attr = $aobj->{attr}{$aname};
		    $inherited = ( $aobj->{id} ne $obj->{id} );
		    if ($inherited && $attr->{flags} & ATTR_NO_INHERIT) {
		        # But it was found on a inherit, and we're not allowed
		        # to inherit this attribute, so this is as good as not
		        # being defined at all. Note that we leave $inherited
		        # set, so the caller can tell if we failed to find it
		        # because it did not exist or could not be inherited, in
		        # case that makes a difference to the caller.
		        undef $attr;
		        last;
		    }
	        } elsif ($man->inheriting_from($aobj)) {
		    # We have an inheritance, so check it.
		    $aobj = $man->inheriting_from($aobj);
	        } else {
		    # No more inheritance up the line, so we stop.
		    undef $aobj;
	        }
	    }

	    # Return the result
	    wantarray ? ( $attr, $inherited ) : $attr;
	}
}

# Do the exact same thing for object flags. See _find_attr() for explanation
# of the logic.

sub _find_flag
{
	my ($obj, $fname) = @_;
	my $flag;
	my $inherited = 0;

	# Fetch the manager of this object.
	my $man = $obj->manager();

	# Check for no inheritance relation
	if (!$man || !$man->has_relation('inherit')) {

	    if (defined($obj->{flag}{$fname})) {
		wantarray ? ( $obj->{flag}{$fname}, 0 ) : $obj->{flag}{$fname};
	    } else {
		wantarray ? ( undef, 0 ) : undef;
	    }

	} else {

	    # Do it
	    my $fobj = $obj;
	    while (!$flag && $fobj) {
	        if (defined($fobj->{flag}{$fname})) {
		    # Found flag.
		    $flag = $fobj->{flag}{$fname};
		    $inherited = ( $fobj->{id} ne $obj->{id} );
		    if ($inherited && $flag->{flags} & FLAG_NO_INHERIT) {
		        # But it was found on a inherit, and we're not allowed
		        # to inherit this attribute, so this is as good as not
		        # being defined at all. Note that we leave $inherited
		        # set, so the caller can tell if we failed to find it
		        # because it did not exist or could not be inherited, in
		        # case that makes a difference to the caller.
		        undef $flag;
		        last;
		    }
	        } elsif ($man->inheriting_from($fobj)) {
		    # We have an inheritance, so check it.
		    $fobj = $man->inheriting_from($fobj);
	        } else {
		    # No more inheritance up the line, so we stop.
		    undef $fobj;
	        }
	    }

	    # Return the result
	    wantarray ? ( $flag, $inherited ) : $flag;
	}

}

####
## ATTRIBUTE METHODS

# Create a new attribute on an object.
#
# Attribute flags:
#    ATTR_STATIC	- Attribute is not to be altered. Attempts to do so
#			  are treated as an error.
#    ATTR_DONTSAVE	- Don't save attribute on a call to save(). Also,
#			  the existing value is preserved on a load().
#    ATTR_NO_INHERIT	- Do not allow this attribute to be inherited.

sub new_attr
{
	my $obj = shift;
	my $attr = {};

	# Fetch params universal to all attribute types.
	FetchParams(\@_, $attr, [
	    [ 'req', 'name' ],
	    [ 'opt', 'type', 'any', [ qw(any int number string object) ] ],
	    [ 'opt', 'priority', 0, 'int' ],
	    [ 'opt', 'flags', 0, 'int' ],
	    [ 'opt', 'on_change', undef, 'callback' ],
	], 1 );

	# Fetch additional args for integer types. Note that we allow the
	# initial value to be fractional. We'll clean this up shortly.
	FetchParams(\@_, $attr, [
	    [ 'req', 'value', undef, 'number' ],
	    [ 'opt', 'real_value', undef, 'number' ],
	    [ 'opt', 'on_fractional', 'int', [ qw(int ceil floor round) ] ],
	    [ 'opt', 'track_fractional', '0', 'boolean' ],
	    [ 'opt', 'tend_to_rate', undef, 'number' ],
	    [ 'opt', 'minimum', undef, 'int' ],
	    [ 'opt', 'maximum', undef, 'int' ],
	    [ 'opt', 'on_minimum', undef, 'callback' ],
	    [ 'opt', 'on_maximum', undef, 'callback' ],
	    [ 'opt', 'out_of_bounds', 'use_up', [ qw(use_up ignore track) ] ],
	], 1 ) if ($attr->{type} eq 'int');

	# Fetch additional args for number types.
	FetchParams(\@_, $attr, [
	    [ 'req', 'value', undef, 'number' ],
	    [ 'opt', 'real_value', undef, 'number' ],
	    [ 'opt', 'tend_to_rate', undef, 'number' ],
	    [ 'opt', 'minimum', undef, 'number' ],
	    [ 'opt', 'maximum', undef, 'number' ],
	    [ 'opt', 'on_minimum', undef, 'callback' ],
	    [ 'opt', 'on_maximum', undef, 'callback' ],
	    [ 'opt', 'out_of_bounds', 'use_up', [ qw(use_up ignore track) ] ],
	    [ 'opt', 'precision', 2, 'int' ],
	], 1 ) if ($attr->{type} eq 'number');

	# Fetch additional args for string types.
	FetchParams(\@_, $attr, [
	    [ 'opt', 'values', undef, 'arrayref' ],
	    [ 'opt', 'value', undef, 'string' ],
	    [ 'opt', 'map', {}, 'hashref' ],
	], 1 ) if ($attr->{type} eq 'string');

	# Fetch additional args for object types. Object refs are stored as-is,
	# and it is assumed they will have their own custom load/save methods.
	# Storing Games::Object-derived objects is prohibited; use the
	# manager's object relationship features for that.
	if ($attr->{type} eq 'object') {
	    FetchParams(\@_, $attr, [
	        [ 'opt', 'value', undef, 'object' ],
	    ], 1 );
	    croak "Cannot use type 'object' for Games::Object-derived " .
		  "objects (use object relationships in the manager for that)"
		if (defined($attr->{value}) && _IsObject($attr->{value}));
	}

	# Fetch additional args for 'any' type.
	FetchParams(\@_, $attr, [
	    [ 'opt', 'value', undef, 'any' ],
	], 1 ) if ($attr->{type} eq 'any');

	# If there are any remaining arguments, sound a warning. Most likely
	# the caller forgot to put a 'type' parameter in.
	if (@_) {
	    my %args = @_;
	    my $extra = "'" . join("', '", keys %args) . "'";
	    carp("Warning: extra args $extra to new_attr($attr->{name}) " .
		  "of '$obj->{id}' ignored (did you forget a 'type' " .
		  "parameter?)");
	}

	# Store.
	my $aname = delete $attr->{name};
	$obj->{attr}{$aname} = $attr;
	_CreateAccessorMethod($aname, 'attr')
	    if ($AccessorMethod && !($attr->{flags} & ATTR_NO_ACCESSOR));

	# If a real_value was defined but no tend-to, drop the real_value.
	delete $attr->{real_value} if (!defined($attr->{tend_to_rate}));

	# And if there is a tend_to_rate but no real_value, set the latter
	# to the current value.
	$attr->{real_value} = $attr->{value}
	  if (defined($attr->{tend_to_rate}) && !defined($attr->{real_value}));

	# Adjust attribute values to get rid of fractionals if not tracking it.
	$obj->_adjust_int_attr($aname)
	    if ($attr->{type} eq 'int' && !$attr->{track_fractional});

	# Finally, if DONTSAVE and AUTOCREATE were used together, then
	# take a kind of "snapshot" of this attribute so it can be later
	# restored.
	if ( ($attr->{flags} & ATTR_DONTSAVE)
	  && ($attr->{flags} & ATTR_AUTOCREATE) ) {
	    my $type = $attr->{type};
	    my $snapshot = {};
	    foreach my $key (keys %$attr) {
		$snapshot->{$key} = (
		    $key =~ /^(value|real_value)$/	? (
		        $type =~ /^(int|number)$/	? (
			    defined($attr->{minimum})	?
				$attr->{minimum} : 0
			) :
		        $type eq 'string'		? '' :
		        $type eq 'any' &&
		          ref($attr->{$key}) eq 'ARRAY'	? [ ] :
		        $type eq 'any' &&
		          ref($attr->{$key}) eq 'HASH'	? { } :
		        undef
		    ) :
		    $attr->{$key}
	        );
	    }
	    $obj->{snapshots}{$aname} = $snapshot;
	}

	# Done.
	$obj;
}

# Delete an attribute. Note that this will delete only on the current object
# and not inherited attributes.

sub del_attr
{
	my $obj = shift;
	my ($aname) = @_;

	# Do nothing if the attribute does not exist.
	return 0 if (!defined($obj->{attr}{$aname}));

	# Delete the attribute.
	delete $obj->{attr}{$aname};

	# Done.
	1;
}

# Check to see if an attribute exists.

sub attr_exists
{
	my ($obj, $aname) = @_;
	my $attr = $obj->_find_attr($aname);

	defined($attr);
}

# Check specifically that the attribute exists on this object and don't
# consider inheritance.

sub attr_exists_here
{
	my ($obj, $aname) = @_;

	defined($obj->{attr}{$aname});
}

# Fetch value or properties of an attribute

sub attr
{
	my ($obj, $aname, $prop) = @_;
	$prop = 'value' if (!defined($prop));

	# If the attribute does not exist, simply return undef.
	my $attr = $obj->_find_attr($aname);
	return undef if (!defined($attr));

	# Check to see if the property exists.
	croak("Attribute '$aname' does not have property called '$prop'")
	  if (!defined($attr->{$prop}));

	# The value and real_value are special cases.
	if ($prop =~ /^(value|real_value)$/) {
	    my $result;
	    if ($attr->{type} eq 'int' && $attr->{track_fractional}) {
		# The value that the caller really sees is the integer.
		my $expr = '$result = ' . $attr->{on_fractional} .
			   '($attr->{$prop})';
		eval($expr);
	    } elsif ($attr->{type} eq 'string'
		 &&  defined($attr->{map})
		 &&  defined($attr->{map}{$attr->{$prop}}) ) {
		# Return the mapped value
		$result = $attr->{map}{$attr->{$prop}};
	    } else {
		# Return whatever is there.
		$result = $attr->{$prop};
	    }
	    # If this value is OOB, this must mean a force was done on a 
	    # mod_attr or the mode was set to 'track', so make sure we return
	    # only a value within the bounds.
	    $result = $attr->{minimum}
		if (defined($attr->{minimum}) && $result < $attr->{minimum});
	    $result = $attr->{maximum}
		if (defined($attr->{maximum}) && $result > $attr->{maximum});
	    $result;
	} else {
	    # No interpretation of the value needed.
	    $attr->{$prop};
	}
}

# Fetch the "raw" attribute property value. This bypasses the code that checks
# for fractional interpretations and mapping.

sub raw_attr
{
	my ($obj, $aname, $prop) = @_;
	$prop = 'value' if (!defined($prop));

	# Check to see if attribute exists.
	my $attr = $obj->_find_attr($aname);
	return undef if (!defined($attr));

	# Check to see if the property exists.
	croak("Attribute '$aname' does not have property called '$prop'")
	  if (!defined($attr->{$prop}));

	# Return the value of the property.
	$attr->{$prop};
}

# Fetch the reference to an attribute.

sub attr_ref
{
	my ($obj, $aname, $prop) = @_;

	$prop = 'value' if (!defined($prop));
	my $attr = $obj->_find_attr($aname);
	if (defined($attr)) {
	    defined($attr->{$prop}) ? \$attr->{$prop} : undef;
	} else {
	    carp "WARNING: Attempt to get reference to '$prop' of " .
		 "non-existent attribute '$aname'";
	    undef;
	}
}

# Modify an attribute

sub mod_attr
{
	my $obj = shift;
	my %args = @_;

	# Check for a cancel operation.
	FetchParams(\@_, \%args, [
	    [ 'opt', 'cancel_modify', undef, 'string' ],
	    [ 'opt', 'cancel_modify_re', undef, 'string' ],
	    [ 'opt', 'immediate', 0, 'boolean' ],
	]);
	if (defined($args{cancel_modify})) {
	    # Normal cancel
	    my $id = $args{cancel_modify};
	    if (defined($obj->{pmod}{$id})) {

		# First check to see if the mod was incremental. If not,
		# then we need to reverse the change that it had effected.
		my $mod = $obj->{pmod}{$id};
		my $aname = $mod->{aname};
		if (!$mod->{incremental}) {
		    # Call myself to do the change. NOTE: We specify "other"
		    # as myself. Why? Because whatever was causing the original
		    # modification (i.e. the original "other") is no longer
		    # apropos, since the change it initiated is no longer
		    # present. One can think of the object itself now putting
		    # back the original value.
		    my %opts = ( -name => $aname, -other => $obj );
		    $opts{modify} = -$mod->{modify}
			if (defined($mod->{modify}));
		    $opts{modify_real} = -$mod->{modify_real}
			if (defined($mod->{modify_real}));
		    # By default, we queue this up and do it at next process(),
		    # to be consistent with the way modifiers are applied.
		    # Specifying an immediate of true forces us to do it now.
		    if ($args{immediate}) {
		        $obj->mod_attr(%opts);
		    } else {
		        $obj->queue('mod_attr', %opts);
		    }
		}
		delete $obj->{pmod}{$id};
		$obj->{pmod_active}--;
		$obj->{pmod_next} = 0 if ($obj->{pmod_active} == 0);
	        return 1;
	    } else {
		return 0;
	    }
	}
	if (defined($args{cancel_modify_re})) {
	    # Cancel all that match the regular expression. We do this by
	    # building a list of matching modifiers and call ourself for each.
	    my $re = $args{cancel_modify_re};
	    my @ids = grep { /$re/ } keys %{$obj->{pmod}};
	    delete $args{cancel_modify_re};
	    foreach my $id (@ids) {
		$args{cancel_modify} = $id;
		$obj->mod_attr(%args);
	    }
	    return scalar(@ids);
	}

	# The first thing we need to is actually find the attribute. If the
	# attribute cannot be found on this object, we check to see if it
	# has an inheritance, and keep checking up the inheritance tree until
	# we find it.
	FetchParams(\@_, \%args, [
	    [ 'req', 'name' ],
	], 1 );
	my $aname = $args{name};
	my ($attr, $inherited) = $obj->_find_attr($aname);
	croak("Attempt to modify unknown attribute '$aname' " .
		"on object $obj->{id}") if (!defined($attr) && !$inherited);
	croak("Attempt to modify attribute '$aname' that could not be " .
	      "inherited") if (!defined($attr) && $inherited);

	# Check for attempt to modify static attribute.
	croak("Attempt to modify static attr '$aname' on '$obj->{id}' " .
	      ( $inherited ? "(inherited)" : "(not inherited)" ) )
	    if ($attr->{flags} & ATTR_STATIC);

	# If we inherited this attribute, then clone it so that we have
	# our own copy. We do this via a clever trick: Using IO::String
	# to create a stringified version of the data.
	if ($inherited) {
	    $obj->{attr}{$aname} = {};
	    my $iostr = IO::String->new();
	    SaveData($iostr, $attr);
	    seek $iostr, 0, 0;
	    LoadData($iostr, $obj->{attr}{$aname});
	    $attr = $obj->{attr}{$aname};
	}

	# Fetch basic modifier parameters.
	%args = ();
	my $vtype = ( defined($attr->{values}) ?
			$attr->{values} :
		      $attr->{type} eq 'int' && $attr->{track_fractional} ?
			'number' :
		      $attr->{type} eq 'object' ?
			'any' :
		      $attr->{type}
		    );
	FetchParams(\@_, \%args, [
	    [ 'opt', 'minimum',     undef,	$vtype ],
	    [ 'opt', 'maximum',     undef,	$vtype ],
	    [ 'opt', 'out_of_bounds', undef,	[ qw(ignore use_up track) ] ],
	    [ 'opt', 'tend_to_rate',  undef,	$vtype ],
	    [ 'opt', 'priority',    undef,	'int' ],
	    [ 'opt', 'flags',	    undef,	'int' ],
	    [ 'opt', 'value',       undef,      $vtype ],
	    [ 'opt', 'real_value',  undef,      $vtype ],
	    [ 'opt', 'modify',      undef,      $vtype ],
	    [ 'opt', 'modify_real', undef,      $vtype ],
	    [ 'opt', 'object',      undef,      'object' ],
	    [ 'opt', 'other',       undef,      'object' ],
	] );

	# Check for property modifiers first.
	my $pcount = 0;
	foreach my $prop (qw(minimum maximum on_fractional out_of_bounds
			     tend_to_rate priority flags)) {
	    next if (!defined($args{$prop}));
	    croak("Property '$prop' allowed only on numeric attribute")
		if ($vtype !~ /^(int|number)$/);
	    $attr->{$prop} = delete $args{$prop};
	    $pcount++;
	}

	# If at least one property set, we're allowed not to have any
	# modification parameters.
	my $acount = scalar(keys(%args));
	return 1 if ($pcount > 0 && $acount == 0);

	# Check for mod parameters
	croak("No modification parameter present") if ($acount == 0);
	croak("Cannot combine attribute absolute set and modification " .
		"in single mod_attr() call")
	  if ( (defined($args{value}) || defined($args{real_value}))
	  &&   (defined($args{modify}) || defined($args{modify_real})) );
	croak("Cannot set/modify real value when value not split")
	  if ( (defined($args{real_value}) || defined($args{modify_real}))
	  &&   !defined($attr->{real_value}) );

	# Check for a simple set operation.
	if (defined($args{value}) || defined($args{real_value})) {

	    # Yes, value is being set. Fetch all optional parameters.
	    FetchParams(\@_, \%args, [
	        [ 'opt', 'force',       0,          'boolean' ],
	        [ 'opt', 'defer',       0,          'boolean' ],
	        [ 'opt', 'no_tend_to',  0,          'boolean' ],
	    ] );

	    # Deferred? If so, queue it and we're done.
	    if ($args{defer}) {
		delete $args{defer};
		$args{name} = $aname;
		$obj->queue('mod_attr', %args);
		return 1;
	    }

	    # If dropped down to here, then this is to be done right now.
	    $obj->_set_attr($aname, %args);

	} else {

	    # No, this is a modification relative to the current value of
	    # the attribute. This is allowed only for numeric types.
	    croak("Attempt a relative modify on non-numeric attribute " .
		    "'$aname' of '$obj->{id}'")
		if ($attr->{type} !~ /^(int|number)$/);

	    # Fetch all possible parameters.
	    FetchParams(\@_, \%args, [
	        [ 'opt', 'persist_as',  undef,	'string' ],
	        [ 'opt', 'priority',    0,	'int' ],
	        [ 'opt', 'time',        undef,  'int' ],
	        [ 'opt', 'delay',       0,	'int' ],
	        [ 'opt', 'force',       0,      'boolean' ],
	        [ 'opt', 'incremental', 0,      'boolean' ],
		[ 'opt', 'apply_now',	0,	'boolean' ],
	    ] );

	    # Is to be persistent?
	    my ($id, $was_pmod, $mod);
	    if ($args{persist_as}) {

		# Yes, so don't do the change right now. Simply add it as
		# a new persistent modifier (pmod). If one already exists,
		# then replace it silently. The index value is used in sorting,
		# so that when pmods of equal priority are placed in the object,
		# they are guaranteed to run in the order they were created.
		#
		# Note that we store the "other" and "object" parameters as the
		# object ID rather than the actual object ref itself.
		$id = $args{persist_as};
		$was_pmod = defined($obj->{pmod}{$id});
		$mod = {
		    aname	=> $aname,
		    index	=> ( $was_pmod ?
					$obj->{pmod}{$id}{index} :
					$obj->{pmod_next}++ ),
		    priority	=> $args{priority},
		    time	=> $args{time},
		    delay	=> $args{delay},
		    force	=> $args{force},
		    modify	=> $args{modify},
		    modify_real	=> $args{modify_real},
		    incremental	=> $args{incremental},
		    applied	=> 0,
		    locked	=> 0,
		};
		$mod->{other} = $args{other}->id() if ($args{other});
		$mod->{object} = $args{object}->id() if ($args{object});
		$obj->{pmod}{$id} = $mod;
		$obj->{pmod_active}++ unless ($was_pmod);

	    }

	    if (!$args{persist_as} || $args{apply_now}) {

		# Either this is NOT a persistent mod, or it IS, but the
		# user wants to force the change to be applied right now.
		$args{value} = $attr->{value} + $args{modify}
		  if (defined($args{modify}));
		$args{real_value} = $attr->{real_value} + $args{modify_real}
		  if (defined($args{modify_real}));
		$obj->_set_attr($aname, %args);

		# And if it is a persistent mod, make sure it does not
		# get applied twice.
		$mod->{applied} = 1 if (defined($args{persist_as}));

	    }

	}  # if defined($args{value}) || defined($args{real_value})

	1;
}

####
## QUEUING AND CALLBACK CONTROL

# Invoke a callback or an array of callbacks on object.

sub invoke_callbacks
{
	my $self = shift;
	my %args = ();

	# Fetch parameters. Note that all parameters are optional. This is OK,
	# but watch how you define your callbacks. If you have a callback that
	# has "O:other" as the target but no 'other' parameter was passed, this
	# will bomb.
	FetchParams(\@_, \%args, [
	    [ 'opt', 'other', undef, 'object' ],
	    [ 'opt', 'object', undef, 'object' ],
	    [ 'opt', 'action', undef, 'string' ],
	    [ 'opt', 'callback', undef, 'callback' ],
	    [ 'opt', 'args', {}, 'hashref' ],
	    [ 'opt', 'flags', 0, 'int' ],
	] );
	my $other = $args{other};
	my $object = $args{object};
	my $action = $args{action};
	my $callback = $args{callback};
	my $aargs = $args{args};
	my $flags = $args{flags};

	# If the callback is undefined, this counts as success.
	return 1 if (!$callback);

	# If this is a list of callbacks rather than a callback itself, then
	# invoke myself with each individual callback. Stop at any time we
	# receive a return of false from a callback.
	my @cargs = @$callback;
	if (ref($cargs[0]) eq 'ARRAY') {
	    my $rc = 0;
	    my $nocheck = 0;
	    while (my $callback = shift(@cargs)) {
		# Check for special flags and commands.
		if (!ref($callback)) {
		    if ($callback eq 'FAIL') {
			# Next item is a failure callback, so skip it, since
			# we already know the previous one succeeded.
		    	shift @cargs;
		    } elsif ($callback eq 'NOCHECK') {
			# Stop checking return codes and execute everything
			# regardless (i.e. assume true return for each)
			$nocheck = 1;
		    } elsif ($callback eq 'CHECK') {
			# Turn return code checking back on.
			$nocheck = 0;
		    }
		    next;
		}
		# Invoke.
		$rc = $self->invoke_callbacks(
		    other	=> $other,
		    object	=> $object,
		    flags	=> $flags,
		    action	=> $action,
		    callback	=> $callback,
		    args	=> $aargs,
		);
		# Force success if NOCHECK is on.
		$rc = 1 if ($nocheck);
		# If the callback failed, we will stop. But before that, see
		# if the next item is a failure callback and execute it if
		# so. We do NOT return the return value of these callbacks.
		# We return the boolean false from the original non-failure
		# callbacks to indicate that a failure indeed occurred.
		if (!$rc) {
		    if (@cargs && !ref($cargs[0]) && $cargs[0] eq 'FAIL') {
			shift @cargs;
			$callback = shift @cargs;
			$self->invoke_callbacks(
			    other	=> $other,
			    object	=> $object,
			    flags	=> $flags,
			    action	=> $action,
			    callback	=> $callback,
			    args	=> $aargs,
			);
		    }
		    last;
		}
	    }
	    $rc;
	} else {
	    my $oname = shift @cargs;
	    my $obj = (
	        $oname eq 'O:self'	? $self :
	        $oname eq 'O:other'	? $other :
	        $oname eq 'O:object'	? $object :
		$oname eq 'O:manager'	? $self->manager() :
		$oname =~ /^O:(.+)$/	? $self->find($1) :
					  $oname
	    );
	    # If the object was not found, look at the flags. If the MISSING_OK
	    # flag is there, skip callback and return success, otherwise
	    # return 0 to abort this list of callbacks.
	    if (!$obj) {
		return 1 if ($flags & ACT_MISSING_OK);
	        croak("Object '$oname' not found in '$action' trigger " .
		      "on $self->{id}");
	    }
	    # Now scan the arguments list and perform substitutions. Any
	    # arg that starts with "A:" represents an arg to be retrieved
	    # from either the $aargs list, or from the callback args (such
	    # as self, other, etc).
	    foreach my $arg (@cargs) {
		# For performance reasons, check to see if any substitution is
		# even needed.
		next if ($arg !~ /[AO]:/);
		# Now check for complete substitutions
		my $narg;
		$narg = (
		    $arg =~ /^A:([a-zA-Z0-9_]+)$/ &&
		    defined($aargs->{$1})	? $aargs->{$1} :
		    $arg eq 'A:action'		? $action :
		    $arg eq 'O:self'		? $self :
		    $arg eq 'O:other'		? $other :
		    $arg eq 'O:object'		? $object :
		    $arg eq 'O:manager'		? $self->manager() :
		    $arg =~ /^O:([a-zA-Z0-9_]+$)/
						? $self->find($1)
						: undef );
		# If we found something, then set it and done.
		if (defined($narg)) {
		    $arg = $narg;
		    next;
		}
		# Otherwise, we do a full substitution and eval() on it.
		while ( $arg =~ /([OA]:[a-zA-Z0-9_]+)/ ) {
		    my $subarg = $1;
		    my $subval = (
		        $subarg =~ /^A:([a-zA-Z0-9_]+)$/ &&
		        defined($aargs->{$1})	        ? "'$aargs->{$1}'" :
		        $subarg eq 'A:action'		? "'$action'" :
		        $subarg eq 'O:self'		? '$self' :
		        $subarg eq 'O:other'		? '$other' :
		        $subarg eq 'O:object'		? '$object' :
		        $subarg eq 'O:manager'		? '$self->manager()' :
		        $subarg =~ /^O:([a-zA-Z0-9_]+$)/
						        ? '$self->find($1)'
						        : 'undef' );
		    $arg =~ s/$subarg/$subval/g;
		}
		my $val = eval($arg);
		croak "Failed on eval of arg expression << $arg >>: $@" if ($@);
		$arg = $val;
	    }
	    # Invoke.
	    if (!ref($obj)) {
		# The user specified a name of a subroutine instead.
		no strict 'refs';
		&$obj(@cargs);
	    } else {
		# Object reference, so the next item is a method name. Note
		# that this means you can do fancy things like specify the
		# method name as an "A:*" specifier and thus have the method
		# called defined in the args.
	        my $meth = shift @cargs;
	        $obj->$meth(@cargs);
	    }
	}
}

# Queue an action to be run when the object is processed. This must take the
# form of a method name that can be invoked with the object reference. This is
# so this data can be properly saved to an external file (CODE refs don't save
# properly). In fact, none of the args to the action can be references. The
# exception is that you can specify a reference to a Games::Object object
# or one subclassed from it. This is translated to a form that can be written
# to the file and read back again (via the unique object ID).
#
# FIXME: Currently this is a black hole. Actions that go in do not come out
# (i.e. they cannot be deleted or told not to run) unless the object is
# deleted.

sub queue
{
	my ($obj, $method, @args) = @_;

	# The method must be valid.
	croak("Attempt to queue action for '$obj->{id}' with non-existent " .
		"method name '$method'") if (!$obj->can($method));

	# Examine the args. If any args are object refs derived from
	# Games::Object, replace with their IDs instead, in case the object
	# gets save()d before the queue is executed.
	foreach my $aindex (0 .. $#args) {
	    if (_IsObject($args[$aindex])) {
		my $qindex = @{$obj->{queue}};
		$args[$aindex] = $args[$aindex]->id();
		$obj->{queue_changed}{$qindex}{$aindex} = "GO::id";
	    }
	}

	# Okay to be queued.
	push @{$obj->{queue}}, [ $method, @args ];
	1;
}

# Process an action.

sub action
{
	my $self = shift;
	my %args = ();

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'opt', 'other', undef, 'object' ],
	    [ 'opt', 'object', undef, 'object' ],
	    [ 'req', 'action', undef, 'string' ],
	    [ 'opt', 'args', {}, 'hashref' ],
	    [ 'opt', 'flags', 0, 'int' ],
	] );
	my $other = $args{other};
	my $object = $args{object};
	my $action = $args{action};
	my $aargs = $args{args};
	my $flags = $args{flags};

	# Find the callback
	my $callback;
	if ($action =~ /^attr:(.+):(.+)$/) {

	    # Attribute-based action.
	    my $aname = $1;
	    my $oname = $2;
	    my $attr = $self->_find_attr($aname);
	    $callback = $attr->{$oname}
		if (defined($attr) && exists($attr->{$oname}));
	    $flags |= $attr->{flags} if ($callback);

	} elsif ($action =~ /^flag:(.+):(.+)$/) {

	    # Attribute-based action.
	    my $fname = $1;
	    my $oname = $2;
	    my $flag = $self->_find_flag($fname);
	    $callback = $flag->{$oname}
		if (defined($flag) && exists($flag->{$oname}));
	    $flags |= $flag->{flags} if ($callback);

	} elsif ($action =~ /^object:(.+)$/) {

	    # Object-based action.
	    my $oname = $1;
	    $callback = $self->attr("_ACT_${oname}");

	} else {

	    croak("Undefined action syntax '$action'");

	}

	# Do nothing (successfully) if no callback was found.
	return 1 if (!$callback);

	# Otherwise invoke the callback and return its value.
	$self->invoke_callbacks(
	    other	=> $other,
	    object	=> $object,
	    action	=> $action,
	    callback	=> $callback,
	    args	=> $aargs,
	    flags	=> $flags,
	);
}

####
## OBJECT PROCESSING METHODS

# Process an object. This is used to do such actions as executing pending
# actions on the queue, updating attributes, and so on. The real work is
# farmed out to other methods, and the @process_list array tells us which
# to call, or the user can pass in a different list.
#
# Note that we do not allow methods to be called recursively.

sub process
{
	my ($obj, $plist) = @_;

	$plist = \@process_list if (!$plist);
	foreach my $method (@process_list) {
	    $obj->_lock_method($method);
	    $obj->$method();
	    $obj->_unlock_method($method);
	}
	1;
}

# Process all items on the object's queue until the queue is empty. To
# praction potential endless loops (routine A runs, places B on the queue,
# routine B runs, places A on the queue, etc), we track how many times we
# saw a given method, and if it reaches a critical threshhold, we issue a
# warning and do not execute that routine any more this time through. This
# is controlled by the $process_limit variable.

sub process_queue
{
	my $obj = shift;
	my $queue = $obj->{queue};
	my %mcount = ();

	my $qindex = 0;
	while (@$queue) {
	    my $callbk = shift @$queue;
	    my ($meth, @args) = @$callbk;
	    if (defined($obj->{queue_changed})
	     && defined($obj->{queue_changed}{$qindex}) ) {
		# Some args were changed, so set them back.
		my $changed = delete $obj->{queue_changed}{$qindex};
		foreach my $aindex (keys %$changed) {
		    my $change = $changed->{$aindex};
		    if ($change eq 'GO::id') {
			$args[$aindex] = $obj->find($args[$aindex]);
		    } else {
			croak "Unknown queue arg change type '$change'";
		    }
		}
	    }
	    $mcount{$meth} = 0 if (!defined($mcount{$meth}));
	    if ($mcount{$meth} > $process_limit) {
		# Already gave a warning on this, so ignore it silently.
		next;
	    } elsif ($mcount{$meth} == $process_limit) {
		# Just reached it last time through, so issue warning.
		carp("Number of calls to '$meth' has reached processing " .
		      "limit of $process_limit for '$obj->{id}', will no " .
		      "longer invoke this method this time through queue " .
		      "(you may have an endless logic loop somewhere)");
		next;
	    }
	    $mcount{$meth}++;
	    $obj->$meth(@args);
	}

	1;
}

# Process all tend_to rates in attributes that have them.

sub process_tend_to
{
	my $obj = shift;
	my @anames = sort { $obj->{attr}{$b}{priority} <=>
			    $obj->{attr}{$a}{priority} } keys %{$obj->{attr}};

	foreach my $aname (@anames) {

	    # Skip if not applicable
	    my $attr = $obj->{attr}{$aname};
	    next if (!defined($attr->{tend_to_rate}));

	    # Get the new value.
	    my $inc = $attr->{tend_to_rate};
	    my $new = $attr->{value};
	    my $target = $attr->{real_value};
	    if ($new < $target) {
		$new += $inc;
		$new = $target if ($new > $target);
	    } elsif ($new > $target) {
		$new -= $inc;
		$new = $target if ($new < $target);
	    } else {
		# Nothing to do.
		next;
	    }

	    # Set to the new value. Note that we specify the "other" object
	    # as ourselves, since the source of the change is ourself.
	    $obj->_set_attr($aname,
		value => $new,
		force => 1,
		other => $obj);

	}

	1;
}

# Process persistent modifications.

sub process_pmod
{
	my $obj = shift;
	my @ids = sort {
	    my $amod = $obj->{pmod}{$a};
	    my $bmod = $obj->{pmod}{$b};
	    if ($amod->{priority} == $bmod->{priority}) {
		$amod->{index} <=> $bmod->{index};
	    } else {
		$bmod->{priority} <=> $amod->{priority};
	    }
	} keys %{$obj->{pmod}};

	foreach my $id (@ids) {

	    my $mod = $obj->{pmod}{$id};
	    my $aname = $mod->{aname};
	    my $attr = $obj->{attr}{$aname};
	    if ($mod->{locked}) {

		# Locked. Simply unlock so it can run next time.
		$mod->{locked} = 0;

	    } elsif ($mod->{delay} > 0) {

		# Delay factor. Decrement and done.
		$mod->{delay}--;

	    } elsif (defined($mod->{time}) && $mod->{time} <= 0) {

		# Time is up, so cancel this one.
		$obj->mod_attr(-name		=> $aname,
			       -cancel_modify	=> $id,
			       -immediate	=> 1);

	    } elsif ($mod->{applied} && !$mod->{incremental}) {

		# This is a non-incremental modifier that was applied already,
		# so simply count down the time if applicable.
		$mod->{time}-- if (defined($mod->{time}));

	    } else {

		# Change has not yet been applied or this is an incremental
		# change, so apply it.
		my %args = (
		    -name	=> $aname,
		    -force	=> $mod->{force},
		    -other	=> $obj->find($mod->{other}),
		    -object	=> $obj->find($mod->{object}),
		);
		$args{modify} = $mod->{modify}
		  if (defined($mod->{modify}));
		$args{modify_real} = $mod->{modify_real}
		  if (defined($mod->{modify_real}));
		$obj->mod_attr(%args);
		$mod->{applied} = 1;

		# Count down the time if applicable
		$mod->{time}-- if (defined($mod->{time}));

	    }
	}

	1;
}

####
## MISCELLANEOUS OBJECT METHODS

# Fetch/change the ID of object. Changing the ID may fail if the object is
# managed and the manager does not like the new ID.

sub id
{
	my ($obj, $id) = @_;

	if (defined($id)) {
	    my $man = $obj->manager();
	    $man->id($obj, $id) if ($man);
	    $obj->{id} = $id;
	} else {
	    $obj->{id};
	}
}

# Fetch/set manager of object. Note that there is a difference between not
# specifying a manager parameter at all and specifying undef:
#
#    $obj->manager($man)	- Sets the manager to object $man
#    $obj->manager(undef)	- Clears the old manager setting without setting
#				  a new one.
#    $obj->manager()		- Returns the current manager setting

sub manager
{
	my ($obj, $man) = @_;

	if (@_ == 2) {
	    $obj->del_attr(ANAME_MANAGER);
	    $obj->new_attr(
		name	=> ANAME_MANAGER,
		type	=> 'any',
		value	=> $man,
		flags	=> ATTR_DONTSAVE | ATTR_NO_INHERIT,
	    ) if ($man);
	} else {
	    $obj->attr(ANAME_MANAGER);
	}
}

# Fetch/set priority of object.

sub priority
{
	my $obj = shift;

	if (@_) {
	    my $pri = shift;
	    $highest_pri = $pri if ($pri >= $highest_pri);
	    my $oldpri = $obj->{priority};
	    $obj->{priority} = $pri;
	    $oldpri;
	} else {
	    $obj->{priority};
	}
}

####
## DESTRUCTORS

# Destroy the object and remove it from its manager's table. The caller can
# pass in optional arbitrary parameters that are passed to any action binding.

sub destroy
{
	my $obj = shift;
	my %aargs = ();

	# Fetch parameters.
	FetchParams(\@_, \%aargs, [
	    [ 'opt', 'other', undef, 'object' ],
	    [ 'opt', 'object', undef, 'object' ],
	    [ 'opt', 'args', {}, 'hashref' ],
	] );

	# Check to see if we have an attribute table. If not present, we
	# did this already.
	return 0 if (!defined($obj->{attr}));

	# Trigger action BEFORE deletion so that the action code can examine
	# the object
	my $id = $obj->{id};
	$aargs{action} = 'object:on_destroy';
	$obj->action(%aargs);

	# Remove from manager, if applicable
	my $man = $obj->manager();
	$man->remove($obj->{id}) if ($man);

	# Delete all keys so that it can no longer be used. This should free
	# up all references to other objects.
	foreach my $key (keys %$obj) {
	    delete $obj->{$key};
	}

	# Done.
	1;
}

1;
