# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Field types, parsing and printing, Perl, C and Java.

# SFNode is in Parse.pm

# XXX Decide what's the forward assertion..

@VRML::Fields = qw/
	SFFloat
	MFFloat
	SFRotation
	MFRotation
	SFVec3f
	MFVec3f
	SFBool
	SFInt32
	MFInt32
	SFNode
	MFNode
	SFColor
	MFColor
	SFTime
	SFString
	MFString
	SFVec2f
	MFVec2f
/;

package VRML::Field;
VRML::Error->import();

sub es {
	$p = (pos $_[1]) - 20;
	return substr $_[1],$p,40;
	
}

# The C type interface for the field type, encapsulated
# By encapsulating things well enough, we'll be able to completely
# change the interface later, e.g. to fit together with javascript etc.
sub ctype ($) {die "VRML::Field::ctype - abstract function called"}
sub calloc ($$) {""}
sub cassign ($$) {"$_[1] = $_[2];"}
sub cfree ($) {if($_[0]->calloc) {return "free($_[1]);"} return ""}
sub cget {if(!defined $_[2]) {return "$_[1]"}
	else {die "If CGet with indices, abstract must be overridden"} }
sub cstruct () {""}
sub cfunc {die("Must overload cfunc")}
sub jsimpleget {return {}}

sub copy {
	my($type, $value) = @_;
	if(!ref $value) {return $value}
	if(ref $value eq "ARRAY") {
		return [map {copy("",$_)} @$value]
	}
	if(ref $value eq "VRML::Node") {
		return $value;
	}
	die("Can't copy this")
}

package VRML::Field::SFFloat;
@ISA=VRML::Field;
VRML::Error->import();

sub parse {
	my($type,$p,$s,$n) = @_;
	$_[2] =~ /\G\s*($Float)/ogcs or 
		parsefail($_[2], "didn't match SFFloat");
	return $1;
}

sub as_string {$_[1]}

sub print {print $_[1]}

sub ctype {"float $_[1]"}
sub cfunc {"$_[1] = SvNV($_[2]);\n"}

