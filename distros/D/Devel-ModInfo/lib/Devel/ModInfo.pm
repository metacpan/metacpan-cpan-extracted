# This code is a part of ModInfo, and is released under the Perl Artistic 
#  License.
# Copyright 2002 by James Tillman and Todd Cushard. See README and COPYING
# for more information, or see 
#  http://www.perl.com/pub/a/language/misc/Artistic.html.
# $Id: ModInfo.pm,v 1.6 2002/08/17 23:23:46 jtillman Exp $

#TODO
#check that RETVAL is getting processed when doing reading in XML for functions
#

$| = 1;

# MODINFO module Devel::ModInfo
package Devel::ModInfo;

use 5.006;
# MODINFO dependency module File::Spec::Functions
use File::Spec::Functions;
# MODINFO dependency module XML::DOM
use XML::DOM;
# MODINFO dependency module Data::Dumper
use Data::Dumper;

# MODINFO dependency module strict
use strict;
# MODINFO dependency module warnings
use warnings;

# MODINFO dependency module Devel::ModInfo::Method
use Devel::ModInfo::Method;
# MODINFO dependency module Devel::ModInfo::Constructor
use Devel::ModInfo::Constructor;
# MODINFO dependency module Devel::ModInfo::Parameter
use Devel::ModInfo::Parameter;
# MODINFO dependency module Devel::ModInfo::Function
use Devel::ModInfo::Function;
# MODINFO dependency module Devel::ModInfo::Property
use Devel::ModInfo::Property;
# MODINFO dependency module Devel::ModInfo::Module
use Devel::ModInfo::Module;
# MODINFO dependency module Devel::ModInfo::Dependency
use Devel::ModInfo::Dependency;
# MODINFO dependency module Devel::ModInfo::ParentClass
use Devel::ModInfo::ParentClass;
# MODINFO dependency module Devel::ModInfo::ParamHash::Key
use Devel::ModInfo::ParamHash::Key;
# MODINFO dependency module Devel::ModInfo::ParamHash
use Devel::ModInfo::ParamHash;
# MODINFO dependency module Devel::ModInfo::ParamHash
use Devel::ModInfo::ParamHashRef;
# MODINFO dependency module Devel::ModInfo::ParamArray
use Devel::ModInfo::ParamArray;
# MODINFO dependency module Devel::ModInfo::DataType
use Devel::ModInfo::DataType 'String2DataType';

# MODINFO dependency module Exporter
require Exporter;

# MODINFO parent_class AutoLoader
our @ISA    = qw(Exporter AutoLoader);
our @EXPORT = qw();

# MODINFO version 2.04
our $VERSION = '2.04';


