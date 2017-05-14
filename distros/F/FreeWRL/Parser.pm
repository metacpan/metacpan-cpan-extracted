# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Parser.pm -- implement a VRML parser
#  

use strict vars;

package VRML::Error;
use vars qw/@ISA @EXPORT $Word $Float $Integer/;
require Exporter;
@ISA=qw/Exporter/;

@EXPORT=qw/parsefail parsewarnstd $Word $Float $Integer/;

# Define the RE for a VRML word.
# $Word = q|[^\-+0-9"'#,\.\[\]\\{}\0-\x20][^"'#,\.\{\}\\{}\0-\x20]*|;
$Word = q|[^\x30-\x39\x0-\x20\x22\x23\x27\x2b\x2c\x2d\x2e\x5b\x5c\x5d\x7b\x7d\x7f][^\x0-\x20\x22\x23\x27\x2c\x2e\x5b\x5c\x5d\x7b\x7d\x7f]*|;

# Spec:
# ([+/-]?(
#         (
#           ([0-9]+(\.)?)
#          |([0-9]*\.[0-9]+)
#         )
#         ([eE][+\-]?[0-9]+)?
#         )
#        ) 
# XXX This is correct but might be too slow...
# $Float = q~[+-]?(?:[0-9]+\.?|[0-9]*\.[0-9]+)(?:[eE][+-]?[0-9]+)?~
$Float = q~[\deE+\-\.]+~;

# ([+\-]?(([0-9]+)|(0[xX][0-9a-fA-F]+))) 
$Integer = q~[\da-fA-FxX+\-]+~;

sub parsefail {
	my $p = pos $_[0];
	my $n = ($p>=50 ? 50 : $p);
	my $textb = substr($_[0],$p-$n,$n);
	my $texta = substr($_[0],$p,50);
	die("PARSE ERROR: '$textb' XXX '$texta', in $_[1] because $_[2]");
}

sub parsewarnstd {
	my $p = pos $_[0];
	my $n = ($p>=100 ? 100 : $0);
	my $textb = substr($_[0],$p-$n,$n);
	warn("Parse warning: nonstandard feature: '$textb': $_[1]");
}

require 'VRML/VRMLNodes.pm';
require 'VRML/VRMLFields.pm';

package VRML::Parser;
use vars qw/$Word/;
VRML::Error->import;

# Parse a whole file into $scene.
sub parse {
	my($scene,$text) = @_;
	# XXX Inside string??
	$text =~ s/#.*\n//g;
	$text =~ s/#.*$//g;
	my @a;
	while($text !~ /\G\s*$/gsc) {
		my $n = parse_statement($scene,$text);
		my $r = ($text =~ /\G\s*,\s*/gsc); # Eat comma if it is there...
		if(defined $n) {push @a, $n}
	}
	$scene->topnodes(\@a);
}

# Parse a statement, return a node if it is a node, otherwise
# return undef.
sub parse_statement { # string in $_[1]
	my($scene) = @_;
	my $justcheck = $_[2];
	print "PARSE: '",substr($_[1],pos $_[1]),"'\n"
		if $VRML::verbose::parse;
	# Peek-ahead to see what is to come... store pos.
	my $p = pos $_[1];
	print "POSN: $p\n"
		if $VRML::verbose::parse;
	if($_[1] =~ /\G\s*PROTO\b/gsc) {
		(pos $_[1]) = $p;
		parse_proto($scene,$_[1]);
		return undef;
	} elsif($_[1] =~ /\G\s*EXTERNPROTO\b/gsc) {
		(pos $_[1]) = $p;
		parse_externproto($scene,$_[1]);
		return undef;
	} elsif($_[1] =~ /\G\s*ROUTE\b/gsc) {
		(pos $_[1]) = $p;
		parse_route($scene,$_[1]);
		return undef;
	} elsif($justcheck) {
		return -1;
	} elsif($_[1] =~ /\G\s*($Word)\b/gsc) {
		(pos $_[1]) = $p;
		print "AND NOW: ",(pos $_[1]),"\n"
			if $VRML::verbose::parse;
		return VRML::Field::SFNode->parse($scene,$_[1]);
	} else {
		print "WORD WAS: '$Word'\n"
			if $VRML::verbose::parse;
		parsefail($_[1],"Can't find next statement");
	}
}

