#!/usr/bin/perl -w

# Minimal perl lexer/parser. No quote escapes currently handled.
sub parse_lisp
{
	local($_) = @_;
	my(@result) = ();
	my($node) = \@result;
	my(@parent) = ();
	while ( m/(\()|(\))|("(.*?)")|(;.*?$)|([^\(\)\s]+)/gm) {
		if (defined($1)) {
			my($new) = [];
			push @$node, $new;
			push @parent, $node;
			$node = $new;
		} elsif (defined($2)) {
			$node = pop @parent;
		} elsif (defined($3)) {
			push @$node, $4;
		} elsif (defined($6)) {
			push @$node, $6;
		}
	}
	@result;
}

sub perlize {
	local($_) = $_[0];
	s/^Gtk/Gtk::/;
	s/^Gtk::Gdk/Gtk::Gdk::/;
	s/^Gdk/Gtk::Gdk::/;
	$_;
}

sub xsize {
	local($_) = perlize($_[0]);
	s/::/__/g;
	$_;
}

sub typeize {
	local($_) = @_;
	s/([a-z])([A-Z])/${1}_$2/g;
	$_ = uc $_;
	s/^GTK_/GTK_TYPE_/;
	s/^GDK_/GTK_TYPE_GDK_/;
	$_;
}


foreach $file (<*.defs>) {
	open(F,"<$file");
	$_ .= join("",<F>);
	close(F);
}

$_ .= join("",<DATA>);

$_ =~ s/;.*$//gm;

# Disect parsed data into separate definitions

