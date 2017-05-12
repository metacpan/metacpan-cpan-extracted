#!/usr/bin/perl

package Goo::WebDBLite;

############################################################################### 
# Turbo10
#								    
# Copyright Nigel Hamilton 2003
# All rights reserved			
#								    
# Author: 		Nigel Hamilton					 
# Filename:		Goo::WebDBLite.pm 		
# Description:  This provides a Lite interface to the Data to reduce RAM
#				requirements. Each Apache child was 100Meg - too big.
#				Many of the templates stored in the WebDB are redundant
#				so in the interests of RAM conservation changed to WebDBLite
#				This does a 'lazy load' of pages into a per Apache child 
#				RAM cache.
#
# Date	 		Change		 
# ----------------------------------------------------------------------------
# 25/02/2002	Version 1
# 24/06/2003	Consuming too much RAM need to reduce the RAM requirements
#				for mod_perl - turned out most of the RAM was consumed by
#				Rackspace's Apache configuration which included: mod_php,
#				mod_perl etc.
# 02/02/2005	Added whitespace compression to compress objects in RAM and
#				for transmission across the Net! Improved parsing of WebDB data
#				Don't compress the files on disk for readability but *do*
# 05/02/2005	Added getTemplate for simpler access to "bodytext" templates
# 22/06/2005	Moving to Goo2! Added type_locations as a bridge before the
#				full Goo changes kick in!
#								    
##############################################################################

use strict;

use Goo::Object;
use Goo::FileUtilities;
use Goo::CompressWhitespace;

use base qw(Goo::Object);

# master data directory
my $datadirectory = "/home/search/web/webdb/";

# master database hash
our $db		  = {};

my $goobase = "$ENV{HOME}/.goo";
my $type_locations = { formtemplate  => "$goobase/things/frm",
				       page	     	 => "$goobase/things/page",
				       email	     => "$goobase/things/email",
				       emailtemplate => "$goobase/things/email",
				       settings	     => "$goobase/things/settings",
				       template	     => "$goobase/things/tpl" };


##############################################################################
#
# get_value - return a value - polymorphically
#								    
##############################################################################

sub get_value {

	my ($type, $id, $field) = @_;
	
	# all ids must be in lowercase
	$type  = lc($type);
	$id    = lc($id);
	$field = lc($field);

	# special exception - HTML pages need a new suffix
	if ($id =~ /html$/) {
		$id =~ s/html/page/g;
	}

	# special exception - yuck!
	if ($id =~ /general$/) {
		$id = "general.settings";
	}
	
	if (not exists $db->{$type}->{$id}) {
		load_object($type, $id);
	}
	
	# accessing an Object attribute
	if ($field ne "") {
		return $db->{$type}->{$id}->{$field};
	} 

	# accessing an Object
	return $db->{$type}->{$id};
	
}


##############################################################################
#
# get_template - simpler access
#								    
##############################################################################

sub get_template {

	my ($template_name) = @_;
	
	return get_value("template", $template_name, "bodytext");


}


##############################################################################
#
# load_object - load the data file from disk - this will take some memory
#		 but should be no problem
#								    
##############################################################################

sub load_object {

	my ($type, $id) = @_;

	my $location = $type_locations->{$type};

	unless ($location) {
		die("No location found for $type [$id]");
	}

	# special exception - HTML pages need a new suffix
	if ($id =~ /html$/) {
		$id =~ s/html/page/g;
	}

	# another special exception
	if ($id =~ /general$/) {
		$id = "general.settings";
	}	

	my $datafile = $location."/".$id;

	# slurp mode
	my $data = Goo::FileUtilities::get_file_as_string($datafile);
	
	# parse here!
	while ($data =~ m|<([^>]*)>(.*?)</\1>|gs) {
			
		my $field = $1;
		my $value = $2;
		
		# compress all objects except for emailtemplates
		if (($value =~ /<[^>]*>/) && ($type ne "emailtemplate")) {
			# compress the object, save RAM and gain speed - strip leading whitespace
			Goo::CompressWhitespace::compress_html(\$value);
			
		}			
			
		# print "$value";
		# a hash of a hash of a hash - wow
		$db->{$type}->{$id}->{$field} = $value;
			
	}
	
}

1;


__END__

=head1 NAME

Goo::WebDBLite - This provides a Lite interface to XMLish Things

=head1 SYNOPSIS

use Goo::WebDBLite;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_value

return a value - polymorphically

=item get_template

return a text template

=item load_object

load the data file from disk - this will take some memory

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