sub parse_proto {
	my($scene) = @_;
	$_[1] =~ /\G\s*PROTO\s+($Word)\s*/ogsxc
	 or parsefail($_[1], "proto statement");
	my $name = $1;
	my $int = parse_interfacedecl($scene,1,1,$_[1]);
	$_[1] =~ /\G\s*{\s*/gsc or parsefail($_[1], "proto body start");
	my $pro = $scene->new_proto($name, $int);
	my @a;
	while($_[1] !~ /\G\s*}\s*/gsc) {
		my $n = parse_statement($pro,$_[1]);
		if(defined $n) {push @a, $n}
	}
	$pro->topnodes(\@a);
}

sub parse_externproto {
	my($scene) = @_;
	$_[1] =~ /\G\s*EXTERNPROTO\s+($Word)\s*/ogsxc
	 or parsefail($_[1], "proto statement");
	my $name = $1;
	my $int = parse_interfacedecl($scene,1,1,$_[1]);
	$_[1] =~ /\G\s*{\s*/gsc or parsefail($_[1], "proto body start");
	my $po = pos $_[1];
	my $str = VRML::Field::MFString->parse($scene,$_[1]);
	my $pro = $scene->new_externproto($name, $int,$str);
}

# Returns:
#  [field, SVFec3F, foo, [..]]
sub parse_interfacedecl {
	my($scene,$exposed,$fieldval,$s, $script,$open,$close) = @_;
	$open = ($open || "\\[");
	$close = ($close || "\\]");
	print "OPCL: '$open' '$close'\n"
		if $VRML::verbose::parse;
	$_[3] =~ /\G\s*$open\s*/gsxc or parsefail($_[3], "interface declaration");
	my %f;
	while($_[3] !~ /\G\s*$close\s*/gsxc) {
		print "PARSINT\n"
			if $VRML::verbose::parse;
		# Parse an interface statement
		if($_[3] =~ /\G\s*(eventIn|eventOut)\s+
			  ($Word)\s+($Word)\s+/ogsxc) {
			$f{$3} = [$1,$2];
			my $n = $3;
			if($script and
			   $_[3] =~ /\G\s*IS\s+($Word)\s+/ogsc) {
			   	push @{$f{$n}}, $scene->new_is($1);
			}
		} elsif($_[3] =~ /\G\s*(field|exposedField)\s+
			  ($Word)\s+($Word)/ogsxc) {
			  if($1 eq "exposedField" and !$exposed) {
			  	parsefail($_[3], "interface", 
					   "exposedFields not allowed here");
			  }
			my($ft, $t, $n) = ($1,$2,$3);
			$f{$n} = [$ft, $t];
			if($fieldval) {
				if($_[3] =~ /\G\s*IS\s+($Word)\b/gsc) {
					push @{$f{$n}}, $scene->new_is($1);
				} else {
					push @{$f{$n}},
					  "VRML::Field::$t"->parse($scene,$_[3]);
				}
			}
		} elsif($script && $_[3] =~ /\G\s*(url|directOutput|mustEvaluate)\b/gsc) {
			my $f = $1;
			my $ft = $VRML::Nodes{Script}->{FieldTypes}{$1};
			my $eft = ($f eq "url" ? "exposedField":"field");
			print "SCRFIELD $f $ft $eft\n"
				if $VRML::verbose::parse;
			if($_[3] =~ /\G\s*IS\s+($Word)\b/gsc) {
				$f{$f} = [$ft, $f, $scene->new_is($1)];
			} else {
				$f{$f} = [$ft, $f, "VRML::Field::$ft"->parse($scene,$_[3])];
				print "SCRF_PARIELD $f $ft $eft\n"
					if $VRML::verbose::parse;
			}
		} else {
			parsefail($_[3], "interface");
		}
	}
	return \%f;
}

sub parse_route {
	my($scene) = @_;
	$_[1] =~ /\G
		\s*ROUTE
		\s*($Word)\s*\.
		\s*($Word)\s+(TO\s+|to\s+|)
		\s*($Word)\s*\.
		\s*($Word)
	/ogsxc or parsefail($_[1], "route statement");
	$scene->new_route([$1,$2,$4,$5]);
	if($3 !~ /TO\s+/) {
		parsewarnstd($_[1],
		   "lowercase or omission of TO");
	}
}

sub parse_script {
	my($scene) = @_;
	my $i = parse_interfacedecl($scene, 0,1,$_[1],1 ,'{','}');
	return $scene->new_node("Script",$i); # Scene knows that Script is different
}

package VRML::Field::SFNode;
use vars qw/$Word/;
VRML::Error->import;

sub parse {
	my($type,$scene) = @_;
	$_[2] =~ /\G\s*/gsc;
	print "PARSENODES, ",(pos $_[2])," ",length $_[2],"\n"
		if $VRML::verbose::parse;
	$_[2] =~ /\G\s*($Word)\b/ogsc or parsefail($_[2],"didn't match for sfnode fword");
	my $nt = $1;
	if($nt eq "NULL") {
		return "NULL";
	}
	if($nt eq "DEF") {
		$_[2] =~ /\G\s*($Word)\b/ogsc or parsefail($_[2],
			"DEF must be followed by a defname");
		my $defname = $1;
		print "DEF $defname\n"
			if $VRML::verbose::parse;
		my $node = VRML::Field::SFNode->parse($scene,$_[2]);
		return $scene->new_def($defname, $node);
	} 
	if($nt eq "USE") {
		$_[2] =~ /\G\s*($Word)\b/ogsc or parsefail($_[2],
			"USE must be followed by a defname");
		my $dn = $1;
		print "USE $dn\n"
			if $VRML::verbose::parse;
		return $scene->new_use($dn);
	}
	if($nt eq "Script") {
		print "SCRIPT!\n"
			if $VRML::verbose::parse;
		return VRML::Parser::parse_script($scene,$_[2]);
	}
	my $proto;
	my $no = $VRML::Nodes{$nt};
	if(!defined $no) {
		$no = $scene->get_proto($nt);
		$proto=1;
		print "PROTO? '$no'\n"
			if $VRML::verbose::parse;
	}
	print "Match: '$1'\n"
		if $VRML::verbose::parse;
	if(!defined $no) {
		parsefail($_[2],"Invalid node '$nt'");
	}
	$_[2] =~ /\G\s*{\s*/gsc or parsefail($_[2],"didn't match brace!\n");
	my $isscript = ($nt eq "Script");
	my %f;
	while(1) {
		while(VRML::Parser::parse_statement($scene,$_[2],1)
			!= -1) {}; # check for PROTO & co
		last if ($_[2] =~ /\G\s*}\s*/gsc);
		print "Pos: ",(pos $_[2]),"\n"
			if $VRML::verbose::parse;
		# Apparently, some people use it :(
		$_[2] =~ /\G\s*,\s*/gsc and parsewarnstd($_[2], "Comma not really right");
		$_[2] =~ /\G\s*($Word)\b\s*/gsc or parsefail($_[2],"Node body","field name not found");
		print "FIELD: '$1'\n"
			if $VRML::verbose::parse;
		my $f = $1;
		my $ft = $no->{FieldTypes}{$f};
		print "FT: $ft\n"
			if $VRML::verbose::parse;
		if(!defined $ft) {
			die("Invalid field '$f' for node '$nt'");
		}
		if($_[2] =~ /\G\s*IS\s+($Word)\b/gsc) {
			$f{$f} = $scene->new_is($1);
		} else {
			$f{$f} = "VRML::Field::$ft"->parse($scene,$_[2]);
		}
	}
	print "END\n"
		if $VRML::verbose::parse;
	return $scene->new_node($nt,\%f);
}


sub print {
	my($typ, $this) = @_;
	if($this->{Type}{Name} eq "DEF") {
		print "DEF $this->{Fields}{id} ";
		$this->{Type}{Fields}{node}->print($this->{Fields}{node});
		return;
	} 
	if($this->{Type}{Name} eq "USE") {
		print "USE $this->{Fields}{id} ";
		return;
	} 
	print "$this->{Type}{Name} {";
	for(keys %{$this->{Fields}}) {
		print "$_ ";
		$this->{Type}{Fields}{$_}->print($this->{Fields}{$_});
		print "\n";
	}
	print "}\n";
}


1;




