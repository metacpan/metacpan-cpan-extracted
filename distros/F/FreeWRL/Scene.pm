# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Scene.pm
#
# Implement a scene model, with the specified parser interface.


# The idea here has been to try to preserve as much as possible
# of the original file structure -- that may not be the best approach
# in the end, but all dependencies on that decision should be in this file.
# It would be pretty easy, therefore, to write a new version that would
# just discard the original structure (USE, DEF, IS).
#
# At some point, this file should be redone so that it uses softrefs
# for circular data structures.

use strict vars;

#######################################################
#
# The FieldHash
#
# This is the object behind the "RFields" hash member of
# the object VRML::Node. It allows you to send an event by
# simply saying "$node->{RFields}{xyz} = [3,4,5]" for which 
# calls the STORE method here which then queues the event.
#
# XXX This needs to be separated into eventins and eventouts --
# assigning has different meanings.

package VRML::FieldHash;
@VRML::FieldHash::ISA=Tie::StdHash;

sub TIEHASH {
	my($type,$node) = @_;
	bless \$node, $type;
}

{my %DEREF = map {($_=>1)} qw/VRML::IS/;
my %REALN = map {($_=>1)} qw/VRML::DEF VRML::USE/;
sub FETCH {
	my($this, $k) = @_;
	my $node = $$this;
	my $v = $node->{Fields}{$k};
	if($VRML::verbose::tief) {
		print "TIEH: FETCH $k $v\n" ;
		if("ARRAY" eq ref $v) {
			print "TIEHARRVAL: @$v\n";
		}
	}
	# while($DEREF{ref $v}) {
	# 	$v = ${$v->get_ref};
	# 	print "DEREF: $v\n" if $VRML::verbose::tief;
	# }
	while($REALN{ref $v}) {
		$v = $v->real_node;
		print "TIEH: MOVED TO REAL NODE: $v\n"
			if $VRML::verbose::tief;
	}
	if(ref $v eq "VRML::IS") {
		die("Is should've been dereferenced by now -- something's cuckoo");
	}
	return $v;
}

sub STORE {
	my($this, $k, $value) = @_;
	if($VRML::verbose::tief) {
		print "TIEH: STORE $k $value\n" ;
		if("ARRAY" eq ref $value) {
			print "TIEHARRVAL: @$value\n";
		}
	}
	my $node = $$this;
	my $v = \$node->{Fields}{$k};
	# while($DEREF{ref $$v}) {
	# 	$v = ${$v}->get_ref;
	# 	print "DEREF: $v\n" if $VRML::verbose::tief;
	# }
	$$v = $value;
	$node->{EventModel}->put_event($node, $k, $value);
	if(defined $node->{BackNode}) { $node->set_backend_fields($k);}
}
}

sub FIRSTKEY {
	return undef
}

#####################################################
#
# IS, DEF, USE, NULL
#
# The following packages implement some of the possible 
# structures in the VRML file.
#
# The implementation here may change for efficiency later.
# 
# However, the fact that we go through these does not usually
# make performance too bad since it only affects us when there
# are changes of the scene graph or IS'ed field values.
#

package VRML::IS;
sub new {bless [$_[1]],$_[0]}
sub copy {my $a = $_[0][0]; bless [$a], ref $_[0]}
sub make_executable {
	my($this,$scene,$node,$field) = @_;
}
sub iterate_nodes {
	my($this,$sub) = @_;
	&$sub($this);
}
sub name { $_[0][0] }
sub set_ref { $_[0][1] = $_[1] }
sub get_ref { if(!defined $_[0][1]) {die("IS not def!")} $_[0][1] }
sub initialize {()}

sub as_string {" IS $_[0][0] "}
 
package VRML::DEF;
sub new {bless [$_[1],$_[2]],$_[0]}
sub copy {(ref $_[0])->new($_[0][0], $_[0][1]->copy($_[1]))}
sub make_executable {
	$_[0][1]->make_executable($_[1]);
}
sub make_backend {
	return $_[0][1]->make_backend($_[1],$_[2]);
}
sub iterate_nodes {
	my($this,$sub,$parent) = @_;
	# print "ITERATE_NODES $this $this->[0]\n";
	&$sub($this,$parent);
	$this->[1]->iterate_nodes($sub,$parent);
}
sub name { return $_[0][0]; }
sub def { return $_[0][1]; }
sub get_ref { $_[0][1] }

sub real_node { return $_[0][1]->real_node($_[1]); }
sub initialize {()}

sub as_string {" DEF $_[0][0] ".$_[0][1]->as_string}

