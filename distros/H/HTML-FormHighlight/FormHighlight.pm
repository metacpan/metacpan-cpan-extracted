################################################################################
# HTML::FormHighlight
#
# A module used to highlight fields in an HTML form.
#
# Author: Adekunle Olonoh
#   Date: March 2001
################################################################################


package HTML::FormHighlight;


################################################################################
# - Modules and Libraries
################################################################################
use strict;
use Carp;
use HTML::Parser;



################################################################################
# - Global Constants and Variables
################################################################################
$HTML::FormHighlight::VERSION = '0.03';


################################################################################
# - Subroutines
################################################################################


################################################################################
# new()
################################################################################
sub new {
    my ($proto, %options) = @_;
    
    my $class = ref($proto) || $proto;
    
    my $self = bless {}, $class;
    
    return $self;
}


################################################################################
# highlight()
################################################################################
sub highlight {
    my ($self, %options) = @_;
    
    # Initialize the fields option with a blank array ref
    $options{'fields'} ||= [];
    
    # Buld a hash containing each of the field names pointing to  a true value
    $self->{'fields'} = { map { $_ => 1 } @{$options{'fields'}} };
    
    # Initialize fields with parameters or defaults
    $self->{'highlight'} = $options{'highlight'} || '<font color="#FF0000" size="+1"><b>*</b></font>';
    $self->{'mark'} = $options{'mark'} || '';    
    $self->{'all_in_group'} = $options{'all_in_group'} || 0;
    
    # Initialize private variables
    $self->{'_output'} = '';
    $self->{'_highlighted'} = {};
    $self->{'_field_filled'} = {};
    $self->{'_buffer'} = '';
    
    # Create a regular expression for mark replacement
    $self->{'_mark_regex'} = qr/^(.*)($self->{'mark'})((?!$self->{'mark'}).*)$/s;
    
    # Check for a CGI.pm (or equivalent) object
    if ($options{'fobject'}) {
        # Die if the param() method isn't defined for the form object
        croak('HTML::FormHighlight->highlight called with fobject option, containing object of type '.ref($options{'fobject'}).' which lacks a param() method.') unless defined($options{'fobject'}->can('param'));

        # Iterate over each form value
        foreach my $key ($options{'fobject'}->param()) {
            # Indicate that the field has been filled in if it contains a true value
            $self->{'_field_filled'}->{$key} = 1 if $options{'fobject'}->param($key);
        }
    }
    
    # Check for a hash reference containing form data
    if ($options{'fdat'}){
        # Iterate over each key
        foreach my $key (keys %{$options{'fdat'}}) {
            # Indicate that the field has been filled in if it contains a true value
            $self->{'_field_filled'}->{$key} = 1 if $options{'fdat'}->{$key};
        }
    }
    

    # Create a new HTML::Parser object    
    my $parser = HTML::Parser->new(
        api_version => 3,
        start_h     => [ sub { _start($self, @_) }, 'tagname, attr, text' ],
        end_h       => [ sub { _end($self, @_) }, 'tagname, text' ],
        default_h   => [ sub { _default($self, @_) }, 'text' ],
    );
   
    
    # Check for the parse method, and use HTML::Parser appropriately
    if ($options{'file'}) {
        # Parse from file
        $parser->parse_file($options{'file'});
    }
    elsif ($options{'scalarref'}) {
        # Parse from scalar reference
        $parser->parse(${$options{'scalarref'}});
    }
    elsif ($options{'arrayref'}) {
        # Parse from array reference, iterating over each line
        for (@{$options{'arrayref'}}) {
            $parser->parse($_);
        }
    }

    # Signal EOF to HTML::Parser    
    $parser->eof();
    
    # Append the last of the buffered text to the output variable
    $self->{'_output'} .= $self->{'_buffer'};
    $self->{'_buffer'} = undef;
    
    # Return the generated output
    return $self->{'_output'};
}