# Preloaded methods go here.
# MODINFO constructor new
# MODINFO param module STRING Package name of the module to get info for
sub new{
	my ($class, $module) = @_;

	#
	#Translate module and find ModInfo metadata file
	#
	my $mod_info_file = $module;
	$mod_info_file =~ s|::|/|g;
	$mod_info_file .= ".mfo";
	$mod_info_file = canonpath(_findINC($mod_info_file));
	if ($mod_info_file eq '') {
		die "Couldn't locate mfo file for $module in @INC path";
	}
	my $parser = XML::DOM::Parser->new();
	my $xml_doc;
	eval {
	    $xml_doc = $parser->parsefile($mod_info_file);
	};
        if ($@) {
	    warn "Error parsing mfo file $mod_info_file: $@";
	    return undef;
	}
	my(@methods, @constructors, @functions, @properties);


	#
	#Get methods
	#
	foreach my $item ($xml_doc->getElementsByTagName('method')) {		
		my $item_obj = Devel::ModInfo::Method->new(
                           _extract_function_data($item, $class)
                       );
		push(@methods, $item_obj);
	}

	#
	#Get constructors
	#
	foreach my $item ($xml_doc->getElementsByTagName('constructor')) {		
		my $item_obj = Devel::ModInfo::Constructor->new(_extract_function_data($item, $class));
		push(@constructors, $item_obj);
	}

	#
	#Get functions
	#
	foreach my $item ($xml_doc->getElementsByTagName('function')) {		
		my $item_obj = Devel::ModInfo::Function->new(_extract_function_data($item, $class));
		push(@functions, $item_obj);
	}

	#
	#Get properties
	#
	foreach my $item ($xml_doc->getElementsByTagName('property')) {		
		my $item_obj = Devel::ModInfo::Property->new(
			name 				=> $item->getAttribute('name'),
			display_name 		=> $item->getAttribute('display_name'),
			short_description	=> $item->getAttribute('short_description'),
			read_method			=> $item->getAttribute('read_method'),
			write_method		=> $item->getAttribute('write_method'),
			data_type			=> _get_datatype(class_name=>$class, data_type=>$item->getAttribute('data_type')),
		);
		push(@properties, $item_obj);
	}
	

	#
	# Get module-level info
	#
	my $mod_node = $xml_doc->getElementsByTagName('module')->[0];

	return undef if !$mod_node;

	my @deps;
	foreach my $dep_node ($mod_node->getElementsByTagName('dependency')) {
		my $dep_obj = Devel::ModInfo::Dependency->new(
			type 	=> $dep_node->getAttribute('type'),
			target 	=> $dep_node->getAttribute('target'),
		);
		push(@deps, $dep_obj);
	}

	my @parents;
	foreach my $parent ($mod_node->getElementsByTagName('parent_class')) {
		my $parent_obj = Devel::ModInfo::ParentClass->new(
			name 	=> $parent->getAttribute('name'),
		);
		push(@parents, $parent_obj);
	}


	my $mod_obj = Devel::ModInfo::Module->new(
		name 				=> $mod_node->getAttribute('name'),
		display_name 		=> $mod_node->getAttribute('display_name'),
		short_description	=> $mod_node->getAttribute('short_description'),
		version				=> $mod_node->getAttribute('version'),
		class 				=> $module,
		dependencies		=> \@deps,
		parent_classes		=> \@parents,
	);
	
	#
	# Assign collections and other attributes to $self
	#
	my $self = {
		module_name		=> $module,
		mod_info_file	=> $mod_info_file,
		methods 		=> \@methods,
		constructors	=> \@constructors,
		functions 		=> \@functions,
		properties		=> \@properties,
		module 			=> $mod_obj,
	};

	#print Dumper $self;
	
	#
	# Return object
	#
	return bless $self => $class;
}

# MODINFO function properties
# MODINFO retval ARRAYREF
sub properties{$_[0]->{properties}}

# MODINFO function methods
# MODINFO retval ARRAYREF
sub methods{$_[0]->{methods}}

# MODINFO function functions
# MODINFO retval ARRAYREF
sub functions{$_[0]->{functions}}

# MODINFO function constructors
# MODINFO retval ARRAYREF
sub constructors{$_[0]->{constructors}}

# MODINFO function module Returns the Module object for this Package
# MODINFO retval Devel::ModInfo::Module
sub module{$_[0]->{module}}

# MODINFO function is_oo Returns 1 if this is an object-oriented package, 0 if not
# MODINFO retval INTEGER
sub is_oo{
	my($self) = @_;
	if ($self->constructors) {return 1}
	else {return 0}
}

# MODINFO function icon Returns the path to an icon for this module (relative to the module file itself)
# MODINFO retval STRING
sub icon{$_[0]->{icon}}

sub _findINC {
	my $file = join('/',@_);
	my $dir;
	$file  =~ s,::,/,g;
	foreach $dir (@INC) {
		my $path;
		return $path if (-e ($path = "$dir/$file"));
	}
	return undef;
}