package VRML::USE;
sub new {bless [$_[1]],$_[0]}
sub copy {(ref $_[0])->new(@{$_[0]})}
sub make_executable {
}
sub set_used {
	my($this, $node) = @_;
	$this->[1] = $node;
}
sub make_backend {
	print "make_backend $_[0] $_[0][0] $_[0][1]\n" if $VRML::verbose::scene;
	return $_[0][1]->make_backend($_[1], $_[2]);
}
sub iterate_nodes {
	my($this,$sub,$parent) = @_;
	&$sub($this,$parent);
}
sub name { return $_[0][0]; }
sub real_node { return $_[0][1]->real_node($_[1]); }
sub get_ref { $_[0][1] }
sub initialize {()}

sub as_string {" USE $_[0][0] "}

package NULL; # ;)
sub make_backend {return ()}
sub make_executable {}
sub iterate_nodes {}
sub as_string {NULL}

###############################################################
#
# This is VRML::Node, the internal representation for a single
# node.

package VRML::Node;

sub new {
	my($type, $scene, $ntype, $fields,$eventmodel) = @_;
	print "new Node: $ntype\n" if $VRML::verbose::nodec;
	my %rf;
	my $this = bless {
		TypeName => $ntype,
		Fields => $fields,
		EventModel => $eventmodel,
		Scene => $scene,
	}, $type;
	tie %rf, VRML::FieldHash, $this;
	$this->{RFields} = \%rf;
	my $t;
	if(!defined ($t = $VRML::Nodes{$this->{TypeName}})) {
		# PROTO
		$this->{IsProto} = 1;
		$this->{Type} = $scene->get_proto($this->{TypeName});
	} else {
		# REGULAR
		$this->{Type} = $t;
	}
	$this->do_defaults();
	return $this;
}

# Construct a new Script node -- the Type argument is different
# and there is no way of this being a proto.
sub new_script {
	my($type, $scene, $stype, $fields, $eventmodel) = @_;
	print "new Node: $stype->{Name}\n" if $VRML::verbose::nodec;
	my %rf;
	my $this = bless {
		TypeName => $stype->{Name},
		Type => $stype,
		Fields => $fields,
		EventModel => $eventmodel,
		Scene => $scene,
	}, $type;
	tie %rf, VRML::FieldHash, $this;
	$this->{RFields} = \%rf;
	$this->do_defaults();
	return $this;
}

# Fill in nonexisting field values by the default values.
# XXX Maybe should copy?
sub do_defaults {
	my($this) = @_;
	for(keys %{$this->{Type}{Defaults}}) {
		if(!exists $this->{Fields}{$_}) {
			$this->{Fields}{$_} = $this->{Type}{Defaults}{$_};
		}
	}
}

sub as_string {
	my($this) = @_;
	my $s = " $this->{TypeName} { \n";
	for(keys %{$this->{Fields}}) {
		$s .= "\n $_ ";
		if("VRML::IS" eq ref $this->{Fields}{$_}) {
			$s .= $this->{Fields}{$_}->as_string();
		} else {
			$s .= "VRML::Field::$this->{Type}{FieldTypes}{$_}"->
				as_string($this->{Fields}{$_});
		}
	}
	$s .= "}\n";
	return $s;
}

# If this is a PROTO expansion, return the actual "physical" VRML
# node under it.
sub real_node {
	my($this, $proto) = @_;
	if(!$proto and $this->{IsProto}) {
		return $this->{ProtoExp}{Nodes}[0]->real_node;
	} else {
		return $this;
	}
}

# Return the initial events returned by this node.
sub get_firstevent {
	my($this,$timestamp) = @_;
	print "GFE $this $this->{TypeName} $timestamp\n" if $VRML::verbose;
	if($this->{Type}{Actions}{ClockTick}) {
		print "ACT!\n" if $VRML::verbose;
		my @ev = &{$this->{Type}{Actions}{ClockTick}}($this, $this->{RFields},
			$timestamp);
		for(@ev) {
			$this->{Fields}{$_->[1]} = $_->[2];
		}
		return @ev;
	}
	return ();
}

sub receive_event {
	my($this,$field,$value,$timestamp) = @_;
	if(!exists $this->{Fields}{$field}) {
		die("Invalid event received: $this->{TypeName} $field")
		unless($field =~ s/^set_// and
		       exists($this->{Fields}{$field})) ;
	}
	print "REC $this $this->{TypeName} $field $timestamp $value : ",
		("ARRAY" eq ref $value? (join ', ',@$value):$value),"\n" if $VRML::verbose::events;
	$this->{RFields}{$field} = $value;
	if($this->{Type}{Actions}{$field}) {
		print "RACT!\n" if $VRML::verbose;
		my @ev = &{$this->{Type}{Actions}{$field}}($this,$this->{RFields},
			$value,$timestamp);
		for(@ev) {
			$this->{Fields}{$_->[1]} = $_->[2];
		}
		return @ev;
	}  elsif($this->{Type}{Actions}{__any__}) {
		my @ev = &{$this->{Type}{Actions}{__any__}}(
			$this,
			$this->{RFields},
			$value,
			$timestamp,
			$field,
		);
		# XXXX!!!???
		for(@ev) {
			$this->{Fields}{$_->[1]} = $_->[2];
		}
		return @ev;
	} elsif ($VRML::Nodes::bindable{$this->{TypeName}} 
			and $field eq "set_bind") {
		my $scene = $this->get_global_scene();
		$scene->set_bind($this, $value, $timestamp);
		return ();
	} else {
		# Ignore event
	}
}

