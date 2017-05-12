package IO::Socket::TIPC::Sockaddr;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(looks_like_number);
use Exporter;

our @ISA = qw(Exporter);

=head1 NAME

IO::Socket::TIPC::Sockaddr - struct sockaddr_tipc class

=head1 SYNOPSIS

	use IO::Socket::TIPC::Sockaddr;


=head1 DESCRIPTION

TIPC Sockaddrs are used with TIPC sockets, to specify local or remote
endpoints for communication.  They are used in the B<bind>(),
B<connect>(), B<sendto>() and B<recvfrom>() calls.

Sockaddrs can be broken down into 3 address-types, I<"name">,
I<"nameseq"> and I<"id">. the I<Programmers_Guide.txt> (linked to in
B<REFERENCES>) explains the details much better than I ever could, I suggest
reading it before trying to use this module.  Also, the B<EXAMPLES> section
is useful for getting a feel for how this module works.

=cut


# Virtually this whole file is just hand-holding for the caller's benefit.
# 
# You can pass it strings like Id => "<a.b.c:d>", or Nameseq => "{a,b,c}".
# You can pass it the pieces, like AddrType => 'name', Type => 4242, Instance => 1.
# You can pass it a mixture of the two, like Id => "<a.b.c>", Ref => 8295.
# You can even omit the AddrType parameter, it'll guess from the other args.

# Passing the pieces (and specifying the AddrType) is the most efficient way to
# use this module, but not the most convenient, so other options exist.


sub divine_address_type {
	my $args = shift;
	# try to figure out what type of address this is.
	if(exists($$args{Type})) {
		if(exists($$args{Instance})) {
			$$args{AddrType} = 'name';
		}
		elsif(exists($$args{Lower})) {
			$$args{AddrType} = 'nameseq';
			$$args{Upper} = $$args{Lower}
				unless exists $$args{Upper};
		}
		elsif(exists($$args{Upper})) {
			$$args{AddrType} = 'nameseq';
			$$args{Lower} = $$args{Upper}
				unless exists $$args{Lower};
		}
	} elsif(exists($$args{Ref})) {
		$$args{AddrType} = 'id';
	} else {
		croak("could not guess AddrType - please specify it");
	}
	return 1;
}

my %valid_args = (
	'AddrType' => [qw(id name nameseq)], # 'id', 'name', or 'nameseq'
	'Scope'    => [qw(   name nameseq)], # TIPC_*_SCOPE, for binding, how far to advertise a name
	'Ref'      => [qw(id             )], # <a.b.c:D>
	'Id'       => [qw(id             )], # <A.B.C> (string or uint32) or <A.B.C:D> (string)
	'Zone'     => [qw(id             )], # <A.b.c:d>
	'Cluster'  => [qw(id             )], # <a.B.c:d>
	'Node'     => [qw(id             )], # <a.b.C:d>
	'Name'     => [qw(   name        )], # {A,B} (string)
	'Type'     => [qw(   name nameseq)], # {A,b} or {A,b,c}
	'Instance' => [qw(   name        )], # {a,B}
	'Domain'   => [qw(   name        )], # tipc_addr, connect/sendto, how far to search for a name
	'Lower'    => [qw(        nameseq)], # {a,B,c}
	'Upper'    => [qw(        nameseq)], # {a,b,C}
	'Nameseq'  => [qw(        nameseq)], # {A,B,C} (string)
);
	
sub validate_args_for_address_type {
	my $args = shift;
	my $addrtype = $$args{AddrType};
	# Validate hash-key arguments for this address type
	foreach my $key (sort keys %$args) {
		my $ref = $valid_args{$key};
		die "got here ($key)" unless defined $ref;
		my %valid = map { $_ => 1 } (@$ref);
		croak("argument $key not valid for AddrType $addrtype")
			unless exists($valid{$addrtype});
	}
	return 1;
}

