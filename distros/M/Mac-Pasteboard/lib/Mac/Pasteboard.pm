package Mac::Pasteboard;

use 5.006002;

use strict;
use warnings;

use Carp;
use Encode ();

BEGIN {
    $ENV{DEVELOPER_DEBUG} and Carp->import ('verbose');
}

use Exporter qw{ import };

{
    my @const = qw{
        defaultFlavor
	kPasteboardClipboard kPasteboardFind kPasteboardUniqueName
	badPasteboardSyncErr badPasteboardIndexErr badPasteboardItemErr
	    badPasteboardFlavorErr duplicatePasteboardFlavorErr
	    notPasteboardOwnerErr noPasteboardPromiseKeeperErr
	kPasteboardModified kPasteboardClientIsOwner
	kPasteboardFlavorNoFlags kPasteboardFlavorSenderOnly
	    kPasteboardFlavorSenderTranslated
	    kPasteboardFlavorNotSaved
	    kPasteboardFlavorRequestOnly
	    kPasteboardFlavorSystemTranslated
	    kPasteboardFlavorPromised
	};
    my @funcs = qw{
	pbcopy pbcopy_find
	pbencode pbencode_find
	pbflavor pbflavor_find
	pbpaste pbpaste_find
    };

    our @EXPORT_OK = (@const, @funcs, qw{coreFoundationUnknownErr});

    our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
	const => \@const,
    );

    # We have a functional interface, and at this point no longer
    # exporting it by default would be a change in the public
    # interface. So we disable Perl::Critic.
    our @EXPORT = @funcs;	## no critic (ProhibitAutomaticExportation)
}

our $VERSION = '0.009';
our $XS_VERSION = $VERSION;
our $ALPHA_VERSION = $VERSION;
$VERSION =~ s/_//g;

require XSLoader;
XSLoader::load('Mac::Pasteboard', $XS_VERSION);

BEGIN {
    eval {
	require Scalar::Util;
	Scalar::Util->import (qw{dualvar});
	1;
    } or do {
	*dualvar = sub {$_[0]};
    };

    # Mac::Errors is optional. We load it by file name to try to avoid
    # prereq_matches_use problems in the Kwalitee Game.
    eval {	## no critic (RequireCheckingReturnValueOfEval)
##	require Mac::Errors;	# Optional
	require 'Mac/Errors.pm';	## no critic (RequireBarewordIncludes)
	1;
    };
}

my %attr = (
    default_flavor	=> 1,	# read/write
    encode	=> 1,	# read/write
    fatal => 1,		# read/write
    id => sub {		# read/write. This is the mutator.
	if (defined $_[2]) {
	    if ($_[2] eq 'undef') {
		$_[2] = undef;
	    } else {
		$_[2] =~ m/\D/
		    and croak "The $_[1] attribute must be numeric or undef";
	    }
	}
	$_[2];
    },
    missing_ok => 1,	# read/write
    name => 0,		# read only
    status => sub {	# read/write. This is the mutator.
	$_[2] =~ m/^[+\-]?\d+$/
	    or croak "Status value must be an integer";
	_error ($_[2]);
    },
);

my %static = (
    fatal => 1,
);

sub new {
    my ($class, $name) = @_;
    ref $class and $class = ref $class;
    defined $name or $name = kPasteboardClipboard();
    $ENV{DEVELOPER_DEBUG}
	and warn __PACKAGE__, "->new() creating $name";
    my $self = bless {
	default_flavor	=> defaultFlavor(),
	encode		=> 0,
	fatal		=> 1,
	id		=> undef,
	missing_ok	=> 0,
	name		=> $name,
    }, $class;
    my ($status, $pbref, $created_name) = xs_pbl_create ($self->{name});
    __PACKAGE__->_check ($status) and return;
    $created_name and $self->{name} = $created_name;
    $self->{pbref} = $pbref;
    $self->{status} = $static{status};
    return $self;
}

sub clear {
    my ($self) = @_;
    return $self->_check (xs_pbl_clear ($self->{pbref}));
}

sub clone {
    my ($self) = @_;
    my $clone = {%$self};	# Works as long as we're a simple hash.
    if (defined (my $pbref = $self->{pbref})) {
	xs_pbl_retain ($pbref);
    }
    return bless $clone, ref $self;
}

sub copy {
    my ($self, $data, $flavor, $flags) = @_;
    defined $flavor
	and $flavor ne ''
	or $flavor = $self->{default_flavor};
    defined $flags or $flags = kPasteboardFlavorNoFlags ();
    return $self->_check (
	xs_pbl_copy (
	    $self->{pbref},
	    $self->_xlate( encode => $data, $flavor ),
	    ( defined $self->{id} ? $self->{id} : 1 ),
	    $flavor,
	    $flags,
	)
    );
}

