package Games::Object::Manager;

use strict;
use Exporter;

use Carp qw(carp croak confess);
use IO::File;
use Games::Object::Common qw(FetchParams LoadData SaveData ANAME_MANAGER);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);

$VERSION = "0.11";
@ISA = qw(Exporter);
@EXPORT_OK = qw($CompareFunction REL_NO_CIRCLE);
%EXPORT_TAGS = (
    flags	=> [ qw(REL_NO_CIRCLE) ],
    variables	=> [ qw($CompareFunction) ],
);

use vars qw($CompareFunction);

# Define flags.
use constant REL_NO_CIRCLE	=> 0x00000001; # Don't allow cir. relates

# Define the comparison function to use for processing order.
$CompareFunction = '_CompareDefault';

# Define the default process info.
my @ProcessList = (
    'process_queue',
    'process_pmod',
    'process_tend_to',
);
my $ProcessLimit = 100;

####
## INTERNAL FUNCTIONS

# Default comparison function when determining the order of processing of
# two objects.

sub _CompareDefault { $b->priority() <=> $a->priority() }

# Comparison function when using the creation order option

sub _CompareAddOrder {
    my $cmp = $b->priority() <=> $a->priority();
    $cmp == 0 ? $a->order() <=> $b->order() : $cmp;
}

# Create a relation methods