sub fixup_hash_names {
	my $args = shift;
	# Validate hash-key arguments to IO::Socket::TIPC::Sockaddr->new()
	foreach my $key (sort keys %$args) {
		if(!exists($valid_args{$key})) {
			# This key needs to be fixed up.  Search for it.
			my $lckey = lc($key);
			my $fixed = 0;
			foreach my $goodkey (sort keys %valid_args) {
				if($lckey eq lc($goodkey)) {
					# Found it.  Fix it up.
					$$args{$goodkey} = $$args{$key};
					delete($$args{$key});
					$fixed = 1;
					last;
				}
			}
			croak("unknown argument $key")
				unless $fixed;
		}
	}
	return 1;
}

sub string_parsing_stuff {
	my $args = shift;
	my %details;
	if(exists($$args{Id})) {
		# just in case the user did Id => '<1.2.3>', Ref => 4, pass in the Ref
		$details{Ref} = $$args{Ref} if exists $$args{Ref};
		return undef unless tipc_parse_string(\%details,$$args{Id});
		$$args{Zone}    = $details{Zone};
		$$args{Cluster} = $details{Cluster};
		$$args{Node}    = $details{Node};
		$$args{Ref}     = $details{Ref} if exists($details{Ref});
	} elsif(exists($$args{Name})) {
		return undef unless tipc_parse_string(\%details,$$args{Name});
		$$args{Type}     = $details{Type};
		$$args{Instance} = $details{Instance};
	} elsif(exists($$args{Nameseq})) {
		return undef unless tipc_parse_string(\%details,$$args{Nameseq});
		$$args{Type}     = $details{Type};
		$$args{Lower}    = $details{Lower};
		$$args{Upper}    = $details{Upper};
	}
	if(exists($details{AddrType})) {
		$$args{AddrType} = $details{AddrType} unless exists $$args{AddrType};
	}
	return 1;
}

my %addr_prereqs = (
	'id'      => [qw(Zone Cluster Node Ref)],
	'name'    => [qw(Scope Type Instance)],
	'nameseq' => [qw(Scope Type Lower Upper)],
);

sub check_prereqs_for_address_type {
	my $args = shift;
	my $addrtype = $$args{AddrType};
	my $ref = $addr_prereqs{$addrtype};
	croak "got here ($addrtype)" unless defined $ref;
	foreach my $key (@$ref) {
		croak "addrtype $addrtype requires a $key value"
			unless exists($$args{$key});
	}
	1;
}



=head1 CONSTRUCTOR

	...->new ( "string", key=>value, key=>value... )
	...->new ( key=>value, key=>value... )
	...->new_from_data ( $binary_data )

Creates an "IO::Socket::TIPC::Sockaddr" object, which is really just a
bunch of fluff to manage C "struct sockaddr_tipc" values easily.

Use the B<new_from_data> constructor if you want to wrap this class
around some sockaddr_tipc data you obtained from somewhere else.
(for instance, from the B<getpeername> builtin.)

Use the B<new>() constructor to create a new sockaddr object.  It
optionally takes a string as its first argument.  Any other arguments
are in the form of Key => Value pairs.

=head2 Initial String Argument (optional)

You can pass any type of TIPC address as a string, to fill in most of
the below values for you.  This is a very useful way to save lots of
typing, and keeps it more readable.  Here is a list of possible string
arguments, and their hash-parameter equivalents:

	"<1.2.3:4>" is equivalent to:
		AddrType => TIPC_ADDR_ID,
		Zone     => 1,
		Cluster  => 2,
		Node     => 3,
		Ref      => 4

	"{1, 2}" is equivalent to:
		AddrType => TIPC_ADDR_NAME,
		Type     => 1,
		Instance => 2

	"{1, 2, 3}" is equivalent to:
		AddrType => TIPC_ADDR_NAMESEQ,
		Type     => 1,
		Lower    => 2,
		Upper    => 3

Of course, noone B<has> to spell the fields out in such excruciating
detail (you can pass the same strings in I<Id>/I<Name>/I<Nameseq>
parameters), but it illustrates my point nicely.

The string does not define everything useful about the address...
consider specifying the I<Scope> parameter for arguments to B<bind>,
and the I<Domain> parameter for I<name>s you plan to B<connect> to.


=head2 AddrType

This tells Sockaddr whether to create an I<id>, I<name> or I<nameseq>
address.  The default is guessed from the other arguments it was
given; pass the I<AddrType> argument to make it explicit.  In
practice, this is rarely (never?) needed.