sub flavors {
    my ($self, $conforms_to) = @_;
    my ($status, @data) = xs_pbl_all (
	$self->{pbref}, $self->{id}, 0, $conforms_to);
    $self->_check ($status) and return;
    return wantarray ? @data : \@data;
}

{
    my %flavors = (
	kPasteboardFlavorSenderOnly => kPasteboardFlavorSenderOnly (),
	kPasteboardFlavorSenderTranslated =>
		kPasteboardFlavorSenderTranslated (),
	kPasteboardFlavorNotSaved => kPasteboardFlavorNotSaved (),
	kPasteboardFlavorRequestOnly => kPasteboardFlavorRequestOnly (),
	kPasteboardFlavorSystemTranslated =>
		kPasteboardFlavorSystemTranslated (),
	kPasteboardFlavorPromised => kPasteboardFlavorPromised (),
    );
    sub flavor_flag_names {
	my $flavor = pop;
	my @rslt;
	foreach my $name (sort keys %flavors) {
	    $flavor & $flavors{$name} or next;
	    push @rslt, $name;
	}
	@rslt or push @rslt, 'kPasteboardFlavorNoFlags';
	return wantarray ? @rslt : join ', ', @rslt;
    }
}

sub flavor_tags {
    my $flavor = pop;
    my $hash = xs_pbl_uti_tags ($flavor);
    return wantarray ? %$hash : $hash;
}

sub get {
    my ($self, $name) = @_;
    exists $attr{$name}
	or croak "No such attribute as '$name'";
    return ref $self ? $self->{$name} : $static{$name};
}

sub paste {
    my ($self, $flavor) = @_;
    defined $flavor
	and $flavor ne ''
	or $flavor = $self->{default_flavor};
    my ($status, $data, $flags) = xs_pbl_paste (
	$self->{pbref}, $self->{id}, $flavor );
    $self->_check ($status);
    $data = $self->_xlate( decode => $data, $flavor );
    return wantarray ? ($data, $flags) : $data;
}

sub paste_all {
    my ($self, $conforms_to) = @_;
    my ($status, @data) = xs_pbl_all (
	$self->{pbref}, $self->{id}, 1, $conforms_to);
    $self->_check ($status) and return;
    foreach my $datum ( @data ) {
	$datum->{data} = $self->_xlate(
	    decode => $datum->{data}, $datum->{flavor} );
    }
    return wantarray ? @data : \@data;
}

sub pbcopy (;$$$) {		## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardClipboard ();
    goto &_pbcopy;
}

sub pbcopy_find (;$$$) {	## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardFind ();
    goto &_pbcopy;
}

sub pbencode (;$) {		## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardClipboard ();
    goto &_pbencode;
}

sub pbencode_find (;$) {	## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardFind ();
    goto &_pbencode;
}

sub pbflavor (;$) {		## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardClipboard ();
    goto &_pbflavor;
}

sub pbflavor_find (;$) {	## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardFind ();
    goto &_pbflavor;
}

sub pbpaste (;$) {		## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardClipboard ();
    goto &_pbpaste;
}

sub pbpaste_find (;$) {		## no critic (ProhibitSubroutinePrototypes)
    unshift @_, kPasteboardFind ();
    goto &_pbpaste;
}

sub set {
    my ($self, @args) = @_;
    my $hash = ref $self ? $self : \%static;
    while (@args) {
	my $name = shift @args;
	exists $attr{$name}
	    or croak "No such attribute as '$name'";
	$attr{$name}
	    or croak "Attribute '$name' is read-only";
	my $ref = ref $attr{$name};
	if ($ref eq 'CODE') {
	    $hash->{$name} = $attr{$name}->($self, $name, shift @args);
	} else {
	    $hash->{$name} = shift @args;
	}
    }
    return $self;
}

sub synch {
    my ($self) = @_;
    return xs_pbl_synch ($self->{pbref});
}

{
    my %flags = (
	kPasteboardModified => kPasteboardModified (),
	kPasteboardClientIsOwner => kPasteboardClientIsOwner (),
    );
    sub synch_flag_names {
	my $flag = pop;
	my @rslt;
	foreach my $name (sort keys %flags) {
	    $flag & $flags{$name} or next;
	    push @rslt, $name;
	}
	return wantarray ? @rslt : join ', ', @rslt;
    }
}

