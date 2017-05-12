package HTML::FormRemove;
# -*- Perl -*- Tue May 21 13:01:01 CDT 2002
###############################################################################
# Written by Tim Skirvin <tskirvin@ks.uiuc.edu>
# Copyright 2000-2002, Tim Skirvin and UIUC Board of Trustees. Redistribution
# terms are below.
###############################################################################
use vars qw( $VERSION );
$VERSION = "0.3a";

=head1 NAME

HTML::FormRemove - remove form tags from HTML

=head1 SYNOPSIS

  my $html = 
    "<FORM> <INPUT TYPE=TEXT NAME='Test' VALUE='Hello World!'> </FORM>";
  use HTML::FormRemove
  print RemoveFormValues($html);

=head1 DESCRIPTION

HTML::FormRemove is a module that removes form tags from HTML, while 
otherwise leaving the HTML intact.  This allows for forms to be converted 
into something printable and usable.


=cut

use strict;
use HTML::Form;

use Exporter;
use vars qw( @EXPORT @EXPORT_OK @ISA );
@ISA = "Exporter";
@EXPORT = qw( RemoveFormValues );

# Untaint $0; this may not be the best idea in the world, but it's
# necessary if we're in taint mode
if ($0 =~ /^(.*)$/) { $0 = $1 }

=over 4

=item RemoveFormValues ( HTML [, HTML [, HTML [...]]] )

Removes the form values.  Exported by default.  Returns an array of lines
containing the updated HTML, or one single like containing them separated
by newlines.

=back

=cut

# We want to modularize this a lot, and fix it up.
sub RemoveFormValues {
  my $line = join("\n", @_);
  return undef unless $line;

  my $form = HTML::Form->parse($line, $0);

  # Take out the <form> and </form> tags
  $line =~ s%</?form[^>]*>%%isg;

  # Take out <textarea> and </textarea>, replacing them with <pre>[...]</pre> 
  # (this may not be the best idea; perhaps we should just leave them in?)
  $line =~ s%<(\s*/?\s*)textarea([^>]*)*>%<$1pre$2>%g;

  my (%radio);

  # Take out <input ...> bits, leaving the 'value' part, unless it's 
  # a 'submit' box, in which case we'll drop it entirely
  my $i;
  $line =~ s%(<input[^>]*>)%   
	my $form = HTML::Form->parse("<form>$1</form>", $0);
        foreach ($form->inputs) { 
	  next unless ref $_;
          $i = "";
	  if ($_->type eq 'submit' || $_->type eq 'reset') {  }
	  elsif ($_->type eq 'image' || $_->type eq 'button' ) { } 
 	  elsif ($_->type eq 'radio') { 
            my $input = $form->find_input($_->name);
            if ($input->value) { $i = " [X] " unless $radio{$_->name}++ } 
	    else { $i = " [ ] " } 
	    }
	  elsif ($_->type eq 'checkbox') { 
            my $input = $form->find_input($_->name);
	    $input->value ? $i = " [X] " : $i = " [ ] ";
	  }
	  elsif ($_->type eq 'hidden') { }
	  elsif ($_->type eq 'file') { }
   	  elsif ($_->type eq 'password') { $i = $_->value; $i =~ s/./x/g; }
 	  elsif ($_->type eq 'text') { $i = $_->value }	
 	  else { $i = ""}
        }
	$i  					%eisgx;


  # Now comes the work with 'select'.  Just leave these in a form tag.
  $line =~ s%(<select[^>]*>.*</select[^>]*>)% 
	"<form>$1</form>" 		%eisgx;

  wantarray ? split("\n", $line) : $line;
}

1;

=head1 NOTES

This module is a work in progress; I've only got basic functionality
working at the moment. 

=head1 REQUIREMENTS

Perl 5 or better, and the C<HTML::Form> module (with everything that
requires).

=head1 SEE ALSO

B<HTML::Form>

http://www.ks.uiuc.edu/Development/MDTools/dbiframe for the latest version.

=head1 TODO

Modularize the code.

Make some more specific functions, and allow for more customizability
within it.  IE, it'd be nice to only take out <textarea> tags, and leave
everything else alone.

=head1 AUTHOR

Written by Tim Skirvin <tskirvin@ks.uiuc.edu>.

=head1 LICENSE

University of Illinois Open Source License
Copyright (c) 2002 University of Illinois Board of Trustees 
All rights reserved
Developed by:	Theoretical Biophysics Group
		University of Illinois, Beckman Institute
		http://www.ks.uiuc.edu/

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software, DBI::Frame, and associated documentation files
(the "Software"), to deal with the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and
to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

	* Redistributions of source code must retain the above copyright 
	  notice, this list of conditions and the following disclaimers.
	* Redistributions in binary form must reproduce the above copyright 
	  notice, this list of conditions and the following disclaimers in 
	  the documentation and/or other materials provided with the 
	  distribution.
	* Neither the names of the Theoretical Biophysics Group, the
	  University of Illinois, nor the names of its contributors may 
	  be used to endorse or promote products derived from this Software 
	  without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
OTHER DEALINGS WITH THE SOFTWARE.

=head1 COPYRIGHT

Copyright 2001-2002 by the University of Illinois Board of Trustees and
Tim Skirvin <tskirvin@ks.uiuc.edu>.  

=cut

##### Version History 
# v0.1a   Fri Jun 15 15:05:10 CDT 2001
### Initial version.  Works, but not all that well.  
# v0.2a   Thu Feb 21 11:24:02 CST 2002
### Changed to UIUC/NCSA Open Source License.
# v0.3a   Tue May 21 11:22:37 CDT 2002
### Made the <textarea> filtering easier, and works properly.  Fixed 
### interaction with URI and taint mode by untainting $0.
