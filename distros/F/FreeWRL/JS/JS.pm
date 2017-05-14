# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

package VRML::JS;
require DynaLoader;
@ISA=DynaLoader;
bootstrap VRML::JS;
use strict qw/vars/;
use vars qw/%Types/;

if($VRML::verbose::js) {
	set_verbose(1);
}

# Unlike with the Java interface, we have one object per script
# for javascript.

init(); # C-level init

%Types = (
	SFBool => sub {$_[0] ? "true" : "false"},
	SFFloat => sub {$_[0]+0},
	SFTime => sub {$_[0]+0},
	SFInt32 => sub {$_[0]+0},
	SFString => sub {'"'.$_[0].'"'}, # XXX
	SFNode => sub {'new SFNode("","'.(VRML::Handles::reserve($_[0])).'")'},
);

sub new {
	my($type,$text,$node,$browser) = @_;
	my $this = bless { },$type;
	$this->{GLO} = "";
	$this->{CX} = newcontext($this->{GLO},$this);
	$this->{Node} = $node;
	$this->{Browser} = $browser;
	print "START JS $text\n" if $VRML::verbose::js;
	my $rs;
	print "INITIALIZE $this->{CX} $this->{GLO}\n" if $VRML::verbose::js;
	# Create default functions 
	runscript($this->{CX}, $this->{GLO}, 
		"function initialize() {} function shutdown() {}
		 function eventsProcessed() {} TRUE=true; FALSE=false; ", $rs);
	print "TEXT $this->{CX} $this->{GLO}\n" if $VRML::verbose::js;
	runscript($this->{CX}, $this->{GLO}, $text, $rs);
# Initialize fields.
	my $t = $node->{Type};
	my @k = keys %{$t->{Defaults}};
	print "TY: $t\n" if $VRML::verbose::js;
	print "FIELDS\n" if $VRML::verbose::js;
	for(@k) {
		next if $_ eq "url" or $_ eq "mustEvaluate" or $_ eq "directOutput";
		my $type = $t->{FieldTypes}{$_};
		my $ftype = "VRML::Field::$type";
		print "CONSTR FIELD $_\n" if $VRML::verbose::js;
		if($t->{FieldKinds}{$_} eq "field" or
  		   $t->{FieldKinds}{$_} eq "eventOut") {
			print "JS FIELD $_\n" if $VRML::verbose::js;
			if($Types{$type}) {
				addwatchprop($this->{CX},$this->{GLO},
					$_);
			} else {
				addasgnprop($this->{CX},$this->{GLO},
				    $_, $ftype->js_default);
			}
			if($t->{FieldKinds}{$_} eq "field") {
				my $value = $node->{RFields}{$_};
				print "JS FIELDPROP $_\n" if $VRML::verbose::js;
				if($Types{$type}) {
					print "SET_TYPE $_ '$value'\n" if $VRML::verbose::js;
					my $v = runscript($this->{CX}, $this->{GLO}, 
					  "$_=".$Types{$type}->($value), $rs);
				} else {
					$this->set_prop($_, $value, $_);
				}
			}
			print "CONED\n" if $VRML::verbose::js;
		} elsif($t->{FieldKinds}{$_} eq "eventIn") {
			if($Types{$type}) {
			} else {
				addasgnprop($this->{CX},$this->{GLO},
				    "__tmp_arg_$_", $ftype->js_default);
			}
		} else {
			warn("INVALID FIELDKIND '$_' for $node->{TypeName}");
		}
	}
	# Ignore all events we may have sent while building
	$this->gathersent(1);
	return $this;
}

sub initialize {
	my($this) = @_;
	my $rs;
	runscript($this->{CX}, $this->{GLO}, "initialize()", $rs);
	$this->gathersent();
}

sub sendevent {
	my($this,$node,$event,$value,$timestamp) = @_;
	my $rs;
	my $typ = $node->{Type}{FieldTypes}{$event};
	print "JS: receive event $node $event $value $timestamp ($typ)\n"
		if $VRML::verbose::js;
	my $aname = "__tmp_arg_$event";
	$this->set_prop($event,$value,$aname);
	runscript($this->{CX}, $this->{GLO}, "$event($aname,$timestamp)", $rs);
	return $this->gathersent();

	unless($Types{$typ}) {
		&{"set_property_$node->{Type}{FieldTypes}{$event}"}(
			$this->{CX}, $this->{GLO}, "__evin", $value);
		runscript($this->{CX}, $this->{GLO}, "$event(__evin,$timestamp)", $rs);
	} else {
		print "JS sendevent $event $timestamp\n".
			"$event(".$Types{$typ}->($value).",$timestamp)\n"
				if $VRML::verbose::js;
		my $v = runscript($this->{CX}, $this->{GLO}, 
			"$event(".$Types{$typ}->($value).",$timestamp)", $rs);
		print "GOT: $v $rs\n"
			if $VRML::verbose::js;
	}
	$this->gathersent();
}

sub sendeventsproc {
	my($this) = @_;
	my $rs;
	runscript($this->{CX}, $this->{GLO}, "eventsProcessed()", $rs);
	$this->gathersent();
}

sub gathersent {
	my($this, $ignore) = @_;
	my $node = $this->{Node};
	my $t = $node->{Type};
	my @k = keys %{$t->{Defaults}};
	my @a;
	my $rs;
	for(@k) {
		next if $_ eq "url";
		my $type = $t->{FieldTypes}{$_};
		my $ftyp = $type;
		if($t->{FieldKinds}{$_} eq "eventOut") {
			print "JS EOUT $_\n"
				if $VRML::verbose::js;
			my $v;
			if($type =~ /^MF/) {
				$v = runscript($this->{CX},$this->{GLO},
					"$_.__touched_flag",$rs);
				runscript($this->{CX},$this->{GLO},
					"$_.__touched_flag = 0",$rs);
			} elsif($Types{$ftyp}) {
				$v = runscript($this->{CX},$this->{GLO},
					"_${_}_touched",$rs);
				runscript($this->{CX},$this->{GLO},
					"_${_}_touched = 0",$rs);
				# print "SIMP_TOUCH $v\n";
			} else {
				$v = runscript($this->{CX},$this->{GLO},
					"$_.__touched()",$rs);
			}
			print "GOT $v $rs $_\n"
				if $VRML::verbose::js;
			if($v && !$ignore) {
				push @a, [$node, $_,
					$this->get_prop($type,$_)];
			}
		}
		# $this->{O}->print("$t->{FieldKinds}{$_}\n
	}
	return @a;
}

sub set_prop { # Assigns a value to a property.
	my($this,$field,$value,$prop) = @_;
	my $typ = $this->{Node}{Type};
	my $ftyp;
	if($field =~ s/^____//) { # recurse hack
		$ftyp = $field;
	} else {
		$ftyp = $typ->{FieldTypes}{$field};
	}
	my $rs;
	my $i;
	if($ftyp =~ /^MF/) {
		my $styp = $ftyp; $styp =~ s/^MF/SF/;
		for($i=0; $i<$#{$value}; $i++) {
			$this->set_prop("____$styp", $value->[$i], "____tmp");
			runscript($this->{CX}, $this->{GLO},
				"$prop"."[$i] = ____tmp");
		}
		runscript($this->{CX},$this->{GLO},
		  "$prop.__touched_flag = 0",$rs);
	} elsif($Types{$ftyp}) {
		runscript($this->{CX},$this->{GLO}, 
			"$prop = ".(&{$Types{$ftyp}}($value)),
			$rs);
		runscript($this->{CX},$this->{GLO},"_${prop}__touched=0",$rs);
	} else {
		print "set_property_ CALL: $ftyp $prop $value\n"
			if $VRML::verbose::js;
		&{"set_property_$ftyp"}(
			$this->{CX}, $this->{GLO}, $prop, $value);
		runscript($this->{CX},$this->{GLO},"$prop.__touched()",$rs);
	}
}

sub get_prop {
	my($this,$type,$prop) = @_;
	my $rs;
	print "RS2: $rs\n"
		if $VRML::verbose::js;
	if($type =~ /^SFNode$/) {
		runscript($this->{CX},$this->{GLO},
			"$prop.__id",$rs);
		return VRML::Handles::get($rs);
	} elsif ($type =~ /^MFNode$/) {
		my $l = runscript($this->{CX},$this->{GLO},
			"$prop.length",$rs);
		print "LENGTH: $l, '$rs'\n"
			if $VRML::verbose::js;
		my $fn = $prop;
		my @res = map {
		     runscript($this->{CX},$this->{GLO},
			"$fn",$rs);
		     print "Just mfnode: '$rs'\n"
		     	if $VRML::verbose::js;
		     runscript($this->{CX},$this->{GLO},
			"$fn"."[$_]",$rs);
		     print "Just node: '$rs'\n"
		     	if $VRML::verbose::js;
		     runscript($this->{CX},$this->{GLO},
			"$fn"."[$_][0]",$rs);
		     print "Just node[0]: '$rs'\n"
		     	if $VRML::verbose::js;
		     runscript($this->{CX},$this->{GLO},
			"$fn"."[$_].__id",$rs);
		     print "MFN: Got '$rs'\n"
		     	if $VRML::verbose::js;
		     VRML::Handles::get($rs);
		} (0..$l-1);
		return \@res;
	} elsif ($type =~ /^MFString$/) {
		my $l = runscript($this->{CX},$this->{GLO},
			"$prop.length",$rs);
		my $fn = $prop;
		my @res = map {
		     runscript($this->{CX},$this->{GLO},
			"$fn"."[$_]",$rs);
		     $rs
		} (0..$l-1);
		return \@res;
	}elsif($type =~ /^MF/) {
		my $l = runscript($this->{CX},$this->{GLO},
			"$prop.length",$rs);
		print "LENGTH: $l, '$rs'\n"
			if $VRML::verbose::js;
		my $fn = $prop;
		my $st = $type;
		$st =~ s/MF/SF/;
		my @res = map {
		     runscript($this->{CX},$this->{GLO},
			"$fn"."[$_]",$rs);
		     print "RES: '$rs'\n"
		     	if $VRML::verbose::js;
		     (pos $rs) = 0;
		     "VRML::Field::$st"
		      -> parse(undef, $rs);
		} (0..$l-1);
		print "RESVAL:\n"
			if $VRML::verbose::js;
		for(@res) {
			if("ARRAY" eq ref $_) {
				print "@$_\n"
					if $VRML::verbose::js;
			}
		}
		my $r = \@res;
		print "REF: $r\n"
			if $VRML::verbose::js;
		return $r;
	} elsif($Types{$type}) {
		my $v = runscript($this->{CX},$this->{GLO},
			"_${_}_touched=0; $prop",$rs);
		print "SIMP VAL: $v '$rs'\n"
			if $VRML::verbose::js;
		return $v;
	} else {
		runscript($this->{CX},$this->{GLO},
			"$prop",$rs);
		# print "VAL: $rs\n";
		(pos $rs) = 0;
		return "VRML::Field::$type"->parse(undef,$rs);
	}
}

sub node_setprop {
	my($this) = @_;
	print "SETTING NODE PROP\n"
		if $VRML::verbose::js;
	my ($node, $prop, $val);
	runscript($this->{CX},$this->{GLO},"__node.__id",$node);
	runscript($this->{CX},$this->{GLO},"__prop",$prop);
	print "SETTING NODE PROP R: '$node' '$prop' \n"
		if $VRML::verbose::js;
	$node = VRML::Handles::get($node);
	my $vt = $node->{Type}{FieldTypes}{$prop};
	if(!defined $vt) {
		die("Javascript tried to assign to invalid property!\n");
	}
	my $val = $this->get_prop($vt, "__val");
#	if($vt =~ /Node/) {die("Can't handle yet");}
#	if($Types{$vt}) {
#		runscript($this->{CX},$this->{GLO},"__val",$val);
#		print "GOT '$val'\n";
#		$val = "VRML::Field::$vt"->parse(undef, $val);
#	} else {
#		runscript($this->{CX},$this->{GLO},"__val.toString()",$val);
#		print "GOT '$val'\n";
#		$val = "VRML::Fields::$vt"->parse(undef, $val);
#	}
	print "SETTING TO '$val'\n"
		if $VRML::verbose::js;
	$node->{RFields}{$prop} = $val;

}

sub brow_getName {
	my($this) = @_;
	print "Brow:getname ($this) !\n"
		if $VRML::verbose::js;
	my $n = $this->{Browser}->getName(); my $rs;
	runscript($this->{CX},$this->{GLO},"Browser.__bret = \"$n\"",$rs);
}

sub brow_getVersion {
	my($this) = @_;
	print "Brow:getname ($this) !\n"
		if $VRML::verbose::js;
	my $n = $this->{Browser}->getVersion(); my $rs;
	runscript($this->{CX},$this->{GLO},"Browser.__bret = \"$n\"",$rs);
}

sub brow_getCurrentFrameRate {
	my($this) = @_;
	print "Brow:getname ($this) !\n"
		if $VRML::verbose::js;
	my $n = $this->{Browser}->getCurrentFrameRate(); my $rs;
	runscript($this->{CX},$this->{GLO},"Browser.__bret = $n",$rs);
}

sub brow_createVrmlFromString {
	my($this) = @_; my $rs;
	runscript($this->{CX},$this->{GLO},"Browser.__arg0",$rs);
	print "BROW_CVRLFSTR '$rs'\n"
		if $VRML::verbose::js;
	my $mfn = $this->{Browser}->createVrmlFromString(
		$rs
	);
	my @hs = map {VRML::Handles::reserve($_)} @$mfn;
	my $sc = "Browser.__bret = new MFNode(".
		(join ',',map {qq'new SFNode("","$_")'} @hs).")";
	runscript($this->{CX},$this->{GLO},$sc,$rs);
}