# Get the outermost scene we are in
sub get_global_scene {
	my($this) = @_;
	return $this->{Scene}->get_scene();
}

sub events_processed {
	my($this,$timestamp,$be) = @_;
	print "EP: $this $this->{TypeName} $timestamp $be\n" if $VRML::verbose;
	if($this->{Type}{Actions}{EventsProcessed}) {
		print "PACT!\n" if $VRML::verbose;
		return &{$this->{Type}{Actions}{EventsProcessed}}($this, 
			$this->{RFields},
			$timestamp);
	}
	if($this->{BackNode}) {
		$this->set_backend_fields();
	}
}

# Copy a deeper struct
sub ccopy {
	my($v,$scene) = @_;
	if(!ref $v) { return $v }
	elsif("ARRAY" eq ref $v) { return [map {ccopy($_,$scene)} @$v] }
	else { return $v->copy($scene) }
}

# Copy me
sub copy {
	my($this, $scene) = @_;
	my $new = {};
	$new->{Type} = $this->{Type};
	$new->{TypeName} = $this->{TypeName};
	$new->{EventModel} = $this->{EventModel} ;
	my %rf;
	$new->{IsProto} = $this->{IsProto};
	tie %rf, VRML::FieldHash, $new;
	$new->{RFields} = \%rf;
	for(keys %{$this->{Fields}}) {
		my $v = $this->{Fields}{$_};
		$new->{Fields}{$_} = ccopy($v,$scene);
	}
	$new->{Scene} = $scene;
	return bless $new,ref $this;
}

sub iterate_nodes {
	my($this, $sub,$parent) = @_;
	print "ITERATE_NODES $this $this->{TypeName} %{$this->{Fields}}\n" if $VRML::verbose::scene;
	&$sub($this,$parent);
	for(keys %{$this->{Fields}}) {
		if($this->{Type}{FieldTypes}{$_} =~ /SFNode$/) {
			print "FIELDI: SFNode\n" if $VRML::verbose::scene;
			$this->{Fields}{$_}->iterate_nodes($sub,$this);
		} elsif($this->{Type}{FieldTypes}{$_} =~ /MFNode$/) {
			print "FIELDT: MFNode\n" if $VRML::verbose::scene;
			my $ref = $this->{RFields}{$_};
			for(@$ref) {
				$_->iterate_nodes($sub,$this);
			}
		} else {
		}
	}
}

sub make_executable {
	my($this,$scene) = @_;
	print "MKEXE $this->{TypeName}\n"
		if $VRML::verbose::scene;
	for(keys %{$this->{Fields}}) {
		# First, get ISes values
		if( ref $this->{Fields}{$_} eq "VRML::IS" ) {
			my $n = $this->{Fields}{$_}->name;
			$this->{Fields}{$_} =
				$scene->make_is($this, $_, $n);
		} 
		# Then, make the elements executable
		if(ref $this->{Fields}{$_} and
		   "ARRAY" ne ref $this->{Fields}{$_}) {
			# print "EFIELDT: SFReference\n";
			$this->{Fields}{$_}->make_executable($scene,
				$this, $_);
		} elsif( $this->{Type}{FieldTypes}{$_} =~ /^MF/) {
			# print "EFIELDT: MF\n";
			my $ref = $this->{RFields}{$_};
			for (@$ref)
			 {
			 	$_->make_executable($scene)
				 if(ref $_ and "ARRAY" ne ref $_);
			 } 
		} else {
			# Nada
		}
	}
	if($this->{IsProto} && !$this->{ProtoExp}) {
		# print "MAKE_EXECUTABLE_PROTOEXP $this $this->{TypeName}
		#	$this->{Type} $this->{Type}{Name}\n";
		print "COPYING $this->{Type} $this->{TypeName}\n"
			if $VRML::verbose::scene;
		$this->{ProtoExp} = $this->{Type}->get_copy();
		# print "MAKE_EXECUTABLE_PROTOEXP_EXP $this->{ProtoExp}\n";
		$this->{ProtoExp}->set_parentnode($this,$scene);
		$this->{ProtoExp}->make_executable();
	} 
	print "END MKEXE $this->{TypeName}\n"
		if $VRML::verbose::scene;
}