sub _CreateRelators
{
	my %args = @_;
	my $realname = $args{name};
	my $name = $args{relate_method};
	my $uname = $args{unrelate_method};
	my $rname = $args{related_method};
	my $iname = $args{is_related_method};
	my $lname = $args{related_list_method};

	no strict 'refs';
	*$name = sub {
	    my $man = shift;
	    my $args = ( ref($_[$#_]) eq 'HASH' ? pop @_ : {} );
	    $man->relate(how => $realname,
			 self => $_[0],
			 object => $_[1],
			 other => $_[2],
			 args => $args);
	} if (!defined(&$name));
	*$uname = sub {
	    my $man = shift;
	    my $args = ( ref($_[$#_]) eq 'HASH' ? pop @_ : {} );
	    $man->unrelate(how => $realname,
			   object => $_[0],
			   other => $_[1],
			   args => $args);
	} if (!defined(&$uname));
	*$rname = sub {
	    my $man = shift;
	    $man->related(how => $realname, object => $_[0]);
	} if (!defined(&$rname));
	*$iname = sub {
	    my $man = shift;
	    $man->is_related(how => $realname, self => $_[0], object => $_[1]);
	} if (!defined(&$iname));
	*$lname = sub {
	    my $man = shift;
	    $man->related_list(how => $realname, self => $_[0]);
	} if (!defined(&$lname));
}

####
## CONSTRUCTOR

# Basic constructor

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $man = {};
	my %args = ();

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'opt', 'base_id', 0, 'int' ],
	    [ 'opt', 'process_list', \@ProcessList, 'arrayref' ],
	    [ 'opt', 'process_limit', $ProcessLimit, 'int' ],
	] );
	bless $man, $class;

	# Define storage for created objects. Note that this means that objects
	# will be persistent. They can go out of scope and still exist, since
	# each is identified by a unique ID.
	$man->{index} = {};

	# Define tables that handle object relationships
	$man->{relation_def} = {};
	$man->{relate_to} = {};
	$man->{relate_from} = {};

	# Define a counter for creating objects when the user wants us to
	# assume that every new object is unique. The starting number can be
	# changed with base_id() but only if no objects have been created yet.
	$man->{next} = $args{base_id};

	# Define a counter that will be used to track the order in which objects
	# are created. This is to support a new feature in v0.05
	$man->{order} = 0;

	# And if we are doing this, we want to try and use space efficiently by
	# reclaiming unused IDs. Thus we track the lowest available opening.
	# [ NOT YET IMPLEMENTED ]
	$man->{reclaim} = 1;
	$man->{avail} = 0;

	# Track the highest priority object.
	$man->{highest_pri} = 0;

	# Define a table that shows what order process() is supposed to do
	# things.
	$man->{process_list} = $args{process_list};

	# Define a limit to how many times the same item can be processed in a
	# queue (see process_queue() for details)
	$man->{process_limit} = $args{process_limit};

	# Set the default inherit_from relationship.
	$man->define_relation(
	    name		=> 'inherit',
	    relate_method	=> 'inherit',
	    unrelate_method	=> 'disinherit',
	    related_method	=> 'inheriting_from',
	    related_list_method	=> 'has_inherting',
	    is_related_method	=> 'is_inheriting_from',
	    flags		=> REL_NO_CIRCLE,
	);

	# Done.
	$man;
}

# Constructor for loading entire container from a file.

sub load
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $file = shift;
	my $filename;

	# If we got a filename instead of a file object, open the file.
	if (!ref($file)) {
	    $filename = $file;
	    $file = IO::File->new();
	    $file->open("<$filename") or
		croak "Unable to open manager file '$filename'";
	}

	# Initialize the object.
	my $man;
	if (ref($proto)) {
	    # This is a "load in place", meaning we're reloading to an
	    # existing object, so clear out the old stuff.
	    $man = $proto;
	    foreach my $key (keys %$man) { delete $man->{$key}; }
	} else {
	    # Totally new object originating from the file.
	    $man = {};
	    bless $man, $class;
	}

	# Check the header to make sure this is manager data.
	my $line = <$file>; chomp $line;
	croak "Did not find manager header data in file"
	  if ($line ne 'OBJ:__MANAGER__');
	$line = <$file>; chomp $line;
	croak "Second line of manager data header bad"
	  if ($line !~ /^CL:(.+)$/);
	my $mclass = $1;

	# Load.
	LoadData($file, $man);
	$file->close() if defined($filename);

	# Restore manager attributes to all objects.
	foreach my $obj (values %{$man->{index}}) { $obj->manager($man); }

	# Restore relators.
	foreach my $rel (values %{$man->{relation_def}}) {
	    _CreateRelators(%$rel);
	}

	# Done.
	bless $man, $mclass;
	$man;
}

####
## MANAGER DATA METHODS

# Save the manager and its contents to a file.

sub save
{
	my $man = shift;
	my $file = shift;
	my $filename;

	# If we got a filename instead of a file object, open the file.
	if (!ref($file)) {
	    $filename = $file;
	    $file = IO::File->new();
	    $file->open(">$filename") or
		croak "Unable to open manager file '$filename'";
	}

	# Save header. This indicates that this is indeed manager object
	# data and preserves the class.
	print $file "OBJ:__MANAGER__\n" .
		    "CL:" . ref($man) . "\n";

	# Save data. See the comments on the save() routine in Games::Object
	# for why we copy the ref to an ordinary hash first.
	my %hash = %$man;
	SaveData($file, \%hash);
	$file->close() if (defined($filename));
	1;
}

# "Find" an object (i.e. look up its ID). If given something that is
# already an object, validates that the object is still valid. If the
# assertion flag is passed, an invalid object will result in a fatal error.

sub find
{
	my ($man, $id, $assert) = @_;

	if (!defined($id)) {
	    if ($assert) {
		confess "Assertion failed: ID is undefined";
	    } else {
		return undef;
	    }
	}
	$id = $id->id() if (ref($id) && UNIVERSAL::isa($id, 'Games::Object'));
	if (defined($man->{index}{$id})) {
	    $man->{index}{$id};
	} elsif ($assert) {
	    # Report with confess() so user can see where the assertion was made
	    confess "Assertion failed: '$id' is not a valid/managed object ID";
	} else {
	    undef;
	}
}

# Return the number of objects in the manager.

sub total_objects {
    my $man = shift;
    scalar keys %{$man->{index}};
}

# Returns the ID of an object, with the side effect that it validates that
# this object is really a Games::Object derivative and is being managed by
# this manager. The user specifies either the ID or the object ref. If valid,
# the ID is always returned (thus it can be used to guarantee the return of
# an ID when you're not sure if you were passed an object or the ID).

sub id
{
	my ($man, $obj, $assert) = @_;

	if (ref($obj) && UNIVERSAL::isa($obj, 'Games::Object')) {
	    my $id = $obj->id();
	    defined($man->{index}{$id}) ? $id : undef;
	} elsif (defined($man->{index}{$obj})) {
	    $obj;
	} elsif ($assert) {
	    # Report with confess() so user can see where the assertion was made
	    confess "Assertion failed: '$obj' is not a valid/managed object";
	} else {
	    undef;
	}
}

####
## OBJECT MANAGEMENT METHODS

# Add a new object to the manager. The user may either specify an ID (which
# must not already exist), or allow it to take a predefined ID from the object
# (if defined), or pick one on its own (if previous two undefined)

sub add
{
	my ($man, $obj, $id) = @_;

	# Pick new ID if needed.
	$id = $obj->id() if (!defined($id));
	$id = $man->{next}++ if (!defined($id));

	# Make sure it does not exist.
	croak "Attempt to add duplicate object ID '$id'"
	    if (defined($man->{index}{$id}));

	# Add it. Do this before adding the manager link so we don't get
	# a call back to us.
	$man->{index}{$id} = $obj;
	$obj->id($id);

	# Add the manager attribute
	$obj->manager($man);

	# Done.
	$id;
}

# Similar to add, but allows an object to already exist under this ID, in
# which case the old on is removed. Returns the same values as add(). The
# ID to replace is always taken from the existing object. The ID parameter
# is applied to the new object (thus it must not already exist).

sub replace
{
	my ($man, $obj, $id) = @_;

	# Get rid of the old object. Don't worry if the object does not
	# already exist.
	$man->remove($id);

	# Add new one.
	$man->add($obj, $id);
}

# Remove an object. Returns the object if the object was found and removed,
# undef if not. The on_removed action is invoked on the object (but before
# the object is actually removed so it can still access the manager linkage).
# User may specify additional args to be passed to the action() call.

sub remove
{
	my $man = shift;
	my $self = shift;

	# If the last arg is a hash, this is additional args to any callback
	# that might get invoked.
	my $aargs = ( @_ && ref($_[$#_]) eq 'HASH' ? pop @_ : {} );

	# Any remaining arg is other.
	my $other = ( @_ ? shift : $self );

	# If object does not exist, no need to go any further.
	my $id = $man->id($self);
	return undef if (!defined($man->{index}{$id}));

	# Fetch the object and invoke action.
	$self = $man->find($id);
	$self->action(other => $other,
		      action => "object:remove",
		      args => $aargs);

	# Break relationships TO this object. These are all done with the
	# force option. This means that no tests will be done for each
	# unrelate(), but post-unrelate() actions WILL occur.
	my @hows = ();
	@hows = keys %{$man->{relate_from}{$id}}
	  if (defined($man->{relate_from}{$id}));
	foreach my $how (@hows) {
	    my @fobjs = @{$man->{relate_from}{$id}{$how}};
	    foreach my $fobj (@fobjs) {
		$man->unrelate(
		    how		=> $how,
		    object	=> $fobj,
		    other	=> $other,
		    force	=> 1,
		    args	=> { source => 'remove:to', %$aargs },
		);
	    }
	}

	# Break all relationships FROM this object to others.
	@hows = ();
	@hows = keys %{$man->{relate_to}{$id}}
	  if (defined($man->{relate_to}{$id}));
	foreach my $how (@hows) {
	    my @objs = map { $man->find($_) } @{$man->{relate_from}{$id}{$how}};
	    foreach my $obj (@objs) {
	        $man->unrelate(
		    how		=> $how,
		    object	=> $obj,
		    other	=> $other,
		    force	=> 1,
		    args	=> { source => 'remove:from', %$aargs }
		);
	    }
	}

	# Delete from internal tables, which should remove all references to
	# it save the one we have.
	delete $man->{index}{$id};
	delete $man->{relate_to}{$id};
	delete $man->{relate_from}{$id};

	# Remove the manager attribute.
	$self->manager(undef);

	# Done.
	$self;
}

# Go down the complete list of objects and perform a method call on each. If
# no args are given, 'process' is assumed. This will call them in order of
# priority.
#
# The caller may choose to filter the list by providing a CODE ref as the
# first argument. Only the objects for which the CODE ref returns true are
# considered (new in v0.10).

sub process
{
	my $man = shift;

	# Note that we grab the actual objects and not the ids in the sort.
	# This is more efficient, as each object is simply a reference (a
	# scalar with a fixed size) as opposed to a string (a scalar with
	# a variable size).
	my $method = shift;
	my $code = ( ref($method) eq 'CODE' ? $method : undef );
	$method = shift if ($code);
	my @args = @_;
	$method = 'process' if (!defined($method));

	# Derive the object list.
	my @objs = (
	    $code ?
		grep { &$code($_, @args) }
		grep { UNIVERSAL::can($_, $method) }
		sort $CompareFunction values %{$man->{index}}
	    :
		grep { UNIVERSAL::can($_, $method) }
		sort $CompareFunction values %{$man->{index}}
	);

	# Process.
	unshift @args, $man->{process_list} if ($method eq 'process');
	foreach my $obj (@objs) {
	    $obj->$method(@args) if (UNIVERSAL::can($obj, $method));
	}

	# Return the number of objects processed.
	scalar(@objs);
}

# Set/fetch the process list for the process() function. Note that the user is
# not limited to the methods found here. The methods can be in the subclass
# if desired. Note that we have no way to validate the method names here,
# so we take it on good faith that they exist.

sub process_list {
    my $man = shift;
    if (@_) { @{$man->{process_list}} = @_ } else { @{$man->{process_list}} }
}

####
## OBJECT RELATIONSHIP METHODS

# Check to see if a relationship is valid. If assertion flag present, this
# will bomb the program if the relationship is not present.

sub has_relation
{
	my ($man, $how, $assert) = @_;

	defined($man->{relation_def}{$how}) ? 1 :
	$assert ? croak "'$how' is an invalid relationship type"
		: 0;
}

# Define a new relationship. This allows objects to be related with the
# relate() method, or via a relator method created.

sub define_relation
{
	my $man = shift;
	my %args = ();

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'req', 'name', undef, 'string' ],
	    [ 'opt', 'relate_method', undef, 'string' ],
	    [ 'opt', 'unrelate_method', undef, 'string' ],
	    [ 'opt', 'related_method', undef, 'string' ],
	    [ 'opt', 'related_list_method', undef, 'string' ],
	    [ 'opt', 'is_related_method', undef, 'string' ],
	    [ 'opt', 'on_remove', undef, 'callback' ],
	    [ 'opt', 'flags', 0, 'int' ],
	], 1 );

	# Add it. Note that we allow redefinition at will.
	my $rname = $args{name};
	$args{relate_method} = $rname
	    if (!$args{relate_method});
	$args{unrelate_method} = "un${rname}"
	    if (!$args{unrelate_method});
	$args{related_method} = "${rname}_to"
	    if (!$args{related_method});
	$args{related_list_method} = "${rname}_list"
	    if (!$args{related_list_method});
	$args{is_related_method} = "is_${rname}"
	    if (!$args{is_related_method});
	$man->{relation_def}{$rname} = \%args;

	# Create relator.
	_CreateRelators(%args);

	# Done.
	1;
}

# Relate two objects.

sub relate
{
	my $man = shift;
	my %args = ();

	# Fetch parameters. Self is the thing being related to, object is
	# the thing being related to it.
	FetchParams(\@_, \%args, [
	    [ 'req', 'how', undef, sub { $man->has_relation(shift); } ],
	    [ 'req', 'self', undef, 'any' ],
	    [ 'req', 'object', undef, 'any' ],
	    [ 'opt', 'other', undef, 'any' ],
	    [ 'opt', 'force', 0, 'boolean' ],
	    [ 'opt', 'args', {}, 'hashref' ],
	] );
	my $how = $args{how};
	my $self = $args{self};
	my $object = $args{object};
	my $other = $args{other};
	my $force = $args{force};
	my $aargs = $args{args};

	# If other is undefined, then we set it equal to self, meaning we assume
	# that the receipient of the object itself instigated the action.
	$other = $self if (!defined($other));

	# Do it. First fetch necesary parameters.
	my $rel = $man->{relation_def}{$how};
	my $doaction = "object:on_" . $rel->{relate_method};
	my $tryaction = "object:try_" . $rel->{relate_method};
	my $idself = $man->id($self); $self = $man->find($idself);
	my $idobject = $man->id($object); $object = $man->find($idobject);

	# Perform check to see if relationship is allowed. We do this
	# before anything else, including attempting to unrelate it from
	# whatever it may be currently related to. This way the relate
	# check code can see how it is related now in case that means
	# anything, plus it prevents orphaned objects (which would happen
	# if we first unrelate()d it and then failed the relate() check).
	my $check =
	    $force
	||
	    $self->action(
		action	=> $tryaction,
		object	=> $object,
		other	=> $other,
		args	=> $aargs);
	return 0 if (!$check);

	# Relation is allowed, so check to see if already related.
	if (defined($man->{relate_to}{$idobject}{$how})) {

	    # Already related in this fashion.
	    if ($man->{relate_to}{$idobject}{$how} eq $idself) {
	        # And to the same object, so do nothing (successfully).
	        return 1;
	    } elsif ($man->unrelate(
	      how	=> $how,
	      object	=> $object,
	      force	=> $force,
	      args	=> { source => 'relate', %$aargs } )) {
	        # The unrelate from the previous object succeeded, so
	        # invoke myself to try again.
	        return $man->relate(@_);
	    } else {
	        # The unrelate failed, so no-go.
	        return 0;
	    }

	}

	# Not currently related to anything in this way. The first
	# thing we do is check the REL_NO_CIRCLE flag. If set,
	# then we make a check to see if a circular reference would
	# result from this. If so, then bomb, as this is assumed to
	# be a logic error in the main program.
	if ($rel->{flags} & REL_NO_CIRCLE) {

	    # Check to make sure no circular relationship would result from
	    # this (i.e. self is already related to object in this manner).
	    croak "Relating $idobject to $idself in manner $how would " .
	          "create a circular relationship"
	      if ($man->is_related(
	        object  => $self,
	        self	=> $object,
	        how     => $how,
	        distant => 1));

	}

	# Do it.
	$man->{relate_to}{$idobject}{$how} = $idself;
	$man->{relate_from}{$idself}{$how} = []
	    if (!defined($man->{relate_from}{$idself}{$how}));
	push @{$man->{relate_from}{$idself}{$how}}, $idobject;

	# Invoke post-relate actions.
	$self->action(
	    object	=> $object,
	    other	=> $other,
	    action	=> $doaction,
	    args	=> $aargs,
	);

	# Done.
	1;

}

# Return the object to which this one is related (if any)

sub related
{
	my $man = shift;
	my %args = ();

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'req', 'how', undef, sub { $man->has_relation(shift) } ],
	    [ 'req', 'object', undef, 'any' ],
	] );
	my $how = $args{how};
	my $object = $args{object};
	my $id = $man->id($object); $object = $man->find($id);

	defined($man->{relate_to}{$id}) &&    # @*!&$ autovivication
	defined($man->{relate_to}{$id}{$how}) ?
	    $man->find($man->{relate_to}{$id}{$how}) : undef;
}