sub jdata {"float v;"}
sub jalloc {""}
sub jset {return {""=>"v = 0;", "float val" => "v=val;"}}
sub jeaiset {return "float val"}
sub jset_str { '
	s = s.trim();
	v = new Float(s).floatValue();
'}
sub jget {return {float => "return v;"}}
sub jcopy {"v = f.getValue();"}
sub jstr {"return new Float(v).toString();"}
sub jclonearg {"v"}
sub toj {$_[1]}
sub fromj {$_[1]}

package VRML::Field::SFTime;
@ISA=VRML::Field::SFFloat;

sub jdata {"double v;"}
sub jset {return {""=>"v = 0;", "double val" => "v=val;"}}
sub jeaiset {return "double val"}
sub jset_str { '
	s = s.trim();
	v = new Double(s).doubleValue();
'}
sub jget {return {double => "return v;"}}
sub jstr {"return new Double(v).toString();"}

package VRML::Field::SFInt32;
@ISA=VRML::Field;
VRML::Error->import;

sub parse {
	my($type,$p,$s,$n) = @_;
	$_[2] =~ /\G\s*($Integer)\b/ogsc 
		or parsefail($_[2],"not proper SFInt32");
	return $1;
}

sub print {print " $_[1] "}
sub as_string {$_[1]}

sub ctype {return "int $_[1]"}
sub cfunc {return "$_[1] = SvIV($_[2]);\n"}

package VRML::Field::SFColor;
@ISA=VRML::Field;
VRML::Error->import;

sub parse {
	my($type,$p) = @_;
	$_[2] =~ /\G\s*($Float)\s+($Float)\s+($Float)/ogsc 
		or parsefail($_[2],"Didn't match SFColor");
	return [$1,$2,$3];
}

sub print {print join ' ',@{$_[1]}}
sub as_string {join ' ',@{$_[1]}}

sub cstruct {return "struct SFColor {
	float c[3]; };"}
sub ctype {return "struct SFColor $_[1]"}
sub cget {return "($_[1].c[$_[2]])"}

sub cfunc {
#	return ("a,b,c","float a;\nfloat b;\nfloat c;\n",
#		"$_[1].c[0] = a; $_[1].c[1] = b; $_[1].c[2] = c;");
	return "{
		AV *a;
		SV **b;
		int i;
		if(!SvROK($_[2])) {
			$_[1].c[0] = 0;
			$_[1].c[1] = 0;
			$_[1].c[2] = 0;
			/* die(\"Help! SFColor without being ref\"); */
		} else {
			if(SvTYPE(SvRV($_[2])) != SVt_PVAV) {
				die(\"Help! SFColor without being arrayref\");
			}
			a = (AV *) SvRV($_[2]);
			for(i=0; i<3; i++) {
				b = av_fetch(a, i, 1); /* LVal for easiness */
				if(!b) {
					die(\"Help: SFColor b == 0\");
				}
				$_[1].c[i] = SvNV(*b);
			}
		}
	}
	"
}

# java

sub jdata {"float red,green,blue;"}
sub jalloc {""}
sub jset {return {"" => "red=0; green=0; blue=0;",
	"float colors[]" => "red = colors[0]; green=colors[1]; blue=colors[2];",
	"float r,float g,float b" => "red=r; green=g; blue=b;"
}}
sub jeaiset { return "float colors[]" }
sub jset_str {"
   	StringTokenizer tok = new StringTokenizer(s);
	red = 	new Float(tok.nextToken()).floatValue();
	green =	new Float(tok.nextToken()).floatValue();
	blue =	new Float(tok.nextToken()).floatValue();
	"
}
sub jget {return {"void" => ["float colors[]",
	"colors[0] = red; colors[1] = green; colors[2] = blue;"]}
}
sub jcopy {"red = f.getRed(); green = f.getGreen(); blue = f.getBlue();"}
sub jstr {'return Float.toString(red) + " " + 
	Float.toString(green) + " " + Float.toString(blue);'}
sub jclonearg {"red,green,blue"}

sub jsimpleget {return {red => float, green => float, blue => float}}
sub toj {join ' ',@{$_[1]}}
sub fromj {[split ' ',$_[1]]}

# javascript

sub jsprop {
	return '{"r", 0, JSPROP_ENUMERATE},{"g", 1, JSPROP_ENUMERATE},
		{"b", 2, JSPROP_ENUMERATE}'
}
sub jsnumprop {
	return { map {($_ => "$_[1].c[$_]")} 0..2 }
}
sub jstostr {
	return "
		{static char buff[250];
		 sprintf(buff,\"\%f \%f \%f\", $_[1].c[0], $_[1].c[1], $_[1].c[2]);
		 \$RET(buff);
		}
	"
}
sub jscons {
	return [
		"jsdouble pars[3];",
		"d d d",
		"&(pars[0]),&(pars[1]),&(pars[2])",
		"$_[1].c[0] = pars[0]; $_[1].c[1] = pars[1]; $_[1].c[2] = pars[2];",
		# Last: argless
		"$_[1].c[0] = 0; $_[1].c[1] = 0; $_[1].c[2] = 0;",
	];
}

sub js_default {
	return "new SFColor(0,0,0)"
}

package VRML::Field::SFVec3f;
@ISA=VRML::Field::SFColor;
sub cstruct {return ""}

sub jsprop {
	return '{"x", 0, JSPROP_ENUMERATE},{"y", 1, JSPROP_ENUMERATE},
		{"z", 2, JSPROP_ENUMERATE}'
}
sub js_default {
	return "new SFVec3f(0,0,0)"
}

sub vec_add { join '',map {"$_[3].c[$_] = $_[1].c[$_] + $_[2].c[$_];"} 0..2; }
sub vec_subtract { join '',map {"$_[3].c[$_] = $_[1].c[$_] - $_[2].c[$_];"} 0..2; }
sub vec_negate { join '',map {"$_[2].c[$_] = -$_[1].c[$_];"} 0..2; }
sub vec_length { "$_[2] = sqrt(".(join '+',map {"$_[1].c[$_]*$_[1].c[$_]"} 0..2)
	.");"; }
sub vec_normalize { "{double xx = sqrt(".(join '+',map {"$_[1].c[$_]*$_[1].c[$_]"} 0..2)
	.");
	". (join '', map {"$_[2].c[$_] = $_[1].c[$_]/xx;"} 0..2)."}" }

sub vec_cross {
	"
		$_[3].c[0] = 
			$_[1].c[1] * $_[2].c[2] - 
			$_[2].c[1] * $_[1].c[2];
		$_[3].c[1] = 
			$_[1].c[2] * $_[2].c[0] - 
			$_[2].c[2] * $_[1].c[0];
		$_[3].c[2] = 
			$_[1].c[0] * $_[2].c[1] - 
			$_[2].c[0] * $_[1].c[1];
	"
}

package VRML::Field::SFVec2f;
@ISA=VRML::Field;
VRML::Error->import();

sub parse {
	my($type,$p) = @_;
	$_[2] =~ /\G\s*($Float)\s+($Float)/gsc 
		or parsefail($_[2],"didn't match SFVec2f");
	return [$1,$2];
}

sub print {print join ' ',@{$_[1]}}
sub as_string {join ' ',@{$_[1]}}

sub cstruct {return "struct SFVec2f {
	float c[2]; };"}
sub ctype {return "struct SFVec2f $_[1]"}
sub cget {return "($_[1].c[$_[2]])"}

sub cfunc {
	return "{
		AV *a;
		SV **b;
		int i;
		if(!SvROK($_[2])) {
			$_[1].c[0] = 0;
			$_[1].c[1] = 0;
			/* die(\"Help! SFVec2f without being ref\"); */
		} else {
			if(SvTYPE(SvRV($_[2])) != SVt_PVAV) {
				die(\"Help! SFVec2f without being arrayref\");
			}
			a = (AV *) SvRV($_[2]);
			for(i=0; i<2; i++) {
				b = av_fetch(a, i, 1); /* LVal for easiness */
				if(!b) {
					die(\"Help: SFColor b == 0\");
				}
				$_[1].c[i] = SvNV(*b);
			}
		}
	}
	"
}

sub jdata {"float x,y;"}
sub jalloc {""}
sub jset {return {"" => "x=0; y=0;",
	"float coords[]" => "x = colors[0]; y=colors[1];",
	"float x2,float y2" => "x=x2; y=y2;"
}}
sub jeaiset { "float coords[]" }
sub jset_str {"
   	StringTokenizer tok = new StringTokenizer(s);
	x = 	new Float(tok.nextToken()).floatValue();
	y =	new Float(tok.nextToken()).floatValue();
	"
}
sub jget {return {"void" => ["float coords[]",
	"coords[0] = x; coords[1] = y;"]}
}
sub jcopy {"x = f.getX(); y = f.getY();"}
sub jstr {'return Float.toString(x) + " " + 
	Float.toString(y) ;'}
sub jclonearg {"x,y"}

sub jsimpleget {return {x => float, y => float}}
sub toj {join ' ',@{$_[1]}}
sub fromj {[split ' ',$_[1]]}


package VRML::Field::SFRotation;
@ISA=VRML::Field;
VRML::Error->import();

sub parse {
	my($type,$p) = @_;
	$_[2] =~ /\G\s*($Float)\s+($Float)\s+($Float)\s+($Float)/ogsc 
		or VRML::Error::parsefail($_[2],"not proper rotation");
	return [$1,$2,$3,$4];
}

sub print {print join ' ',@{$_[1]}}
sub as_string {join ' ',@{$_[1]}}

sub cstruct {return "struct SFRotation {
 	float r[4]; };"}

sub rot_invert {
	"
	 $_[2].r[0] = $_[1].r[0];
	 $_[2].r[1] = $_[1].r[1];
	 $_[2].r[2] = $_[1].r[2];
	 $_[2].r[3] = -$_[1].r[3];
	"
}

$VRML::Field::avecmacros = "
#define AVECLEN(x) (sqrt((x)[0]*(x)[0]+(x)[1]*(x)[1]+(x)[2]*(x)[2]))
#define AVECPT(x,y) ((x)[0]*(y)[0]+(x)[1]*(y)[1]+(x)[2]*(y)[2])
#define AVECCP(x,y,z)   (z)[0]=(x)[1]*(y)[2]-(x)[2]*(y)[1]; \\
			(z)[1]=(x)[2]*(y)[0]-(x)[0]*(y)[2]; \\
			(z)[2]=(x)[0]*(y)[1]-(x)[1]*(y)[0];
#define AVECSCALE(x,y) x[0] *= y; x[1] *= y; x[2] *= y;
";

sub rot_multvec {
	qq~
		double rl = AVECLEN($_[1].r);
		double vl = AVECLEN($_[2].c);
		double rlpt = AVECPT($_[1].r, $_[2].c) / rl / vl;
		float c1[3];
		float c2[3];
		double s = sin($_[1].r[3]), c = cos($_[1].r[3]);
		AVECCP($_[1].r,$_[2].c,c1); AVECSCALE(c1, 1.0 / rl );
		AVECCP($_[1].r,c1,c2); AVECSCALE(c2, 1.0 / rl) ;
		$_[3].c[0] = $_[2].c[0] + s * c1[0] + (1-c)*c2[0];
		$_[3].c[1] = $_[2].c[1] + s * c1[1] + (1-c)*c2[1];
		$_[3].c[2] = $_[2].c[2] + s * c1[2] + (1-c)*c2[2];
		/*
		printf("ROT MULTVEC (%f %f %f : %f) (%f %f %f) -> (%f %f %f)\\n",
			$_[1].r[0], $_[1].r[1], $_[1].r[2], $_[1].r[3],
			$_[2].c[0], $_[2].c[1], $_[2].c[2],
			$_[3].c[0], $_[3].c[1], $_[3].c[2]);
		*/
	~
}

sub ctype {return "struct SFRotation $_[1]"}
sub cget {return "($_[1].r[$_[2]])"}

sub cfunc {
#	return ("a,b,c,d","float a;\nfloat b;\nfloat c;\nfloat d;\n",
#		"$_[1].r[0] = a; $_[1].r[1] = b; $_[1].r[2] = c; $_[1].r[3] = d;");
	return "{
		AV *a;
		SV **b;
		int i;
		if(!SvROK($_[2])) {
			$_[1].r[0] = 0;
			$_[1].r[1] = 1;
			$_[1].r[2] = 0;
			$_[1].r[3] = 0;
			/* die(\"Help! SFRotation without being ref\"); */
		} else {
			if(SvTYPE(SvRV($_[2])) != SVt_PVAV) {
				die(\"Help! SFRotation without being arrayref\");
			}
			a = (AV *) SvRV($_[2]);
			for(i=0; i<4; i++) {
				b = av_fetch(a, i, 1); /* LVal for easiness */
				if(!b) {
					die(\"Help: SFColor b == 0\");
				}
				$_[1].r[i] = SvNV(*b);
			}
		}
	}
	"
}

sub jsprop {
	return '{"x", 0, JSPROP_ENUMERATE},{"y", 1, JSPROP_ENUMERATE},
		{"z", 2, JSPROP_ENUMERATE},{"angle",3, JSPROP_ENUMERATE}'
}
sub jsnumprop {
	return { map {($_ => "$_[1].r[$_]")} 0..3 }
}
sub jstostr {
	return "
		{static char buff[250];
		 sprintf(buff,\"\%f \%f \%f \%f\", $_[1].r[0], $_[1].r[1], $_[1].r[2], $_[1].r[3]);
		 \$RET(buff);
		}
	"
}
sub jscons {
return ["",qq~
	jsdouble pars[4];
	JSObject *ob1;
	JSObject *ob2;
	if(JS_ConvertArguments(cx,argc,argv,"d d d d",
		&(pars[0]),&(pars[1]),&(pars[2]),&(pars[3])) == JS_TRUE) {
		$_[1].r[0] = pars[0]; 
		$_[1].r[1] = pars[1]; 
		$_[1].r[2] = pars[2]; 
		$_[1].r[3] = pars[3];
	} else if(JS_ConvertArguments(cx,argc,argv,"o o",
		&ob1,&ob2) == JS_TRUE) {
		TJL_SFVec3f *vec1;
		TJL_SFVec3f *vec2;
		double v1len, v2len, v12dp;
		    if (!JS_InstanceOf(cx, ob1, &cls_SFVec3f, argv)) {
			die("sfrot obj: has to be SFVec3f ");
			return JS_FALSE;
		    }
		    if (!JS_InstanceOf(cx, ob2, &cls_SFVec3f, argv)) {
			die("sfrot obj: has to be SFVec3f ");
			return JS_FALSE;
		    }
		vec1 = JS_GetPrivate(cx,ob1);
		vec2 = JS_GetPrivate(cx,ob2);
		v1len = sqrt( vec1->v.c[0] * vec1->v.c[0] + 
			vec1->v.c[1] * vec1->v.c[1] + 
			vec1->v.c[2] * vec1->v.c[2] );
		v2len = sqrt( vec2->v.c[0] * vec2->v.c[0] + 
			vec2->v.c[1] * vec2->v.c[1] + 
			vec2->v.c[2] * vec2->v.c[2] );
		v12dp = vec1->v.c[0] * vec2->v.c[0] + 
			vec1->v.c[1] * vec2->v.c[1] + 
			vec1->v.c[2] * vec2->v.c[2] ;
		$_[1].r[0] = 
			vec1->v.c[1] * vec2->v.c[2] - 
			vec2->v.c[1] * vec1->v.c[2];
		$_[1].r[1] = 
			vec1->v.c[2] * vec2->v.c[0] - 
			vec2->v.c[2] * vec1->v.c[0];
		$_[1].r[2] = 
			vec1->v.c[0] * vec2->v.c[1] - 
			vec2->v.c[0] * vec1->v.c[1];
		v12dp /= v1len * v2len;
		$_[1].r[3] = 
			atan2(sqrt(1-v12dp*v12dp),v12dp);
		/* 
		printf("V12cons: (%f %f %f) (%f %f %f) %f %f %f (%f %f %f : %f)\n",
			vec1->v.c[0], vec1->v.c[1], vec1->v.c[2],
			vec2->v.c[0], vec2->v.c[1], vec2->v.c[2],
			v1len, v2len, v12dp, 
			$_[1].r[0], $_[1].r[1], $_[1].r[2], $_[1].r[3]);
		*/
	} else if(JS_ConvertArguments(cx,argc,argv,"o d",
		&ob1,&(pars[0])) == JS_TRUE) {
		TJL_SFVec3f *vec;
		    if (!JS_InstanceOf(cx, ob1, &cls_SFVec3f, argv)) {
			die("multVec: has to be SFVec3f ");
			return JS_FALSE;
		    }
		vec = JS_GetPrivate(cx,ob1);
		$_[1].r[0] = vec->v.c[0]; 
		$_[1].r[1] = vec->v.c[1]; 
		$_[1].r[2] = vec->v.c[2]; 
		$_[1].r[3] = pars[0];
		
	} else if(argc == 0) {
		$_[1].r[0] = 0;
		$_[1].r[0] = 0;
		$_[1].r[0] = 1;
		$_[1].r[0] = 0;
	} else {
		die("Invalid constructor for SFRotation");
	}

~];
}

sub js_default {
	return "new SFRotation(0,0,1,0)"
}

package VRML::Field::SFBool;
@ISA=VRML::Field;

sub parse {
	my($type,$p,$s,$n) = @_;
	$_[2] =~ /\G\s*(TRUE|FALSE)\b/gs or die "Invalid value for BOOL\n";
	return ($1 eq "TRUE");
}

sub ctype {return "int $_[1]"}
sub cget {return "($_[1])"}
sub cfunc {return "$_[1] = SvIV($_[2]);\n"}

sub print {print ($_[1] ? TRUE : FALSE)}
sub as_string {($_[1] ? TRUE : FALSE)}

# The java interface
sub jdata {"boolean v;"}
sub jalloc {""}
sub jset {return {"" => "v = false;",
	"boolean value" => "v = value;",
}}
sub jeaiset { "boolean value" }
sub jset_str { q~
   	s = s.trim();
	if(s.equals("1")) {v = true;}
	else if(s.equals("0") || s.equals("")) {v = false;}
	else {throw new Exception("Invalid boolean '"+s+"'");}
~}
sub jget {return {"boolean" => "return v;"}}
sub jcopy {"v = f.getValue();"}
sub jstr {'return (v? "1": "0");'}
sub jclonearg {"v"}
sub toj {return $_[1]}
sub fromj {return $_[1]}

sub js_default {return "false"}

package VRML::Field::SFString;
@ISA=VRML::Field;

# XXX Handle backslashes in string properly
sub parse {
	my($type,$p,$s,$n) = @_;
	# Magic regexp which hopefully exactly quotes backslashes and quotes
	$_[2] =~ /\G\s*"((?:[^"\\]|\\.)*)"\s*/gsc 
		or VRML::Error::parsefail($_[2],"improper SFString");
	my $str = $1;
	$str =~ s/\\(.)/$1/g;
	# print "GOT STRING '$str'\n";
	return $str;
}

sub ctype {return "SV *$_[1]"}
sub calloc {"$_[1] = newSVpv(\"\",0);"}
sub cassign {"sv_setsv($_[1],$_[2]);"}
sub cfree {"SvREFCNT_dec($_[1]);"}
sub cfunc {"sv_setsv($_[1],$_[2]);"}

sub print {print "\"$_[1]\""}

package VRML::Field::MFString;
@ISA=VRML::Field::Multi;

# XXX Should be optimized heavily! Other MFs are ok.
package VRML::Field::MFFloat;
@ISA=VRML::Field::Multi;

sub parse {
	my($type,$p) = @_;
	if($_[2] =~ /\G\s*\[\s*/gsc) {
		$_[2] =~ /\G([^\]]*)\]/gsc or
		 VRML::Error::parsefail($_[2],"unterminated MFFloat");
		my $a = $1;
		$a =~ s/^\s*//;
		$a =~ s/\s*$//;
		# XXX Errors ???
		my @a = split /\s*,\s*|\s+/,$a;
		pop @a if $a[-1] =~ /^\s+$/;
		# while($_[2] !~ /\G\s*,?\s*\]\s*/gsc) {
		# 	$_[2] =~ /\G\s*,\s*/gsc; # Eat comma if it is there...
		# 	my $v =  $stype->parse($p,$_[2],$_[3]);
		# 	push @a, $v if defined $v; 
		# }
		return \@a;
	} else {
		my $res = [VRML::Field::SFFloat->parse($p,$_[2],$_[3])];
		# Eat comma if it is there
		$_[2] =~ /\G\s*,\s*/gsc;
		return $res;
	}
}

package VRML::Field::MFNode;
@ISA=VRML::Field::Multi;

package VRML::Field::MFColor;
@ISA=VRML::Field::Multi;

package VRML::Field::MFVec3f;
@ISA=VRML::Field::Multi;

package VRML::Field::MFVec2f;
@ISA=VRML::Field::Multi;

package VRML::Field::MFInt32;
@ISA=VRML::Field::Multi;

sub parse {
	my($type,$p) = @_;
	if($_[2] =~ /\G\s*\[\s*/gsc) {
		$_[2] =~ /\G([^\]]*)\]/gsc or
		 VRML::Error::parsefail($_[2],"unterminated MFFloat");
		my $a = $1;
		$a =~ s/^\s*//s;
		$a =~ s/\s*$//s;
		# XXX Errors ???
		my @a = split /\s*,\s*|\s+/,$a;
		pop @a if $a[-1] =~ /^\s+$/;
		# while($_[2] !~ /\G\s*,?\s*\]\s*/gsc) {
		# 	$_[2] =~ /\G\s*,\s*/gsc; # Eat comma if it is there...
		# 	my $v =  $stype->parse($p,$_[2],$_[3]);
		# 	push @a, $v if defined $v; 
		# }
		return \@a;
	} else {
		my $res = [VRML::Field::SFInt32->parse($p,$_[2],$_[3])];
		# Eat comma if it is there
		$_[2] =~ /\G\s*,\s*/gsc;
		return $res;
	}
}

package VRML::Field::MFRotation;
@ISA=VRML::Field::Multi;

package VRML::Field::Multi;
@ISA=VRML::Field;

sub ctype {
	my $r = (ref $_[0] or $_[0]);
	$r =~ s/VRML::Field::MF//;
	return "struct Multi_$r $_[1]";
}
sub cstruct {
	my $r = (ref $_[0] or $_[0]);
	my $t = $r;
	$r =~ s/VRML::Field::MF//;
	$t =~ s/::MF/::SF/;
	my $ct = $t->ctype;
	return "struct Multi_$r { int n; $ct *p; };"
}
sub calloc {
	return "$_[1].n = 0; $_[1].p = 0;";
}
sub cassign {
	my $t = (ref $_[0] or $_[0]);
	$t =~ s/::MF/::SF/;
	my $cm = $t->calloc("$_[1].n");
	my $ca = $t->cassign("$_[1].p[__i]", "$_[2].p[__i]");
	"if($_[1].p) {free($_[1].p)};
	 $_[1].n = $_[2].n; $_[1].p = malloc(sizeof(*($_[1].p))*$_[1].n);
	 {int __i;
	  for(__i=0; __i<$_[1].n; __i++) {
	  	$cm
		$ca
	  }
	 }
	"
}
sub cfree {
	"if($_[1].p) {free($_[1].p);$_[1].p=0;} $_[1].n = 0;"
}
sub cgetn { "($_[1].n)" }
sub cget { if($#_ == 1) {"($_[1].p)"} else {
	my $r = (ref $_[0] or $_[0]);
	$r =~ s/::MF/::SF/;
	if($#_ == 2) {
		return "($_[1].p[$_[2]])";
	}
	return $r->cget("($_[1].p[$_[2]])", @$_[3..$#_])
	} }

sub cfunc {
	my $r = (ref $_[0] or $_[0]);
	$r =~ s/::MF/::SF/;
	my $cm = $r->calloc("$_[1].p[iM]");
	my $su = $r->cfunc("($_[1].p[iM])","(*bM)");
	return "{
		AV *aM;
		SV **bM;
		int iM;
		int lM;
		if(!SvROK($_[2])) {
			$_[1].n = 0;
			$_[1].p = 0;
			/* die(\"Help! Multi without being ref\"); */
		} else {
			if(SvTYPE(SvRV($_[2])) != SVt_PVAV) {
				die(\"Help! Multi without being arrayref\");
			}
			aM = (AV *) SvRV($_[2]);
			lM = av_len(aM)+1;
			/* XXX Free previous p */
			$_[1].n = lM;
			$_[1].p = malloc(lM * sizeof(*($_[1].p)));
			/* XXX ALLOC */
			for(iM=0; iM<lM; iM++) {
				bM = av_fetch(aM, iM, 1); /* LVal for easiness */
				if(!bM) {
					die(\"Help: Multi $r bM == 0\");
				}
				$cm
				$su
			}
		}
	}
	"
}


sub parse {
	my($type,$p) = @_;
	my $stype = $type;
	$stype =~ s/::MF/::SF/;
	if($_[2] =~ /\G\s*\[\s*/gsc) {
		my @a;
		while($_[2] !~ /\G\s*,?\s*\]\s*/gsc) {
			# print "POS0: ",(pos $_[2]),"\n";
			# removing $r = causes this to be evaluated
			# in array context -> fail.
			my $r = ($_[2] =~ /\G\s*,\s*/gsc); # Eat comma if it is there...
			# my $wa = wantarray;
			# print "R: '$r' (WA: $wa)\n";
			# print "POS1: ",(pos $_[2]),"\n";
			my $v =  $stype->parse($p,$_[2],$_[3]);
			# print "POS2: ",(pos $_[2]),"\n";
			push @a, $v if defined $v; 
		}
		return \@a;
	} else {
		my $res = [$stype->parse($p,$_[2],$_[3])];
		# Eat comma if it is there
		my $r = $_[2] =~ /\G\s*,\s*/gsc;
		return $res;
	}
}

sub print {
	my($type) = @_;
	print " [ ";
	my $r = $type;
	$r =~ s/::MF/::SF/;
	for(@{$_[1]}) {
		$r->print($_);
	}
	print " ]\n";
}

sub as_string {
	my $r = $_[0];
	$r =~ s/::MF/::SF/;
	" [ ".(join ' ',map {$r->as_string($_)} @{$_[1]})." ] "
}

sub js_default {
	my($type) = @_;
	# $type =~ s/::MF/::SF/;
	$type =~ s/VRML::Field:://;
	return "new $type()";
}

package VRML::Field::SFNode;

sub copy { return $_[1] }

sub ctype {"void *$_[1]"}      # XXX ???
sub calloc {"$_[1] = 0;"}
sub cfree {"$_[1] = 0;"}
sub cstruct {""}
sub cfunc {
	"$_[1] = (void *)SvIV($_[2]);"
}
sub cget {if(!defined $_[2]) {return "$_[1]"}
	else {die "SFNode index!??!"} }

sub as_string {
	$_[1]->as_string();
}

sub js_default { 'new SFNode("","NULL")' }

# javascript implemented in place because of special nature.
