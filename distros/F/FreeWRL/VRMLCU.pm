# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.


# Use the C routines..

use strict;
no strict "refs";

package VRML::CU;

use VRML::VRMLFunc;

VRML::VRMLFunc::load_data(); # Fill hashes.

sub alloc_struct {
	my($node) = @_;
	my $type = $node->{Type}{Name};
	if(!defined $VRML::CNodes{$type}) {
		return undef;
	}
	my $s = VRML::VRMLFunc::alloc_struct($VRML::CNodes{$type}{Offs}{_end_},
		$VRML::CNodes{$type}{Virt}
		);
	for(keys %{$node->{Fields}}) {
		# print "DO FIELD $_\n";
		my $o;
		if(!defined ($o=$VRML::CNodes{$type}{Offs}{$_})) {
			die("Field $_ undefined for $type in C");
		}
		# print "$node->{Fields}{$_} \n";
		&{"VRML::VRMLFunc::alloc_offs_$node->{Type}{FieldTypes}{$_}"}(
			$s, $o
		);
	}
	$node->{CNode} = $s;
}

sub alloc_struct_be {
	my($type) = @_;
	if(!defined $VRML::CNodes{$type}) {
		die("No CNode for $type\n");
	}
	# print "ALLNod: '$type' $VRML::CNodes{$type}{Offs}{_end_} $VRML::CNodes{$type}{Virt}\n";
	my $s = VRML::VRMLFunc::alloc_struct($VRML::CNodes{$type}{Offs}{_end_},
		$VRML::CNodes{$type}{Virt}
		);
	my($k,$o);
	while(($k,$o) = each %{$VRML::CNodes{$type}{Offs}}) {
		next if $k eq '_end_';
		my $ft = $VRML::Nodes{$type}{FieldTypes}{$k};
		# print "ALLS: $type $k $ft $o\n";
		&{"VRML::VRMLFunc::alloc_offs_$ft"}(
			$s, $o
		);
	}
	return $s;
}

sub free_struct_be {
	my($node,$type) = @_;
	if(!defined $VRML::CNodes{$type}) {
		die("No CNode for $type\n");
	}
	my($k,$o);
	while(($k,$o) = each %{$VRML::CNodes{$type}{Offs}}) {
		my $ft = $VRML::Nodes{$type}{FieldTypes}{$k};
		&{"VRML::VRMLFunc::free_offs_$ft"}(
			$node, $o
		);
	}
	VRML::VRMLFunc::free_struct($node)
}

sub set_field_be {
	my($node, $type, $field, $value) = @_;
	my $o;
	if(!defined ($o=$VRML::CNodes{$type}{Offs}{$field})) {
		die("Field $field undefined for $type in C");
	}
	if((ref $value) eq "HASH") {
		if(!defined $value->{CNode}) {
			print "UNABLE TO RETURN UNCNODED\n";
			return undef;
		}
		$value = $value->{CNode};
	}
	if((ref $value) eq "ARRAY" and (ref $value->[0]) eq "HASH") {
		$value = [map {$_->{CNode}} @{$value}];
	}
	my $ft = $VRML::Nodes{$type}{FieldTypes}{$field};
	my $fk = $VRML::Nodes{$type}{FieldKinds}{$field};
	# if($fk !~ /[fF]ield$/ and !defined $value) {return}
	print "SETS: $node $type $field '$value' (",(
		"ARRAY" eq ref $value ? join ',',@$value : $value ),") $ft $o\n"
		if $VRML::verbose::be && $field ne "__data";
	&{"VRML::VRMLFunc::set_offs_$ft"}(
		$node, $o, 
		$value
	);
}

sub set_c_value {
	my($node, $field) = @_;
	my $type = $node->{Type}{Name};
#	print "DO FIELD $field\n";
	my $o;
	if(!defined ($o=$VRML::CNodes{$type}{Offs}{$field})) {
		die("Field $field undefined for $type in C");
	}
	# print "$node->{Fields}{$field} \n";
	if("ARRAY" eq ref $node->{Fields}{$field}) {
		#print "C: ",(join ',',@{$node->{Fields}{$field}}),"\n";
	}
	# print "$node $node->{Type}{Name} $field $node->{Type}{FieldTypes}{$field}\n";
	my $val = $node->{Fields}{$field};
	if((ref $val) =~ /Node$/) {
		if(!defined $val->{CNode}) {
			print "UNABLE TO RETURN UNCNODED\n";
			return undef;
		}
		$val = $val->{CNode};
	}
	&{"VRML::VRMLFunc::set_offs_$node->{Type}{FieldTypes}{$field}"}(
		$node->{CNode}, $o, 
		$val
	);
}

sub make_struct {
	my($node) = @_;
#	print "K: ",(join ',',keys %{$node->{Fields}}),"\n";
	if(!defined $node->{CNode}) {
		alloc_struct($node);
	}
	for(keys %{$node->{Fields}}) {
		set_c_value($node,$_);
	}
}

1;