# Return a list of items that are related to a paricular object in a certain
# way.

sub related_list
{
	my $man = shift;
	my %args = ();

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'req', 'how', undef, sub { $man->has_relation(shift) } ],
	    [ 'req', 'self', undef, 'any' ],
	] );
	my $how = $args{how};
	my $self = $args{self};

	# Return list of objects.
	my $id = $man->id($self);
	my @list = ();
	@list = map { $man->find($_) } @{$man->{relate_from}{$id}{$how}}
		if (defined($man->{relate_from}{$id})
		 && defined($man->{relate_from}{$id}{$how}));
	@list;
}

# Check to see if two objects are related. By default, this checks only if
# two objects are DIRECTLY related. However, specifying the "distant" flag
# will perform a recursive check to see if the relationship exists indirectly.

sub is_related
{
	my $man = shift;
	my %args = ();

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'req', 'how', undef, sub { $man->has_relation(shift); } ],
	    [ 'req', 'object', undef, 'any' ],
	    [ 'opt', 'self', undef, 'any' ],
	    [ 'opt', 'distant', 0, 'boolean' ],
	] );
	my $how = $args{how};
	my $idobject = $man->id($args{object});
	my $idself = $man->id($args{self});
	my $distant = $args{distant};
	return 0 if (!defined($idobject) || !defined($idself));

	# If idobject is related to nothing then no relation.
	return 0 if (!defined($man->{relate_to}{$idobject})
		  || !defined($man->{relate_to}{$idobject}{$how}));

	# If there is a direct relationships, success.
	return 1 if ($man->{relate_to}{$idobject}{$how} eq $idself);

	# If user did not want a distant relationship, then fail.
	return 0 if (!$distant);

	# Otherwise, check what idobject is related to and see if that is
	# related to idself.
	$man->is_related(
	    object	=> $man->{relate_to}{$idobject}{$how},
	    self	=> $idself,
	    how		=> $how,
	    distant	=> 1);
}