If the right constants were imported, you can pass the following
arguments: I<TIPC_ADDR_ID>, I<TIPC_ADDR_NAME>, I<TIPC_ADDR_NAMESEQ>,
or I<TIPC_ADDR_MCAST> (which is an alias for I<TIPC_ADDR_NAMESEQ>).
Otherwise, you can just say I<"id">, I<"name"> or I<"nameseq">, these
will work equally well.


=head2 Scope

Valid for I<name> and I<nameseq> addresses.  Specifies how loudly to
advertise the name/nameseq, to the rest of the network.  The default
is I<TIPC_NODE_SCOPE>.

If the right constants were imported, you can pass the following
arguments: I<TIPC_ZONE_SCOPE>, I<TIPC_CLUSTER_SCOPE>, or
I<TIPC_NODE_SCOPE>.  Otherwise, you can just say I<"zone">,
I<"cluster"> or I<"node">, which will work equally well.


=head2 Id

Defines an I<id> address.  An I<id> address has the format
"<Zone.Cluster.Node:Ref>".  With the I<Id> parameter, you can specify
the "<Zone.Cluster.Node>" portion of that address, either with a
string (like "<1.2.3>") or as an unsigned 32-bit integer.
Alternately, you can define the whole thing, Ref included, as a
string (like "<1.2.3:4>").  This is a useful way to avoid having to
specify the I<Ref>, I<Zone>, I<Cluster>, and I<Node> parameters
individually.


=head2 Ref

Valid for I<id> addresses.  This 32-bit field is usually assigned
randomly by the operating system, and only needs to be set when you
are attempting to connect to someone else.


=head2 Zone

Valid for I<id> addresses.  This 8-bit field defines the I<Zone>
portion of the Id address.  See the I<Id> parameter.


=head2 Cluster

Valid for I<id> addresses.  This 12-bit field defines the
I<Cluster> portion of the Id address.  See the I<Id> parameter.


=head2 Node

Valid for I<id> addresses.  This 12-bit field defines the I<Node>
portion of the Id address.  See the I<Id> parameter.


=head2 Name

Defines a I<name> address.  A I<name> address comprises two fields,
I<Type> and I<Instance>, 32 bits each.  It has the format
"{Name, Instance}".  Name addresses also have a I<Domain> flag,
which is used in B<connect>ing, to specify where to start looking
for the server.

The I<Name> parameter is useful for defining a name address all in
one go (minus the I<Domain>).  Pass it a string, like "{1, 2}",
to avoid having to specify the I<Type> and I<Instance> parameters
individually.


=head2 Type

Required for I<name> and I<nameseq> addresses.  This 32-bit field
defines the I<Type> portion of the address.


=head2 Instance

Required for I<name> addresses.  This 32-bit field defines the
I<Instance> portion of the address.  


=head2 Domain

Valid for I<name> addresses.  This 32-bit field defines the starting
point, when searching for a server by name.  You can pass it an
integer, or a TIPC address string, of the form "<1.2.3>".


=head2 Nameseq

Defines a I<nameseq> address.  A I<nameseq> address comprises three
fields, I<Type>, I<Lower> and I<Upper>, 32 bits each.  The I<Lower>
and I<Upper> attributes define a range of I<Instance> values (see
I<Name>).

I<nameseq> addresses have the format "{Type, Lower, Upper}".

The I<Nameseq> parameter is useful for defining a nameseq address
all in one go.  Pass it a string, like "{1, 2, 3}", to avoid having
to specify the I<Type>, I<Lower> and I<Upper> parameters
individually.


=head2 Lower

Required for I<nameseq> addresses.  This 32-bit field defines the
lower end of an I<Instance> range.  If unspecified, it defaults to
I<Upper>, resulting in a "range" of 1.


=head2 Upper

Required for I<nameseq> addresses.  This 32-bit field defines the
upper end of an I<Instance> range.  If unspecified, it defaults to
I<Lower>, resulting in a "range" of 1.

=cut

