package HTML::DWT::Simple;
#############################################################
#  HTML::DWT::Simple
#  Whyte.Wolf DreamWeaver HTML Template Module (Simple)
#  Version 1.02
#
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Created 13 March 2002, Modified 05 April 2002
#
#  A perl module designed to parse a simple HTML template file
#  generated by Macromedia Dreamweaver and replace fields in the
#  template with values from a CGI script.
#
#############################################################
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

@ISA = qw(Exporter);
@EXPORT_OK = qw(output param);

use strict;
use vars qw($errmsg $VERSION @ISA @EXPORT_OK  
	    $NOTICE %DWT_FIELDS %DWT_VALUES);

$VERSION = '1.02';

$NOTICE = "\n<!-- Generated using HTML::DWT::Simple version " . $VERSION . " -->\t\t\n";
$NOTICE .= "<!-- HTML::DWT::Simple Copyright (c) 2002 Sean Campbell -->\t\n";
$NOTICE .= "<!-- HTML::DWT::Simple is licenced under the GNU General Public License -->\t\n";
$NOTICE .= "<!-- You can find HTML::DWT::Simple at http://www.spots.ab.ca/~whytwolf -->\t\n";
$NOTICE .= "<!-- or by going to http://www.cpan.org -->\n";

%DWT_FIELDS = ();
%DWT_VALUES = ();

$errmsg = "";

#############################################################
# new
#
#  The constructor for the class.  Requires a HTML Template
#  filename.  Returns a reference to the new object or undef
#  on error.  Errors can be retrieved from 
#  $HTML::DWT::Simple::errmsg.

sub new {
    my $class = shift;
    my %params = @_;
    

    my $self = {};
    
    if (!$params{filename}){    	
	$params{filename} = $_[0];
    }
    
	if (exists($params{associate})){
	if (ref($params{associate}) ne 'ARRAY') {
    		$$self{associate} = [ $params{associate} ];
    	}
    	$$self{associate} = $params{associate};
    } else {
	$$self{associate} = undef;
    }

	
    $$self{filename} = $params{filename};
    $$self{template} = '';
    
    
    unless(open(TEMPLATE_FILE, $$self{filename})){
	$errmsg = "HTML::DWT::Simple--Template File $$self{filename} not opened: $!\n";
	return undef;
    }

    while(<TEMPLATE_FILE>){
	$$self{template} .= $_;
    }

    $$self{html} = $$self{template};
    $$self{html} =~ s/<html>/_beginTemplate($$self{filename})/ie;
    $$self{html} =~ s/<\/html>/_endTemplate()/ie;
    $$self{html} =~ s/<!--\s*#BeginEditable\s*\"(\w*)\"\s*-->?/_quoteReplace($1)/ieg;

    bless $self, $class;
	
	if (exists($$self{associate})){
		$self->_load();
	}
	
    return $self;
}


#############################################################
# output
#
#  Returns the substituted HTML as generated by fill() or
#  param().  For compatibility with HTML::Template.

sub output {
    my $self = shift;
    my %params = @_;

   
    foreach my $key (keys %DWT_VALUES) {
		$$self{html}=~s/<!--\s*#BeginEditable\s*($key)\s*-->?(.*?)<?!--\s*#EndEditable\s*-->/_keyReplace($DWT_VALUES{$key},$1)/iegs;
    }

       
    if ($params{'print_to'}){
		my $print_to = $params{'print_to'};
	    print $print_to $$self{html};
		return undef;
	} else {	
    	return $$self{html};
	}
}

#############################################################
# param
#
#  Take a hash of one or more key/value pairs and substitutes
#  the HTML value in the key's spot in the template.  For
#  compatibility with HTML::Template.

sub param {

    my $self = shift;
        
    if (scalar(@_) == 0) {
    	return keys %DWT_FIELDS; 
    } elsif (scalar(@_) == 1){
    	my $field = shift;
    	return $DWT_VALUES{$field};
    } else {
	my %params = @_;   
    	foreach my $key (keys %params) {
		if ($key eq 'doctitle' && !($params{$key}=~/<title>(.*?)<\/title>/i)){
		    $DWT_VALUES{'doctitle'} = "<title>" . $params{$key} . "</title>";
		} else {
		    $DWT_VALUES{$key} = $params{$key};
		}
	}
    }

}


#############################################################
# _keyReplace
#
#  An internal subroutine that does the actual key/value
#  replacement.  Takes the contents scalar and returns a
#  HTML string.