# Unrelate an object.

sub unrelate
{
	my $man = shift;
	my %args = ();

	# Fetch parameters.
	FetchParams(\@_, \%args, [
	    [ 'req', 'how', undef, sub { $man->has_relation(shift) } ],
	    [ 'req', 'object', undef, 'any' ],
	    [ 'opt', 'other', undef, 'any' ],
	    [ 'opt', 'args', {}, 'hashref' ],
	] );
	my $how = $args{how};
	my $object = $args{object};
	my $other = $args{other};
	my $aargs = $args{args};
	my $rel = $man->{relation_def}{$how};
	my $doaction = "object:on_" . $rel->{unrelate_method};
	my $tryaction = "object:try_" . $rel->{unrelate_method};

	# Set the source if not already defined.
	$aargs->{source} = 'direct' if (!defined($aargs->{source}));

	# Get ID and check if related.
	my $idobject = $man->id($object); $object = $man->find($idobject);
	if (defined($man->{relate_to}{$idobject})
	 && defined($man->{relate_to}{$idobject}{$how})) {
	    # Yes it is, so check that object to see if we can unrelate.
	    my $idself = $man->{relate_to}{$idobject}{$how};
	    my $self = $man->find($idself);
	    $other = $self if (!defined($other));
	    my $check =
		$self->action(
		    object	=> $object,
		    other	=> $other,
		    action	=> $tryaction,
		    args	=> { %$aargs },
		);
	    if ($check) {
		# Check succeeded, so unrelate them.
		delete $man->{relate_to}{$idobject}{$how};
		my @nlist = ();
		foreach my $item (@{$man->{relate_from}{$idself}{$how}}) {
		    push @nlist, $item if ($item ne $idobject);
		}
		@{$man->{relate_from}{$idself}{$how}} = @nlist;
		# Invoke post-unrelate actions.
		$self->action(
		    object	=> $object,
		    other	=> $other,
		    action	=> $doaction,
		    args	=> $aargs,
		);
		1;
	    } else {
		0;
	    }
	} else {
	    # Not related to anything in this manner. Since the end result
	    # is the same as the original condition, we consider this to
	    # be success.
	    1;
	}
}

1;