sub new {
	my $package = shift;
	my %args = ();
	if(@_) {
		if(scalar @_ & 1) {
			return undef unless tipc_parse_string(\%args, shift);
		}
		%args = (%args, @_);
	}
	# sanity-check input, correct capitalization, make sure all keys are valid
	return undef unless fixup_hash_names(\%args);
	# handle things like Id => '<1.2.3:4>'
	return undef unless string_parsing_stuff(\%args); 
	unless(exists($args{AddrType})) {
		return undef unless divine_address_type(\%args);
	}
	# check that we don't have any extra values.  (like Name, for an "id" addr)
	return undef unless validate_args_for_address_type(\%args);
	# fill in some optional stuff
	if($args{AddrType} eq 'name') {
		if(exists($args{Domain})) {
			unless(looks_like_number($args{Domain})) {
				my $href = {};
				tipc_parse_string($href,$args{Domain});
				croak "Domain string should be an id!"
					unless $$href{AddrType} eq 'id';
				$args{Domain} = tipc_addr(@$href{'Zone','Cluster','Node'});
			}
		} else {
			$args{Domain} = 0;
		}
	}
	if(exists($args{Scope})) {
		my $scope = $args{Scope};
		my %valid_scopes = (
			IO::Socket::TIPC::TIPC_ZONE_SCOPE()    => 1,
			IO::Socket::TIPC::TIPC_CLUSTER_SCOPE() => 1,
			IO::Socket::TIPC::TIPC_NODE_SCOPE()    => 1,
		);
		my %scope_values = (
			zone    => IO::Socket::TIPC::TIPC_ZONE_SCOPE(),
			cluster => IO::Socket::TIPC::TIPC_CLUSTER_SCOPE(),
			node    => IO::Socket::TIPC::TIPC_NODE_SCOPE(),
		);
		unless(exists($valid_scopes{$scope})) {
			$args{Scope} = $scope_values{lc($scope)}
				if exists $scope_values{lc($scope)};
		}
		$scope = $args{Scope};
		croak("invalid Scope $scope")
			unless exists $valid_scopes{$scope};
	} else {
		$args{Scope}  = IO::Socket::TIPC::TIPC_NODE_SCOPE();
	}

	# check that we do have the arguments we need.
	return undef unless check_prereqs_for_address_type(\%args);
	my $sockaddr = _tipc_create();
	_tipc_fill_common($sockaddr, $args{Scope});
	if($args{AddrType} eq 'id') {
		_tipc_fill_id_pieces($sockaddr, @args{"Ref","Zone","Cluster","Node"});
	} elsif($args{AddrType} eq 'name') {
		_tipc_fill_name($sockaddr, @args{"Type","Instance","Domain"});
	} elsif($args{AddrType} eq 'nameseq') {
		_tipc_fill_nameseq($sockaddr, @args{"Type","Lower","Upper"});
	} else {
		croak("invalid AddrType $args{AddrType}");
	}
	return $sockaddr;
}

sub new_from_data {
	my ($package, $data) = @_;
	get_family(\$data); # this calls _sanity_check
	return bless(\$data, $package);
}


=head1 METHODS

=head2 stringify()

B<stringify> returns a string representing the sockaddr.  These
strings are the same as the ones used in the TIPC documentation,
see I<Programmers_Guide.txt> (linked to in B<REFERENCES>).  Depending
on the address type, it will return something that looks like one of:

	"<1.2.3:4>"        # ID, addr = 1.2.3, ref = 4
	"{4242, 100}"      # NAME, type = 4242, instance = 100
	"{4242, 100, 101}" # NAMESEQ, type = 4242, range 100-101

Note that these strings are intended for use as shorthand, with
someone familiar with TIPC.  They do not include all the fields of
the sockaddr structure, and sometimes the hidden fields are important.
In particular, they are missing the I<Scope> and I<Domain> fields,
which affect how far away binding/connecting may occur for I<name>s and
I<nameseq>s.  If you need to store an address for reuse, you are better
off reusing the Sockaddr object itself, rather than storing one of
these strings.

=head2 get/set routines