{
    my %errtxt = (
	0 => '',
	badPasteboardSyncErr() => {
	    sym => 'badPasteboardSyncErr',
	    desc => 'The pasteboard has been modified and must be synchronized before use',
	},
	badPasteboardIndexErr() => {
	    sym => 'badPasteboardIndexErr',
	    desc => 'The specified pasteboard item index does not exist',
	},
	badPasteboardItemErr() => {
	    sym => 'badPasteboardItemErr',
	    desc => 'The item reference does not exist',
	},
	badPasteboardFlavorErr() => {
	    sym => 'badPasteboardFlavorErr',
	    desc => 'The item flavor does not exist',
	},
	coreFoundationUnknownErr() => {
	    type => 'Mac OS',
	    sym => 'coreFoundationUnknownErr',
	    desc => 'The unknown error',
	},
	duplicatePasteboardFlavorErr() => {
	    sym => 'duplicatePasteboardFlavorErr',
	    desc => 'The item flavor already exists',
	},
	notPasteboardOwnerErr() => {
	    sym => 'notPasteboardOwnerErr',
	    desc => 'The application did not clear the pasteboard before attempting to add flavor data',
	},
	noPasteboardPromiseKeeperErr() => {
	    sym => 'noPasteboardPromiseKeeperErr',
	    desc => 'The application attempted to add promised data without previously registering a promise keeper callback',
	},
    );

    sub _error {
	my $val = pop;
	if (!$val) {
	    return dualvar (0, '');
	} elsif (my $err = $Mac::Errors::MacErrors{$val}) {
	    return dualvar ($val,
		sprintf ('Mac OS error %d (%s): %s',
		    $err->number, $err->symbol, $err->description));
	} elsif (exists $errtxt{$val}) {
	    return dualvar ($val,
		sprintf ('%s error %d (%s): %s',
		    $errtxt{$val}{type} || 'Pasteboard', $val,
		    $errtxt{$val}{sym}, $errtxt{$val}{desc}));
	} else {
	    return dualvar ($val, "Unknown error ($val)");
	}
    }

    sub _check {
	my ($self, $error) = @_;
	my $hash = ref $self ? $self : \%static;
	$hash->{status} = my $dual = _error ($error);
	if ($error == -25133 && $hash->{missing_ok}) {
	    return $dual;
	} elsif ($error && $hash->{fatal}) {
	    croak $dual;
	} else {
	    return $dual;
	}
    }
}

{
    my %encoding = (
	'public.utf8-plain-text'	=> 'UTF-8',
	'public.utf16-plain-text'	=> 'UTF-16LE',
	'public.utf16-external-plain-text'	=> 'UTF-16',
    );

    sub _xlate {
	my ( $self, $function, $data, $flavor ) = @_;
	$self->get( 'encode' )
	    or return $data;
	defined $flavor
	    and $flavor ne ''
	    or $flavor = $self->get( 'default_flavor' );
	defined $encoding{$flavor}
	    or return $data;
	my $code = Encode->can( $function )
	    or confess "Programming error - Encode can not $function()";
	return $code->( $encoding{$flavor}, $data );
    }
}

{

    my %cache;	# So we don't have to keep instantiating pasteboards.

    sub _pbobj {
	my ( $name ) = @_;
	return $cache{$name} ||= __PACKAGE__->new( $name )->set(
	    id => undef,	# should be undef anyway, but ...
	    missing_ok => 1,	# no exception for missing data ...
	);
    }

}

sub _pbcopy {
    my ( $name, @args ) = @_;
    my $pb = _pbobj( $name );
    @args or push @args, $_;
    $pb->clear ();
    return $pb->copy (@args);
}

sub _pbencode {
    my ( $name, $encode ) = @_;
    my $pb = _pbobj( $name );
    my $old = $pb->get( 'encode' );
    defined $encode
	and $encode ne ''
	and $pb->set( encode => $encode );
    return $old;
}

sub _pbflavor {
    my ( $name, $flavor ) = @_;
    my $pb = _pbobj( $name );
    my $old = $pb->get( 'default_flavor' );
    defined $flavor
	and $flavor ne ''
	and $pb->set( default_flavor => $flavor );
    return $old;
}

sub _pbpaste {
    my ( $name, @args ) = @_;
    return _pbobj( $name )->paste( @args );
}