sub initialize {
	my($this,$scene) = @_;
# Inline is initialized at make_backend
	if($this->{Type}{Actions}{Initialize}
	 && $this->{TypeName} ne "Inline") {
		return &{$this->{Type}{Actions}{Initialize}}($this,$this->{RFields},
			(my $timestamp=XXX), $this->{Scene});
		# XXX $this->{Scene} && $scene ??
	}
	return ()
}

sub set_backend_fields {
	my($this, @fields) = @_;
	my $be = $this->{BackEnd};
	if(!@fields) {@fields = keys %{$this->{Fields}}}
	my %f;
	for(@fields) {
		my $v = $this->{RFields}{$_};
		print "SBEF: $this $_ '",("ARRAY" eq ref $v ?
			(join ' ,',@$v) : $v),"' \n" if 
				$VRML::verbose::be && $_ ne "__data";
		if($this->{Type}{FieldTypes}{$_} =~ /SFNode$/) {
			print "SBEF: SFNODE\n" if $VRML::verbose::be;
			$f{$_} = $v->make_backend($be);
		} elsif($this->{Type}{FieldTypes}{$_} =~ /MFNode$/) {
			print "SBEF: MFNODE @$v\n" if $VRML::verbose::be;
			$f{$_} = [
				map {$_->make_backend($be)} @{$v}
			];
			print "MFNODE GOT $_: @{$f{$_}}\n" if $VRML::verbose::be;
		} else {
			$f{$_} = $v;
		}
	}
	$be->set_fields($this->{BackNode},\%f);
}

{
my %NOT = map {($_=>1)} qw/WorldInfo TimeSensor TouchSensor
	ScalarInterpolator ColorInterpolator
	PositionInterpolator
	OrientationInterpolator
	CoordinateInterpolator
	NavigationInfo
	PlaneSensor
	SphereSensor
	CylinderSensor
	VisibilitySensor
	Collision
	/;

sub make_backend {
	my($this,$be,$parentbe) = @_;
	print "Node::make_backend $this $this->{TypeName}\n" if $VRML::verbose::be;
	if(defined $this->{BackNode}) {return $this->{BackNode}}
	if($this->{TypeName} eq "Inline") {
		&{$this->{Type}{Actions}{Initialize}}($this,$this->{RFields},
			(my $timestamp=XXX), $this->{Scene});
	}
	if($NOT{$this->{TypeName}} or $this->{TypeName} =~ /^__script/) {
		print "NODE: makebe NOT\n" if $VRML::verbose::be;
		return ();
	}
	if($this->{IsProto}) {
		print "NODE: makebe PROTO\n" if $VRML::verbose::be;
		return $this->{ProtoExp}->make_backend($be,$parentbe);
	}
	my $ben = $be->new_node($this->{TypeName});
	$this->{BackNode} = $ben;
	$this->{BackEnd} = $be;
	$this->set_backend_fields();
	return $ben;
}
}

#######################################################################
#
# VRML::Scene
#  this package represents a scene or a prototype definition/copy of it.
#

package VRML::Scene;
#
# Pars - parameters for proto, hashref
# Nodes - arrayref of toplevel nodes
# Protos - hashref of prototypes
# Routes - arrayref of routes [from,fromf,to,tof]
#
# Expansions:
#  - expand_protos = creates actual copied nodes for all prototypes
#    the copied nodes are stored in the field ProtoExp of the Node
#    
#  - expand_usedef

sub new {
	my($type,$eventmodel,$url) = @_;
	my $this = bless {
		EventModel => $eventmodel,
		URL => $url,
	},$type;
	print "Newscene $this\n" if $VRML::verbose::scene;
	return $this;
}

sub set_url {
	$_[0]{URL} = $_[1];
}

sub newp {
	my ($type,$pars,$parent,$name) = @_;
	my $this = $type->new;
	$this->{Pars} = $pars;
	$this->{Name} = $name;
# Extract the field types
	$this->{FieldTypes} = {map {$_ => $this->{Pars}{$_}[1]} keys %{$this->{Pars}}};
	$this->{FieldKinds} = {map {$_ => $this->{Pars}{$_}[0]} keys %{$this->{Pars}}};
	$this->{Parent} = $parent;
	$this->{EventModel} = $parent->{EventModel};
	$this->{Defaults} = {map {$_ => $this->{Pars}{$_}[2]} keys %{$this->{Pars}}};
	for(keys %{$this->{FieldKinds}}) {
		my $k = $this->{FieldKinds}{$_};
		if($k eq "exposedField") {
			$this->{EventOuts}{$_} = $_;
			$this->{EventOuts}{$_."_changed"} = $_;
			$this->{EventIns}{$_} = $_;
			$this->{EventIns}{"set_".$_} = $_;
		} elsif($k eq "eventIn") {
			$this->{EventIns}{$_} = $_;
		} elsif($k eq "eventOut") {
			$this->{EventOuts}{$_} = $_;
		} elsif($k ne "field") {
			die("Truly strange - shouldn't happen");
		}
	}
	return $this;
}