The C structure looks like this (minor edits for clarity):

	struct sockaddr_tipc {
	        unsigned short family;
	        unsigned char  addrtype;
	        signed   char  scope;
	        union {
	                struct {
	                	__u32 ref;
	                	__u32 node;
	                } id;
	                struct {
	                	__u32 type;
	                	__u32 lower;
	                	__u32 upper;
	                } nameseq;
	                struct {
	                        struct {
	                        	__u32 type;
	                        	__u32 instance;
	                        } name;
	                        __u32 domain;
	                } name;
	        } addr;
	};

Each of these fields has methods to get and set it.  The only
exception is "family", which is always set to I<AF_TIPC>, and
has very good reasons for being read-only.

An exhaustive list of these methods follows.  All functions return
integers, "val" means an unsigned integer argument, "<1.2.3>" means a
string-address argument (obviously).

=over

=item global stuff

	get_family()
	get_addrtype()    set_addrtype(val)
	get_scope()       set_scope(val)

=item TIPC_ADDR_ID stuff

	get_ref()         set_ref(val)
	get_id()          set_id(val)     or set_id("<1.2.3>")
	get_zone()        set_zone(val)
	get_cluster()     set_cluster(val)
	get_node()        set_node(val)

NOTE: for id-style addresses, direct access to the address as a whole (id) is
allowed, as well as its constituent components (zone, cluster, and node).
This may cause confusion, since the whole address is called "node" in the C
structure, but "node" refers to only a portion of the address here.


=item TIPC_ADDR_NAME stuff

	get_ntype()       set_ntype(val)
	get_instance()    set_instance(val)
	get_domain()      set_domain(val) or set_domain("<1.2.3>")

=item TIPC_ADDR_NAMESEQ stuff

	get_stype()       set_stype(val)
	get_lower()       set_lower(val)
	get_upper()       set_upper(val)

=item Type helpers

	get_type()        set_type(arg)

The B<get_type>/B<set_type> functions call either B<get_ntype>/B<set_ntype>,
or B<get_stype>/B<set_stype>, depending on whether the I<addrtype> is I<name>
or I<nameseq>.

=back

=cut

# NOTE: Most of the above accessor calls go straight to XS code.  The
# following subroutines are wrappers, to handle cases where I want to
# parse a string or something before it goes down to the XS layer.

# wrap set_domain: accept string-address arguments
sub set_domain {
	my ($self, $addr) = @_;
	unless(looks_like_number($addr)) {
		my $components = {};
		tipc_parse_string($components, $addr);
		croak "'domain' is an address field."
			unless $$components{AddrType} eq 'id';
		$addr = tipc_addr(@$components{'Zone', 'Cluster', 'Node'});
	}
	return $self->_tipc_set_domain($addr);
}

# wrap set_id: accept string-address arguments
sub set_id {
	my ($self, $addr) = @_;
	unless(looks_like_number($addr)) {
		my $components = {};
		tipc_parse_string($components, $addr);
		croak "'id' is an address field."
			unless $$components{AddrType} eq 'id';
		$addr = tipc_addr(@$components{'Zone', 'Cluster', 'Node'});
	}
	return $self->_tipc_set_id($addr);
}


=head1 SUBROUTINES (non-methods)

=head2 tipc_zone(int)

Unpacks the Zone from a TIPC address (integer).  You can also pass it a string
address, like "<1.2.3>".  Returns the zone as an integer.  Example below.

=cut

sub tipc_zone {
	my ($addr) = @_;
	unless(looks_like_number($addr)) {
		my $components = {};
		tipc_parse_string($components, $addr);
		croak "'zone' is an 'id' address field."
			unless $$components{AddrType} eq 'id';
		$addr = tipc_addr(@$components{'Zone', 'Cluster', 'Node'});
	}
	return _tipc_zone($addr);
}

=head2 tipc_cluster(int)

Unpacks the Cluster from a TIPC address (integer).  You can also pass it a
string address, like "<1.2.3>".  Returns the cluster as an integer.

	my $zone    = tipc_zone(0x01002003); # $zone    is now set to 1
	my $cluster = tipc_zone(0x01002003); # $cluster is now set to 2
	my $node    = tipc_zone(0x01002003); # $node    is now set to 3
	printf("<%i.%i.%i>\n",
	       $zone, $cluster, $node); # prints <1.2.3>

