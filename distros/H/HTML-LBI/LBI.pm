package HTML::LBI;
#############################################################
#  HTML::LBI
#  Whyte.Wolf DreamWeaver HTML Library Module
#  Version 2.00
#
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Created 03 February 2002; Revised 12 February 2002 by SDC
#
#  Description:
#	A perl module for use with CGI scripts that opens a 
#	Macromedia Dreamweaver library file (.lbi) and returns
#	the resulting HTML code snippet.
#
#############################################################
#
#  Construction:
#	  use HTML::LBI;
#
#	  $html = new HTML::LBI("file.lbi");
#
#  Use:
#	Create a new instance of HTML::LBI as above by passing
#	a pathname to the library file (absolute or relative)
#	to the constructor.  The constructor will return
#	the HTML from the .lbi file, which can then be printed out.
#
#  Errors:
#	Should the library file fail to open an error will be set
#	in $HTML::LBI::errmsg
#
#############################################################
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#############################################################

use Exporter;
use Carp;
use File::Find;
use File::Basename;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw($errmsg);

use strict;
use vars qw($errmsg $VERSION @ISA @EXPORT @EXPORT_OK $filepath $fname);

$VERSION = '2.00';

$errmsg = "";
$filepath ='';
$fname = '';

#############################################################
# new
#
#  The constructor for the class.  Requires a HTML Library
#  filename.  Returns a reference to the new object or undef
#  on error.

sub new {
    my $class = shift;
    my %params = @_;
    my @search = ();

    my $self = {};
    
    if (!$params{filename}){    	
	$params{filename} = $_[0];
    }
    
    $$self{filename} = $params{filename};
    $$self{lbi} = _beginLbi($$self{filename});
    
    if (exists($params{path})){
	if (ref($params{path}) ne 'ARRAY') {
    		$$self{path} = [ $params{path} ];
    	}
    	$$self{path} = $params{path};
    } else {
	$$self{path} = './';
    }

    foreach my $path ($$self{path}){
    	push @search, $path;
    }
    
    if ($ENV{'HTML_TEMPLATE_ROOT'}) {
    	my $temproot = $ENV{'HTML_TEMPLATE_ROOT'};
	push @search, $temproot;
    }
    
    if ($ENV{'DOCUMENT_ROOT'}) {
    	my $docroot = $ENV{'DOCUMENT_ROOT'};
	push @search, $docroot;
    }
   
    
    if (substr($$self{filename}, 0, 1) ne '/') {
    	$fname = $$self{filename};
	foreach my $dir (@search){
	    	find(\&_wanted, $dir);
	}
	if (!$filepath) {
		$filepath = $$self{filename};
	}
    } elsif (substr($$self{filename}, 0, 8) eq '/Library') {
    	my ($name, $path, $suffix) = fileparse($$self{filename}, '\.lbi');
	$fname = $name . $suffix;
	foreach my $dir (@search){
	    	find(\&_wanted, $dir);
	}
	if (!$filepath) {
		$filepath = $$self{filename};
	}
    } else {
    	$filepath = $$self{filename};
    }

    unless(open(LBI_FILE, $filepath)){
		$errmsg = "Library File $filepath not opened: $!\n";
		return undef;
    }

    while(<LBI_FILE>){
		$$self{lbi} .= $_;
    }

    $$self{lbi} .= _endLbi();

    bless $self, $class;
    return $$self{lbi};
}

#############################################################
# _beginLbi
#
#  Returns the begin library string and file name back into
#  the parsed HTML.

sub _beginLbi {
    my $filename = shift;
    return "\n<!-- \#BeginLibraryItem \"$filename\" -->\n";
}


#############################################################
# _endLbi
#
#  Returns the end library string back into the parsed HTML.

sub _endLbi {
    return "\n<!-- \#EndLibraryItem -->\n";
}

#############################################################
# _wanted
#
#  Returns the path to a file (if it exists).

sub _wanted {
    
    /$fname$/ or return;
    $filepath = $File::Find::name;
    
}


1;
__END__

=head1 NAME

HTML::LBI - DreamWeaver HTML Library Module

=head1 SYNOPSIS

  use HTML::LBI;

  $html = new HTML::LBI(
                       filename => 'file.lbi',
	               path => '/path/to/file'
		       );


=head1 DESCRIPTION

A perl module for use with CGI scripts that opens a 
Macromedia Dreamweaver library file (.lbi) and returns
the resulting HTML code snippet.

=head1 METHODS

=head2 Creation

  $lbi = new HTML::LBI("file.lbi");
  
  $lbi = new HTML::LBI(
                       filename => 'file.lbi',
	               path => '/path/to/file'
		       );

Creates a new HTML::LBI object and loads HTML from the Dreamweaver
library 'file.lbi' (can specify a relative or absolute path).  Returns
the HTML from the library, which could then be printed to STDOUT.

=head1 DIAGNOSTICS

=over 4

=item Library File $file not opened:

(F) The library file was not opened properly.  
This message is stored in $HTML::LBI::errmsg

=back

=head1 AUTHOR

S.D. Campbell, whytwolf@spots.ab.ca

=head1 SEE ALSO

perl(1), HTML::Template, HTML::DWT.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut

