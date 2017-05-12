#!/usr/bin/perl -w

package gendefs;

sub gendefs {
	local(@ARGV) = @_;

# Minimal LISP lexer/parser. No quote escapes currently handled.
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
#	if (!/^(Gtk|Gdk)/) {
#		s/^([A-Z][a-z]*)/Gtk$1::/;
#	}
#	s/^Gtk/Gtk::/;
#	s/^Gtk::Gdk/Gtk::Gdk::/;
#	s/^Gdk/Gtk::Gdk::/;
	foreach $p (@prefix) {
		my($f, $t) = @{$p};
		next if /^${t}::/;
		s/^$f/${t}::/;
	}
	$_;
}

sub xsize {
	local($_) = @_;
	s/::/__/g;
	$_;
}

sub typeize {
	local($_) = @_;
	#my ($old) = $_;
	#s/([A-Z])/_$1/g;
	s/([A-Z][a-z])/_$1/g;
	s/([a-z])([A-Z])/$1_$2/g;
	$_ = uc $_;
	s/_([A-Z])_/_$1/g;
	s/^_GTK//;
	# exceptions
	#s/GNOME_MD_I/GNOME_MDI_/;
	#warn "BOO: $_\n" if "GTK_TYPE$_" ne oldtypeize($old);
	return "GTK_TYPE".$_;
}

sub oldtypeize {
	local($_) = @_;
	s/([a-z])([A-Z])/${1}_$2/g;
	$_ = uc $_;
	s/^GTK_/GTK_TYPE_/;
	s/^GNOME_/GTK_TYPE_GNOME_/;
	s/^GDK_/GTK_TYPE_GDK_/;
	$_;
}

%opt = ();
%enum = ();
%boxed = ();
%flags = ();
%struct = ();
%object = ();