=cut

sub tipc_cluster {
	my ($addr) = @_;
	unless(looks_like_number($addr)) {
		my $components = {};
		tipc_parse_string($components, $addr);
		croak "'cluster' is an 'id' address field."
			unless $$components{AddrType} eq 'id';
		$addr = tipc_addr(@$components{'Zone', 'Cluster', 'Node'});
	}
	return _tipc_cluster($addr);
}

=head2 tipc_node(int)

Unpacks the Node from a TIPC address (integer).  You can also pass it a string
address, like "<1.2.3>".  Returns the node as an integer.  Example above.

=cut

sub tipc_node {
	my ($addr) = @_;
	unless(looks_like_number($addr)) {
		my $components = {};
		tipc_parse_string($components, $addr);
		croak "'node' is an 'id' address field."
			unless $$components{AddrType} eq 'id';
		$addr = tipc_addr(@$components{'Zone', 'Cluster', 'Node'});
	}
	return _tipc_node($addr);
}


=head2 tipc_addr(int)

Packs a zone, cluster and node into a tipc address.  You can also pass it
a "<1.2.3>" string address.

	my $addr = tipc_addr($zone, $cluster, $node);
	printf("0x%x\n", $addr); # prints 0x01002003

=cut

sub tipc_addr {
	my ($zone, $cluster, $node) = @_;
	unless(looks_like_number($zone)) {
		my $addr = $zone;
		my $components = {};
		tipc_parse_string($components, $addr);
		croak "this is not an 'id' address."
			unless $$components{AddrType} eq 'id';
		return _tipc_addr(@$components{'Zone', 'Cluster', 'Node'});
	}
	return _tipc_addr($zone, $cluster, $node);
}


=head2 tipc_parse_string(hashref, string)

Given a string that looks like "<1.2.3:4>", "<1.2.3>", "{1, 2}", or
"{1, 2, 3}", chop it into its components.  Puts the components into
appropriately named keys in hashref, like I<Zone>, I<Cluster>,
I<Node>, I<Ref>, I<Type>, I<Instance>, I<Upper>, I<Lower>.  It also
guesses the I<AddrType> of the string you passed.  Returns 1 on
success, croaks on error.

	my $href = {};
	tipc_parse_string($href, "<1.2.3:4>");
	printf("Address <%i.%i.%i:%i> is of type %s\n",
		 @$href{"Zone", "Cluster", "Node", "Ref", "AddrType"});
	# prints "Address <1.2.3:4> is of type id\n"

This is a function which B<new>() uses internally, to turn user
provided garbage into some values it can actually use.  There is
no need to call it directly, unless you want to use the same parser
for some other reason, like input checking.

=cut

sub tipc_parse_string {
	my ($args, $string) = @_;
	# we got a string.  we accept the following types of string:
	# ID:       '<a.b.c>'    (REF=0)
	# ID (dec): '12345'      (REF=0)
	# ID (hex): '0x01002003' (REF=0)
	# ID+REF:   '<a.b.c:d>' 
	# NAME:     '{a,b}'
	# NAMESEQ:  '{a,b,c}'
	my $valid = 0;
	# handle string ID+REF or string ID
	if($string =~ /^<(\d+)\.(\d+)\.(\d+)(:(\d+))?>$/) {
		$$args{AddrType} = 'id';
		$$args{Zone}     = $1;
		$$args{Cluster}  = $2;
		$$args{Node}     = $3;
		$$args{Ref}      = $5 if defined $5;
		$$args{Ref}      = 0 unless defined $$args{Ref};
		$valid           = 1;
	}
	# handle decimal ID
	if($string =~ /^(\d+)$/) {
		$$args{Zone}     = tipc_zone($1);
		$$args{Cluster}  = tipc_cluster($1);
		$$args{Node}     = tipc_node($1);
		printf(STDERR "dec: <%i.%i.%i>\n",@$args{'Zone','Cluster','Node'});
		$$args{AddrType} = 'id';
		$valid           = 1;
	}
	# handle hex ID
	if($string =~ /^0x([0-9a-fA-F]{1,8})$/) {
		$$args{Zone}     = tipc_zone(hex($1));
		$$args{Cluster}  = tipc_cluster(hex($1));
		$$args{Node}     = tipc_node(hex($1));
		$$args{AddrType} = 'id';
		$valid           = 1;
	}
	
	# handle string NAME
	if($string =~ /^\{(\d+),\s*(\d+)\}$/) {
		$$args{AddrType} = 'name';
		$$args{Type}     = $1;
		$$args{Instance} = $2;
		$valid           = 1;
	}
	# handle string NAMESEQ
	if($string =~ /^\{(\d+),\s*(\d+),\s*(\d+)\}$/) {
		$$args{AddrType} = 'nameseq';
		$$args{Type}     = $1;
		$$args{Lower}    = $2;
		$$args{Upper}    = $3;
		$valid           = 1;
	}
	croak("string argument '$string' is not a valid TIPC address.")
		unless($valid);
	return 1;
}