#sub _check_module_version {
#	my($version, $module) = @_;
#	my $module_file = $module . ".pm";
#	$module_file =~ s/::/\//g;
#	open(MOD, _findINC($module_file)) or warn "Couldn't open $module_file for verification of version: $!";
#	while(my $line = <MOD>) {
#		if($line =~ /^package\s+(.);/ && $1 eq $module)
#	}
#	
#	print "Version for $module is: $module_version\n";
#	return $module_version;	
#
#}

sub _extract_function_data {
	my($function_node, $class) = @_;
	#my $function_node = $params{function_node};
	
	my $name = $function_node->getAttribute('name');
	my $display_name = $function_node->getAttribute('display_name');
	my $short_description = $function_node->getAttribute('short_description');
	my @ret_val = $function_node->getElementsByTagName('retval');
	my $data_type;
	if (@ret_val) {
		$data_type = $ret_val[0]->getAttribute('data_type');
	}
	else {
		$data_type = String2DataType('VOID');
	}

	# Get parameters
	my @params;
	foreach my $param ($function_node->getElementsByTagName('param')) {
		my $name = $param->getAttribute('name');
		my $data_type = _get_datatype(class_name=>$class, data_type=>$param->getAttribute('data_type'));
		my $short_description = $param->getAttribute('short_description');
		my $display_name = $param->getAttribute('display_name');
		
		my $param_obj = Devel::ModInfo::Parameter->new(
			name				=> $name,
			display_name		=> $display_name,
			data_type			=> $data_type,
			short_description	=> $short_description,
		);
		
		push(@params, $param_obj);
	}

	#
	# Check for paramhash(ref) at end of param list.  Paramhashes must be
	#  last item in parameter list, anyway
	#
	my(@keys);
	my $param_hash;
	if ($param_hash = $function_node->getElementsByTagName('paramhash')->[0] or 
	      $param_hash = $function_node->getElementsByTagName('paramhashref')->[0]) {
		my $name = $param_hash->getAttribute('name');
		my $data_type = $param_hash->getAttribute('data_type');
		my $short_description = $param_hash->getAttribute('short_description');
		my $display_name = $param_hash->getAttribute('display_name');
		
		foreach my $key ($param_hash->getElementsByTagName('key')) {
			my $name = $key->getAttribute('name');
			my $data_type = _get_datatype(class_name=>$class, data_type=>$key->getAttribute('data_type'));
			my $short_description = $key->getAttribute('short_description');
			my $display_name = $key->getAttribute('display_name');
			my $key_obj = Devel::ModInfo::ParamHash::Key->new(
				name				=> $name,
				display_name		=> $display_name,
				data_type			=> $data_type,
				short_description	=> $short_description,
			);
			
			push(@keys, $key_obj);
		}
		my $param_hash_obj;
		if ($data_type eq 'paramhash') {
		    $param_hash_obj = Devel::ModInfo::ParamHash->new(
			name				=> $name,
			display_name		=> $display_name,
			data_type			=> $data_type,
			short_description	=> $short_description,
			keys				=> \@keys,
		       );	
		}
		else {
		    $param_hash_obj = Devel::ModInfo::ParamHashRef->new(
			name				=> $name,
			display_name		=> $display_name,
			data_type			=> $data_type,
			short_description	=> $short_description,
			keys				=> \@keys,
		       );	
		}
		
		push(@params, $param_hash_obj);
	}

	#
	# Check for paramarray at end of parameter list.  Paramarrays must be
	#  last item in parameter list, anyway
	#
	if (my $param_array = $function_node->getElementsByTagName('paramarray')->[0]) {
		my $name = $param_array->getAttribute('name');
		my $data_type = _get_datatype(class_name=>$class, data_type=>$param_array->getAttribute('data_type'));
		my $short_description = $param_array->getAttribute('short_description');
		my $display_name = $param_array->getAttribute('display_name');
		
		my $param_array_obj = Devel::ModInfo::ParamArray->new(
			name				=> $name,
			display_name		=> $display_name,
			data_type			=> $data_type,
			short_description	=> $short_description,
			keys				=> \@keys,
		);			
		
		push(@params, $param_array_obj);

	}

	my %data = (
		name				=> $name,
		display_name		=> $display_name,
		short_description	=> $short_description,
		data_type			=> $data_type,
		parameters 			=> \@params,
	);

	return %data;
}