sub newextp {
	my ($type,$pars,$parent,$name) = @_;
	die("not yet");
	my $this = $type->new;
	$this->{Pars} = $pars;
	$this->{Name} = $name;
# Extract the field types
	$this->{FieldTypes} = {map {$_ => $this->{Pars}{$_}[1]} keys %{$this->{Pars}}};
	$this->{Parent} = $parent;
	$this->{EventModel} = $parent->{EventModel};
	$this->{Defaults} = {map {$_ => $this->{Pars}{$_}[2]} keys %{$this->{Pars}}};
	return $this;
}

##################################################################
#
# This is the public API for use of the parser or whoever..

{my $cnt;
sub new_node {
	my($this, $type, $fields) = @_;
	if($type eq "Script") {
		# Special handling for Script which has an interface.
		my $t = "__script__".$cnt++;
		my %f = 
		(url => [MFString, []],
		 directOutput => [SFBool, 0, ""], # not exposedfields
		 mustEvaluate => [SFBool, 0, ""]);
		for(keys %$fields) {
			$f{$_} = [
				$fields->{$_}[1],
				$fields->{$_}[2],
				$fields->{$_}[0],
			];
		}
		my $type = VRML::NodeType->new($t,\%f,
			$VRML::Nodes{Script}{Actions});
		my $node = VRML::Node->new_script(
			$this, $type, {}, $this->{EventModel});
		return $node;
	}
	my $node = VRML::Node->new($this,$type,$fields, $this->{EventModel});
	# Check if it is bindable and first -> bind to it later..
	if($VRML::Nodes::bindable{$type}) {
		if(!defined $this->{Bindable}{$type}) {
			$this->{Bindable}{$type} = $node;
		}
		push @{$this->{Bindables}{$type}}, $node;
	}
	return $node;
}
}

sub new_route {
	my $this = shift;
	print "NEW_ROUTE $_[0][0] $_[0][1] $_[0][2] $_[0][3]\n" if $VRML::verbose::scene;
	push @{$this->{Routes}}, $_[0];
}

sub new_def {
	my($this,$name,$node) = @_;
	print "NEW DEF $name $node\n" if $VRML::verbose::scene;
	my $def = VRML::DEF->new($name,$node);
	$this->{TmpDef}{$name} = $def;
	return $def;
}

sub new_use {
	my($this,$name) = @_;
	return VRML::USE->new($name, $this->{TmpDef}{$name});
}

sub new_is {
	my($this, $name) = @_;
	return VRML::IS->new($name);
}

sub new_proto {
	my($this,$name,$pars) = @_;
	print "NEW_PROTO $this $name\n" if $VRML::verbose::scene;
	my $p = $this->{Protos}{$name} = (ref $this)->newp($pars,$this,$name);
	return $p;
}

sub new_externproto {
	my($this,$name,$pars,$url) = @_;
	print "NEW_EXTERNPROTO $this $name\n";
	$this->{Protos}{$name} = (ref $this)->newextp($pars,$this,$name,$url);
}

sub topnodes {
	my($this,$nodes) = @_;
	$this->{Nodes} = $nodes;
	$this->{RootNode} = $this->new_node("Group",{children => $nodes});
}

sub get_proto {
	my($this,$name) = @_;
	print "GET_PROTO $this $name\n" if $VRML::verbose::scene;
	if($this->{Protos}{$name}) {return $this->{Protos}{$name}}
	if($this->{Parent}) {return $this->{Parent}->get_proto($name)}
	print "GET_PROTO_UNDEF $this $name\n" if $VRML::verbose::scene;
	return undef;
}

sub get_url {
	my($this) = @_;
	print "Get_url $this\n";
	if(defined $this->{URL}) {return $this->{URL}}
	if($this->{Parent}) {return $this->{Parent}->get_url()}
	die("Undefined URL tree");
}

sub get_scene {
	my($this) = @_;
	if($this->{Parent}) {return $this->{Parent}->get_scene()}
	return $this;
}

sub set_browser { $_[0]{Browser} = $_[1] }

sub get_browser {
	my($this) =@_;
	if($this->{Parent}) {return $this->{Parent}->get_browser()}
	return $this->{Browser};
}

########################################################
#
# Private functions again.

sub get_as_mfnode {
	return $_[0]{Nodes};
}

sub getNode {
	my $n = $_[0]{TmpDef}{$_[1]};
	if(!defined $n) {die("Node '$_[1]' not defined");}
	return $n->real_node(1); # Return proto enclosing node.
}