################################################################################
# _start()
################################################################################
sub _start {
    my($self, $tagname, $attr, $origtext) = @_;
       
    # Check to make sure the current tag is a form field
    if (
        ($tagname eq 'input')    or 
        ($tagname eq 'textarea') or 
        ($tagname eq 'select')   or 
        ($tagname eq 'option')
    ){
    
        # Make sure the field has a name and that the field wasn't filled in
        if ($self->{'fields'}->{$attr->{'name'}} and !$self->{'_field_filled'}->{$attr->{'name'}}) {
        
            # Check for all input tags
            if ($tagname eq 'input') {
            
                # Check for text, password and file tags
                if (($attr->{'type'} eq 'text') or ($attr->{'type'} eq 'password') or ($attr->{'type'} eq 'file')) {
                
                    # Insert the highlight
                    $self->_insert_highlight();
                }
                # Check for radio and checkbox tags
                elsif (($attr->{'type'} eq 'radio') or ($attr->{'type'} eq 'checkbox')) {
                
                    # Check if all options in a group should be highlighted,
                    # or if an option in the group hasn't already been highlighted
                    if ($self->{'all_in_group'} or (!$self->{'_highlighted'}->{$attr->{'name'}})) {
                    
                        # Insert the highlight
                        $self->_insert_highlight();

                        # Indicate that an option in the group has been highlighted
                        $self->{'_highlighted'}->{$attr->{'name'}} = 1;                    
                    }
                }
            }
            # Check for textarea or select tags
            elsif (($tagname eq 'textarea') or ($tagname eq 'select')) {    
                # Insert the highlight    
                $self->_insert_highlight();
            }
        }
    
        # Add the buffer and original text to output
        $self->{'_output'} .= $self->{'_buffer'}.$origtext;
        
        # Clear the buffer
        $self->{'_buffer'} = '';
    }
    else {
        # Add the original text to the buffer
        $self->{'_buffer'} .= $origtext;
    }    
}


################################################################################
# _end()
################################################################################
sub _end {
    my($self, $tagname, $origtext) = @_;
    
    # Check if the current tag is a form tag
    if (
        ($tagname eq 'textarea') or 
        ($tagname eq 'select')   or 
        ($tagname eq 'option')
    ){
        # Add the buffer and original text to output
        $self->{'_output'} .= $self->{'_buffer'}.$origtext;
        
        # Clear the buffer
        $self->{'_buffer'} = '';
    }
    else {    
        # Add the original text to the buffer
        $self->{'_buffer'} .= $origtext;
    }
}


################################################################################
# _default()
################################################################################
sub _default {
    my($self, $origtext) = @_;
    
    # Add the original text to the buffer
    $self->{'_buffer'} .= $origtext;    
}


################################################################################
# _insert_highlight()
################################################################################
sub _insert_highlight {
    my $self = shift;
    
    # Check to make sure the buffer and mark exist, and that the buffer contains the mark
    if (($self->{'_buffer'}) and ($self->{'mark'}) and ($self->{'_buffer'} =~ $self->{'_mark_regex'})) {
        # Replace the last occurence of the mark with the highlight
        $self->{'_buffer'} =~ s/$self->{'_mark_regex'}/$1$2$self->{'highlight'}$3/;
    }
    else {
        # Just append the highlight to the buffer
        $self->{'_buffer'} .= $self->{'highlight'};
    }
}


1;


=head1 NAME

HTML::FormHighlight - Highlights fields in an HTML form.


=head1 SYNOPSIS

    use HTML::FormHighlight;

    my $h = new HTML::FormHighlight;
    
    print $h->highlight(
        scalarref => \$form,
        fields    => [ 'A', 'B', 'C' ],
    );
    
    print $h->highlight(
        scalarref    => \$form,
        fields       => [ 'A', 'B', 'C' ],
        highlight    => '*',
        mark         => '<!-- HIGHLIGHT HERE -->',
        all_in_group => 1,
    );
    

=head1 DESCRIPTION

HTML::FormHighlight can be used to highlight fields in an HTML form.  It uses HTML::Parser to parse the HTML form, and then places text somewhere before each field to highlight the field.  You can specify which fields to highlight, and optionally supply a CGI object for it to check whether or not an input value exists before highlighting the field.

It can be used when displaying forms where a user hasn't filled out a required field.  The indicator can make it easier for a user to locate the fields that they've missed.  If you're interested in more advanced form validation, see L<HTML::FormValidator>.  L<HTML::FillInForm> can also be used to fill form fields with values that have already been submitted.

=head1 METHODS


=head2 new()

    Create a new HTML::FormHighlight object.  Example:
    
        $h = new HTML::FormHighlight;

        
=head2 highlight()

Parse through the HTML form and highlight fields.  The method returns a scalar containing the parsed form.  Here are a few examples:

    To highlight the fields 'A', 'B' and 'C' (form on disk):
    
        $h->highlight(
            file   => 'form.html',
            fields => [ 'A', 'B', 'C' ],
        );
 
    To highlight the fields 'A' and 'B' with a smiley face
    (form as a scalar):
    
        $h->highlight(
            scalarref => \$form,
            fields    => [ 'A', 'B' ],
            highlight => '<img src="smiley.jpg">',
        );       
    
    To highlight the fields 'A' and 'B' if they haven't been supplied
    by form input (form as an array of lines):
    
        $q = new CGI;
        
        $h->highlight( 
            arrayref => \@form,
            fields  => [ 'A', 'B' ],
            fobject => $q,
        );
 