sub _get_datatype {
	my(%params) = @_;
	#print "Converting $params{data_type}\n";
	my $data_type = String2DataType($params{'data_type'});
	if (!$data_type) {
		my $file_path = $params{'class_name'};
		$file_path =~ s|::|/|g;
		$file_path = _findINC("$file_path.pm");
		if (-f $file_path) {
			$data_type = $params{'data_type'};
		}
		else {
			warn "Could not resolve data type " . $params{'data_type'} . " while processing " . $params{'class_name'} . "\n";
		}
	}	
	
	return $data_type;
};

1;
__END__

=head1 NAME

Devel::ModInfo - provides metadata about a module's methods, properties, and arguments

=head1 SYNOPSIS

  use ModInfo;
  my $mi        = Devel::ModInfo->new('Data::Dumper');
  my @functions = $mi->function_descriptors();
  my (@methods, @properties);
  if ($mi->is_oo) {
	  @methods    = $mi->method_descriptors;
      @properties = $mi->property_descriptors();
  }

=head1 DESCRIPTION

Devel::ModInfo will use a previously created XML file
(with the extension .mfo) to generate 
a data structure that describes the interface for a Perl module.

The Devel::ModInfo system is made up of several object-oriented modules
which are all used exclusively by the ModInfo module.
This means that the developer should only ever 
need to directly instantiate the Devel::ModInfo
object with the class name of the desired module.

=head1 INTERFACE

=begin ModInfo

=head2 Parent Classes

=over 4

=item * AutoLoader

=back


=head2 Constructors

=over 4

=item * sub new returns [VOID]

=item *	module as STRING

=back


=head2 Functions

=over 4

=item * sub properties returns [ARRAYREF]

=item * sub methods returns [ARRAYREF]

=item * sub functions returns [ARRAYREF]

=item * sub constructors returns [ARRAYREF]

=item * sub module returns [Devel::ModInfo::Module]

Returns the Module object for this Package

=item * sub is_oo returns [INTEGER]

Returns 1 if this is an object-oriented package, 0 if not

=item * sub icon returns [STRING]

Returns the path to an icon for this module (relative to the module file itself)

=back





=head2 Dependencies

=over 4

=item * module File::Spec::Functions

=item * module XML::DOM

=item * module Data::Dumper

=item * module strict

=item * module vars

=item * module Devel::ModInfo::Method

=item * module Devel::ModInfo::Constructor

=item * module Devel::ModInfo::Parameter

=item * module Devel::ModInfo::Function

=item * module Devel::ModInfo::Property

=item * module Devel::ModInfo::Module

=item * module Devel::ModInfo::Dependency

=item * module Devel::ModInfo::ParentClass

=item * module Devel::ModInfo::ParamHash::Key

=item * module Devel::ModInfo::ParamHash

=item * module Devel::ModInfo::ParamArray

=item * module Devel::ModInfo::DataType

=item * module Exporter

=back


=end ModInfo


=head1 KNOWN ISSUES

ModInfo currently has problems with mfo files that define more than one module.

=head1 REPOSITORY

L<https://github.com/neilbowers/Devel-ModInfo>

=head1 AUTHOR

jtillman@bigfoot.com
tcushard@bigfoot.com

=head1 SEE ALSO

L<Devel::ModInfo::Tutorial>

pl2modinfo.pl

modinfo2xml.pl

modinfo2html.pl

perl(1).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002 by James Tillman E<lt>jtillman@bigfoot.comE<gt>

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 1.0.

=cut