sub as_string {
	my($this) = @_;
	join "\n",map {$_->as_string} @{$this->{Nodes}};
}

# Construct a full copy of this scene -- used for protos.
# Note: much data is shared - problems?
sub get_copy {
	my($this,$name) = @_;
	my $new = bless {
	},ref $this;
	$new->{Pars} = $this->{Pars};
	$new->{FieldTypes} = $this->{FieldTypes};
	$new->{Nodes} = [map {$_->copy($new)} @{$this->{Nodes}}];
	$new->{EventModel} = $this->{EventModel};
	$new->{Routes} = $this->{Routes};
# XXX Done using the scene arg above..
#	$new->iterate_nodes(sub {
#		if(ref $_[0] eq "VRML::Node") {
#			$_[0]{Scene} = $new;
#		}
#	});
	return $new;
}

sub make_is {
	my($this, $node, $field, $is) = @_;
	my $retval;
	print "Make_is $this $node $node->{TypeName} $field $is\n"
		if $VRML::verbose::scene;
	my $pk = $this->{NodeParent}{Type}{FieldKinds}{$is} or
		die("IS node problem") ;
	my $ck = $node->{Type}{FieldKinds}{$field} or
		die("IS node problem 2");
	if($pk ne $ck and $ck ne "exposedField") {
		die("INCOMPATIBLE PROTO TYPES (XXX FIXME Error message)!");
	}
	# If child's a field or exposedField, get initial value
	print "CK: $ck, PK: $pk\n" if $VRML::verbose::scene;
	if($ck =~ /[fF]ield$/ and $pk =~ /[fF]ield$/) {
		print "SETV: $_ NP : '$this->{NodeParent}' '$this->{NodeParent}{Fields}{$_}'\n" if $VRML::verbose::scene;
		$retval=
		 "VRML::Field::$node->{Type}{FieldTypes}{$field}"->copy(
		 	$this->{NodeParent}{Fields}{$is}
		 );
	} else {
		$retval = $node->{Type}{Defaults}{$_};
	}
	# For eventIn, eventOut or exposedField, store for route
	# building.
	if($ck ne "field" and $pk ne "field") {
		if($pk eq "eventIn" or ($pk eq "exposedField" and
			$ck eq "exposedField")) {
			push @{$this->{IS_ALIAS_IN}{$is}}, [$node, $field];
		}
		if($pk eq "eventOut" or ($pk eq "exposedField" and
			$ck eq "exposedField")) {
			push @{$this->{IS_ALIAS_OUT}{$is}}, [$node, $field];
		}
	}
	return $retval;
}

#
# Here come the expansions:
#  - make executable: create copies of all prototypes.
#

sub iterate_nodes {
	my($this,$sub,$parent) = @_;
	# for(@{$this->{Nodes}}) {
	if($this->{RootNode}) {
		for($this->{RootNode}) {
			$_->iterate_nodes($sub,$parent);
		}
	} else {
		for(@{$this->{Nodes}}) {
			$_->iterate_nodes($sub,$parent);
		}
	}
}

sub iterate_nodes_all {
	my($this,$subfoo) = @_;
	# for(@{$this->{Nodes}}) {
	my @l; 
	if($this->{RootNode}) {@l = $this->{RootNode}}
	else {@l = @{$this->{Nodes}}}
	for(@l) {
		my $sub;
		$sub = sub {
			# print "ALLITER $_[0]\n";
			&$subfoo($_[0]);
			if(ref $_[0] eq "VRML::Node" and $_[0]->{ProtoExp}) {
				$_[0]->{ProtoExp}->iterate_nodes($sub);
			}
		};
		$_->iterate_nodes($sub);
		undef $sub;
	}
}

sub set_parentnode { $_[0]{NodeParent} = $_[1]; $_[0]{Parent} = $_[2] }