# Record command line options
for ($i=0;$i<@ARGV;$i++) {
	if ($ARGV[$i] =~ /^-([a-zA-Z])/) {
		if (length($')) {
			push @{$opt{$1}}, $';
		} else {
			push @{$opt{$1}}, $ARGV[$i+1];
		}
	}
}

# -L = enable lazyloading

# -d = defs file
# -f = filename prefix
# -i = include files to use in FooDefs.h
# -p = package prefix (Gtk=Gtk, Gdk=Gtk::Gdk, Gnome=Gnome, etc.)
# -m = Module name (Gtk, Gnome, etc.)
## -P = default package prefix (Gtk)

$opt{FilePrefix} = $opt{'f'}[0] || "";

$FilePrefix = $opt{FilePrefix};

foreach (@{$opt{'p'}}) {
	if (/=/) {
		push @prefix, [$`, $'];
	}
}

#$Prefix = $opt{'P'}[0];

$Module = $opt{'m'}[0];

$Lazy = $opt{'L'} || 0;

# Read all supplied definition files
foreach $file (@{$opt{"d"}}) {
	warn "Loading $file\n";
	if ($file =~ m!^(.*/)!) {
		$_ .= "\n(set-directory \"$1\")\n";
	}
	open(F,"<$file") || next;
	$_ .= join("",<F>);
	close(F);

	$_ .= "\n(set-directory \"\")\n";
}

$_ =~ s/;.*$//gm;

$directory = "";

sub process_node {
	my(@node) = @{$_[0]};

	if ( !defined($node[0]) ) {
		return;
	}
	
	if ($node[0] eq "set-directory") {
		$directory = $node[1];
		print "Dir |$directory|\n";
		return;
	}

	if ($node[0] eq "min-version") {
		my($h) = $node[1];
		$h = "0x$h" unless $h =~ /^0x/;
		
		if ($::gtk_hver < hex($h)) {
			return;
		}
		
		foreach $node (@node[2..$#node]) {
			process_node($node);
		}
		return;
	}

	if ($node[0] eq "max-version") {
		my($h) = $node[1];
		$h = "0x$h" unless $h =~ /^0x/;
		
		if ($::gtk_hver > hex($h)) {
			return;
		}
		
		foreach $node (@node[2..$#node]) {
			process_node($node);
		}
		return;
	}

	if ($node[0] eq "version") {
		my($h) = $node[1];
		$h = "0x$h" unless $h =~ /^0x/;
		
		if ($::gtk_hver != hex($h)) {
			return;
		}
		
		foreach $node (@node[2..$#node]) {
			process_node($node);
		}
		return;
	}
	
	if ($node[0] eq "define-enum") {
		@enum = ();
		my($perl) = perlize($node[1]);
		foreach (@node[2..$#node]) {
			if (not ref $_) {
				$perl = $_;
				next;
			}
			# new convention is to use '-'
			#$_->[0] =~ tr/-/_/;
			$_->[0] =~ tr/_/-/;
			push @enum, {simple => $_->[0], constant => $_->[1]};
		}
		if ( exists $enum{$node[1]} ) {
			warn "Overriding enum `$node[1]'\n";
		}
		$enum{$node[1]}->{'values'} = [@enum];
		$enum{$node[1]}->{perlname} = $perl;
		$enum{$node[1]}->{xsname} = xsize($perl);
		$enum{$node[1]}->{typename} = typeize($node[1]);
		$enum{$node[1]}->{directory} = $directory;
		
	} elsif ($node[0] eq "define-boxed") {
		if ( exists $boxed{$node[1]} ) {
			warn "Overriding boxed `$node[1]'\n";
		}
		$boxed{$node[1]}->{'ref'} = $node[2];
		$boxed{$node[1]}->{unref} = $node[3];
		if (defined $node[4]) {
			$boxed{$node[1]}->{size} = $node[4];
		}

		my($perl) = perlize($node[1]);
		$boxed{$node[1]}->{perlname} = $perl;
		$boxed{$node[1]}->{xsname} = xsize($perl);
		$boxed{$node[1]}->{typename} = typeize($node[1]);
		$boxed{$node[1]}->{directory} = $directory;
		
	} elsif ($node[0] eq "define-flags") {
		@flag = ();
		my($perl) = perlize($node[1]);
		foreach (@node[2..$#node]) {
			if (not ref $_) {
				$perl = $_;
				next;
			}
			# new convention is to use '-'
			#$_->[0] =~ tr/-/_/;
			$_->[0] =~ tr/_/-/;
			push @flag, {simple => $_->[0], constant => $_->[1]};
		}
		if ( exists $flags{$node[1]} ) {
			warn "Overriding flags `$node[1]'\n";
		}
		$flags{$node[1]}->{'values'} = [@flag];
		$flags{$node[1]}->{perlname} = $perl;
		$flags{$node[1]}->{xsname} = xsize($perl);
		$flags{$node[1]}->{typename} = typeize($node[1]);
		$flags{$node[1]}->{directory} = $directory;

	} elsif ($node[0] eq "define-struct") {
		my($struct) = {directory => $directory };
		
		my($perl) = perlize($node[1]);
		if ( exists $struct{$node[1]} ) {
			warn "Overriding struct `$node[1]'\n";
		}

		foreach $node (@node[2..$#node]) {
			if (not ref $node) {
				$perl = $node;
			} else {
				my (@node) = @$node;
				if ($node[0] eq "members") {
					foreach $node (@node[1..$#node]) {
						my(@node) = @$node;
						push @{$struct->{members}}, { name => $node[0], type => $node[1] };
					}
				}
			}
		}

		$struct->{perlname} = $perl;
		$struct->{xsname} = xsize($perl);
		$struct->{typename} = typeize($node[1]);
		

		$struct{$node[1]} = $struct;
		
	} elsif ($node[0] eq "define-object") {
		my($object) = {parent => $node[2]->[0], directory => ($directory."") };

		my ($cast) = $node[1];
		$cast =~ s/([a-z])([A-Z])/${1}_$2/g;
		my($perl) = perlize($node[1]);
		
		#print "Obj |$perl| in $directory\n";
		
		foreach $node (@node[3..$#node]) {
			my (@node) = @$node;
			if ($node[0] eq "fields") {
				my(@fields) = ();
				foreach (@node[1..$#node]) {
					push @fields, {type => $_->[0], name => $_->[1]};
				}
				$object->{fields} = [@fields];
			}
			elsif ($node[0] eq "cast") {
				$cast = $node[1];
			}
			elsif ($node[0] eq "perl") {
				$perl = $node[1];
			}
		}
		if ( exists $object{$node[1]} ) {
			warn "Overriding object `$node[1]'\n";
		}

		$object{$node[1]} = $object;
		$object{$node[1]}->{perlname} = $perl;
		$object{$node[1]}->{xsname} = xsize($perl);
		
		$object{$node[1]}->{cast} = uc $cast;
		$object{$node[1]}->{prefix} = lc $cast;
		$objectlc{lc $cast} = $node[1];
		
	} elsif ($node[0] eq "define-func") {
		my($func) = {returntype => $node[2], directory => $directory };
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
		
		my($perl) = perlize($node[1]);
		$func->{perlname} = $perl;
		$func->{xsname} = xsize($perl);
		
		if ( exists $func{$node[1]} ) {
			warn "Overriding func `$node[1]'\n";
		}
		$func{$node[1]} = $func;


	} elsif ($node[0] eq "export-enum") {
		warn "Cannot export unknown enum `$node[1]'\n" if not exists $enum{$node[1]};
		$enum{$node[1]}->{export} = 1;
	} elsif ($node[0] eq "export-boxed") {
		warn "Cannot export unknown boxed `$node[1]'\n" if not exists $boxed{$node[1]};
		$boxed{$node[1]}->{export} = 1;
	} elsif ($node[0] eq "export-flags") {
		warn "Cannot export unknown flags `$node[1]'\n" if not exists $flags{$node[1]};
		$flags{$node[1]}->{export} = 1;
	} elsif ($node[0] eq "export-struct") {
		warn "Cannot export unknown struct `$node[1]'\n" if not exists $struct{$node[1]};
		$struct{$node[1]}->{export} = 1;
	}
}

# Parse the data and disect it into separate definitions
foreach $node (parse_lisp($_)) {
	
	process_node($node);

}

# Better way to get export stuff right with gtk+ 1.2.x:
# We query gtk directly about the types it knows about...
open(T, ">gtktypexp.c");
print T <<'EOT';
#include <gtk/gtktypeutils.h>
#include <stdio.h>
#include <string.h>

int 
main() {
	char buf[256];
	char *p;
	GSList *names=NULL;

	gtk_type_init();
	while(fgets(buf, 256, stdin)) {
		p = strchr(buf, '\n');
		if (p)
			*p = 0;
		names = g_slist_prepend(names, g_strdup(buf));
	}
	for (; names; names = names->next) {
		if (gtk_type_from_name((char*)names->data))
			fprintf(stdout, "%s\n", names->data);
	}
	return 0;
}
EOT
close(T);

use Config;

#this two lines break the build on debian sparc: investigate
#$c = "$Config{cc} $::inc gtktypexp.c $::libs -o gtktypexp";
#open(T, "|$c 2> /dev/null && ./gtktypexp > gtktypexp.out 2> /dev/null");
system("$Config{cc} $::inc gtktypexp.c $::libs -o gtktypexp");
open(T, "|./gtktypexp > gtktypexp.out 2> /dev/null");
foreach my $hasht ((\%enum, \%flags, \%struct, \%boxed)) {
	foreach (keys %{$hasht}) {
		print T "$_\n";
	}
}
close(T);
open(T, "gtktypexp.out");
@e = <T>;
chomp(@e);
@texported{@e} = ();
close(T);
unlink("gtktypexp.out", "gtktypexp", "gtktypexp.o", "gtktypexp.c");
foreach my $hasht ((\%enum, \%flags, \%struct, \%boxed)) {
	# does not work because gtk is broken: GTK_TYPE_GDK_WMFUNCTION
	last;
	# disabled for sub-modules...
	last if $Module ne "Gtk";
	foreach (keys %{$hasht}) {
		#print "Checking $_: ", exists $texported{$_}, "\n";
		$hasht->{$_}->{export} = exists $texported{$_};
	}
}

# handle non-exported enums and flags...
$enum_flags_code_decl = "";
$enum_flags_code_init = "";
$enum_flags_code_incl = "";

foreach (sort keys %enum) {
	next if $enum{$_}->{export};
	print "Exporting enum: $_\n";
	$v = $enum{$_};
	$enum_flags_code_init .= "if (!($v->{typename}=gtk_type_from_name(\"$_\")))\n";
	$enum_flags_code_init .= "\t\t$v->{typename} = gtk_type_register_enum(\"$_\", names_$_);\n";
	$enum_flags_code_incl .= "extern GtkType $v->{typename};\n";
	$enum_flags_code_decl .= "GtkType $v->{typename};\n";
	$enum_flags_code_decl .= "static GtkEnumValue names_$_"."[] = {\n";
	foreach $v (@{$enum{$_}->{'values'}}) {
		 $enum_flags_code_decl .= "\t{$v->{constant}, \"$v->{constant}\", \"$v->{simple}\"},\n";
	}
	$enum_flags_code_decl .= "\t{0, 0, 0}\n";
	$enum_flags_code_decl .= "};\n";
	$enum{$_}->{export} = 1;
}

foreach (sort keys %flags) {
	next if $flags{$_}->{export};
	print "Exporting flags: $_\n";
	$v = $flags{$_};
	$enum_flags_code_init .= "if (!($v->{typename}=gtk_type_from_name(\"$_\")))\n";
	$enum_flags_code_init .= "\t\t$v->{typename} = gtk_type_register_flags(\"$_\", names_$_);\n";
	$enum_flags_code_incl .= "extern GtkType $v->{typename};\n";
	$enum_flags_code_decl .= "GtkType $v->{typename};\n";
	$enum_flags_code_decl .= "static GtkEnumValue names_$_"."[] = {\n";
	foreach $v (@{$flags{$_}->{'values'}}) {
		$enum_flags_code_decl .= "\t{$v->{constant}, \"$v->{constant}\", \"$v->{simple}\"},\n";
	}
	$enum_flags_code_decl .= "\t{0, 0, 0}\n";
	$enum_flags_code_decl .= "};\n";
	$flags{$_}->{export} = 1;
}



delete $pointer{""};
#foreach (qw(CHAR BOOL INT UINT LONG ULONG FLOAT DOUBLE STRING ENUM FLAGS BOXED OBJECT POINTER)) {
#	$pointer{$_} = $_;
#}

#use Data::Dumper;
#
#print Dumper(\%enum);
#print Dumper(\%flags);
#print Dumper(\%boxed);
#print Dumper(\%object);
#print Dumper(\%func);
#print Dumper(\%struct);

foreach (@ARGV) {
	if (-f "$_.opl") {
		do "$_.opl";
	}
}
#do 'overrides.pl';

delete $object{""};
delete $func{""};
delete $boxed{""};
delete $flags{""};
delete $struct{""};

delete $objectlc{""}; # Shut up warning
delete $overridestruct{""}; # Shut up warning
delete $overrideboxed{""}; # Shut up warning

foreach (sort keys %object) {
	if (not defined $object{$_}) {
		print "Improperly defined object $_\n";
	}
}

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

select(OUT);

foreach (sort keys %object) {
	#print STDERR "Obj '$_', directory $object{$_}->{directory}, perlname $object{$_}->{perlname}\n";
	my($f) = $object{$_}->{directory} . "xs/$_.xs";
	if (!-f "$f") {
		print STDERR "Unable to find widget file $f: creating from template.\n";
		open(OUT,">$f") or die "Unable to write to $f: $!";
		print <<"EOT";

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

EOT
		# this introduces pointer to functions and may generate crashes
		#if ($FilePrefix ne "Gtk") {
		#	print "#include \"PerlGtkExt.h\"\n";
		#}

		print <<"EOT";
#include "Perl${FilePrefix}Int.h"

#include "${FilePrefix}Defs.h"

MODULE = $object{$_}->{perlname}		PACKAGE = $object{$_}->{perlname}		PREFIX = $object{$_}->{prefix}_

#ifdef $object{$_}->{cast}

#endif

EOT
		close(OUT);
	}
}



open(OUT,">build/$opt{FilePrefix}Typemap") or die "Unable to write to build/$opt{FilePrefix}Typemap: $!";
print "\n\n# Do not edit this file, as it is automatically generated by gendefs.pl\n\n";
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
	print $object{$_}->{perlname},"_Sink\tT_GtkPTROBJSink\n";
	print $object{$_}->{perlname},"_OrNULL\tT_GtkPTROBJOrNULL\n";
	#print perlize($_),"\tT_GtkPTROBJ\n";
}
foreach (sort keys %boxed) {
	print $boxed{$_}->{perlname},"\tT_SimpleVal\n";
	print $boxed{$_}->{perlname},"_OrNULL\tT_SimpleValOrNULL\n";
	#print perlize($_),"\tT_SimpleVal\n"; #MISCPTROBJ\n";
}
foreach (sort keys %struct) {
	print $struct{$_}->{perlname},"\tT_SimpleVal\n";
	print $struct{$_}->{perlname},"_OrNULL\tT_SimpleValOrNULL\n";
	#print perlize($_),"\tT_SimpleVal\n"; #MISCPTROBJ\n";
}


open(OUT,">build/$opt{FilePrefix}Defs.h") or die "Unable to write to build/$opt{FilePrefix}Defs.h: $!";;
print <<"EOT";

/* Do not edit this file, as it is automatically generated by gendefs.pl */

#ifndef _${FilePrefix}_Defs_h_
#define _${FilePrefix}_Defs_h_

#include "ppport.h"

/* Clean up some Perl Pollution that confuses Gnome */
#ifdef _
#undef _
#endif

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# undef printf
#endif

#ifndef Perl${FilePrefix}DeclareFunc
#include "Perl${FilePrefix}Int.h"
#endif

EOT

foreach (@{$opt{"i"}}) {
	print "#include $_\n";
}

print <<"EOT";

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# define printf PerlIO_stdoutf
#endif

Perl${FilePrefix}DeclareFunc(void, $opt{FilePrefix}_InstallObjects)(void);
Perl${FilePrefix}DeclareFunc(void, $opt{FilePrefix}_InstallTypedefs)(void);

EOT

print $enum_flags_code_incl;

$i = 0;
foreach (sort keys %enum) {
	print "#define TYPE_$_\n";
	if ($enum{$_}->{export}) {
		print "#define newSV$_(value) newSVDefEnumHash($enum{$_}->{typename}, (value))\n";
		print "#define Sv$_(value) SvDefEnumHash($enum{$_}->{typename}, (value))\n";
	} else {
		print "Perl${FilePrefix}DeclareFunc(SV *, newSV$_)($_ value);\n";
		print "Perl${FilePrefix}DeclareFunc($_, Sv$_)(SV * value);\n";
	}
#	print "#define pGE_$_ pGtkType[$i]\n";
#	print "#define pGEName_$_ pGtkTypeName[$i]\n";
#	print "#define newSV$_(v) newSVOptsHash(v, pGEName_$_, pGE_$_)\n";
#	print "#define Sv$_(v) SvOptsHash(v, pGEName_$_, pGE_$_)\n";
	print "typedef $_ $enum{$_}->{xsname};\n";
#	if ($_ !~ /^Gtk/) {
#		print "#define newSVGtk$_(v) newSVOptsHash(v, pGEName_$_, pGE_$_)\n";
#		print "#define SvGtk$_(v) SvOptsHash(v, pGEName_$_, pGE_$_)\n";
#	}
	$i++;
}
foreach (sort keys %flags) {
	print "#define TYPE_$_\n";
	if ($flags{$_}->{export}) {
		print "#define newSV$_(value) newSVDefFlagsHash($flags{$_}->{typename}, (value))\n";
		print "#define Sv$_(value) SvDefFlagsHash($flags{$_}->{typename}, (value))\n";
	} else {
		print "Perl${FilePrefix}DeclareFunc(SV *, newSV$_)($_ value);\n";
		print "Perl${FilePrefix}DeclareFunc($_, Sv$_)(SV * value);\n";
	}
#	print "#define pGF_$_ pGtkType[$i]\n";
#	print "#define pGFName_$_ pGtkTypeName[$i]\n";
#	# Generate arrays
#	print "#define newSV$_(v) newSVFlagsHash(v, pGFName_$_, pGF_$_, 1)\n";
#	print "#define Sv$_(v) SvFlagsHash(v, pGFName_$_, pGF_$_)\n";
	print "typedef $_ $flags{$_}->{xsname};\n";
#	if ($_ !~ /^Gtk/) {
#		print "#define newSVGtk$_(v) newSVFlagsHash(v, pGFName_$_, pGF_$_, 1)\n";
#		print "#define SvGtk$_(v) SvFlagsHash(v, pGFName_$_, pGF_$_)\n";
#	}
	$i++;
}
foreach (sort keys %boxed) {
	print "#define TYPE_$_\n";
	print "Perl${FilePrefix}DeclareFunc(SV *, newSV$_)($_ * value);\n";
	print "Perl${FilePrefix}DeclareFunc($_ *, Sv$_)(SV * value);\n";
	print "typedef $_ * $boxed{$_}->{xsname};\n";
	print "typedef $_ * $boxed{$_}->{xsname}_OrNULL;\n";
#	if ($_ !~ /^Gtk/) {
#		print "#define newSVGtk$_ newSV$_\n";
#		print "#define SvGtk$_ Sv$_\n";
#	}
}
foreach (sort keys %struct) {
	print "#define TYPE_$_\n";
	print "Perl${FilePrefix}DeclareFunc(SV *, newSV$_)($_ * value);\n";
	print "Perl${FilePrefix}DeclareFunc($_ *, SvSet$_)(SV * value, $_ * dest);\n";
	print "#define Sv$_(value) SvSet$_((value), 0)\n";
	print "typedef $_ * $struct{$_}->{xsname};\n";
	print "typedef $_ * $struct{$_}->{xsname}_OrNULL;\n";
#	if ($_ !~ /^Gtk/) {
#		print "#define newSVGtk$_ newSV$_\n";
#		print "#define SvGtk$_ Sv$_\n";
#		print "#define SvSetGtk$_ SvSet$_\n";
#	}
}
foreach (sort keys %object) {
	print "#ifdef $object{$_}->{cast}\n";
	print "#define TYPE_$_\n";
	print "typedef $_ * $object{$_}->{xsname};\n";
	print "typedef $_ * $object{$_}->{xsname}_OrNULL;\n";
	print "typedef $_ * $object{$_}->{xsname}_Sink;\n";
	print "#define Cast$object{$_}->{xsname} $object{$_}->{cast}\n";
	print "#define Cast$object{$_}->{xsname}_OrNULL $object{$_}->{cast}\n";
	print "#define Cast$object{$_}->{xsname}_Sink $object{$_}->{cast}\n";
	print "#define newSV$_(x) newSVGtkObjectRef(GTK_OBJECT(x),0)\n";
	print "#define Sv$_(x) $object{$_}->{cast}(SvGtkObjectRef((x),0))\n";
	print "#endif\n";
}

$j = 0;
print "/*extern GtkType ttype[];\n";
foreach (sort keys %pointer) {
	print "#ifndef GTK_TYPE_POINTER_$_\n";
	print "#define GTK_TYPE_POINTER_$_ ttype[$j]\n";
	print "#define need_GTK_TYPE_POINTER_$_\n";
	print "#endif\n";
	$j++;
}
foreach (sort keys %struct) {
	print "#ifndef $struct{$_}->{typename}\n";
	print "#define $struct{$_}->{typename} ttype[$j]\n";
	print "#define need_$struct{$_}->{typename}\n";
	print "#endif\n";
	$j++;
}
foreach (sort keys %boxed) {
	print "#ifndef $boxed{$_}->{typename}\n";
	print "#define $boxed{$_}->{typename} ttype[$j]\n";
	print "#define need_$boxed{$_}->{typename}\n";
	print "#endif\n";
	$j++;
}
print "*/\n";

print "#endif /*_${FilePrefix}_Defs_h_*/\n";

open(OUT,">build/$opt{FilePrefix}Types.pm") or die "Unable to write to build/$opt{FilePrefix}Types.pm: $!";
print "\n\n# Do not edit this file, as it is automatically generated by gendefs.pl\n\n";


print "package $opt{FilePrefix}::Types;\n";
foreach (sort keys %object) {
	if (defined $object{$_}->{parent}) {
		my ($pp) = $object{$object{$_}->{parent}}->{perlname} || perlize($object{$_}->{parent});
		print "\@$object{$_}->{perlname}::ISA = '$pp';\n";
	}
}

print "1;\n";

if ($Lazy) {
open(OUT,">build/$opt{FilePrefix}TypesLazy.pm") or die "Unable to write to build/$opt{FilePrefix}TypesLazy.pm: $!";
print "\n\n# Do not edit this file, as it is automatically generated by gendefs.pl\n\n";


print "package $opt{FilePrefix}::Types;\n";
foreach (sort keys %object) {
	if (defined $object{$_}->{parent}) {
		my ($pp) = $object{$object{$_}->{parent}}->{perlname} || perlize($object{$_}->{parent});
		print "\@$object{$_}->{perlname}::_ISA = '$pp';\n";
		print "\@$object{$_}->{perlname}::ISA = 'Gtk::_LazyLoader';\n";
	}
}

print "1;\n";

}

open(OUT,">build/$opt{FilePrefix}Defs.c")  or die "Unable to write to build/$opt{FilePrefix}Defs.c: $!";

print <<"EOT";

/* Do not edit this file, as it is automatically generated by gendefs.pl*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Perl${FilePrefix}Int.h"

#include "${FilePrefix}Defs.h"

EOT

print "#include \"GtkDefs.h\"\n\n" if ($opt{FilePrefix} ne 'Gtk');

foreach (sort keys %boxed) {
	next if $overrideboxed{$_};
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

foreach (sort keys %struct) {
	next if $overridestruct{$_};
	print <<"EOT";

SV * newSV$_($_ * value) {
	HV * h;
	SV * r;
	
	if (!value)
	  return newSVsv(&PL_sv_undef);

	h = newHV();
	r = newRV((SV*)h);
	SvREFCNT_dec(h);

	sv_bless(r, gv_stashpv("$struct{$_}->{perlname}", TRUE));
	
EOT

	foreach $member (@{$struct{$_}->{members}}) {
		my($name) = $member->{name};
		my($type) = $member->{type};
		if ($struct{$type}) {
			print "	hv_store(h, \"",$name,"\", ",length($name),", newSV$type(&value->$name), 0);\n";
		} else {
			if ($type ne "GtkWidget") {
				print "	hv_store(h, \"",$name,"\", ",length($name),", newSV$type(value->$name), 0);\n";
			} else {
				print "	if (value->$name)\n \thv_store(h, \"",$name,"\", ",length($name),", newSV$type(value->$name), 0);\n";
			}
		}
	}

	print <<"EOT";
	
	return r;
}

$_ * SvSet$_(SV * value, $_ * dest) {
	SV ** s;
	HV * h;
	
	if (!SvOK(value) || !(h=(HV*)SvRV(value)) || (SvTYPE(h) != SVt_PVHV))
		return 0;
	
	if (!dest) {
		dest = pgtk_alloc_temp(sizeof($_));
	}

	memset(dest, 0, sizeof($_));
	
EOT

	foreach $member (@{$struct{$_}->{members}}) {
		my($name) = $member->{name};
		my($type) = $member->{type};
		if ($struct{$type}) {
			print "	if ((s=hv_fetch(h, \"",$name,"\", ",length($name),", 0)) && SvOK(*s))\n";
			print "		SvSet$type(*s, &dest->$name);\n";
		} else {
			print "	if ((s=hv_fetch(h, \"",$name,"\", ",length($name),", 0)) && SvOK(*s))\n";
			print "		dest->$name = Sv$type(*s);\n";
		}
	}

	print <<"EOT";
	
	return dest;
}
EOT
}

print <<"EOT";

static SV * $opt{FilePrefix}_GetArg(GtkArg * a)
{
	SV * result = 0;
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	next if $enum{$_}->{export};
	print "#ifdef $enum{$_}->{typename}\n" unless $enum{$_}->{export};
	print "			if (a->type == $enum{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_ENUM(*a));\n";
	print "			else\n";
	print "#endif\n" unless $enum{$_}->{export};
}

print <<"EOT";
				break;
			break;
		case GTK_TYPE_FLAGS:
EOT

foreach (sort keys %flags) {
	next if $flags{$_}->{export};
	print "#ifdef $flags{$_}->{typename}\n" unless $flags{$_}->{export};
	print "			if (a->type == $flags{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_FLAGS(*a));\n";
	print "			else\n";
	print "#endif\n" unless $flags{$_}->{export};
}

print <<"EOT";
				break;
			break;
		case GTK_TYPE_POINTER:
EOT
		
foreach (sort keys %struct) {
	print "#ifdef $struct{$_}->{typename}\n" unless $struct{$_}->{export};
	print "			if (a->type == $struct{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_POINTER(*a));\n";
	print "			else\n";
	print "#endif\n" unless $struct{$_}->{export};
}

print <<"EOT";
				break;
			break;
		case GTK_TYPE_BOXED:
EOT

foreach (sort keys %boxed) {
	print "#ifdef $boxed{$_}->{typename}\n" unless $boxed{$_}->{export};
	print "			if (a->type == $boxed{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_BOXED(*a));\n";
	print "			else\n";
	print "#endif\n" unless $boxed{$_}->{export};
}

print <<"EOT";
				break;
			break;
	}
	return result;
}

static int $opt{FilePrefix}_SetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	int result = 1;
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_POINTER:
EOT

foreach (sort keys %struct) {
	print "#ifdef $struct{$_}->{typename}\n" unless $struct{$_}->{export};
	print "			if (a->type == $struct{$_}->{typename})\n";
	print "				GTK_VALUE_POINTER(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $struct{$_}->{export};
}
print <<"EOT";
				result = 0;
			break;
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	next if $enum{$_}->{export};
	print "#ifdef $enum{$_}->{typename}\n" unless $enum{$_}->{export};
	print "			if (a->type == $enum{$_}->{typename})\n";
	print "				GTK_VALUE_ENUM(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $enum{$_}->{export};
}
print <<"EOT";
				result = 0;
			break;
		case GTK_TYPE_FLAGS:
EOT
foreach (sort keys %flags) {
	next if $flags{$_}->{export};
	print "#ifdef $flags{$_}->{typename}\n" unless $flags{$_}->{export};
	print "			if (a->type == $flags{$_}->{typename})\n";
	print "				GTK_VALUE_FLAGS(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $flags{$_}->{export};
}

print <<"EOT";
				result = 0;
			break;
		case GTK_TYPE_BOXED:
EOT
foreach (sort keys %boxed) {
	print "#ifdef $boxed{$_}->{typename}\n" unless $boxed{$_}->{export};
	print "			if (a->type == $boxed{$_}->{typename})\n";
	print "				GTK_VALUE_BOXED(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $boxed{$_}->{export};
}

print <<"EOT";
				result = 0;
			break;
		default:
			result = 0;
	}
	return result;
}

static int $opt{FilePrefix}_SetRetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	int result = 1;
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	next if $enum{$_}->{export};
	print "#ifdef $enum{$_}->{typename}\n" unless $enum{$_}->{export};
	print "			if (a->type == $enum{$_}->{typename})\n";
	print "				*GTK_RETLOC_ENUM(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $enum{$_}->{export};
}
print <<"EOT";
				result = 0;
			break;
		case GTK_TYPE_FLAGS:
EOT
foreach (sort keys %flags) {
	next if $flags{$_}->{export};
	print "#ifdef $flags{$_}->{typename}\n" unless $flags{$_}->{export};
	print "			if (a->type == $flags{$_}->{typename})\n";
	print "				*GTK_RETLOC_FLAGS(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $flags{$_}->{export};
}

print <<"EOT";
				result = 0;
			break;
		case GTK_TYPE_POINTER:
EOT

foreach (sort keys %struct) {
	print "#ifdef $struct{$_}->{typename}\n" unless $struct{$_}->{export};
	print "			if (a->type == $struct{$_}->{typename})\n";
	print "				GTK_VALUE_POINTER(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $struct{$_}->{export};
}

print <<"EOT";
				result = 0;
			break;
		case GTK_TYPE_BOXED:
EOT
foreach (sort keys %boxed) {
	print "#ifdef $boxed{$_}->{typename}\n" unless $boxed{$_}->{export};
	print "			if (a->type == $boxed{$_}->{typename})\n";
	print "				GTK_VALUE_BOXED(*a) = Sv$_(v);\n";
	print "			else\n";
	print "#endif\n" unless $boxed{$_}->{export};
}

print <<"EOT";
				result = 0;
			break;
		default:
			result = 0;
	}
	return result;
}

static SV * $opt{FilePrefix}_GetRetArg(GtkArg * a)
{
	SV * result = 0;
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_ENUM:
EOT

foreach (sort keys %enum) {
	next if $enum{$_}->{export};
	print "#ifdef $enum{$_}->{typename}\n" unless $enum{$_}->{export};
	print "			if (a->type == $enum{$_}->{typename})\n";
	print "				result = newSV$_(*GTK_RETLOC_ENUM(*a));\n";
	print "			else\n";
	print "#endif\n" unless $enum{$_}->{export};
}
print <<"EOT";
				break;
			break;
		case GTK_TYPE_FLAGS:
EOT
foreach (sort keys %flags) {
	next if $flags{$_}->{export};
	print "#ifdef $flags{$_}->{typename}\n" unless $flags{$_}->{export};
	print "			if (a->type == $flags{$_}->{typename})\n";
	print "				result = newSV$_(*GTK_RETLOC_FLAGS(*a));\n";
	print "			else\n";
	print "#endif\n" unless $flags{$_}->{export};
}

print <<"EOT";
				break;
			break;
		case GTK_TYPE_POINTER:
EOT

foreach (sort keys %struct) {
	print "#ifdef $struct{$_}->{typename}\n" unless $struct{$_}->{export};
	print "			if (a->type == $struct{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_POINTER(*a));\n";
	print "			else\n";
	print "#endif\n" unless $struct{$_}->{export};
}

print <<"EOT";
				break;
			break;
		case GTK_TYPE_BOXED:
EOT
foreach (sort keys %boxed) {
	print "#ifdef $boxed{$_}->{typename}\n" unless $boxed{$_}->{export};
	print "			if (a->type == $boxed{$_}->{typename})\n";
	print "				result = newSV$_(GTK_VALUE_BOXED(*a));\n";
	print "			else\n";
	print "#endif\n" unless $boxed{$_}->{export};
}

print <<"EOT";
				break;
			break;
	}
	return result;
}

static int $opt{FilePrefix}_FreeArg(GtkArg * a)
{
	return 0;
}

static struct PerlGtkTypeHelper help =
	{
		$opt{FilePrefix}_GetArg,
		$opt{FilePrefix}_SetArg,
		$opt{FilePrefix}_SetRetArg,
		$opt{FilePrefix}_GetRetArg,
		$opt{FilePrefix}_FreeArg,
		0
	};

EOT

print $enum_flags_code_decl;

foreach (sort keys %enum) {
	if ($enum{$_}->{export}) {
		#print "SV * newSV$_($_ v) { return newSVDefEnumHash($enum{$_}->{typename}, v);}\n";
		#print "$_ Sv$_(SV * s) { return SvDefEnumHash($enum{$_}->{typename}, s); }\n\n";
	} else {
		print "\nstatic HV * enum_$_;\n";
		print "SV * newSV$_($_ v) { return newSVOptsHash(v, \"$enum{$_}->{perlname}\", enum_$_); }\n";
		print "$_ Sv$_(SV * s) { return SvOptsHash(s, \"$enum{$_}->{perlname}\", enum_$_); }\n\n";
	}
}

foreach (sort keys %flags) {
	if ($flags{$_}->{export}) {
		# MAYBE its better to return an array ref instead of an hash
		#print "SV * newSV$_($_ v) { return newSVDefFlagsHash($flags{$_}->{typename}, v, 1);}\n";
		#print "$_ Sv$_(SV * s) { return SvDefFlagsHash($flags{$_}->{typename}, s); }\n\n";
	} else {
		print "\nstatic HV * flags_$_;\n";
		print "SV * newSV$_($_ v) { return newSVFlagsHash(v, \"$flags{$_}->{perlname}\", flags_$_); }\n";
		print "$_ Sv$_(SV * s) { return SvFlagsHash(s, \"$flags{$_}->{perlname}\", flags_$_); }\n\n";
	}
}



print <<"EOT";

void $opt{FilePrefix}_InstallTypedefs(void) {
	static int did_it = 0;
	if (did_it)
		return;
	did_it = 1;
	
EOT

print $enum_flags_code_init;

$i = 0;
foreach (sort keys %enum) {
	next if $enum{$_}->{export};
	next; # disable
	print "\n	enum_$_ = newHV();\n";
	foreach $v (@{$enum{$_}->{'values'}}) {
		print "	hv_store(enum_$_, \"$v->{simple}\", ", length($v->{simple}), ", newSViv(", $v->{constant},"), 0);\n";
	}
	#print "	hv_store(pG_EnumHash, \"$enum{$_}->{perlname}\", ", length($enum{$_}->{perlname}), ", newRV((SV*)enum_$_), 0);\n";
	#print " SvREFCNT_dec(enum_$_);\n";
	$i++;
}

foreach (sort keys %flags) {
	next if $flags{$_}->{export};
	next; # disable
	print "\n	flags_$_ = newHV();\n";
	foreach $v (@{$flags{$_}->{'values'}}) {
		print "	hv_store(flags_$_, \"$v->{simple}\", ", length($v->{simple}), ", newSViv(", $v->{constant},"), 0);\n";
	}
	#print "	hv_store(pG_FlagsHash, \"$flags{$_}->{perlname}\", ", length($flags{$_}->{perlname}), ", newRV((SV*)flags_$_), 0);\n";
	#print " SvREFCNT_dec(h);\n";
	$i++;
}
print <<"EOT";

	AddTypeHelper(&help);

}

void $opt{FilePrefix}_InstallObjects(void) {
	static int did_it = 0;
	if (did_it)
		return;
	did_it = 1;

EOT
foreach (sort keys %object) {
	next if not length $object{$_}->{cast};
	print "#ifdef $object{$_}->{cast}\n";
#	print "\tadd_typecast(", $object{$_}->{prefix}, "_get_type(),	\"$object{$_}->{perlname}\");\n"
#		;#unless /preview/i;
	print "\tpgtk_link_types(\"$_\",	\"$object{$_}->{perlname}\", 0,	", $object{$_}->{prefix}, "_get_type);\n"
		;#unless /preview/i;
	print "#endif\n";
}
#$j = 0;
#print "/*\n";
#foreach (sort keys %pointer) {
#	print "#ifdef need_GTK_TYPE_POINTER_$_\n";
#	print "\tttype[$j] = gtk_type_new(GTK_TYPE_POINTER);\n";
#	print "#endif\n";
#	$j++;
#}
#foreach (sort keys %struct) {
#	next if not length $struct{$_}->{typename};
#	print "#ifdef need_GTK_TYPE_$struct{$_}->{typename}\n";
#	print "\tttype[$j] = gtk_type_new(GTK_TYPE_POINTER);\n";
#	print "#endif\n";
#	$j++;
#}
#foreach (sort keys %boxed) {
#	next if not length $boxed{$_}->{typename};
#	print "#ifdef need_GTK_TYPE_$boxed{$_}->{typename}\n";
#	print "\tttype[$j] = gtk_type_new(GTK_TYPE_BOXED);\n";
#	print "#endif\n";
#	$j++;
#}
#print "*/\n";

print "}\n";


open(OUT,">build/boxed.xsh") or die "Unable to write to boxed.xsh: $!";

print "\n\n# Do not edit this file, as it is automatically generated by gendefs.pl\n\n";


foreach (sort keys %boxed) {
	print <<"EOT";
	
MODULE = $Module	PACKAGE = $boxed{$_}->{perlname}

void
DESTROY(self)
	$boxed{$_}->{perlname}	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	$boxed{$_}->{unref}(self);

EOT
}

foreach (sort keys %struct) {
	print <<"EOT";
	
MODULE = $Module	PACKAGE = $struct{$_}->{perlname}

void
DESTROY(self)
	$struct{$_}->{perlname}	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);

EOT
}

if ($Lazy) {
	open(OUT,">build/$opt{FilePrefix}objects.xsh") or die "Unable to write to $opt{FilePrefix}objects.xsh: $!";
	print "\n\n/* Do not edit this file, as it is automatically generated by gendefs.pl*/\n\n";
} else {
	open(OUT,">build/objects.xsh") or die "Unable to write to objects.xsh: $!";
	print "\n\n# Do not edit this file, as it is automatically generated by gendefs.pl\n\n";
}


print "MODULE = $Module	PACKAGE = $Module\n\n" unless $Lazy;

foreach (sort keys %object) {
	next if not length $object{$_}->{xsname};
	next if $object{$_}->{perlname} eq $Module;
	print "BOOT:\n" unless $Lazy;
	print <<"EOT";
{
	#ifdef $object{$_}->{cast}
                extern void boot_$object{$_}->{xsname}(CV *cv);
		callXS (boot_$object{$_}->{xsname}, cv, mark);
	#endif
}

EOT
}

close(OUT);
select(STDOUT);

	return map $object{$_}->{directory} . "xs/$_.xs", sort grep (defined $object{$_}->{cast}, keys %object);


#open(OUT,">Objects.xpl") or die "Unable to write to Objects.xpl: $!";
#
#print "\n\n# Do not edit this file, as it is automatically generated by gendefs.pl\n\n";
#
#print "\"\n";
#foreach (sort keys %object) {
#	print "$_.xs\n";
#}
#print "\"\n;\n";


# Write out the data structures documentation

sub gen_doc {
	my ($tag) = shift || 'gtk';
	print STDERR "Creating reference documentation\n";
	open (DOC, ">build/perl-$tag-ds.pod") || die "Cannot open doc file: $!";
	#print DOC "\n=head1 NAME\n\nPerl/Gtk data structures reference\n\n";

	print DOC "=head1 Enumerations\n\n";
	foreach (sort keys %enum) {
		print DOC "=head2 $enum{$_}->{perlname}\n\n";
		print DOC "=over 4\n\n";
		foreach $v (@{$enum{$_}->{'values'}}) {
			print DOC "=item * $v->{simple}\n\n";
		}
		print DOC "=back\n\n";
	}

	print DOC "=head1 Flags\n\n";
	foreach (sort keys %flags) {
		print DOC "=head2 $flags{$_}->{perlname}\n\n";
		print DOC "=over 4\n\n";
		foreach $v (@{$flags{$_}->{'values'}}) {
			print DOC "=item * $v->{simple}\n\n";
		}
		print DOC "=back\n\n";
	}

	close(DOC);
}

}

1;