sub DESTROY {
    my ($self) = @_;
    $self->{pbref} and xs_pbl_release ($self->{pbref});
    return;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Mac::Pasteboard - Manipulate Mac OS X clipboards/pasteboards.

=head1 SYNOPSIS

To acquire text from the system clipboard, replacing it with your own:

  use Mac::Pasteboard;
  my $old_text = pbpaste();
  pbcopy ("Hello, sailor!\n");

or equivalently, using the object-oriented interface,

  use Mac::Pasteboard;
  my $pb = Mac::Pasteboard->new ();
  my $old_text = $pb->paste ();
  $pb->clear ();
  $pb->copy ("Hello, sailor!\n");

=head1 CAVEATS

This module is only useful if the script calling it has access to the
desktop. Otherwise attempts to instantiate a Mac::Pasteboard object will
fail, with Mac::Pasteboard->get ('status') returning
coreFoundationUnknownErr (-4960). This may happen when running over an
ssh connection, and probably from a cron job as well, depending on your
version of Mac OS X. This restriction appears to apply not only to the
system clipboard but to privately-created pasteboards.

Beginning with Mac OS 10.6 Snow Leopard, pasteboards could contain
multiple items. Until I upgrade, this package can only access the first
item. If your interest is in writing a droplet (that is, an application
that processes files which are dropped on it), see
L<the droplet documentation|Mac::Pasteboard::Droplet>.

This module is in general ignorant of the semantics implied by the
system-declared flavors, and makes no attempt to enforce them. In
plainer English, it is up to the user of this module to ensure that the
specified flavor is actually appropriate to the data it is used to
describe. For example, if you store some data on the pasteboard as
flavor 'public.jpeg', it is up to you to make sure that the data are, in
fact, a valid JPEG image.

On the other hand, it is (or at least may be) convenient to get the text
types encoded and decoded properly off the pasteboard. This is what the
L<encode|/encode (boolean)> attribute is for. It is false by default
because it appears not to work as one would hope under older versions of
Mac OS. It also does not cover C<com.apple.traditional-mac-plain-text>
because the encoding of this appears to change, and I have been unable
to find documentation (or to figure out on my own) which encoding to
expect.  B<Caveat user>.

=head1 DESCRIPTION

This XS module accesses Mac OS X pasteboards, which can be thought of as
clipboards with bells and whistles. Under Mac OS X, the system clipboard
is simply a special case of a pasteboard. In the following
documentation, 'clipboard' refers to the system clipboard, and
'pasteboard' refers to pasteboards in general.

This module uses the Pasteboard interface, which was introduced in Mac
OS 10.3 (a.k.a. 'Panther'), so it requires Mac OS 10.3 or better to run.

The simple case of placing plain text onto and reading it from the
system clipboard is accomplished by subroutines pbcopy() and pbpaste()
respectively. These correspond roughly to the command-line executables
of the same name, and are exported by default. If this is all you are
interested in, you can stop reading here. The rest of this section
describes the bells and whistles associated with a Mac OS X pasteboard.

A Mac OS X pasteboard contains zero or more data items, each of which is
capable of holding one or more flavors of data. The system defines a
couple pasteboards, including the system clipboard, named
'com.apple.pasteboard.clipboard'. The system clipboard is the default
taken if new() is called without arguments.

Data items are identified by an item id which is provided by the creator
of the item, and which (the documentation says) should only be
interpreted by the creator. Item flavors may be duplicated between items
but not within items. The item L<id|/id (integer)> is an attribute of
the Mac::Pasteboard object, with the default chosen so that you should
not need to worry about it unless you explicitly want more than one item
on a pasteboard.

A flavor is a Uniform Type Identifier which describes the semantics of
the data with which it is associated. In practice any string can be
used, but you probably want to stick to the system-declared flavors if
it is important to you that other software understand your data. The
L</SEE ALSO> section contains a link to a reference for Uniform Type
Identifiers which includes a description of all the system-declared
UTIs. All methods (or subroutines) that place data on or retrieve data
from a pasteboard take the flavor as an argument. This argument defaults
to 'com.apple.traditional-mac-plain-text'.

Data may be placed on a pasteboard only by the owner of that pasteboard.
Ownership is acquired by clearing the pasteboard. In general, the owner
of a pasteboard may either place data directly on to it, or place a
promise of data to be generated when the data are actually requested.
This module does not support placing a promise onto the pasteboard.
It will retrieve data promised by another application, but can not
specify a paste location for that data; it is simply returned verbatim.

=head1 METHODS

Some of the methods are documented as returning a status. This status is
a dualvar, whose numeric value is the Mac OS error encountered, and
whose string value is a description of the error similar to that
produced by the Mac::Error 'macerror' script. Errors other than the
documented pasteboard error will be described as 'Unknown error' unless
Mac::Error is installed and the error is known to that module.

Note, however, that by default the L<fatal|/fatal (boolean)> attribute
is true, which means an error will result in an exception. If
L<fatal|/fatal (boolean)> is false, the status will be false for success
and true for failure.

The following methods are provided:

=head2 $pb = Mac::Pasteboard->new ($name)

This method creates a new pasteboard object, connected to the pasteboard
of the given name, creating the pasteboard if necessary. If called with
no argument, you get the system clipboard, a.k.a.
L</kPasteboardClipboard>, a.k.a.  'com.apple.pasteboard.clipboard'.
Passing undef to new() is B<not> equivalent to calling it with no
arguments at all, since undef is the encoding for
L</kPasteboardUniqueName>.

Note that an error in creating a new pasteboard B<will> cause an
exception, since the L<fatal|/fatal (boolean)> attribute defaults to 1.
If you want to get a status back, you will need to call

 Mac::Pasteboard->set (fatal => 0);

If the attempt to instantiate an object fails, the status is available
from

 Mac::Pasteboard->get ('status');

=head2 $status = $pb->clear ()

This method clears the pasteboard. You must clear the pasteboard before
adding data to it.

=head2 $clone = $pb->clone ()

This method clones the pasteboard object.

=head2 $status = $pb->copy ($data, $flavor, $flags)

This method puts the given data on the pasteboard, identifying it as
being of the given flavor, and assigning the given pasteboard flags,
which are the bitwise 'or' (a.k.a. the '|' operator) of the individual
L<flavor flags|/Flavor flags>. If $flags is omitted,
L<kPasteboardFlavorNoFlags|/kPasteboardFlavorNoFlags> is used. If
$flavor is omitted, undefined, or the empty string, the L<default
flavor|/defaultFlavor> is used.

The pasteboard is B<not> cleared prior to this operation; any other data
of other flavors remain on the pasteboard.

If the L<id|/id (integer)> attribute is undef, the data are placed in
the item whose id is 1. Otherwise, the data are placed in the item with
the given id.  It is an error to attempt to place a given flavor in a
given item more than once.

=head2 @names = $pb->flavor_flag_names ($flags)

This method (or subroutine) interprets its last argument as flavor
flags, and returns the names of the flags set. If no recognized flags
are set, you get an empty list.

If called in scalar context you get back the names joined with ', ', or
'kPasteboardFlavorNoFlags' if there are none.

=head2 %tags = $pb->flavor_tags ($flavor)

This method (or subroutine) interprets its last argument as a flavor
name, and returns the preferred tags associated with the flavor in a
hash. The hash will have zero or more of the following keys:

 extension: the preferred file name extension for the flavor;
 mime: the preferred MIME type for the flavor;
 pboard: the preferred NSPBoard type for the flavor;
 os: the preferred 4-byte Mac OS document type for the flavor.

If called in scalar context, you get back a reference to the hash.

=head2 @flavors = $pb->flavors ($conforms_to)

This method returns the list of data flavors conforming to the given
flavor currently on the pasteboard. If $conforms_to is omitted or undef,
you get all flavors. If the L<id|/id (integer)> attribute is defined,
you get only flavors from the corresponding pasteboard item; otherwise
you get all conforming flavors. If you turn off the L<fatal|/fatal
(boolean)> attribute, you will get an empty list if an error occurs, and
you will need to check the L<status|/status (dualvar)> attribute so see
if the operation actually succeeded.

The return is a list of anonymous hashes, each containing the following
keys:

 flags: the flavor flags;
 flavor: the flavor name;
 id: the pasteboard item ID.

If called in scalar context, you get a reference to the list.

The L</SEE ALSO> section has a link to the I<Uniform Type Identifiers
Overview>, which deals with the notion of type conformance.

=head2 $value = $pb->get ($name)

This method returns the value of the given L<attribute|/ATTRIBUTES>. An
exception is thrown if the attribute does not exist.

This method can also be called statically (that is, as
Mac::Pasteboard->get ($name)), in which case it returns the static value
of the attribute, if any.

=head2 ($data, $flags) = $pb->paste ($flavor)

If the L<id|/id (integer)> attribute is defined, this method returns the
data of the given flavor from that pasteboard id, and the associated
L<flavor flags|/Flavor flags>; otherwise it returns the data from the
last instance of that flavor found, and the associated flavor flags. If
no such flavor data is found, an exception is thrown if the
L<missing_ok|/missing_ok (boolean)> attribute is false, or undef is
returned for $data if L<missing_ok|/missing_ok (boolean)> is true.

You test the $flags value for individual flags by using the bitwise
'and' operator ('&'). For example:

 $flags & kPasteboardFlavorSystemTranslated
   and print "This data provided by Translation Services\n";

If called in scalar context, you get $data.

=head2 @data = $pb->paste_all ($conforms_to)

This method returns all flavors of data on the pasteboard which conform
to the given flavor. If $conforms_to is omitted or undef, all flavors of
data are returned. If the L<id|/id (integer)> attribute is defined, only
data from that pasteboard item are returned; otherwise everything
accessible is returned.

The return is a list of anonymous hashes, each having the following
keys:

 data: the flavor data;
 flags: the flavor flags;
 flavor: the flavor name;
 id: the pasteboard item ID.

If called in scalar context, you get a reference to the list.

The L</SEE ALSO> section has a link to the I<Uniform Type Identifiers
Overview>, which deals with the notion of type conformance.

=head2 pbcopy ($data, $flavor, $flags)

This convenience subroutine (B<not> method) clears the system clipboard
and then copies the given data to it. All three arguments are optional
(the prototype being (;$$$). If $data is undef, the value of $_ is used.
If $flavor is undef, the L<default flavor|/defaultFlavor> is used. If
$flags is undef, L<kPasteboardFlavorNoFlags|/kPasteboardFlavorNoFlags>
is used.

In other words, this subroutine is more-or-less equivalent to the
'pbcopy' executable.

=head2 pbcopy_find ($data, $flavor, $flags)

This convenience subroutine (B<not> method) clears the 'find' pasteboard
and then copies the given data to it. All three arguments are optional
(the prototype being (;$$$). If $data is undef, the value of $_ is used.
If $flavor is undef, the L<default flavor|/defaultFlavor> is used. If
$flags is undef, L<kPasteboardFlavorNoFlags|/kPasteboardFlavorNoFlags>
is used.

In other words, this subroutine is more-or-less equivalent to

 $ pbcopy -pboard find

=head2 $encode = pbencode ();

=head2 $old_encode = pbencode ( $new_encode );

this convenience subroutine (b<not> method) returns the encode setting
for the system pasteboard. if the argument is defined and not c<''>, the
argument becomes the new encode setting and the old encode setting is
returned.

=head2 $encode = pbencode_find ();

=head2 $old_encode = pbencode_find ( $new_encode );

this convenience subroutine (b<not> method) returns the encode setting
for the 'find' pasteboard. if the argument is defined and not c<''>, the
argument becomes the new encode setting and the old encode setting is
returned.

=head2 $default_flavor = pbflavor ();

=head2 $old_default_flavor = pbflavor ( $new_default_flavor );

this convenience subroutine (b<not> method) returns the default data
flavor for the system pasteboard. if the argument is defined and not
c<''>, the argument becomes the new default flavor and the old default
flavor is returned.

=head2 $default_flavor = pbflavor_find ();

=head2 $old_default_flavor = pbflavor_find ( $new_default_flavor );

this convenience subroutine (b<not> method) returns the default data
flavor for the 'find' pasteboard. if the argument is defined and not
c<''>, the argument becomes the new default flavor and the old default
flavor is returned.

=head2 ($data, $flags) = pbpaste ($flavor)

This convenience subroutine (B<not> method) retrieves the given flavor
of data from the system clipboard, and its associated flavor flags. The
flavor is optional, the default being the L<default
flavor|/defaultFlavor>. If the given flavor is not found undef is
returned for $data.

The functionality is equivalent to calling paste() on an object whose
L<id|/id (integer)> attribute is undef.

If called in scalar context, you get $data.

In other words, this subroutine is more-or-less equivalent to the
'pbpaste' executable.

=head2 ($data, $flags) = pbpaste_find ($flavor)

This convenience subroutine (B<not> method) retrieves the given flavor
of data from the 'find' pasteboard, and its associated flavor flags. The
flavor is optional, the default being the L<default
flavor|/defaultFlavor>. If the given flavor is not found undef is
returned for $data.

The functionality is equivalent to calling paste() on an object whose
L<id|/id (integer)> attribute is undef.

If called in scalar context, you get $data.

In other words, this subroutine is more-or-less equivalent to

 $ pbpaste -pboard find

=head2 $pb = $pb->set ($name => $value ...)

This method sets the values of the given L<attributes|/ATTRIBUTES>. More
than one attribute can be set at a time. An exception is thrown if the
attribute does not exist, or if the attribute is read-only. The object
is returned, so that calls can be chained.

This method can also be called statically (that is, as
Mac::Pasteboard->set ($name => $value ...)). If an attribute does
something useful when set statically, its description will say so.
Setting other attributes statically is unsupported, at least in the
sense that the author makes no representation what will happen if you do
set them, and does not promise that whatever happens when you do this
will not change in the future.

=head2 $flags = $pb->synch ()

This method synchronizes the local copy of the pasteboard with the
global pasteboard, and returns the L<synchronization
flags|/Synchronization flags>. This B<should> be called on your behalf
when needed, but it is exposed because one of the flags returned says
whether the calling process owns the pasteboard.  For example:

 $pb->synch & kPasteboardClientIsOwner
     or $pb->clear ();

to take ownership of the pasteboard (by clearing it) if it is not
already owned by the process. Note that
L<kPasteboardClientIsOwner|/kPasteboardClientIsOwner> is not imported by
default.

=head2 @names = $pb->synch_flag_names ($flags)

This method (or subroutine) interprets its last argument as
synchronization flags (i.e. as the return from the synch() method), and
returns the names of the flags set. If none are set, you get an empty
list.

If called in scalar context you get back the names joined with ', ', or
an empty string if there are none, since there is no manifest constant
for synchronization flags that corresponds to
'kPasteboardFlavorNoFlags'.

=head1 ATTRIBUTES

The types of the attributes are specified in parentheses after their
names. Boolean attributes are interpreted in the Perl sense - that is,
C<undef>, C<0> and C<''> are false, and anything else is true.

This class supports the following attributes:

=head2 encode (boolean)

This attribute specifies whether or not certain flavors are to be
encoded into and decoded from the pasteboard. Supported flavors and the
encodings used are:

    public.utf8-plain-text           UTF-8
    public.utf16-plain-text          UTF-16LE
    public.utf16-external-plain-text UTF-16

Flavor C<com.apple.traditional-mac-plain-text> (the initial default
flavor) is not supported by this attribute because the normal encoding
is undocumented (ASCII? MacRoman? MacSomething depending on locale?).
When it has wide characters to handle it seems to get upgraded to
UTF-16LE, but how to tell when this is done is also undocumented.

=head2 default_flavor (string)

This attribute stores the name of the default flavor to use if a flavor
is not specified in the C<copy()> or C<paste()> call. The default value
of this attribute is C<defaultFlavor()>.

=head2 fatal (boolean)

If this attribute is true, any pasteboard error throws an exception. If
false, error codes are returned to the caller.

This attribute can be set statically, in which case it controls whether
static methods throw an exception on a pasteboard error. Currently, only
new() is affected by this; pbcopy() and friends are subroutines, not
static methods.

Setting this statically does B<not> affect the default value of this
attribute in an instantiated object.

The default is 1 (i.e. true).

=head2 id (integer)

This attribute supplies the id for data to be copied to or pasted from
the pasteboard. In addition to a non-negative integer, it can be set to
undef. See copy() and paste() for the effects of this attribute on their
action.  In most cases you will not need to change this.

The default is undef.

=head2 missing_ok (boolean)

If this attribute is true, paste() returns undef if the required flavor
is missing, rather than throwing an exception if 'fatal' is true. The
pbpaste() subroutine sets this true for the object it manufactures to
satisfy its request.

The default is 0 (i.e. false).

=head2 name (string, readonly)

This attribute reports the actual name assigned to the pasteboard. Under
Panther (Mac OS 10.3) it is the name passed to new (), or the name of
the system pasteboard if no name was passed in. Under Tiger (Mac OS
10.4) and above, the actual name is retrieved once the pasteboard is
created. If this name cannot be retrieved you get the same result as
under Panther.

This name may not be the name you used to create the
pasteboard, even if you used one of the built-in names. But unless you
created the pasteboard using name kPasteboardUniqueName, the name will
be equivalent. That is,

 my $pb1 = Mac::Pasteboard->new();
 my $pb2 = Mac::Pasteboard->new(
     $pb1->get('name'));

gives two handles to the same clipboard.

=head2 status (dualvar)

This attribute contains the status of the last operation. You can set
this with an integer; the dualvar will be generated.

The static attribute contains the status of the last static method to
operate on a pasteboard. Currently, this means the last call to new().

=head1 EXPORT

The pbcopy(), pbcopy_find(), pbpaste(), and pbpaste_find() subroutines
are exported by default. In addition, tag ':all' exports everything, and
tag ':const' exports all constants except those which must be exported
explicitly (currently only coreFoundationUnknownErr). Constants are also
accessible by &Mac::Pasteboard::constant_name. The following constants
are defined:

=head2 Error codes

=head3 badPasteboardFlavorErr

This constant represents the error number returned when a flavor is not
found on the pasteboard. It is not a dualvar -- it just represents the
number of the error, which is -25133.

=head3 duplicatePasteboardFlavorErr

This constant represents the error number returned when an attempt is
made to place in a pasteboard item a flavor that is already there.  It
is not a dualvar -- it just represents the number of the error, which is
-25134.

=head3 badPasteboardIndexErr

This constant represents the error number returned when the code indexes
off the end of the pasteboard. If you get it in use, it probably
represents a bug in this module, and should be reported as such. It is
not a dualvar -- it just represents the number of the error, which is
-25131.

=head3 badPasteboardItemErr

This constant represents the error number returned when the user
requests data from a non-existent item ID. It is not a dualvar -- it
just represents the number of the error, which is -25132.

=head3 badPasteboardSyncErr

This constant represents the error returned when the user tries to fetch
stale data from the pasteboard. Because this module is supposed to
synchronize before fetching, it represents either a bug or a race
condition. It is not a dualvar -- it just represents the number of the
error, which is -25130.

=head3 coreFoundationUnknownErr

This constant represents B<the> unknown error, not just B<an> unknown
error. One would think you would never get this from Apple's code, but
it appears that you will get this error if the caller does not have
access to the desktop. For example, you can get this error in a script
running over an ssh connection, or in a cron job.

B<This constant is not exported with the :const tag,> because there are
other places it could potentially come from. If you want it, you will
need to import it explicitly. It is not a dualvar -- it just represents
the number of the error, which is -4960.

=head3 noPasteboardPromiseKeeperErr

This constant represents the error returned when the user tries place
promised data on the pasteboard without first registering a promise
keeper callback. This package does not support promised data.
This constant is not a dualvar -- it just represents the number of the
error, which is -25136.

=head3 notPasteboardOwnerErr

This constant represents the error returned when the user tries place
data on the pasteboard without first becoming its owner by clearing it.
It is not a dualvar -- it just represents the number of the
error, which is -25135.

=head2 Flavor flags

=head3 kPasteboardFlavorNoFlags

This pasteboard flavor flag is really a value, to be used if no flags
are set.

=head3 kPasteboardFlavorNotSaved

This pasteboard flavor flag indicates that the flavor's data is
volatile, and should not be saved.

=head3 kPasteboardFlavorPromised

This pasteboard flavor flag indicates that the flavor's data is
promised. This module does not support creating promised data.

=head3 kPasteboardFlavorRequestOnly

This pasteboard flavor flag indicates that the flavor must be requested
explicitly; scanning for available flavors will not find it.

=head3 kPasteboardFlavorSenderOnly

This pasteboard flavor flag indicates that the flavor's data are only
available to the process that placed it on the pasteboard.

Oddly enough, the 'pbpaste' executable seems to be able to find such
data. But the Pasteboard Peeker demo application can not, so I am pretty
sure this module is working OK. Unfortunately I was unable to find the
source for pbpaste online, so I am unable to verify what's going on.

=head3 kPasteboardFlavorSenderTranslated

This pasteboard flavor flag indicates that the flavor's data has been
translated in some way by the process that placed it on the clipboard,
and it will not be saved by the Finder in clipping files.

=head3 kPasteboardFlavorSystemTranslated

This pasteboard flavor flag indicates that the flavor's data must be
translated by the Translation Manager. This flag cannot be set
programmatically, and the Finder will not save this data in clipping
files.

=head2 Pasteboard and flavor names

=head3 defaultFlavor

This constant represents the name of the default flavor,
'com.apple.traditional-mac-plain-text'.

=head3 kPasteboardClipboard

This constant represents the name of the system clipboard,
'com.apple.pasteboard.clipboard'.

=head3 kPasteboardFind

This constant represents the name of the find pasteboard,
'com.apple.pasteboard.find'.

=head3 kPasteboardUniqueName

This constant specifies that a unique name be generated for the
pasteboard. Under Mac OS 10.4 (Tiger) or above, the generated name will
be available in the L<name|/name (string, readonly)> attribute; under
Mac OS 10.3 (Panther), the generated name is unavailable, and the
L<name|/name (string, readonly)> attribute will be undef.

The value of this constant is documented as (CFStringRef) NULL, so it is
represented in Perl by undef.

=head2 Synchronization flags

=head3 kPasteboardClientIsOwner

This synchronization flag is true if the caller is the owner of the
pasteboard.

=head3 kPasteboardModified

This synchronization flag indicates that the pasteboard has been
modified since the last time this program accessed it, and the local
copy of the pasteboard has been synchronized.

=head1 BUGS

Please report bugs either through L<http://rt.cpan.org/> or by mail to
the author.

=head1 SEE ALSO

The B<Clipboard> module by Ryan King will access text on the clipboard
under most operating systems. Under Mac OS X, it shells out to the
I<pbpaste> and I<pbcopy> executables.

The I<pbpaste> and I<pbcopy> executables themselves are available, and
described by their respective man pages.

The I<Pasteboard Manager Reference> is available online at
L<http://developer.apple.com/documentation/Carbon/Reference/Pasteboard_Reference/Reference/reference.html>.
See also the I<Pasteboard Manager Programming Guide> at
L<http://developer.apple.com/documentation/Carbon/Conceptual/Pasteboard_Prog_Guide/>.

The I<Uniform Type Identifiers Overview> is available online at
L<http://developer.apple.com/documentation/Carbon/Conceptual/understanding_utis/>.

=head1 AUTHOR

Thomas R. Wyant, III, F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2011-2017 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