# XXX This routine is too static - should be split and executed
# as the scene graph grows/shrinks.
{
my %sends = map {($_=>1)} qw/
	TouchSensor TimeSensor
/;
sub make_executable {
	my($this) = @_;
	for(@{$this->{Nodes}}) {
		$_->make_executable($this);
	}
	# Give all ISs references to my data
	# print "MAKEEX $this\n";
	if($this->{NodeParent}) {
		# print "MAKEEXNOD\n";
		$this->iterate_nodes(sub {
			# print "MENID\n";
			return unless ref $_[0] eq "VRML::Node";
			for(keys %{$_[0]->{Fields}}) {
				# print "MENIDF $_\n";
				next unless ((ref $_[0]{Fields}{$_}) eq "VRML::IS");
				# print "MENIDFSET $_\n";
				$_[0]{Fields}{$_}->set_ref(
				  \$this->{NodeParent}{Fields}{
				  	$_[0]{Fields}{$_}->name});
			}
		});
	}
	# Gather all 'DEF' statements
	my %DEF;
	$this->iterate_nodes(sub {
		return unless ref $_[0] eq "VRML::DEF";
		# print "FOUND DEF ($this, $_[0]) ",$_[0]->name,"\n";
		$DEF{$_[0]->name} = $_[0]->def;
	});
	# Set all USEs
	$this->iterate_nodes(sub {
		return unless ref $_[0] eq "VRML::USE";
		# print "FOUND USE ($this, $_[0]) ",$_[0]->name,"\n";
		$_[0]->set_used($DEF{$_[0]->name});
	});
	$this->{DEF} = \%DEF;
	# Collect all prototyped nodes from here
	# so we can call their events
	$this->iterate_nodes(sub {
		return unless ref $_[0] eq "VRML::Node";
		push @{$this->{SubScenes}}, $_[0]
		 	if $_[0]->{ProtoExp};
		push @{$this->{Sensors}}, $_[0] 
			if $sends{$_[0]};
	});
}
}

