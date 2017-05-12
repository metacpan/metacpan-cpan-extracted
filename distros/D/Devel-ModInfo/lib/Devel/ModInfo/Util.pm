# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: Util.pm,v 1.4 2002/08/17 23:24:17 jtillman Exp $

# MODINFO module Devel::ModInfo::Util
package Devel::ModInfo::Util;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;

# MODINFO dependency module IO::File
use IO::File;
# MODINFO dependency module Parse::RecDescent
use Parse::RecDescent;
# MODINFO dependency module XML::DOM
use XML::DOM;
# MODINFO dependency module Data::Dumper
use Data::Dumper;

# MODINFO dependency module Exporter
require Exporter;

# MODINFO parent_class Exporter
our @ISA       = qw/ Exporter /;
our @EXPORT_OK = qw/ parse_modinfo_file parse_modinfo_multiline
                     parse_modinfo_line convert_modinfo_to_xml /;

our $VERSION = '2.04';

my $error;
my $parser = new Parse::RecDescent(grammar());
$::RD_HINT = 1;
my $indent_level = 0;
my $indent = '  ';
my $current_node;

# MODINFO function error  Returns the most recent error string
# MODINFO retval STRING
sub error {$error}

# MODINFO function reset_error  Reset the error string
# MODINFO retval
sub reset_error {$error = undef}

# MODINFO function parse_modinfo_file
# MODINFO param file			ANY		File to parse (can be GLOB, IO::Handle, FileHandle, or a string containing the path
# MODINFO param include_code	BOOLEAN Include the original perl code, if any
# MODINFO param no_die			BOOLEAN Warn instead of dying when errors occur
# MODINFO retval STRING
sub parse_modinfo_file {
	my($file, $include_code, $no_die) = @_;
	my @output;
	my $handle = to_filehandle($file) or die "Couldn't convert $file to filehandle: $!";
	my $done;
	while (my $line = <$handle>) {
		$done = 1 if $line =~ /^\_\_(END|DATA)\_\_/;
		if (!$done) {
		  push(@output, parse_modinfo_line($line, $include_code, $no_die));
		}
		else {
		    push(@output, $line);
		}
	}
	if (wantarray()) {
		return @output;
	}
	else{
		return join("\n", @output);
	} 
}

# MODINFO function parse_modinfo_multiline
# MODINFO param input			STRING String to parse
# MODINFO param include_code	BOOLEAN Include the original perl code, if any
# MODINFO param no_die			BOOLEAN Warn instead of dying when errors occur
# MODINFO retval STRING
sub parse_modinfo_multiline {
	my($input, $include_code, $no_die) = @_;
	my @output;
	my $done = 0;
	foreach my $line (split(/\n/, $input)) {
		$done = 1 if $line =~ /^\_\_(END|DATA)\_\_/;
		if (!$done) {
		    push(@output, parse_modinfo_line($line, $include_code, $no_die));
		}
		else {
		    push(@output, $line);
		}
	}

	if (wantarray()) {
		return @output;
	}
	else{
		return join("\n", @output);
	}
}