Note: highlight() will only highlight the first option in a radio or select group unless the all_in_group flag is set to a true value.
       
Here's a list of possible parameters for highlight() and their descriptions:

=over 4

=item *

scalarref - a reference to a scalar that contains the text of the form.

=item *

arrayref - a reference to an array of lines that contain the text of the form.

=item *

file - a scalar that contains the file name where the form is kept.

=item *

fields - a reference to an array that lists the fields to be highlighted.  If used in conjunction with "fobject" or "fdat", only the fields listed that are empty will be highlighted.

=item *

highlight - a scalar that contains the highlight indicator.  Defaults to a red asterisk (<font color="#FF0000" size="+1"><b>*</b></font>).

=item *

mark - a regex specifying where to place the highlight indicator.  If this is empty, the indicator will be inserted directly before the form field.  The HTML form does not need to contain the text specified in the regex before each form field.  highlight() will only use a mark for a field if there is no other form field before the field it's highlighting. If there is more than one mark before a field, it will only highlight the last mark.  If it doesn't find a mark, it will insert the indicator directly before the form field.  Here are a few examples:

    code:
    =====
    
    $h->highlight(
        file      => 'form.html',
        fields    => [ 'A', 'B', 'C' ],
        mark      => '<!-- MARK THIS -->'
        highlight => '***',
    );
    
    
    input:
    ======
    
    <input type=text name="A">
    <!-- MARK THIS --> Field B:<input type=text name="B">
    <input type=text name="C">
    
    output:
    =======
    
    ***<input type=text name="A">
    <!-- MARK THIS -->*** Field B:<input type=text name="B">
    ***<input type=text name="C">    
    
    
    input:
    ======
    
    Field A: <!-- MARK THIS --><br><input type=text name="A">
    Field B: <input type=text name="B">
    Field C:
        <!-- MARK THIS --><input type=radio name="D" value="1">
        <input type=text name="C">
        <input type=radio name="D" value="2">
        
    output:
    =======
    
    Field A: <!-- MARK THIS -->***<br><input type=text name="A">
    Field B: ***<input type=text name="B">
    Field C:
        <!-- MARK THIS --><input type=radio name="D" value="1">
        ***<input type=text name="C">
        <input type=radio name="D" value="2">    
        
        
    input:
    ======
    
    Field A:
        <!-- MARK THIS --><br> Foo...
        <!-- MARK THIS --><br> Bar...
        <input type=text name="A">
        
    Field B:
        <!-- MARK THIS --><input type=hidden name="E"><input type=text name="B">
        
    Field C:
        <select>
        <option>
        <input type=text name="C">
        </select>
        
    output:
    =======
    
    Field A:
        <!-- MARK THIS --><br> Foo...
        <!-- MARK THIS -->***<br> Bar...
        <input type=text name="A">
        
    Field B:
        <!-- MARK THIS --><input type=hidden name="E">***<input type=text name="B">
        
    Field C:
        <select>
        <!-- MARK THIS --><option>
        ***<input type=text name="C">
        </select>
        
        
Warning: Since the mark field is a regular expression, make sure to escape it appropriately.  "\s" will insert the highlight after the last space character.  To replace all occurrences of a backslash followed by the letter s, use "\\\s".

=item *

all_in_group - set this to 1 if you want all options in a radio or checkbox group to be highlighted.  It's set to 0 by default.

=item *

fobject - a CGI.pm object, or another object which has a param() method that works like CGI.pm's.  HTML::FormHighlight will check to see if a parameter does not have a value before highlighting the field.

=item *

fdat - a hash reference, with the field names as keys.  HTML::FormHighlight will check to see if a parameter does not have a value before highlighting the field.

=back 4

=head1 BUGS

=over 4

=item *

highlight() will add the highlight indicator inside an HTML tag if you're not careful.

For example, if you use "\s" as your mark and "***" as your indicator,

    A: <font face="arial"><input type=text name="A">
    
  will result in:
  
    A: <font ***face="arial"><input type=text name="A">
    
  not:
  
    A: ***<font face="arial"><input type=text name="A">
    
=back 4


=head1 VERSION

0.03

=head1 AUTHOR

Adekunle Olonoh, ade@bottledsoftware.com

=head1 CREDITS

Hiroki Chalfant

=head1 COPYRIGHT

Copyright (c) 2000 Adekunle Olonoh. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 SEE ALSO

L<HTML::Parser>, L<CGI>, L<HTML::FormValidator>, L<HTML::FillInForm>

=cut