foreach $node (parse_lisp($_)) {
	@node = @$node;

	if ( !defined($node[0]) ) {
		next;
	}
	if ($node[0] eq "define-enum") {
		@enum = ();
		foreach (@node[2..$#node]) {
			push @enum, {simple => $_->[0], constant => $_->[1]};
		}
		if ( exists $enum{$node[1]} ) {
			warn "Overriding enum `$node[1]'\n";
		}
		$enum{$node[1]}->{'values'} = [@enum];
		$enum{$node[1]}->{perlname} = perlize($node[1]);
		$enum{$node[1]}->{xsname} = xsize($node[1]);
		$enum{$node[1]}->{typename} = typeize($node[1]);
		
	} elsif ($node[0] eq "define-boxed") {
		if ( exists $boxed{$node[1]} ) {
			warn "Overriding boxed `$node[1]'\n";
		}
		$boxed{$node[1]}->{'ref'} = $node[2];
		$boxed{$node[1]}->{unref} = $node[3];
		if (defined $node[4]) {
			$boxed{$node[1]}->{size} = $node[4];
		}

		$boxed{$node[1]}->{perlname} = perlize($node[1]);
		$boxed{$node[1]}->{xsname} = xsize($node[1]);
		$boxed{$node[1]}->{typename} = typeize($node[1]);
		
	} elsif ($node[0] eq "define-flags") {
		@flag = ();
		foreach (@node[2..$#node]) {
			push @flag, {simple => $_->[0], constant => $_->[1]};
		}
		if ( exists $flags{$node[1]} ) {
			warn "Overriding flags `$node[1]'\n";
		}
		$flags{$node[1]}->{'values'} = [@flag];
		$flags{$node[1]}->{perlname} = perlize($node[1]);
		$flags{$node[1]}->{xsname} = xsize($node[1]);
		$flags{$node[1]}->{typename} = typeize($node[1]);
		
	} elsif ($node[0] eq "define-object") {
		my($object) = {parent => $node[2]->[0]};
		foreach $node (@node[3..$#node]) {
			my (@node) = @$node;
			if ($node[0] eq "fields") {
				my(@fields) = ();
				foreach (@node[1..$#node]) {
					push @fields, {type => $_->[0], name => $_->[1]};
				}
				$object->{fields} = [@fields];
			}
		}
		if ( exists $object{$node[1]} ) {
			warn "Overriding object `$node[1]'\n";
		}
		$object{$node[1]} = $object;
		$object{$node[1]}->{perlname} = perlize($node[1]);
		$object{$node[1]}->{xsname} = xsize($node[1]);
		
		my ($cast) = $node[1];
		$cast =~ s/([a-z])([A-Z])/${1}_$2/g;
		$object{$node[1]}->{cast} = uc $cast;
		
		$object{$node[1]}->{prefix} = lc $cast;
		$objectlc{lc $cast} = $node[1];
		
	} elsif ($node[0] eq "define-func") {
		my($func) = {returntype => $node[2]};
		my(@args) = ();
		foreach $arg (@{$node[3]}) {
			my (@arg) = @$arg;
			if ($arg->[0] eq "...") {
				$func->{flexargs} = 1;
				next;
			}
			my ($a) = { type => $arg[0], name => $arg[1] };
			foreach $o (@arg[2..$#arg]) {
				if ($o->[0] eq "=") {
					$a->{default} = $o->[1];
				} elsif ($o->[0] eq "null-ok") {
					$a->{nullok} = 1;
				}
			}
			#if (defined($arg[2]) and ref($arg[2]) and $arg[2]->[0] eq "=") {
			#	$a->{default} = $arg[2]->[1];
			#}
			push @args, $a;
		}
		$func->{args} = \@args;
		
		$func->{perlname} = perlize($node[1]);
		$func->{xsname} = xsize($node[1]);
		
		if ( exists $func{$node[1]} ) {
			warn "Overriding func `$node[1]'\n";
		}
		$func{$node[1]} = $func;

	} 	
}

#use Data::Dumper;
#
#print Dumper(\%enum);
#print Dumper(\%flags);
#print Dumper(\%boxed);
#print Dumper(\%object);
#print Dumper(\%func);

$boxed{GdkPixmap} = { 'ref' => "gdk_window_ref", unref => "gdk_window_unref", 
						perlname => "Gtk::Gdk::Pixmap", xsname => "Gtk__Gdk__Pixmap",
						 typename => "GTK_TYPE_GDK_WINDOW"};

$boxed{GdkWindow} = { 'ref' => "gdk_window_ref", unref => "gdk_window_unref", 
                                               perlname => "Gtk::Gdk::Window", xsname => "Gtk__Gdk__Window",
                                                typename => "GTK_TYPE_GDK_WINDOW"};

$boxed{GdkBitmap} = { 'ref' => "gdk_window_ref", unref => "gdk_window_unref", 
                                               perlname => "Gtk::Gdk::Bitmap", xsname => "Gtk__Gdk__Bitmap",
                                                typename => "GTK_TYPE_GDK_WINDOW"};

#delete $boxed{GdkWindow};
delete $boxed{GdkEvent};
delete $boxed{GdkColor};
delete $flags{GtkWidgetFlags};

$object{GtkObject} = {perlname => "Gtk::Object", cast => "GTK_OBJECT", xsname => "Gtk__Object", prefix => "gtk_object"};

delete $object{""};
delete $func{""};
delete $boxed{""};
delete $flags{""};

#
#foreach (keys %func) {
#	if ($_ =~ /_new/) {
#		$constructor{$_} = $func{$_};
#		delete $func{$_};
#	}
#}
#
#foreach (keys %func) {
#	if (@{$func{$_}->{args}}) {
#		my($argtype) = $func{$_}->{args}->[0]->{type};
#		print "$argtype\n";
#		if (defined $object{$argtype}) {
#			my ($n) = $_;
#			my ($o) = $object{$argtype}->{prefix} . "_";
#			$n =~ s/^$o//;
#			push @{$object{$argtype}->{method}}, {function => $func{$_}, name => $n};
#			next;
#		}
#	}
#	my($prefix) = $_;
#	my($name);
#	while ($prefix =~ /_[^_]+$/) {
#		$prefix = $`;
#		$name = $& . $name;
#		print "pref/name = $prefix/$name\n";
#		if ($objectlc{$prefix}) {
#			last;
#		}
#	}
#	print "Function $_ belongs to prefix $prefix ($objectlc{$prefix})\n";
#}
#
#foreach (keys %constructor) {
#	if ($constructor{$_}->{returntype}) {
#		my($argtype) = $constructor{$_}->{returntype};
#		my($n) = $_;
#		$n =~ /_(new.*$)/;
#		my($prefix,$name) = ($`, $1);
#		print "const: $argtype/$prefix/$name\n";
#		if (defined $objectlc{$prefix}) {
#			push @{$object{$objectlc{$prefix}}->{constructor}}, {function => $constructor{$_}, name => $name};
#		}
#	}
#}
#
#use Data::Dumper;
#print Dumper(\%func);
#print Dumper(\%constructor);
#print Dumper(\%object);
#print Dumper(\%objectlc);
#exit;

foreach (sort keys %object) {
	if (!-f "$_.xs") {
		print "Unable to find widget file $_.xs: creating from template.\n";
		open(STDOUT,">$_.xs") or die "Unable to write to $_.xs: $!";
		print <<"EOT";

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

MODULE = $object{$_}->{perlname}		PACKAGE = $object{$_}->{perlname}		PREFIX = $object{$_}->{prefix}_

#ifdef $object{$_}->{cast}

#endif

EOT
		close(STDOUT);
	}
}



open(STDOUT,">typemap.gtk") or die "Unable to write to typemap.gtk: $!";
print "TYPEMAP\n";
$i = 0;
foreach (sort keys %enum) {
	print $enum{$_}->{perlname},"\tT_SimpleVal\n";
	$i++;
}
foreach (sort keys %flags) {
	print $flags{$_}->{perlname},"\tT_SimpleVal\n";
	#print perlize($_),"\tT_SimpleVal\n";
	$i++;
}
foreach (sort keys %object) {
	print $object{$_}->{perlname},"\tT_GtkPTROBJ\n";
	print $object{$_}->{perlname},"OrNULL\tT_GtkPTROBJOrNULL\n";
	#print perlize($_),"\tT_GtkPTROBJ\n";
}
foreach (sort keys %boxed) {
	print $boxed{$_}->{perlname},"\tT_SimpleVal\n";
	#print perlize($_),"\tT_SimpleVal\n"; #MISCPTROBJ\n";
}


open(STDOUT,">GtkDefs.h") or die "Unable to write to GtkDefs.h: $!";;
print <<"EOT";
extern HV * pGtkType[];
extern char * pGtkTypeName[];
extern HV * pG_EnumHash;
extern HV * pG_FlagsHash;
extern AV * gtk_typecasts;
extern int type_name(char * name);

extern void add_typecast(int type, char * perlName);
extern SV * GtkGetArg(GtkArg * a);
extern void GtkSetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object);
extern void GtkSetRetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object);

/*extern SV * newSVOptsHash(long value, char * name, HV * hash);
extern long SvOptsHash(SV * value, char * name, HV * hash);
extern SV * newSVFlagsHash(long value, char * name, HV * hash, int);
extern long SvFlagsHash(SV * value, char * name, HV * hash);*/

EOT
$i = 0;
foreach (sort keys %enum) {
	print "#define pGE_$_ pGtkType[$i]\n";
	print "#define pGEName_$_ pGtkTypeName[$i]\n";
	print "#define newSV$_(v) newSVOptsHash(v, pGEName_$_, pGE_$_)\n";
	print "#define Sv$_(v) SvOptsHash(v, pGEName_$_, pGE_$_)\n";
	print "typedef $_ $enum{$_}->{xsname};\n";
	$i++;
}
foreach (sort keys %flags) {
	print "#define pGF_$_ pGtkType[$i]\n";
	print "#define pGFName_$_ pGtkTypeName[$i]\n";
	print "#define newSV$_(v) newSVFlagsHash(v, pGFName_$_, pGF_$_, 1)\n";
	print "#define Sv$_(v) SvFlagsHash(v, pGFName_$_, pGF_$_)\n";
	print "typedef $_ $flags{$_}->{xsname};\n";
	$i++;
}
foreach (sort keys %boxed) {
	print "extern SV * newSV$_($_ * value);\n";
	print "extern $_ * Sv$_(SV * value);\n";
	print "typedef $_ * $boxed{$_}->{xsname};\n";
}
foreach (sort keys %object) {
	print "#ifdef $object{$_}->{cast}\n";
	print "typedef $_ * $object{$_}->{xsname};\n";
	print "typedef $_ * $object{$_}->{xsname}OrNULL;\n";
	print "#define Cast$object{$_}->{xsname} $object{$_}->{cast}\n";
	print "#define Cast$object{$_}->{xsname}OrNULL $object{$_}->{cast}\n";
	print "#endif\n";
}


open(STDOUT,">GtkTypes.pm") or die "Unable to write to GtkTypes.pm: $!";
print "package Gtk::Types;\n";
foreach (sort keys %object) {
	if (defined $object{$_}->{parent}) {
		print "\@$object{$_}->{perlname}::ISA = '$object{$object{$_}->{parent}}->{perlname}';\n";
	}
}
print "1;\n";



open(STDOUT,">GtkDefs.c")  or die "Unable to write to GtkDefs.c: $!";

print <<"EOT";
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"
#include "GtkDefs.h"

HV * pGtkType[$i];
char * pGtkTypeName[$i];
HV * pG_EnumHash;
HV * pG_FlagsHash;

AV * gtk_typecasts = 0;
static HV * types = 0;

void add_typecast(int type, char * perlName)
{
	/*GtkObjectClass * klass = gtk_type_class(type);*/
	av_extend(gtk_typecasts, type/* klass->type*/);
	av_store(gtk_typecasts, type/*klass->type*/, newSVpv(perlName, 0));
	hv_store(types, perlName, strlen(perlName), newSViv(type), 0);
}

int type_name(char * name) {
	SV ** s = hv_fetch(types, name, strlen(name), 0);
	if (s)
		return SvIV(*s);
	else
		return 0;
}

EOT

foreach (sort keys %boxed) {
	print <<"EOT";

SV * newSV$_($_ * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "$boxed{$_}->{perlname}", &n);
	if (n)
		$boxed{$_}->{'ref'}(value);
	return result;
}

$_ * Sv$_(SV * value) { return ($_*)SvMiscRef(value, "$boxed{$_}->{perlname}"); }
EOT
}

print <<"EOT";

SV * GtkGetArg(GtkArg * a)
{
	SV * result;
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_BOOL:	result = newSViv(GTK_VALUE_BOOL(*a)); break;
		case GTK_TYPE_CHAR:	result = newSViv(GTK_VALUE_CHAR(*a)); break;
		case GTK_TYPE_INT:	result = newSViv(GTK_VALUE_INT(*a)); break;
		case GTK_TYPE_LONG:	result = newSViv(GTK_VALUE_LONG(*a)); break;
		case GTK_TYPE_UINT:	result = newSViv(GTK_VALUE_UINT(*a)); break;
		case GTK_TYPE_ULONG:	result = newSViv(GTK_VALUE_ULONG(*a)); break;
		case GTK_TYPE_FLOAT:	result = newSVnv(GTK_VALUE_FLOAT(*a)); break;	
		case GTK_TYPE_STRING:	result = newSVpv(GTK_VALUE_STRING(*a),0); break;
		case GTK_TYPE_POINTER:	result = newSVpv(GTK_VALUE_POINTER(*a),0); break;
		case GTK_TYPE_OBJECT:	result = newSVGtkObjectRef(GTK_VALUE_OBJECT(*a), 0); break;
		case GTK_TYPE_SIGNAL:
		{
			AV * args = (AV*)GTK_VALUE_SIGNAL(*a).d;
			SV ** s;
			if ((GTK_VALUE_SIGNAL(*a).f != 0) ||
				(!args) ||
				(SvTYPE(args) != SVt_PVAV) ||
				(av_len(args) < 3) ||
				!(s = av_fetch(args, 2, 0))
				)
				croak("Unable to return a foreign signal type to Perl");

			result = newSVsv(*s);
			return;
		}
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	print "#ifdef $enum{$_}->{typename}\n";
	print "			if (a->type == $enum{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_ENUM(*a));\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
EOT

foreach (sort keys %flags) {
	print "#ifdef $flags{$_}->{typename}\n";
	print "			if (a->type == $flags{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_FLAGS(*a));\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				result = newSVGdkEvent(GTK_VALUE_BOXED(*a));
			else
EOT

foreach (sort keys %boxed) {
	print "#ifdef $boxed{$_}->{typename}\n";
	print "			if (a->type == $boxed{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_BOXED(*a));\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot get argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
	return result;
}

void GtkSetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_CHAR:		GTK_VALUE_CHAR(*a) = SvIV(v); break;
		case GTK_TYPE_BOOL:		GTK_VALUE_BOOL(*a) = SvIV(v); break;
		case GTK_TYPE_INT:		GTK_VALUE_INT(*a) = SvIV(v); break;
		case GTK_TYPE_UINT:		GTK_VALUE_UINT(*a) = SvIV(v); break;
		case GTK_TYPE_LONG:		GTK_VALUE_LONG(*a) = SvIV(v); break;
		case GTK_TYPE_ULONG:	GTK_VALUE_ULONG(*a) = SvIV(v); break;
		case GTK_TYPE_FLOAT:	GTK_VALUE_FLOAT(*a) = SvNV(v); break;	
		case GTK_TYPE_STRING:	GTK_VALUE_STRING(*a) = g_strdup(SvPV(v,na)); break;
		case GTK_TYPE_POINTER:	GTK_VALUE_POINTER(*a) = SvPV(v,na); break;
		case GTK_TYPE_OBJECT:	GTK_VALUE_OBJECT(*a) = SvGtkObjectRef(v, "Gtk::Object"); break;
		case GTK_TYPE_SIGNAL:
		{
			AV * args;
			int i,j;
			int type;
			char * c = strchr(a->name, ':');
			c+=2;
			c = strchr(c, ':');
			c += 2;
			args = newAV();

			type = gtk_signal_lookup(c, Object->klass->type);

			av_push(args, newSVsv(Class));
			av_push(args, newSVpv(c, 0));
			av_push(args, newSVsv(v));
			av_push(args, newSViv(type));

			GTK_VALUE_SIGNAL(*a).f = 0;
			GTK_VALUE_SIGNAL(*a).d = args;
			return;
		}
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	print "#ifdef $enum{$_}->{typename}\n";
	print "			if (a->type == $enum{$_}->{typename})\n";
	print "				GTK_VALUE_ENUM(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}
print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
EOT
foreach (sort keys %flags) {
	print "#ifdef $flags{$_}->{typename}\n";
	print "			if (a->type == $flags{$_}->{typename})\n";
	print "				GTK_VALUE_FLAGS(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				GTK_VALUE_BOXED(*a) = SvGdkEvent(v);
			else
EOT
foreach (sort keys %boxed) {
	print "#ifdef $boxed{$_}->{typename}\n";
	print "			if (a->type == $boxed{$_}->{typename})\n";
	print "				GTK_VALUE_BOXED(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot set argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
}

void GtkSetRetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_CHAR:		*GTK_RETLOC_CHAR(*a) = SvIV(v); break;
		case GTK_TYPE_BOOL:		*GTK_RETLOC_BOOL(*a) = SvIV(v); break;
		case GTK_TYPE_INT:		*GTK_RETLOC_INT(*a) = SvIV(v); break;
		case GTK_TYPE_UINT:		*GTK_RETLOC_UINT(*a) = SvIV(v); break;
		case GTK_TYPE_LONG:		*GTK_RETLOC_LONG(*a) = SvIV(v); break;
		case GTK_TYPE_ULONG:	*GTK_RETLOC_ULONG(*a) = SvIV(v); break;
		case GTK_TYPE_FLOAT:	*GTK_RETLOC_FLOAT(*a) = SvNV(v); break;	
		case GTK_TYPE_STRING:	*GTK_RETLOC_STRING(*a) = SvPV(v,na); break;
		case GTK_TYPE_POINTER:	*GTK_RETLOC_POINTER(*a) = SvPV(v,na); break;
		case GTK_TYPE_OBJECT:	*GTK_RETLOC_OBJECT(*a) = SvGtkObjectRef(v, "Gtk::Object"); break;
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	print "#ifdef $enum{$_}->{typename}\n";
	print "			if (a->type == $enum{$_}->{typename})\n";
	print "				*GTK_RETLOC_ENUM(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}
print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
EOT
foreach (sort keys %flags) {
	print "#ifdef $flags{$_}->{typename}\n";
	print "			if (a->type == $flags{$_}->{typename})\n";
	print "				*GTK_RETLOC_FLAGS(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				*GTK_RETLOC_BOXED(*a) = SvGdkEvent(v);
			else
EOT
foreach (sort keys %boxed) {
	print "#ifdef $boxed{$_}->{typename}\n";
	print "			if (a->type == $boxed{$_}->{typename})\n";
	print "				GTK_VALUE_BOXED(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot set argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
}

void initPerlGtkDefs(void) {
	int i;
	HV * h;
	pG_EnumHash = newHV();
	pG_FlagsHash = newHV();
	
EOT
$i = 0;
foreach (sort keys %enum) {
	print "\n	h = newHV();\n";
	print "	pGtkType[$i] = h;\n";
	print "	pGtkTypeName[$i] = \"$enum{$_}->{perlname}\";\n";
	foreach (@{$enum{$_}->{'values'}}) {
		print "	hv_store(h, \"$_->{simple}\", ", length($_->{simple}), ", newSViv(", $_->{constant},"), 0);\n";
	}
	print "	hv_store(pG_EnumHash, \"$enum{$_}->{perlname}\", ", length($enum{$_}->{perlname}), ", newRV((SV*)h), 0);\n";
	print " SvREFCNT_dec(h);\n";
	$i++;
}

foreach (sort keys %flags) {
	print "\n	h = newHV();\n";
	print "	pGtkType[$i] = h;\n";
	print "	pGtkTypeName[$i] = \"$flags{$_}->{perlname}\";\n";
	foreach (@{$flags{$_}->{'values'}}) {
		print "	hv_store(h, \"$_->{simple}\", ", length($_->{simple}), ", newSViv(", $_->{constant},"), 0);\n";
	}
	print "	hv_store(pG_FlagsHash, \"$flags{$_}->{perlname}\", ", length($flags{$_}->{perlname}), ", newRV((SV*)h), 0);\n";
	print " SvREFCNT_dec(h);\n";
	$i++;
}
print <<"EOT";

	/*for(i=0;i<$i;i++) {
		HV * p = perl_get_hv(pGtkTypeName[i], TRUE);
		sv_setsv((SV*)p, (SV*)pGtkType[i]);
	}*/

	gtk_typecasts = newAV();
	types = newHV();

EOT
foreach (sort keys %object) {
	next if not length $object{$_}->{cast};
	print "#ifdef $object{$_}->{cast}\n";
	print "\tadd_typecast(", $object{$_}->{prefix}, "_get_type(),	\"$object{$_}->{perlname}\");\n"
		;#unless /preview/i;
	print "#endif\n";
}


print "}\n";


open(STDOUT,">boxed.xsh") or die "Unable to write to boxed.xsh: $!";

foreach (sort keys %boxed) {
	print <<"EOT";
	
MODULE = Gtk	PACKAGE = $boxed{$_}->{perlname}

void
DESTROY(self)
	$boxed{$_}->{perlname}	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	$boxed{$_}->{unref}(self);

EOT
}

open(STDOUT,">objects.xsh") or die "Unable to write to objects.xsh: $!";

foreach (sort keys %object) {
	next if not length $object{$_}->{prefix};
	print <<"EOT";
	
MODULE = Gtk	PACKAGE = $object{$_}->{perlname}		PREFIX = $object{$_}->{prefix}_

#ifdef $object{$_}->{cast}

int
$object{$_}->{prefix}_get_type(self)
	$object{$_}->{perlname}	self
	CODE:
	RETVAL = $object{$_}->{prefix}_get_type();
	OUTPUT:
	RETVAL

int
$object{$_}->{prefix}_get_size(self)
	$object{$_}->{perlname}	self
	CODE:
	RETVAL = sizeof($_);
	OUTPUT:
	RETVAL


int
$object{$_}->{prefix}_get_class_size(self)
	$object{$_}->{perlname}	self
	CODE:
	RETVAL = sizeof(${_}Class);
	OUTPUT:
	RETVAL

#endif

EOT
}

foreach (sort keys %object) {
	next if not length $object{$_}->{xsname};
	print <<"EOT";
BOOT:
{
	#ifdef $object{$_}->{cast}
                extern void boot_$object{$_}->{xsname}(CV *cv);
		callXS (boot_$object{$_}->{xsname}, cv, mark);
	#endif
}

EOT
}

open(STDOUT,">Objects.xpl") or die "Unable to write to Objects.xpl: $!";
print "\"\n";
foreach (sort keys %object) {
	print "$_.o\n";
}
print "\"\n;\n";

exit;















%enum = ();

while (/\(define-enum\s+(\S+)((\s+\(\S+\s+\S+\))+)\)/gs) {
	my($a,$b) = ($1,$2);
	$enum{$a} = [];
	while ($b =~ /\((\S+)\s+(\S+)\)/gs) {
		push @{$enum{$a}}, [$1, $2];
	}
}

%boxed = ();

while (/\(define-boxed\s+(\S+)((\s+\S+?)+)\)/gs) {
	my($a,$b) = ($1,$2);
	$boxed{$a} = [];
	while ($b =~ /(\S+)/gs) {
		push @{$boxed{$a}}, $1;
	}
}

%flags = ();

while (/\(define-flags\s+(\S+)((\s+\(\S+\s+\S+\))+)\)/gs) {
	my($a,$b) = ($1,$2);
	$flags{$a} = [];
	while ($b =~ /\((\S+)\s+(\S+)\)/gs) {
		push @{$flags{$a}}, [$1, $2];
	}
}

%func = ();

while (/\(define-func\s+(\S+)\s+(\S+)((\s+\(\S+\s+\S+\))+)\)/gs) {
	my($a,$ret,$b) = ($1,$2,$3);
	$func{$a} = [$ret,[]];
	while ($b =~ /\((\S+)\s+(\S+)\)/gs) {
		push @{$func{$a}[1]}, [$1, $2];
	}
}

%object = ();

while (/\(define-object\s+(\S+)\s+\((\S*?)\)\)/gs) {
	my($a,$b,$c) = ($1,$1,$2);
	$b =~ s/([a-z])([A-Z])/${1}_$2/g;
	$b = uc $b;
	$object{$a} = [$b,$c];
}



# Exceptions

$boxed{GdkPixmap} = $boxed{GdkWindow};
delete $boxed{GdkWindow};
delete $boxed{GdkEvent};

open(STDOUT,">typemap.gtk");
print "TYPEMAP\n";
$i = 0;
foreach (sort keys %enum) {
	print perlize($_),"\tT_SimpleVal\n";
	$i++;
}
foreach (sort keys %flags) {
	print perlize($_),"\tT_SimpleVal\n";
	$i++;
}
foreach (sort keys %object) {
	print perlize($_),"\tT_GtkPTROBJ\n";
}
foreach (sort keys %boxed) {
	print perlize($_),"\tT_SimpleVal\n"; #MISCPTROBJ\n";
}

open(STDOUT,">GtkDefs.h");
print <<"EOT";
extern HV * pGtkType[];
extern char * pGtkTypeName[];
extern HV * pG_EnumHash;
extern HV * pG_FlagsHash;
extern AV * gtk_typecasts;
extern int type_name(char * name);

extern void add_typecast(int type, char * perlName);
extern SV * GtkGetArg(GtkArg * a);
extern void GtkSetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object);
extern void GtkSetRetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object);

/*extern SV * newSVOptsHash(long value, char * name, HV * hash);
extern long SvOptsHash(SV * value, char * name, HV * hash);
extern SV * newSVFlagsHash(long value, char * name, HV * hash, int);
extern long SvFlagsHash(SV * value, char * name, HV * hash);*/

EOT
$i = 0;
foreach (sort keys %enum) {
	print "#define pGE_$_ pGtkType[$i]\n";
	print "#define pGEName_$_ pGtkTypeName[$i]\n";
	print "#define newSV$_(v) newSVOptsHash(v, pGEName_$_, pGE_$_)\n";
	print "#define Sv$_(v) SvOptsHash(v, pGEName_$_, pGE_$_)\n";
	$p = perlize($_);
	$p =~ s/:/_/g;
	print "#define $p $_\n";
	$i++;
}
foreach (sort keys %flags) {
	print "#define pGF_$_ pGtkType[$i]\n";
	print "#define pGFName_$_ pGtkTypeName[$i]\n";
	print "#define newSV$_(v) newSVFlagsHash(v, pGFName_$_, pGF_$_, 1)\n";
	print "#define Sv$_(v) SvFlagsHash(v, pGFName_$_, pGF_$_)\n";
	$p = perlize($_);
	$p =~ s/:/_/g;
	print "#define $p $_\n";
	$i++;
}
foreach (sort keys %boxed) {
	$p = perlize($_);
	$q = $p;
	$q =~ s/::/__/g;
	print "extern SV * newSV$_($_ * value);\n";
	print "extern $_ * Sv$_(SV * value);\n";
	print "typedef $_ * $q;\n";
}
foreach (sort keys %object) {
	$p = xsize($_);
#	$p =~ s/:/_/g;
#	$q = $p;
#	$q =~ s/__/_/g;
#	$q =~ s/([a-z])([A-Z])/$1_$2/g;
#	$q = uc $q;
	print "typedef $_ * $p;\n";
	print "#define Cast$p $object{$_}[0]\n";
}

open(STDOUT,">GtkTypes.pm");
print "package Gtk::Types;\n";
foreach (sort keys %object) {
	$p = perlize($_);
	$q = perlize($object{$_}[1]);
	print "\@${p}::ISA = qw($q);\n";
}
print "1;\n";

open(STDOUT,">GtkDefs.c");
print <<"EOT";
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"
#include "GtkDefs.h"

HV * pGtkType[$i];
char * pGtkTypeName[$i];
HV * pG_EnumHash;
HV * pG_FlagsHash;

AV * gtk_typecasts = 0;
static HV * types = 0;

void add_typecast(int type, char * perlName)
{
	/*GtkObjectClass * klass = gtk_type_class(type);*/
	av_extend(gtk_typecasts, type/* klass->type*/);
	av_store(gtk_typecasts, type/*klass->type*/, newSVpv(perlName, 0));
	hv_store(types, perlName, strlen(perlName), newSViv(type), 0);
}

int type_name(char * name) {
	SV ** s = hv_fetch(types, name, strlen(name), 0);
	if (s)
		return SvIV(*s);
	else
		return 0;
}

EOT

foreach (sort keys %boxed) {
	$p = perlize($_);
	print <<"EOT";

SV * newSV$_($_ * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "$p", &n);
	if (n)
		$boxed{$_}[0](value);
	return result;
}

$_ * Sv$_(SV * value) { return ($_*)SvMiscRef(value, "$p"); }
EOT
}

print <<"EOT";

SV * GtkGetArg(GtkArg * a)
{
	SV * result;
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_BOOL:	result = newSViv(GTK_VALUE_BOOL(*a)); break;
		case GTK_TYPE_CHAR:	result = newSViv(GTK_VALUE_CHAR(*a)); break;
		case GTK_TYPE_INT:	result = newSViv(GTK_VALUE_INT(*a)); break;
		case GTK_TYPE_LONG:	result = newSViv(GTK_VALUE_LONG(*a)); break;
		case GTK_TYPE_UINT:	result = newSViv(GTK_VALUE_UINT(*a)); break;
		case GTK_TYPE_ULONG:	result = newSViv(GTK_VALUE_ULONG(*a)); break;
		case GTK_TYPE_FLOAT:	result = newSVnv(GTK_VALUE_FLOAT(*a)); break;	
		case GTK_TYPE_STRING:	result = newSVpv(GTK_VALUE_STRING(*a),0); break;
		case GTK_TYPE_POINTER:	result = newSVpv(GTK_VALUE_POINTER(*a),0); break;
		case GTK_TYPE_OBJECT:	result = newSVGtkObjectRef(GTK_VALUE_OBJECT(*a), 0); break;
		case GTK_TYPE_SIGNAL:
		{
			AV * args = (AV*)GTK_VALUE_SIGNAL(*a).d;
			SV ** s;
			if ((GTK_VALUE_SIGNAL(*a).f != 0) ||
				(!args) ||
				(SvTYPE(args) != SVt_PVAV) ||
				(av_len(args) < 3) ||
				!(s = av_fetch(args, 2, 0))
				)
				croak("Unable to return a foreign signal type to Perl");

			result = newSVsv(*s);
			return;
		}
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				result = newSV$_(GTK_VALUE_ENUM(*a));\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
EOT

foreach (sort keys %flags) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				result = newSV$_(GTK_VALUE_FLAGS(*a));\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				result = newSVGdkEvent(GTK_VALUE_BOXED(*a));
			else
EOT

foreach (sort keys %boxed) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				result = newSV$_(GTK_VALUE_BOXED(*a));\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot get argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
	return result;
}

void GtkSetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_CHAR:		GTK_VALUE_CHAR(*a) = SvIV(v); break;
		case GTK_TYPE_BOOL:		GTK_VALUE_BOOL(*a) = SvIV(v); break;
		case GTK_TYPE_INT:		GTK_VALUE_INT(*a) = SvIV(v); break;
		case GTK_TYPE_UINT:		GTK_VALUE_UINT(*a) = SvIV(v); break;
		case GTK_TYPE_LONG:		GTK_VALUE_LONG(*a) = SvIV(v); break;
		case GTK_TYPE_ULONG:	GTK_VALUE_ULONG(*a) = SvIV(v); break;
		case GTK_TYPE_FLOAT:	GTK_VALUE_FLOAT(*a) = SvNV(v); break;	
		case GTK_TYPE_STRING:	GTK_VALUE_STRING(*a) = SvPV(v,na); break;
		case GTK_TYPE_POINTER:	GTK_VALUE_POINTER(*a) = SvPV(v,na); break;
		case GTK_TYPE_OBJECT:	GTK_VALUE_OBJECT(*a) = SvGtkObjectRef(v, "Gtk::Object"); break;
		case GTK_TYPE_SIGNAL:
		{
			AV * args;
			int i,j;
			int type;
			char * c = strchr(a->name, ':');
			c+=2;
			c = strchr(c, ':');
			c += 2;
			args = newAV();

			type = gtk_signal_lookup(c, Object->klass->type);

			av_push(args, newSVsv(Class));
			av_push(args, newSVpv(c, 0));
			av_push(args, newSVsv(v));
			av_push(args, newSViv(type));

			GTK_VALUE_SIGNAL(*a).f = 0;
			GTK_VALUE_SIGNAL(*a).d = args;
			return;
		}
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				GTK_VALUE_ENUM(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}
print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
EOT
foreach (sort keys %flags) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				GTK_VALUE_FLAGS(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				GTK_VALUE_BOXED(*a) = SvGdkEvent(v);
			else
EOT
foreach (sort keys %boxed) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				GTK_VALUE_BOXED(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot set argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
}

void GtkSetRetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_CHAR:		*GTK_RETLOC_CHAR(*a) = SvIV(v); break;
		case GTK_TYPE_BOOL:		*GTK_RETLOC_BOOL(*a) = SvIV(v); break;
		case GTK_TYPE_INT:		*GTK_RETLOC_INT(*a) = SvIV(v); break;
		case GTK_TYPE_UINT:		*GTK_RETLOC_UINT(*a) = SvIV(v); break;
		case GTK_TYPE_LONG:		*GTK_RETLOC_LONG(*a) = SvIV(v); break;
		case GTK_TYPE_ULONG:	*GTK_RETLOC_ULONG(*a) = SvIV(v); break;
		case GTK_TYPE_FLOAT:	*GTK_RETLOC_FLOAT(*a) = SvNV(v); break;	
		case GTK_TYPE_STRING:	*GTK_RETLOC_STRING(*a) = SvPV(v,na); break;
		case GTK_TYPE_POINTER:	*GTK_RETLOC_POINTER(*a) = SvPV(v,na); break;
		case GTK_TYPE_OBJECT:	*GTK_RETLOC_OBJECT(*a) = SvGtkObjectRef(v, "Gtk::Object"); break;
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				*GTK_RETLOC_ENUM(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}
print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
EOT
foreach (sort keys %flags) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				*GTK_RETLOC_FLAGS(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				*GTK_RETLOC_BOXED(*a) = SvGdkEvent(v);
			else
EOT
foreach (sort keys %boxed) {
	$p = $_;
	$p =~ s/^Gtk//;
	$p =~ s/([a-z])([A-Z])/$1_$2/g;
	$p = "GTK_TYPE_" . uc $p;
	print "#ifdef $p\n";
	print "			if (a->type == $p)\n";
	print "				GTK_VALUE_BOXED(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n";
}

print <<"EOT";
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot set argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
}

void initPerlGtkDefs(void) {
	int i;
	HV * h;
	pG_EnumHash = newHV();
	pG_FlagsHash = newHV();
	
EOT
$i = 0;
foreach (sort keys %enum) {
	$p = perlize($_);
	print "\n	h = newHV();\n";
	print "	pGtkType[$i] = h;\n";
	print "	pGtkTypeName[$i] = \"$p\";\n";
	for ($j=0;$j<@{$enum{$_}};$j++) {
		$p = $enum{$_}[$j][0];
		print "	hv_store(h, \"$p\", ", length($p), ", newSViv(", $enum{$_}[$j][1],"), 0);\n";
	}
	$p = perlize($_);
	print "	hv_store(pG_EnumHash, \"$p\", ", length($p), ", newRV((SV*)h), 0);\n";
	print " SvREFCNT_dec(h);\n";
	$i++;
}

foreach (sort keys %flags) {
	$p = perlize($_);
	print "\n	h = newHV();\n";
	print "	pGtkType[$i] = h;\n";
	print "	pGtkTypeName[$i] = \"$p\";\n";
	for ($j=0;$j<@{$flags{$_}};$j++) {
		$p = $flags{$_}[$j][0];
		print "	hv_store(h, \"$p\", ", length($p), ", newSViv(", $flags{$_}[$j][1],"), 0);\n";
	}
	$p = perlize($_);
	print "	hv_store(pG_FlagsHash, \"$p\", ", length($p), ", newRV((SV*)h), 0);\n";
	print " SvREFCNT_dec(h);\n";
	$i++;
}
print <<"EOT";

	/*for(i=0;i<$i;i++) {
		HV * p = perl_get_hv(pGtkTypeName[i], TRUE);
		sv_setsv((SV*)p, (SV*)pGtkType[i]);
	}*/

	gtk_typecasts = newAV();
	types = newHV();

EOT
foreach (sort keys %object) {
	$p = perlize($_);
	print "\tadd_typecast(", lc $object{$_}[0], "_get_type(),	\"$p\");\n"
		;#unless /preview/i;
}


print "}\n";


open(STDOUT,">boxed.xsh");

foreach (sort keys %boxed) {
	$p = perlize($_);
	print <<"EOT";
	
MODULE = Gtk	PACKAGE = $p

void
DESTROY(self)
	$p	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	$boxed{$_}[1](self);

EOT
}

open(STDOUT,">objects.xsh");

foreach (sort keys %object) {
	$p = perlize($_);
	$c = lc $object{$_}->[0];
	print <<"EOT";
	
MODULE = Gtk	PACKAGE = $p		PREFIX = ${c}_

int
${c}_get_type(self)
	$p	self
	CODE:
	RETVAL = ${c}_get_type();
	OUTPUT:
	RETVAL

int
${c}_get_size(self)
	$p	self
	CODE:
	RETVAL = sizeof($_);
	OUTPUT:
	RETVAL


int
${c}_get_class_size(self)
	$p	self
	CODE:
	RETVAL = sizeof(${_}Class);
	OUTPUT:
	RETVAL

EOT
}

pos = 0;

__END__;

;additions over gtk.defs from gtk+-0.99.2:

;(define-enum GtkCurveType
;  (linear GTK_CURVE_TYPE_LINEAR)
;  (spline GTK_CURVE_TYPE_SPLINE)
;  (free GTK_CURVE_TYPE_FREE))

;(define-enum GtkSelectionMode
;  (single GTK_SELECTION_SINGLE)
;  (browse GTK_SELECTION_BROWSE)
;  (multiple GTK_SELECTION_MULTIPLE)
;  (extended GTK_SELECTION_EXTENDED))

;(define-enum GdkFunction
;  (copy GDK_COPY)
;  (invert GDK_INVERT)
;  (xor GDK_XOR)) 

;(define-enum GdkFill
;  (solid GDK_SOLID)
;  (tiled GDK_TILED)
;  (stippled GDK_STIPPLED)
;  (opaque-stippled GDK_OPAQUE_STIPPLED))

;(define-enum GdkLineStyle
;  (solid GDK_LINE_SOLID)
;  (on-off-dash GDK_LINE_ON_OFF_DASH)
;  (double-dash GDK_LINE_DOUBLE_DASH))

;(define-enum GdkInputMode
;  (disabled GDK_MODE_DISABLED)
;  (screen GDK_MODE_SCREEN)
;  (window GDK_MODE_WINDOW))

;(define-enum GdkInputSource
;  (mouse GDK_SOURCE_MOUSE)
;  (pen GDK_SOURCE_PEN)
;  (eraser GDK_SOURCE_ERASER)
;  (cursor GDK_SOURCE_CURSOR))


;(define-enum GdkAxisUse
;  (ignore GDK_AXIS_IGNORE)
;  (x GDK_AXIS_X)
;  (y GDK_AXIS_Y)
;  (pressure GDK_AXIS_PRESSURE)
;  (xtilt GDK_AXIS_XTILT)
;  (ytilt GDK_AXIS_YTILT)
;  (last GDK_AXIS_LAST))

;(define-enum GtkJustification
;  (left GTK_JUSTIFY_LEFT)
;  (right GTK_JUSTIFY_RIGHT)
;  (center GTK_JUSTIFY_CENTER)
;  (fill GTK_JUSTIFY_FILL))

;(define-enum GdkDndType
;  (not-dnd GDK_DNDTYPE_NOTDND)
;  (unknown GDK_DNDTYPE_UNKNOWN)
;  (raw-data GDK_DNDTYPE_RAWDATA)
;  (file GDK_DNDTYPE_FILE)
;  (files GDK_DNDTYPE_FILES)
;  (text GDK_DNDTYPE_TEXT)
;  (dir GDK_DNDTYPE_DIR)
;  (link GDK_DNDTYPE_LINK)
;  (exe GDK_DNDTYPE_EXE)
;  (url GDK_DNDTYPE_URL)
;  (mime GDK_DNDTYPE_MIME)
;  (end GDK_DNDTYPE_END))

;(define-enum GtkUpdateType
;  (continuous GTK_UPDATE_CONTINUOUS)
;  (discontinuous GTK_UPDATE_DISCONTINUOUS)
;  (delayed GTK_UPDATE_DELAYED))

;(define-object GtkHandleBox (GtkEventBox))


;(define-object GtkAdjustment (GtkData))
;(define-object GtkAspectFrame (GtkFrame))
;(define-object GtkAlignment (GtkBin))
;(define-object GtkArrow (GtkMisc))
;(define-object GtkBin (GtkContainer))
;(define-object GtkBox (GtkContainer))
;(define-object GtkButton (GtkContainer))
;(define-object GtkCheckButton (GtkToggleButton))
;(define-object GtkColorSelection (GtkVBox))
;(define-object GtkColorSelectionDialog (GtkWindow))
;(define-object GtkContainer (GtkWidget))
;(define-object GtkCurve (GtkDrawingArea))
;(define-object GtkData (GtkObject))
;(define-object GtkDialog (GtkWindow))
;(define-object GtkDrawingArea (GtkWidget))
;(define-object GtkEntry (GtkWidget))
;(define-object GtkFileSelection (GtkWindow))
;(define-object GtkFrame (GtkBin))
;(define-object GtkGammaCurve (GtkVBox))
;(define-object GtkHBox (GtkBox))
;(define-object GtkHPaned (GtkPaned))
;(define-object GtkHRuler (GtkRuler))
;(define-object GtkHScale (GtkScale))
;(define-object GtkHScrollbar (GtkScrollbar))
;(define-object GtkHSeparator (GtkSeparator))
(define-object GtkImage (GtkMisc))
;(define-object GtkInputDialog (GtkWindow))
;(define-object GtkItem (GtkBin))
;(define-object GtkLabel (GtkMisc))
;(define-object GtkList (GtkContainer))
;(define-object GtkListItem (GtkItem))
;(define-object GtkMenu (GtkMenuShell))
;(define-object GtkMenuBar (GtkMenuShell))
;(define-object GtkMenuItem (GtkItem))
;(define-object GtkMenuShell (GtkContainer))
;(define-object GtkMisc (GtkWidget))
;(define-object GtkNotebook (GtkContainer))
;(define-object GtkObject ())
;(define-object GtkOptionMenu (GtkButton))
;(define-object GtkPaned (GtkContainer))
;(define-object GtkPixmap (GtkMisc))
;(define-object GtkPreview (GtkWidget))
;(define-object GtkProgressBar (GtkWidget))
;(define-object GtkRadioButton (GtkCheckButton))
;(define-object GtkRadioMenuItem (GtkCheckMenuItem))
;(define-object GtkRange (GtkWidget))
;(define-object GtkRuler (GtkWidget))
;(define-object GtkScale (GtkRange))
;(define-object GtkScrollbar (GtkRange))
;(define-object GtkScrolledWindow (GtkContainer))
;(define-object GtkSeparator (GtkWidget))
;(define-object GtkTable (GtkContainer))
;(define-object GtkText (GtkWidget))
;(define-object GtkToggleButton (GtkButton))
;(define-object GtkTree (GtkContainer))
;(define-object GtkTreeItem (GtkItem))
;(define-object GtkVBox (GtkBox))
;(define-object GtkViewport (GtkBin))
;(define-object GtkVPaned (GtkPaned))
;(define-object GtkVRuler (GtkRuler))
;(define-object GtkVScale (GtkScale))
;(define-object GtkVScrollbar (GtkScrollbar))
;(define-object GtkVSeparator (GtkSeparator))
;(define-object GtkWidget (GtkObject))
;(define-object GtkWindow (GtkBin))
;
;(define-object GtkCheckMenuItem (GtkMenuItem))
;(define-object GtkButtonBox (GtkBox))
;(define-object GtkEventBox (GtkBin))
;(define-object GtkFixed (GtkContainer))
;(define-object GtkHButtonBox (GtkButtonBox))
;(define-object GtkVButtonBox (GtkButtonBox))

;(define-boxed GdkFont
;  gdk_font_ref
;  gdk_font_unref)

(define-enum GdkInputSource
  (mouse GDK_SOURCE_MOUSE)
  (pen GDK_SOURCE_PEN)
  (eraser GDK_SOURCE_ERASER)
  (cursor GDK_SOURCE_CURSOR))

(define-enum GdkInputMode
  (disabled GDK_MODE_DISABLED)
  (screen GDK_MODE_SCREEN)
  (window GDK_MODE_WINDOW))

(define-enum GdkAxisUse
  (ignore GDK_AXIS_IGNORE)
  (x GDK_AXIS_X)
  (y GDK_AXIS_Y)
  (pressure GDK_AXIS_PRESSURE)
  (x-tilt GDK_AXIS_XTILT)
  (y-tilt GDK_AXIS_YTILT)
  (last GDK_AXIS_LAST))

;(define-object GtkToolbar (GtkContainer))