sub make_backend {
	my($this,$be,$parentbe) = @_;
	if($this->{BackNode}) {return $this->{BackNode}}
	my $bn;
	if($this->{Parent}) {
		# I am a proto -- only my first node renders anything...
		print "Scene: I'm a proto $this $be $parentbe\n"
			if $VRML::verbose::scene;
		$bn = $this->{Nodes}[0]->make_backend($be,$parentbe);
	} else {
		print "Scene: I'm not proto $this $be $parentbe ($this->{IsInline})\n"
			if $VRML::verbose::scene;
		# I am *the* root node.
		# my $n = $be->new_node(Group);
		# $be->set_fields($n, {children => [
		# 	map { $_->make_backend($be,$n) } @{$this->{Nodes}}
		# 	]
		# });

		$bn = $this->{RootNode}->make_backend($be,$parentbe);

		$be->set_root($bn) unless $this->{IsInline};

		# print "MBESVP VIEWPOINT $this->{Bindable}{Viewpoint} $this->{Bindable}{Viewpoint}{BackNode}\n";
		# $be->set_viewpoint($this->{Bindable}{Viewpoint}{BackNode});
		# $bn = $n;
		my $nthvp = 0;
		$be->set_vp_sub(
			sub {
				my $p = $this->{Bindables}{Viewpoint};
				return if !@$p;
				$nthvp += $_[0];
				if($nthvp < 0) {$nthvp = $#$p};
				$nthvp = $nthvp % scalar @$p;
				$this->{EventModel}->send_event_to(
					$p->[$nthvp], set_bind, 1
				);
				print "GOING TO VP: '$p->[$nthvp]{Fields}{description}'\n";
			}
		);
	}
	$this->{BackNode} = $bn;
	return $bn;
}

# Events are generally in the format
#  [$scene, $node, $name, $value]

# XXX This routine is too static - should be split and executed
# But also: we can simply redo this every time the scenegraph
# or routes change. Of course, that's a bit overkill.

sub setup_routing {
	my($this,$eventmodel,$be) = @_;
	print "SETUP_ROUTING $this $eventmodel $be\n" if $VRML::verbose::scene;

	$this->iterate_nodes(sub {
		print "ITNOREF: $_[0]\n" if $VRML::verbose::scene;
		return unless "VRML::Node" eq ref $_[0];
		print "ITNO: $_[0] $_[0]->{TypeName} ($VRML::Nodes::initevents{$_[0]->{TypeName}})\n" if $VRML::verbose::scene;
		if($VRML::Nodes::initevents{$_[0]->{TypeName}}) {
			print "ITNO:FIRST $_[0]\n" if $VRML::verbose::scene;
			$eventmodel->add_first($_[0]);
		} else {
			if($_[0]{ProtoExp}) {
				 $_[0]{ProtoExp}->setup_routing(
				 	$eventmodel,$be) ;
			}
		}
		# Look at child nodes
		my $c;
		# for(keys %{$_[0]{Fields}}) {
		# 	if("VRML::IS" eq ref $_[0]{Fields}{$_}) {
		# 		$eventmodel->add_is($this->{NodeParent},
		# 			$_[0]{Fields}{$_}->name,
		# 			$_[0],
		# 			$_
		# 		);
		# 	}
		# }
		if(($c = $VRML::Nodes::children{$_[0]->{TypeName}})) {
			my $ref = $_[0]{RFields}{$c};
			print "CHILDFIELD: GOT @$ref FOR CHILDREN\n"
				if $VRML::verbose::scene;
			for(@$ref) {
				# XXX Removing/moving sensors?!?!
				my $n = $_->real_node();
				print "REALNODE: $n $n->{TypeName}\n"
					if $VRML::verbose::scene;
				if($VRML::Nodes::siblingsensitive{$n->{TypeName}}) {
					print "SES: $n $n->{TypeName}\n" if $VRML::verbose::scene;
					$be->set_sensitive(
						$_[0]->{BackNode},
						sub {
							$eventmodel->
							    handle_touched($n,
							    		@_);
						}
					);
				}
			}
		}
		if($VRML::Nodes::sensitive{$_[0]{TypeName}}) {
			$be->set_sensitive($_[0]->{BackNode},
				sub {},
			);
		}
	});
	print "DEVINED NODES in $this: ",(join ',',keys %{$this->{DEF}}),"\n" if $VRML::verbose::scene;
	for(@{$this->{Routes}}) {
		my($fnam, $ff, $tnam, $tf) = @$_;
		my ($fn, $tn) = map {
			print "LOOKING FOR $_ in $this\n" if $VRML::verbose::scene;
			$this->{DEF}{$_} or
			 die("Routed node name '$_' not found ($fnam, $ff, $tnam, $tf)!");
		} ($fnam, $tnam);
		$eventmodel->add_route($fn,$ff,$tn,$tf);
	}
	for my $isn (keys %{$this->{IS_ALIAS_IN}}) {
		for(@{$this->{IS_ALIAS_IN}{$isn}}) {
			$eventmodel->add_is_in($this->{NodeParent},
				$isn, @$_);
		}
	}
	for my $isn (keys %{$this->{IS_ALIAS_OUT}}) {
		for(@{$this->{IS_ALIAS_OUT}{$isn}}) {
			$eventmodel->add_is_out($this->{NodeParent},
				$isn, @$_);
		}
	}
}


# Send initial events
sub init_routing {
	my($this,$eventmodel, $backend, $no_bind) = @_;
	# XXX no_bind not used - I initialize all subnodes...
	my @e;

	print "INIT_ROUTING\n" if $VRML::verbose::scene;
	$this->iterate_nodes_all(sub { push @e, $_[0]->initialize($this); });

	for(keys %{$this->{Bindable}}) {
		print "INIT_BINDABLE '$_'\n" if $VRML::verbose::scene;
		$eventmodel->send_event_to($this->{Bindable}{$_},
			set_bind, 1);
	}

	$eventmodel->put_events(\@e);
}

sub set_bind {
	my($this, $node, $value, $time) = @_;
	my $t = $node->{TypeName};
	my $s = ($this->{Stack}{$t} or $this->{Stack}{$t} = []);
	print "SET_BIND! $this ($node $t $value), STACK #: $#$s\n"
		if $VRML::verbose::bind;
	if($value) {
		if($#$s != -1) {  # Do we have a stack?
			if($node == $s->[-1]) {
				print("Bind eq, ign\n")
					if $VRML::verbose::bind;
			}
			my $i;
			for(0..$#$s) {
				if($s->[$_] == $node) {$i = $_}
			}
			print "WAS AS '$i'\n"
				if $VRML::verbose::bind;
			$s->[-1]->{RFields}{isBound} = 0;
			if($s->[-1]->{Type}{Actions}{WhenUnBound}) {
				&{$s->[-1]->{Type}{Actions}{WhenUnBound}}($s->[-1],$this);
			}
			if(defined $i) {
				splice @$s, $i, 1;
			}
		}
		$node->{RFields}{bindTime} = $time;
		$node->{RFields}{isBound} = 1;
		if($node->{Type}{Actions}{WhenBound}) {
			&{$node->{Type}{Actions}{WhenBound}}($node,$this,0);
		}
		print "PUSHING $node on $s\n" if $VRML::verbose::bind;
		push @$s, $node;
	} else {
		# We're unbinding a node.
		print "UNBINDING IT!\n"
			if $VRML::verbose::bind;
		if($node == $s->[-1]) {
			print "WAS ON TOP!\n"
				if $VRML::verbose::bind;
			$node->{RFields}{isBound} = 0;
			if($node->{Type}{Actions}{WhenUnBound}) {
				&{$node->{Type}{Actions}{WhenUnBound}}($node,$this);
			}
			pop @$s;
			if(@$s) {
				$s->[-1]->{RFields}{isBound} = 1;
				$s->[-1]->{RFields}{bindTime} = $time;
				if($s->[-1]->{Type}{Actions}{WhenBound}) {
					&{$s->[-1]->{Type}{Actions}{WhenBound}}($s->[-1],$this,1);
				}
			}
		} else {
			my $i;
			for(0..$#$s) {
				if($s->[$_] == $node) {$i = $_}
			}
			print "WAS AS '$i'\n"
				if $VRML::verbose::bind;
			if(defined $i) {
				splice @$s, $i, 1;
			}
		}
	}
}

1;