=head1 EXPORT

None by default.

=head2 Exportable subroutines

  tipc_addr
  tipc_zone
  tipc_cluster
  tipc_node
  tipc_parse_string

=cut

our @EXPORT    = qw();
our @EXPORT_OK = qw();

our %EXPORT_TAGS = ( 
	'all' => [ qw(
		tipc_addr tipc_zone tipc_cluster tipc_node tipc_parse_string
	) ]
);
Exporter::export_ok_tags('all');

1;
__END__

=head1 EXAMPLES

In TIPC, there are 3 types of sockaddrs.  Here are examples for all 3.

=head2 Name sockaddr: creation

You can use I<name> sockets in the following manner:

	$name = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "name",
		Type => 4242,
		Instance => 1005);

Or

	$name = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "name",
		Name => "{4242, 1005}");

Or, even

	$name = IO::Socket::TIPC::Sockaddr->new("{4242, 1005}");

With all address types, the B<stringify> method will return something
readable.

	$string = $name->stringify();
	# stringify returns "{4242, 1005}"


=head2 Nameseq sockaddr: creation

You can use I<nameseq> sockets in the following manner:

	$nameseq = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "nameseq",
		Type     => 4242,
		Lower    => 100,
		Upper    => 1000);

Or, more simply,

	$nameseq = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "nameseq",
		Name     => "{4242, 100, 1000}");

Or even just

	$nameseq = IO::Socket::TIPC::Sockaddr->new("{4242, 100, 1000}");

If I<Upper> is unspecified, it defaults to I<Lower>.  If I<Lower>
is unspecified, it defaults to I<Upper>.  You must specify at least
one.

	$nameseq = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "nameseq",
		Type => 4242,
		Lower => 100);

With all address types, the B<stringify> method will return something
readable.

	$string = $nameseq->stringify();
	# stringify returns "{4242, 100, 100}"


=head2 Id sockaddr: creation

You can use I<id> sockets in the following manner:

	$id = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "id",
		Zone     => 1,
		Cluster  => 2,
		Node     => 3,
		Ref      => 5000);

Or, more simply,

	$id = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "id",
		Id       => "<1.2.3>",
		Ref      => 5000);

Or, more simply,

	$id = IO::Socket::TIPC::Sockaddr->new(
		AddrType => "id",
		Id       => "<1.2.3:5000>");

Or even just

	$id = IO::Socket::TIPC::Sockaddr->new("<1.2.3:5000>");
		
With all address types, the B<stringify> method will return something
readable.

	$string = $id->stringify();
	# stringify returns "<1.2.3:5000>"


=head1 BUGS

Probably many.  Please report any bugs you find to the author.  A TODO file
exists, which lists known unimplemented and broken stuff.


=head1 REFERENCES

See also:

IO::Socket, Socket, IO::Socket::TIPC, http://tipc.sf.net/.
The I<Programmers_Guide.txt> is particularly helpful, and is available
off the SourceForge site.  See http://tipc.sf.net/doc/Programmers_Guide.txt,
or http://tipc.sf.net/documentation.html.


=head1 AUTHOR

Mark Glines <mark-tipc@glines.org>


=head1 COPYRIGHT AND LICENSE

This module is licensed under a dual BSD/GPL license, the same terms as TIPC
itself.