# MODINFO function parse_modinfo_line
# MODINFO param line			STRING Line to parse
# MODINFO param include_code	BOOLEAN Include the original perl code, if any
# MODINFO param no_die			BOOLEAN Warn instead of dying when errors occur
# MODINFO retval STRING
sub parse_modinfo_line {
	my ($line, $include_code, $no_die) = @_;
	my $output;
	
	if ($line =~ /^# MODINFO/) {
		if ($no_die) {
			$error = "ModInfo directives encountered.  Ignoring line.";	
			return undef;
		}
		else {
			die "ModInfo directives encountered.  Aborting.";
		}
	}
	if($line =~ /package\s+(\S+);/) {
		$output = "# MODINFO module $1\n";
	}
	elsif ($line =~ /\$(\S+::|)VERSION\s*=\s*['"]*([^'"]+)['"]*;/) {
		$output = "# MODINFO version $2\n";
	}
	elsif ($line =~ /^\s*require\s*([\d\.]+).*;/) {
		$output = "# MODINFO dependency perl $1\n";
	}
	elsif ($line =~ /^\s*use\s*(\S+).*;/) {
		$output = "# MODINFO dependency module $1\n";
	}
	elsif ($line =~ /^\s*require \s*([^"^\$]\S+[^;]).*;/) {
		$output = "# MODINFO dependency module $1\n";
	}
	elsif ($line =~ /^\s*(\@ISA.+)/) {
		my @ISA;
		eval "$1";
		foreach my $parent_class (@ISA) {
			$output = "# MODINFO parent_class $parent_class\n";
		}
	}
	elsif ($line =~ /^\s*sub\s+([^{_][^\{(\s;]*)/) {
		$output = "# MODINFO function $1\n";
	}
	
	$output = $output . $line if $include_code;
	return $output;
}

# MODINFO function convert_modinfo_to_xml
# MODINFO param file ANY
# MODINFO retval STRING
sub convert_modinfo_to_xml {
	my($file) = @_;
	my $handle = to_filehandle($file) or die "Couldn't convert $file to filehandle: $!";
	
	#
	#The two retval's in the grammar are intentional
	# the second one allows a retval of "VOID" to be
	# defined.
	#
	
	my $doc = new XML::DOM::Document();
	my $decl = $doc->createXMLDecl("1.0");
	$doc->setXMLDecl($decl);
	my $modinfo_node = $doc->createElement('modinfo');
	$doc->appendChild($modinfo_node);
	
	#Create modules node
	my $elem = $modinfo_node->getOwnerDocument->createElement('modules');
	$modinfo_node->appendChild($elem);
	$current_node = $elem;
	
	while(<$handle>) {
		my $directive;
		if (/\$VERSION\s*=\s*['"]*([^'"]+)['"]*;/) {
			$directive = "version $1";
		}
		elsif (/use\s*(\S+).*;\s*# MODINFO/) {
			#print "Found a use statement: $_\n";
			$directive = "dependency module $1";
		}
		elsif (/(\@ISA.+# MODINFO)/) {
			my @ISA;
			eval "$1";
			#print "ISA array is: " . join(", ", @ISA);
			#exit;
			#print "Found an @ISA statement: $_\n";
			foreach my $parent_class (@ISA) {
				$directive = "parent_class $parent_class";
				#print "Directive is $directive\n";
				$parser->Directive($directive) || warn "Parse error: $directive\n";
			}
			next;
		}
		else {
			next if !/^#\s*MODINFO\s+(.+)/;
			$directive = $1;
		}
		chomp $directive;
		exit if $directive eq '';
		while($directive =~ s/\\\s*$//) {
			my $line = <STDIN>;
			$line =~ s/^#//;
			$directive .= $line;
		}
		
		$parser->Directive($directive) || warn "Parse error: $directive\n";
	}
	
	#if($current_container) {
	#	$indent_level -= 1;
	#	#print indent() . "</$current_container>\n";
	#}
	
	return join(">\n", split(/\>/, $doc->toString));
	
	#print "</modinfo>\n";
}


sub Parse::RecDescent::unquote{
	for (@_) {
		if (ref($_) eq 'ARRAY') {Parse::RecDescent::unquote(@$_)}
		$_ =~ s/(^"|"$)//g;
		$_ =~ s/(^'|'$)//g;
	}
}

sub indent{
	return $indent x $indent_level;
}
	
sub Parse::RecDescent::out{
	Parse::RecDescent::unquote(@_);
	#print Dumper \@_;
	
	my($null, $dir, @params) = @_;
	#RETVAL
	if($dir eq 'retval') {
		while ($current_node->getNodeName !~ /^(method|constructor|function)$/) {
			$current_node = $current_node->getParentNode;
		}
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$current_node->appendChild($elem);
		$elem->setAttribute("data_type", $params[0]);
		#print indent() . qq|<$dir data_type="| . $params[0] . qq|" />\n|;
	}
	#VERSION
	elsif ($dir =~ /^version$/) {
		my $temp_node = $current_node;
		while ($temp_node && $temp_node->getNodeName ne 'module') {
			$temp_node = $temp_node->getParentNode;
		}
		$temp_node->setAttribute("version", $params[0]) if $temp_node;
	}
	#DEPENDENCY
	elsif ($dir =~ /^dependency$/) {
		my $temp_node = $current_node;
		while ($temp_node->getNodeName ne 'module') {
			$temp_node = $temp_node->getParentNode;
		}
		$temp_node = $temp_node->getElementsByTagName('dependencies')->[0];
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$temp_node->appendChild($elem);
		$elem->setAttribute("type", $params[0]->[0]);
		$elem->setAttribute("target", $params[0]->[1]);
	}
	#PARENT_CLASS
	elsif ($dir =~ /^parent_class$/) {
		my $temp_node = $current_node;
		while ($temp_node->getNodeName ne 'module') {
			$temp_node = $temp_node->getParentNode;
		}
		$temp_node = $temp_node->getElementsByTagName('parent_classes')->[0];
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$temp_node->appendChild($elem);
		$elem->setAttribute("name", $params[0]);
	}
	#PROPERTY
	elsif ($dir =~ /^(property)$/) {
		while ($current_node->getNodeName ne 'module') {
			$current_node = $current_node->getParentNode;
		}
		$current_node = $current_node->getElementsByTagName('properties')->[0];
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$current_node->appendChild($elem);
		$elem->setAttribute("name", $params[0]->[0]);
		$elem->setAttribute("data_type", $params[0]->[1]);
		$elem->setAttribute("short_description", $params[0]->[2]);
		$current_node = $elem;
	}
	#PARAM/KEY
	elsif ($dir =~ /^(param|key)$/) {
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$current_node->appendChild($elem);
		$elem->setAttribute("name", $params[0]->[0]);
		$elem->setAttribute("data_type", $params[0]->[1]);
		$elem->setAttribute("short_description", $params[0]->[2]);
	}
	#READ/WRITE
	elsif ($dir =~ /^(read|write)$/) {
		$current_node->setAttribute($dir . "_method", $params[0]->[0]);
	}
	#MODULE
	elsif ($dir =~ /^(module)$/) {
		while ($current_node->getNodeName ne 'modules') {
			$current_node = $current_node->getParentNode;
		}		
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$current_node->appendChild($elem);
		$elem->setAttribute("name", $params[0]->[0]);
		$elem->setAttribute("short_description", $params[0]->[1]);
		$current_node = $elem;
		
		#Create collection nodes
		$elem = $current_node->getOwnerDocument->createElement('functions');
		$current_node->appendChild($elem);
		$elem = $current_node->getOwnerDocument->createElement('methods');
		$current_node->appendChild($elem);
		$elem = $current_node->getOwnerDocument->createElement('constructors');
		$current_node->appendChild($elem);
		$elem = $current_node->getOwnerDocument->createElement('properties');
		$current_node->appendChild($elem);
		$elem = $current_node->getOwnerDocument->createElement('parent_classes');
		$current_node->appendChild($elem);
		$elem = $current_node->getOwnerDocument->createElement('dependencies');
		$current_node->appendChild($elem);

	}
	#ICON
	elsif ($dir eq 'icon') {
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$current_node->appendChild($elem);
		$elem->setAttribute("file_path", $params[0]);
	}
	#METHOD/CONSTRUCTOR/FUNCTION
	elsif ($dir =~ /^(method|constructor|function)$/) {
		while ($current_node->getNodeName ne 'module') {
			$current_node = $current_node->getParentNode;
		}
		$current_node = $current_node->getElementsByTagName($dir . 's')->[0];
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$current_node->appendChild($elem);
		$elem->setAttribute("name", $params[0]->[0]);
		$elem->setAttribute("short_description", $params[0]->[1]);
		$current_node = $elem;
	}
	#PARAMARRAY/PARAMHASH
	elsif ($dir =~ /^(paramarray|paramhash|paramhashref)$/) {
		my $elem = $current_node->getOwnerDocument->createElement($dir);
		$current_node->appendChild($elem);
		$elem->setAttribute("name", $params[0]->[0]);
		$elem->setAttribute("short_description", $params[0]->[1]);
		$current_node = $elem;
	}

	return 1;
}



# borrowed from CGI.pm, and modified to fit our needs (Is there a better way to do this?)
sub to_filehandle {
    my $thingy = shift;
    return undef unless $thingy;
    return $thingy if UNIVERSAL::isa($thingy,'GLOB');
    return $thingy if UNIVERSAL::isa($thingy,'FileHandle');
    return $thingy if UNIVERSAL::isa($thingy,'IO::Handle');
    if (!ref($thingy)) {
		my $fh = new IO::File($thingy);
		if (!$fh or $fh->error) {
			$error = $!;
			return undef;
		}
		return $fh;
    }
    return undef;
}

# MODINFO function grammar
# MODINFO retval STRING
sub grammar {
	return q{
	
		Directive: 
			'icon' 			Desc 			{out(@item)} |
			'version' 		Name 			{out(@item)} |
			'parent_class' 	Name 			{out(@item)} |
			'dependency'	NameDesc		{out(@item)} |
			'method' 		NameDesc 		{out(@item)} |
			'function'  	NameDesc 		{out(@item)} |
			'module' 		NameDesc 		{out(@item)} |
			'constructor' 	NameDesc 		{out(@item)} |
			'paramhashref'		NameDesc 		{out(@item)} |
			'paramhash'		NameDesc 		{out(@item)} |
			'paramarray' 	NameDesc 		{out(@item)} |
			'write' 		NameDesc 		{out(@item)} |
			'read' 			NameDesc 		{out(@item)} |
			'property' 		TypedNameDesc	{out(@item)} |
			'param' 		TypedNameDesc 	{out(@item)} |
			'key' 			TypedNameDesc 	{out(@item)} |
			'retval' 		DataType 		{out(@item)} |
			'retval' 						{out(@item)}
		
		TypedNameDesc:
			Name DataType Desc {[$item[1], $item[2], $item[3]]} |
			Name DataType {[$item[1], $item[2]]}
	
		
		NameDesc: 
			Name Desc {[$item[1], $item[2]]} |
			Name {[$item[1]]}
		
		DataType:
			/\S+/
		
		Name:
			/\S+/
			
		Desc:
			/.*\S/
		
	};
}

1;

__END__

=head1 Devel::ModInfo::Util

Devel::ModInfo::Util - Provides utility functions for dealing with ModInfo data structures

=head1 SYNOPSIS

  use Devel::ModInfo::Util 'parse_modinfo_file';
  print parse_modinfo_file('/home/jtillman/MyModule.pm', 1, 0);
  
=head1 DESCRIPTION

Devel::ModInfo::Util is simply a means of storing miscellaneous "smart" functions that know 
how to do certain things related to ModInfo.  They are mainly used by the command 
line tools (pl2modinfo.pl, modinfo2xml.pl, and modinfo2html.pl) in order to do their 
jobs.  In fact, the functions in this module started out as the core code of those 
command line tools.  The code was moved into a module to provide for re-use as well 
as to centralize the "rules" for processing ModInfo directives and data.

=head1 AUTHOR

jtillman@bigfoot.com
tcushard@bigfoot.com

=head1 SEE ALSO

Devel::ModInfo::Tutorial

pl2modinfo.pl

modinfo2xml.pl

modinfo2html.pl

perl(1).

=cut