sub _keyReplace {
    my $cont = shift;
    my $key = shift;

    return "<!-- \#BeginEditable \"$key\" -->\n" . $cont . "\n<!-- \#EndEditable -->\n";
}

#############################################################
# _beginTemplate
#
#  Returns the begin template string and file name back into
#  the parsed HTML.

sub _beginTemplate {
    my $filename = shift;
    return "<html>\n<!-- \#BeginTemplate \"$filename\" -->\n" . $NOTICE;
}

#############################################################
# _endTemplate
#
#  Returns the end template string back into the parsed HTML.

sub _endTemplate {
    return "<!-- \#EndTemplate -->\n</html>";
}

#############################################################
# _quoteReplace
#
#  An internal subroutine that removes quotes from around
#  the editable region name (fixes recursive loop bug).
#  As of version 2.06 also builds %DWT_FIELDS and %DWT_VALUES

sub _quoteReplace {
    my $key = shift;
    $DWT_FIELDS{$key} = 'VAR';
    $DWT_VALUES{$key} = undef;
    
    return "<!-- \#BeginEditable $key -->";
}

#############################################################
# _load
#
#  Loads the parameters from external sources

sub _load {

    my $self = shift;

    if ($$self{associate}){
       	foreach my $query ($$self{associate}){
			foreach my $param ($query->param) {
				$self->param($param => $query->param($param));
   			}
    	}
    }

}

1;
__END__

=head1 NAME

HTML::DWT::Simple - DreamWeaver HTML Template Module (Simple)


=head1 SYNOPSIS

  use HTML::DWT::Simple;
  
  $template = new HTML::DWT::Simple(filename => "file.dwt");    
  %dataHash = (
               doctitle => 'DWT Generated',
               leftcont => 'some HTML content here'	
               );  
  $template->param(%dataHash);
  $html = $template->output();

=head1 DESCRIPTION

A perl module designed to parse a simple HTML template file
generated by Macromedia Dreamweaver and replace fields in the
template with values from a CGI script.  

=head1 METHODS

=head2 new()

  new HTML::DWT("file.dwt");

  new HTML::DWT(
                filename => "file.dwt",
                associate => $q,
               );

Creates and returns a new HTML::DWT object based on the Dreamweaver
template 'file.dwt' (can specify a relative or absolute path).  The
Second instance is recommended, although the first style is still 
supported for backwards compatability with versions of HTML::DWT
before 2.05.

B<associate>:
The associate option allows the template to inherit parameter
values from other objects.  The object associated with the template
must have a param() method which works like HTML::DWT::Simple's param().
Both CGI and HTML::Template fit this profile.  To associate another 
object, create it and pass the reference scalar to HTML::DWT::Simple's 
new() method under the associate option (see above).

=head2 param()

  $template->param();

  $template->param('doctitle');

  $template->param(
                  doctitle => '<title>DWT Generated</title>',
                  leftcont => 'Some HTML content here'
                  );

Takes a hash of one or more key/value pairs, where each key is a named
area of the template, and the associated value is the HTML content for
that area.  This method returns void (HTML substitiutions are stored
within the object awaiting output()).

If called with a single paramter--this parameter must be a valid field
name--param() returns the value currently set for the field, or undef
if no value has been set.

If called with no parameters, param() returns a list of all field names.

NOTE: All Dreamweaver templates store the HTML page's title in a field
named 'doctitle'.  HTML::DWT::Simple will accept a raw title (without 
<title> tags) and will add the appropriate tags if the content of the 
'doctitle' field should require them.

This is a HTML::Template compatible method.

=head2 output()

  $template->output();
  
  $template->output(print_to => \*STDOUT);

Returns the parsed template and its substituted HTML for output.
The template must be filled using either fill() or param() before
calling output().

B<print_to>:
Alternativly, by passing a filehandle reference to output()'s 
print_to option you may output the template content directly to
that filehandle.  In this case output() returns an undefined value.

This is a HTML::Template compatible method.

=head1 DIAGNOSTICS

=over 4

=item Template File $file not opened:

(F) The template file was not opened properly.  
This message is stored in $HTML::DWT::Simple::errmsg

=back

=head1 BUGS

No known bugs, but if you find any please contact the author.

=head1 AUTHOR

S.D. Campbell, whytwolf@spots.ab.ca

=head1 SEE ALSO

perl(1), HTML::Template, HTML::DWT, HTML::LBI.

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
