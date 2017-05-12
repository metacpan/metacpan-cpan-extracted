#!/usr/local/bin/perl -w
#
#   HTML::Defaultify-- Pre-fill default values into an existing HTML form.
#
#   The main purpose of this module is the defaultify() routine, which
#   takes a block of HTML and a hash of default values, and returns that HTML
#   with all form fields set based on those default values.  Default values
#   (hash elements) may each be given in any of three forms:  as a single
#   scalar, as a list in "\0"-delimited form, or as a reference to an actual
#   list.  If the HTML contains more than one form, you can name which form to
#   defaultify.  Return values are the defaultified block of HTML and a hash of
#   all unused default values (which may be useful as input to hidden_vars()).
#   Multiple form fields with the same name are handled correctly.  Besides
#   the main defaultify() routine, this module includes several related
#   routines which the programmer may find useful.
#
#   This package prefers to have the HTML::Entities module available, but
#   can improvise without it.
#     
#   Copyright (c) 1996, 1997, 2002 James Marshall (james@jmarshall.com).
#   Adapted from the toolbox htmlutil.pl, which is (c) 1996, 1997 by same.
#   All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
#
#   Exported by default:
#     $new_HTML=                 &defaultify($HTML, \%defaults [, $form_name]) ;
#     ($new_HTML, $unused_defs)= &defaultify($HTML, \%defaults [, $form_name]) ;
#
#     $my_subset_ref=            &subhash(\%hash, @keys_to_include) ;
#
#   Export is allowed:
#     $hidden_vars=           &hidden_vars($unused_defaults_ref) ;
#     $hidden_vars=           &hidden_vars(%unused_defaults) ;
#     $hidden_tag=            &hidden_var($name, $value) ;
#
#     ($tag_name, $attr_ref)= &parse_tag($tag) ;
#     $new_tag=               &build_tag($tag_name, $attr_ref) ;
#     $new_tag=               &build_tag($tag_name, %attr) ;
#
#
#   For better documentation, see "perldoc HTML::Defaultify" (or
#     "perldoc -F this_file_name.pm").
#
#   For the latest, see http://www.jmarshall.com/tools/defaultify/ .
#

#---- package-definition-related stuff -------------------------------------

package HTML::Defaultify ;

use strict ;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS) ;

require Exporter ;
@ISA= qw(Exporter) ;

$VERSION=  '1.01' ;
@EXPORT=    qw( defaultify  subhash ) ;
@EXPORT_OK= qw( hidden_vars  hidden_var  parse_tag  build_tag ) ;

%EXPORT_TAGS= (
    parse => [qw( parse_tag  build_tag )],
    all   => [@EXPORT, @EXPORT_OK],
) ;


#---- actual package code below --------------------------------------------

use Carp ;

use vars qw($HAS_HTML_ENTITIES) ;

# Load HTML::Entities if available; set $HAS_HTML_ENTITIES accordingly.
eval 'use HTML::Entities' ;
$HAS_HTML_ENTITIES= ($@ eq '') ;


# defaultify()-- takes a chunk of HTML that includes form input fields,
#   and sets defaults according to the hash sent.
# Returns defaultified HTML block, and a reference to a hash of all defaults
#   that were not used (possibly for use with hidden_vars()).
# In scalar context, only returns defaultified HTML block.
#
#    ($new_HTML, $unused_defs)= &defaultify($HTML, $defaults [, $form_name]) ;
#    $new_HTML= &defaultify($HTML, $defaults [, $form_name]) ;
#
# $defaults is a reference to a hash of default values.  Each default (hash
#   element) may be a scalar, a list in the form of a "\0"-delimited scalar,
#   or a reference to a real list.
# As a special case, if $defaults is undefined, this routine clears all default
#   settings from $HTML, even if they were set with tag attributes, etc.
# As another special case, if $defaults is a CGI object (from CGI.pm), this
#   routine uses its existing parameters as the default set, by calling its
#   Vars() method.
# If you have an existing hash instead of a reference, use e.g. \%my_hash .
# If $form_name is given, then only the form(s) with that name in $HTML will
#   be defaultified.  Otherwise, all of $HTML will be defaultified.
# Tags inside comments or <script> or <style> blocks are not affected.
# For a given set of defaults, there may be more than one way to defaultify
#   a form to return those results, e.g. if several fields have the same
#   name.  This routine tries to generate a reasonable choice in those cases
#   (one tactic is to populate <select> tags before the others), but it may
#   not always be the intended choice.
# The input HTML must be valid HTML, of course.  This routine makes a
#   reasonable effort to support certain invalid but common HTML, but it
#   makes no guarantee that all invalid HTML will be handled the same way
#   that browsers do.  If you get unexpected results, check that your input
#   HTML is valid.
# A previous version allowed defaults to be sent as a full hash in the
#   parameter list, instead of a reference.  This feature was removed to
#   better allow future support of named parameters; in other words, we're
#   reserving the case of second-parameter-is-not-a-reference for use with
#   named parameters.  Additionally, that previous version would modify the
#   hash in place if sent as a reference, but it was decided that wasn't the
#   best API, so now the defaults hash is copied before being used and
#   modified.

sub defaultify {
    my($HTML, $defaults, $form_name)= @_ ;
    my(@extracts, $i, $marker) ;
    local($_) ;

    # First, temporarily remove all comments, <script>...</script> blocks,
    #   and <style>...</style> blocks from $HTML, to avoid matching tags
    #   inside them.  Replace these extractions with markers, so they can be
    #   restored after defaultification is complete.  Somewhat hacky approach,
    #   but works.
    # Extractions are stored in @extracts, and the markers consist of: a random
    #   string not otherwise in $HTML, plus each extraction's location in
    #   @extracts, plus "\0".
    # All four kinds of extractions (two comment formats, scripts, and styles)
    #   are handled simultaneously.  This correctly handles cases of when
    #   "<script>" is inside a comment, or "<!--" is inside a script, etc.
    #   Note that comments ending with "--\s*>" take precedence over comments
    #   ending with just ">", so they must be the first alternative in the
    #   extraction regex below.  The next comment explains the reasoning:
    # Handling end-of-comments is tricky and varies slightly by browser,
    #   though all try to handle the illegal but common usage of comments
    #   ending with only ">" (they are supposed to end with "-->", with
    #   possible whitespace after the "--").  Netscape and Konqueror seem to
    #   end comments on "-->" if available (Konqueror allows the whitespace),
    #   else the comment ends on the next ">".  So to extract comments here,
    #   first extract "<!-- ... --\s*>" blocks, then extract any remaining
    #   comments with "<!-- ... >" .  The real solution is to use correct
    #   HTML in the first place, i.e. end comments with "-->".
    # <script> and <style> blocks are supposed to end on the first "</" string,
    #   but in fact browsers seem to end those blocks at the actual </script>
    #   or </style> tags.  This is most likely what the HTML author expects
    #   anyway, though it violates the HTML spec.  Worse, browsers vary on
    #   whether they'll end a <script> block on a literal string "</script>"
    #   inside the script code.  Balancing all this, for here it's a reasonable
    #   policy to end those blocks on "</script>" and "</style>".
    # There's a potential problem with the marker:  Even if it's not in
    #   $HTML, certain sequences could cause problems.  Consider a marker of
    #   "xy1xy", and a comment preceded by "xy1".  After the comment->marker
    #   replacement, the string is "xy1xy1xy" and will match too early.  But
    #   since we know \d+\0 will always follow the marker, then excluding
    #   digits and \0 from the marker will prevent a wrong match like this.  
    #   I'm pretty sure this solves it, but please tell me if you think of
    #   any combinations that could break this.

    # Generate a random 5-character string.  Exclude digits, \0, and
    #   what the hell, "<" and ">".
    # srand is automatically called in Perl 5.004 and later.
    do {
	$marker= pack("C5", map {rand(193)+63} 1..5) ;  # start after ">"
    } while $HTML=~ /\Q$marker/ ;

    # Extract comments, <script> blocks, and <style> blocks into @extracts,
    #   replacing them with marker in $HTML.  Note the order of the two
    #   comment formats.
    $i= 0 ;
    $HTML=~ s#(<!--.*?--\s*>|<!--.*?>|<\s*script\b.*?<\s*/script\b.*?>|<\s*style\b.*?<\s*/style\b.*?>)#
	      push(@extracts, $1), $marker . $i++ . "\0"  #sgie ;

#    $HTML=~ s/(<!--.*?--\s*>)/ push(@comments,$1), $marker . $i++ . "\0" /sge ;
#    $HTML=~ s/(<!--.*?>)/      push(@comments,$1), $marker . $i++ . "\0" /sge ;


    # Next, defaultify either the entire $HTML or just one form within it.

    # If $form_name is given, then only update the form with that name.
    # This must be done after comments are removed, above.
    if ($form_name ne '') {
	# Here, replace each entire form by either: itself if "name" attribute
	#   doesn't match $form_name, or defaultified self if it does.
	# Note that the resulting $defaults is saved.
	# A little inefficient but not bad.
	$HTML=~ s{(<\s*form\b.*?<\s*/form\b.*?>)} {
		    my($form)= $1 ;   # avoid trouble if $1 gets clobbered
		    ($form, $defaults)= &defaultify($form, $defaults)
			if (&parse_tag($form))[1]->{'name'} eq $form_name ;
		    $form ;
		}sgie ;


    # If no form name was passed, defaultify entire $HTML.  This is the meat
    #   of the module, always run at least once (possibly recursed into by
    #   substitution above).
    } else {
        my($radios_done)= {} ; # must initialize to reference to work correctly

	# First, set $defaults appropriately:  make local copy of hash if it's
	#   a normal hash reference, or {} for undef, or croak.
	if (ref($defaults) eq 'HASH') {
	    $defaults= { %$defaults } ;

	    # make local copies of any referenced lists
	    foreach (keys %$defaults) {
		$defaults->{$_}= [ @{$defaults->{$_}} ] if ref($defaults->{$_});
	    }

	# Special case-- if $defaults is a CGI object, use its Vars() method.
	# Call in list context with {}, to make copy instead of tied hash.
	} elsif (ref($defaults) eq 'CGI') {
	    $defaults= { $defaults->Vars() } ;

	# If $defaults is undef, use an empty hash (clears all form fields).
	} elsif (!defined($defaults)) {
	    $defaults= {} ;

	# Otherwise, croak.
	} else {
	    croak("Second parameter to defaultify() must be hash reference or undef") ;
	}


	# Now, replace all form fields with their defaultified versions!
	# Update all <select><option>...</select>, <input>, and
	#   <textarea>...</textarea> blocks.

	$HTML=~ s#(<\s*select\b.*?<\s*/select\b.*?>)#
	          &new_select($1, $defaults)                 #sgie ;

	$HTML=~ s#(<\s*input\b.*?>)#
	          &new_inputtag($1, $defaults, $radios_done) #sgie ;

	$HTML=~ s#(<\s*textarea\b.*?<\s*/textarea\b.*?>)#
	          &new_textarea($1, $defaults)               #sgie ;
    }


    # Finally, replace comments and <script> and <style> blocks back into $HTML.
    $HTML=~ s/\Q$marker\E(\d+)\0/$extracts[$1]/g ;


    return wantarray  ? ($HTML, $defaults)  : $HTML ;
}



# For the given <input> tag, set the correct default and return corrected tag.
# Any default value that is used is removed from %$defaults.
# The new tag may vary in attribute capitalization and order.
# Radio buttons are special in that only one with a given name may be set in
#   the same form.  Thus, we need to keep track of which radio buttons have
#   been set, and pass as a parameter if the caller cares about this.  The
#   parameter is a reference to a hash, and the hash is modified in place
#   when a radio button is set.  The parameter is not required.
sub new_inputtag {
    my($old_tag, $defaults, $radios_done)= @_ ;
    my($tag_name, $attr)= &parse_tag($old_tag) ;

    # Sanity check
    croak("new_inputtag() called without <input>")
	unless lc($tag_name) eq 'input' ;

    # Lowercase type attribute for easier comparisons
    $attr->{'type'}= lc($attr->{'type'}) ;

    # For text fields, replace value with default value.
    if (($attr->{'type'} eq '') or $attr->{'type'}=~ /^(text|password)$/i ) {
	$attr->{'value'}= &extract_default($defaults, $attr->{'name'}) ;

	# Delete value attribute if it's just set to "".
	delete($attr->{'value'}) if $attr->{'value'} eq '' ;

	# Some old versions of Perl create $attr->{'type'} above, so remove it.
	delete($attr->{'type'}) if $attr->{'type'} eq '' ;

    # For checkboxes, set "checked" if value matches default.
    } elsif ($attr->{'type'} eq 'checkbox') {
	my($value)= defined($attr->{'value'})  ? $attr->{'value'}  : 'on' ;
	$attr->{'checked'}=
	    &extract_default_if_match($defaults, $attr->{'name'}, $value)
		? ''  : undef ;

    # For radio buttons, set "checked" if value matches default.
    # Do not set "checked" if another same-named radio button is already set.
    } elsif ($attr->{'type'} eq 'radio') {
	my($value)= defined($attr->{'value'})  ? $attr->{'value'}  : 'on' ;
	if ($radios_done->{$attr->{'name'}}) {
	    undef($attr->{'checked'}) ;

	} elsif (&extract_default_if_match($defaults, $attr->{'name'}, $value)) {
	    $attr->{'checked'}= '' ;
	    $radios_done->{$attr->{'name'}}= 1 if ref($radios_done) ;
	} else {
	    undef($attr->{'checked'}) ;
	}

    # For other or unknown <input> field types, return tag unchanged.
    } else {
	return $old_tag ;
    }

    return &build_tag($tag_name, $attr) ;
}



# For the given <textarea>...</textarea> block, set the correct default.
# Any default value that is used is removed from %$defaults.
# The new tags may vary in attribute capitalization and order.
sub new_textarea {
    my($old_block, $defaults)= @_ ;
    my($tag_name, $attr)= &parse_tag($old_block) ;  # parses first tag only

    # Sanity check
    croak("new_textarea() called without <textarea>")
	unless lc($tag_name) eq 'textarea' ;

    # Set text between <textarea> and </textarea> to the default.
    my($contents)= &HTMLescape(&extract_default($defaults, $attr->{'name'})) ;
    $old_block=~ s#>.*?<\s*/textarea\b#>$contents</textarea# ;

    return $old_block ;
}


# For the given <select>...</select> block, set the correct default.
# Any default value that is used is removed from %$defaults.
# The new tags may vary in attribute capitalization and order.
sub new_select {
    my($old_block, $defaults)= @_ ;
    my($tag_name, $attr)= &parse_tag($old_block) ;  # parses first tag only

    # Sanity check
    croak("new_select() called without <select>")
	unless lc($tag_name) eq 'select' ;

    # Only allow one option to be set unless <select> has "multiple" attribute.
    # Tricky to update only the first matching option.  Here, we split() with
    #   "delimiters", where the delimiters are what we really care about.
    #   The "<option>..." strings are in array elements 1, 3, 5, ....
    # Note the fourth parameter to new_option() is used to force remaining
    #   options to be unselected after one is set.  Kinda hacky, but works.
    my(@options, $i, $is_selected, $is_done) ;
    @options= split( /(<\s*option[^>]*>[^<]*)/i , $old_block) ;
    for ($i= 1 ; $i<= $#options ; $i+= 2) {
	($options[$i], $is_selected)=
	    &new_option($options[$i], $defaults, $attr->{'name'}, $is_done) ;
	$is_done||= $is_selected && !defined($attr->{'multiple'}) ;
    }

    # Rejoin the <select> block, including both updated options and any other
    #   text before, after, or interspersed within.
    return join('', @options) ;
}


# For the given <option>... block, set "selected" as required.
# Returns new <option>... block, and a flag indicating whether it was selected.
# Any default value that is used is removed from %$defaults.
# The new tag may vary in attribute capitalization and order.
# An alternate use is to merely remove any selected attribute if
#   $force_off is set; this is used by new_select().
sub new_option {
    my($old_block, $defaults, $name, $force_off)= @_ ;
    my($tag_name, $attr)= &parse_tag($old_block) ;  # parses first tag only
    my($orig_text, $remainder)= $old_block=~ />([^<]*)(.*)/s ;
    my($is_match) ;

    # Sanity check
    croak("new_option() called without <option>")
	unless lc($tag_name) eq 'option' ;

    # If $force_off is set, then set $is_match=0 .
    if ($force_off) {
	$is_match= 0 ;

    # If "value" attribute exists, then test match using it.
    } elsif (defined($attr->{'value'})) {
	$is_match= &extract_default_if_match($defaults, $name, $attr->{'value'}) ;

    # Otherwise, test match using text following <option> tag.
    # Apparently, Netscape strips leading and trailing blanks before sending
    #   menu selections.  Thus, compare with or without leading/trailing blanks.
    } else {
	my($stripped_text)= $orig_text ;
	$stripped_text=~ s/^\s+|\s+$//g ;

	# Compare to original or stripped text.  Note short-circuit "||".
	$is_match= &extract_default_if_match($defaults, $name, $orig_text)
		|| &extract_default_if_match($defaults, $name, $stripped_text) ;
    }

    $attr->{'selected'}= $is_match  ? ''  : undef ;

    return (&build_tag($tag_name,$attr) . $orig_text . $remainder, $is_match) ;
}


#---- extract_default() and extract_default_if_match() ---------------

#    $is_match= &extract_default_if_match($defaults, $name, $value) ;
#    $value=    &extract_default($defaults, $name) ;

# Each default (hash element) may be a scalar, a scalar with a "\0"-delimited
#   list of strings, or a reference to a list.

# Return the default value for the given field name.  If there is more than one
#   default (i.e. a list of values), return the first one.  Return undef if
#   there is no default for the given field.
# As a side effect, remove the returned value from the existing default set.
sub extract_default {
    my($defaults, $name)= @_ ;
    my($value) ;

    # Handle the three possible cases of the hash element.
    # First, handle if it's a reference to a list; ...
    if (ref($defaults->{$name})) {
	croak("Default for '$name' is a non-ARRAY reference")
	    unless ref($defaults->{$name}) eq 'ARRAY' ;
	$value= shift(@{$defaults->{$name}}) ;
	delete($defaults->{$name}) if @{$defaults->{$name}}==0 ;

    # ... else, handle if it's a "\0"-delimited list of strings; ...
    } elsif ($defaults->{$name}=~ /\0/) {
	($value, $defaults->{$name})= split(/\0/, $defaults->{$name}, 2) ;
	# will never need to delete hash element here.

    # ... else handle case of normal scalar (including undef).
    } else {
	$value= $defaults->{$name} ;
	delete($defaults->{$name}) ;
    }

    return $value ;
}



# Return true iff there is a default for the given field name that matches the
#   given value (used for things like checkboxes or select menus).  Return
#   undef if there is no default for the given field.
# As a side effect, remove the matched value from the existing default set.
sub extract_default_if_match {
    my($defaults, $name, $value)= @_ ;
    my($is_match, $i) ;

    # Return undef (false) if no defaults are defined for this field.
    return undef unless defined($defaults->{$name}) ;

    # Handle the three possible cases of the hash element.
    # First, handle if it's a reference to a list; ...
    if (ref($defaults->{$name})) {
	croak("Default for '$name' is a non-ARRAY reference")
	    unless ref($defaults->{$name}) eq 'ARRAY' ;
	foreach $i (0..$#{$defaults->{$name}}) {
	    if ($defaults->{$name}[$i] eq $value) {
		$is_match= 1 ;
		splice(@{$defaults->{$name}}, $i, 1) ;
		delete($defaults->{$name}) if @{$defaults->{$name}}==0 ;
		last ;
	    }
	}

    # ... else, handle if it's a "\0"-delimited list of strings; ...
    } elsif ($defaults->{$name}=~ /\0/) {
	# Split into list, then manage like above.
	# Note that w/o a LIMIT, split() drops trailing '' from the result.  :P
	my(@values)= split(/\0/, $defaults->{$name}, length($defaults->{$name})) ;
	foreach $i (0..$#values) {
	    if ($values[$i] eq $value) {
		$is_match= 1 ;
		splice(@values, $i, 1) ;
	        $defaults->{$name}= join("\0", @values) ;
		# will never need to delete hash element here.
		last ;
	    }
	}

    # ... else handle case of normal scalar.
    } else {
	if ($defaults->{$name} eq $value) {
	    $is_match= 1 ;
	    delete($defaults->{$name}) ;
	}
    }

    return $is_match ;
}


#---- parse_tag() and build_tag() ------------------------------------

# Parses an HTML tag into its tagname and attributes.
# Parses first tag in string, ignoring all before and after.
# Returns tag name and reference to hash of attributes.  The hash keys
#   (attribute names) are lowercased, and the values are de-quoted with
#   character entity references replaced by their characters where possible.
sub parse_tag {
    my($tag)= @_ ;
    my($tag_name, $attrs, $attr) ;
    local($_) ;

    # Remove comments to avoid parsing tag within one.
    # See defaultify() above for notes about removing comments.
    $tag=~ s/<!--.*?--\s*>//sg ;
    $tag=~ s/<!--.*?>//sg ;

    # SGML tag and attribute names match "\w[\w.-]*" , except no underscores.  Oh well.
    # Include possible "/" at start.
    ($tag_name,$attrs)= $tag=~ /<\s*(\/?\w[\w.-]*)\s*([^>]*)/ ; # first tag only

    # Extract name/value (possibly quoted), lowercase name, set $attr->{}.
    # If quoted, delimited by quotes; if not, delimited by whitespace.
    $attr->{lc($1)}= &HTMLunescape($+)
        while $attrs=~ s/\s*(\w[\w.-]*)\s*=\s*(([^"']\S*)|"([^"]*)"?|'([^']*)'?)// ;

    # Now, get remaining non-valued attributes.
    # Technically, HTML attributes with no value given get a value equal to the
    #   attribute name, e.g. a plain 'selected' means 'selected="selected"' .
    #   However, most browsers seem to treat them as having a value of "",
    #   so *sigh* we'll do that here.
    foreach ($attrs=~ /(\w[\w.-]*)/g)  { $attr->{+lc}= '' }

    return($tag_name, $attr) ;
}


# Build a tag from its name and attributes.
# Attributes can be passed as either a hash or a reference to one.
sub build_tag {
    my($tag_name)= shift ;
    my($attr, $attrs) ;
    local($_) ;

    # passed by reference or by values?
    $attr= ref($_[0])  ? $_[0]  : { @_ }  ;

    # Undefined attributes are dropped, and attributes equal to "" are put
    #   in the tag with no value.  See note in parse_tag().
    foreach (keys %$attr) {
	next unless defined($attr->{$_}) ;
        $attrs.= ( ($attr->{$_} ne '')
                   ? (" $_=\"" . &HTMLescape($attr->{$_}) . '"')
                   :  " $_" ) ;
    }
    
    return "<$tag_name$attrs>" ;
}


#---- hidden_vars() and hidden_var() ---------------------------------

# For the given set of form data, create a block of hidden form variables
#   that represents that data.
# Each hash element represents a field; each hash value can be a scalar, a
#   "\0"-delimited list of strings, or a reference to a real list.
sub hidden_vars {
    my($f, @ret, $ret, $name, $value) ;

    # First, set the hash of fields we'll use
    $f= ref($_[0])  ? $_[0]  : { @_ }  ;  # passed by reference or by values?

    # Then, for each field, add one or more <input type=hidden> tags to @ret.
    # Don't include undefined variables.
    foreach $name (keys %$f) {
        if (defined($f->{$name})) {

	    # Handle the three possible cases of the hash element.
	    # First, handle if it's a reference to a list; ...
	    if (ref($f->{$name})) { 
		foreach $value (@{$f->{$name}}) {
		    push(@ret, &hidden_var($name, $value)) if defined($value) ;
		}

	    # ... else, handle if it's a "\0"-delimited list of strings; ...
	    } elsif ($f->{$name}=~ /\0/) {
		# Note that w/o a LIMIT, split() drops trailing ''.  :P
		# No values here will be undefined.
		push(@ret, map { &hidden_var($name, $_) }
				split(/\0/, $f->{$name}, length($f->{$name}))) ;

	    # ... else handle case of normal scalar.
	    } else {
		push(@ret, &hidden_var($name, $f->{$name}))
		    if defined($f->{$name}) ;
	    }
	}
    }

    return join("\n", @ret) ;
}


# Returns an <input type=hidden> tag to represent the given form field.
sub hidden_var {
    my($name, $value)= @_ ;

    return '<input type=hidden name="' . &HTMLescape($name) 
         . '" value="' . &HTMLescape($value) . "\">" ;
}


#---- subhash() ------------------------------------------------------

# Returns a subset of the referenced hash, consisting of those elements
#   named by @keys.
# Returns a reference to the hash.  To get the hash itself, use e.g.
#   "%my_hash= %{ &subhash(...) }" .  We removed the list-context option
#   of returning the full hash, because this is usually called in a list
#   context where the hash reference is wanted (such as in a parameter
#   list to &defaultify() ).
# Any elements requested but not present in the input hash will exist
#   in the result hash, with an undefined value.
# How I wish Perl supported a "%hash{@subscripts}" notation for slices!
sub subhash {
    my($hashref, @keys)= @_ ;
    my(%ret) ;

    @ret{@keys}= @$hashref{@keys} ;   # non-existent elements set to undef

    # return wantarray  ? %ret  : \%ret ;   # no longer
    return \%ret ;
}


#---- HTMLescape() and HTMLunescape() --------------------------------

# Escape any &"<> chars to &xxx; and return resulting string.
# Use HTML::Entities if possible, else do adequate job here.
# There is still a slight risk-- if the input here has a character
#   entity reference that was not properly unescaped before (like if
#   HTMLunescape() can't use HTML::Entities), then the resulting string
#   here will be doubly-escaped, e.g. "&amp;xyz;" .
sub HTMLescape {
    my($s)= @_ ;

    # If we have the HTML::Entities module, encode using that.
    return encode_entities($s)  if $HAS_HTML_ENTITIES ;

    # Otherwise, do a simplified version that encodes &"<> chars.
    $s=~ s/&/&amp;/g ;      # must be before all others
    $s=~ s/"/&quot;/g ;
    $s=~ s/</&lt;/g ;
    $s=~ s/>/&gt;/g ;
    return $s ;
}


# Unescape any character entity references and return resulting string.
# Use HTML::Entities if possible, else do adequate job here.
# Possible flaw here-- if there is a character entity reference that this
#   routine does not handle, then data is lost.  For example, input strings
#   of both "&amp;xyz;" and "&xyz;" result in output of "&xyz;" .  This is
#   only a flaw if "&xyz;" is an actual character entity reference; otherwise,
#   those two input strings actually represent the same data anyway.
sub HTMLunescape {
     my($s)= @_ ;

    # Original code; mirrors that in HTMLescape().
#    $s=~ s/&quot;/"/g ;
#    $s=~ s/&lt;/</g ;
#    $s=~ s/&gt;/>/g ;
#    $s=~ s/&amp;/&/g ;      # must be after all others
#    return $s ;

    # If we have the HTML::Entities module, decode using that.
    return decode_entities($s)  if $HAS_HTML_ENTITIES ;

    # Otherwise, do a simplified version ourselves.  Decode &"<> chars
    #   and "&#nnn;" codes; otherwise, leave "&...;" sequences unchanged.
    my(%echar)= ('quot', '"', 'lt', '<', 'gt', '>', 'amp', '&') ;
    $s=~ s/(&([a-zA-Z][a-zA-Z0-9.-]*);?|&#([0-9]+);?)/
            length($3)          ? sprintf("%c",$3) 
          : defined($echar{$2}) ? $echar{$2}  
                                : $1 
          /ge ;
    return $s ;
}


#---- end of module! -------------------------------------------------------

# return true
1 ;

__END__

#---- POD below ------------------------------------------------------------

=head1 NAME

HTML::Defaultify - Pre-fill default values into an existing HTML form

=head1 SYNOPSIS

  use HTML::Defaultify;
 
  # $HTML is a block of HTML with a form, and %my_defaults is a hash of
  #   values to populate the form with.
  # If $HTML contains multiple forms, you can name which form to populate.
 
  $new_HTML= &defaultify($HTML, \%my_defaults) ;
  $new_HTML= &defaultify($HTML, \%my_defaults, 'form1') ;
 
  # If you care which defaults were left over, call it in list context.
  # Result can be passed to hidden_vars() to generate a set of
  #   <input type=hidden> tags.
 
  ($new_HTML, $unused_defaults)= &defaultify($HTML, \%my_defaults) ;
  $remaining_form_values= &hidden_vars($unused_defaults) ;
 
  # subhash() creates a hash that's a subset of a larger hash, similar
  #   to a slice.  Useful to partially populate forms.  This example
  #   might avoid filling in a "password" field.
 
  $new_HTML= &defaultify($HTML, &subhash(\%my_defaults, qw(login type))) ;


=head1 DESCRIPTION

This module lets you take an existing HTML page with forms in it, and
fill in the form fields according to defaults you give.  It's most useful
in CGI scripts.  One common use is to handle invalid user input-- show them
the same form with their previously entered values filled in, and let them
correct any errors.  Another use might be when letting users edit a database
record, such as their account information-- show them an input form with
the current values filled in.  There are other uses.

Other tools can populate form fields, but they require the HTML and program
source code to be highly intermingled.  In contrast, the approach used here
(of populating any existing HTML document) allows a clean separation of the
HTML development and the programming.  This works much better in projects
where the two tasks are done by different people, such as a designer and a
programmer.

To defaultify a form, use the defaultify() function.  The following
command is all most people ever need from this module:

  $new_HTML= &defaultify($HTML, $defaults) ;

or, to specify which form to defaultify on a page with multiple forms:

  $new_HTML= &defaultify($HTML, $defaults, $form_name) ;

C<$HTML> is some HTML text, possibly read in from a file; you might even
replace the parameter above with "C<`cat filename.html`>".
C<$defaults> is a reference to a hash of default values-- the keys
of the hash correspond to the names of the form fields, and the values are
what to set the defaults to; each hash value may be either a scalar,
a reference to a list of scalars (for multiple input fields with the same
name), or a list in the form of a "\0"-delimited scalar.  C<$form_name> is
the name of a form, from the "name" attribute of the C<E<lt>formE<gt>> tag.

The resulting C<$new_HTML> is the same as C<$HTML>, except that all <input>
tags, <select>...</select> blocks, and <textarea>...</textarea> blocks have
been altered to best represent the values given in the defaults hash.  This
includes clearing fields that have no default given.  If C<$form_name> is
given, changes are restricted to that form only.  Otherwise, all of C<$HTML>
is defaultified.

The format of the defaults hash is made to accommodate the most common ways
that form data sets are represented, including how user input is read by common
tools.  For example, if you're using the CGI.pm module, you can use the hash
reference returned by the Vars() method or function as C<$defaults> (but see
below for an easier way if you're using CGI.pm).  You can also use the
hashes returned from other tools that parse form input, such as the
S<cgi-lib.pl> library or the getcgivars() function.  In the last two cases,
note that those functions return hashes instead of hash references, so you
should create a reference when calling defaultify():

  %my_defaults= &getcgivars ;
  $new_HTML= &defaultify($HTML, \%my_defaults) ;

Of course, you can always create your own default set:

  $new_HTML= &defaultify($HTML, { name   => 'Coltrane',
                                  citycb => [qw(SF LA NY)] } ) ;

or the same thing, using a different list format:

  $new_HTML= &defaultify($HTML, { name   => 'Coltrane',
                                  citycb => "SF\0LA\0NY" } ) ;

As a special case, if you're using the CGI.pm module, you can give a
reference to a CGI object as C<$defaults>, and defaultify() will use the
current parameters in the object as its default set.  For example:

  $q= new CGI ;
  $new_HTML= &defaultify($HTML, $q) ;

As another special case, if C<$defaults> is undefined, then defaultify()
will clear all form fields; in other words, passing undef is the same
as passing an empty hash reference.

If defaultify() is called in list context, it returns two values: the
defaultified HTML as above, and a reference to a hash that contains all
the leftover defaults, i.e. those that were not set in any form field.
That hash is in the same format as the input defaults hash, and is a subset
of it (and any included lists are subsets of their respective lists).  It's
useful if you need to know which values were set and which were not.
Also, passing that hash reference to hidden_vars() and inserting the result
into C<$new_HTML> means that all data in the original defaults hash is now
represented in the form.

Besides defaultify(), this module provides other functions that some users
may find helpful.  subhash() creates a subset of a hash and returns a hash
reference, suitable for use when calling defaultify(); this is useful to
set only certain fields in a form.  hidden_vars() creates hidden
form fields that represent a given set of form data, such as the set of
unused defaults returned by defaultify(); hidden_var() creates one
well-formatted hidden form field.  parse_tag() and build_tag() parse an
HTML tag into its tag name and attributes, and rebuild it.  For details on
these functions, see the EXPORTS section below and the examples in the
synopsis above.


=head1 EXPORTS

  @EXPORT=    qw( defaultify  subhash ) ;
  @EXPORT_OK= qw( hidden_vars  hidden_var  parse_tag  build_tag ) ;

The C<:parse> symbol imports parse_tag() and build_tag().
The C<:all> symbol imports everything in @EXPORT and @EXPORT_OK.


=over 4

=item defaultify($HTML, $defaults [, $form_name])

In scalar context, returns C<$HTML> but with all form fields set to best
represent the values specified in the C<$defaults> hash (which may include
clearing explicitly set fields).  C<$HTML> is presumed to be a block of
HTML with one or more form fields.  If C<$form_name> is given, then only
the form with that name in C<$HTML> is affected.  Otherwise, all form
fields in C<$HTML> are set appropriately.

C<$defaults> is a reference to a hash.  The keys of that hash are form
field names, and the values are what those form fields should be set to.
Each value can be a scalar with one value, a scalar with multiple values
separated by the null character "\0", or an array reference.  The last
two forms can be used to represent multiple values associated with the
same field name.  C<$defaults> may also be undefined, in which case it's
treated as an empty hash and clears all form fields of their default
values, even if some are set in the input HTML.  As a special case,
C<$defaults> can be a reference to a CGI object as created by the CGI.pm
module, and defaultify() will call its Vars() method to use the object's
current parameters as the set of defaults.

If called in a list context, defaultify() returns the defaultified HTML as
described above, and a reference to a hash of all the defaults in
C<$defaults> that were not set anywhere in the HTML.  That hash is in the
same format as C<$defaults>, and is a subset of it.

For further explanation and examples, see the DESCRIPTION section above.


=item subhash($hashref, @keys)

Creates a subset of the hash pointed to by C<$hashref>, containing only those
elements named in C<@keys>.  Returns a reference to the created hash.  Any
elements named in C<@keys> that do not exist in C<%$hashref> will be created
in the result hash with an undefined value.

If you want the created hash itself instead of a reference to it, use
something like "S<C<%{ &subhash(...) }>>".

=item hidden_vars($data_set)

=item hidden_vars(%data_set)

Returns a string consisting of C<E<lt>input type=hiddenE<gt>> tags that
represent the form data defined in C<$data_set>.  C<$data_set> points to
a hash of form data that is in exactly the same format as the C<$defaults>
parameter of the defaultify() function, and as the second return value
(unused defaults) from defaultify() when called in list context.  That is,
the hash keys are field names, and each hash value can be any of a scalar, a
list reference, or a scalar with a "\0"-delimited list.  (However, note
that a CGI object is not supported here.)  You may also pass a complete
hash instead of a reference to one.

For any hash value that is a list, each element in that list will result
in one hidden form field in the return string.

If you call hidden_vars() with the hash of unused defaults returned from
defaultify(), and insert the result into the defaultified HTML, you get a
form containing all data represented in the original default set, even if
some of the fields did not exist in the form.

=item hidden_var($name, $value)

Returns a well-formatted C<E<lt>input type=hiddenE<gt>> tag that represents
the given name-value pair.  The name and value are properly escaped with
character entity references if needed.


=item parse_tag($tag)

Parses an HTML tag into its tag name and attributes.  Returns a two-element
list of the tag name and a reference to a hash of attributes.  The tag name
may start with "/" for an end tag.  In the attribute hash, the keys
(attribute names) are lowercased, and the values have been resolved to
remove character entity references where possible.  The values do not
contain their surrounding quotes.

parse_tag() parses the first tag found in C<$tag>.  C<$tag> may safely
contain leading or trailing text, or other tags, and parse_tag() will
ignore them all.  Tags within comments are correctly ignored.

Attributes without an explicit value, such as the "multiple" in
"S<C<E<lt>select name=foo multipleE<gt>>>", are treated as if their value
is the empty string.  Technically, in those cases the value should be
treated as equal to the name, e.g. the above "multiple" is equivalent to
"multiple=multiple".  However, browsers seem to treat its value as the
empty string, so *sigh* this module does the same.

=item build_tag($tag_name, $attr)

=item build_tag($tag_name, %attr)

Builds an HTML tag string from the tag name and attribute hash, and returns it.
Both parameters are in the same format as the return values from parse_tag().
The attribute hash can be passed as either a hash reference or a full hash.
All attribute values are properly escaped with character entity references
if needed.

Attributes with a value of the empty string are added to the tag without an
explicit value, i.e. an "=..." part.  See the note in the parse_tag()
section just above.

Note that if you use parse_tag() to parse a tag and build_tag() to rebuild it,
the resulting tag string may differ from the original in the order and
capitalization of the attributes, but the meaning is the same.

=back


=head1 REQUIRES

No other modules are required, but HTML::Entities is preferred, and used
if available.


=head1 BUGS

For a given set of defaults, there may be more than one way to defaultify
a form to return those results, e.g. if several fields have the same
name.  This routine tries to generate a reasonable choice in those cases
(one tactic is to populate <select> tags before the others), but it may
not always be the intended choice.

The input HTML must be valid HTML, of course.  This module makes a
reasonable effort to support certain invalid but common HTML, but it
makes no guarantee that all invalid HTML will be handled the same way
that browsers do.  If you get unexpected results, check that your input
HTML is valid.

If parse_tag() is used to parse a tag and build_tag() is used to rebuild it,
then the order and capitalization of the attributes may not match the
original.  This should not affect the meaning (ergo behavior) of any HTML,
but it may be confusing to a human reader.

If HTML::Entities is not available, then only the four most common entities
(C<&amp;>, C<&lt;>, C<&gt;>, C<&quot;>) are supported.  This may cause
problems if your HTML uses other character entity references.


=head1 AUTHOR

James Marshall (james@jmarshall.com)

=head1 COPYRIGHT

Copyright (c) 1996, 1997, 2002, James Marshall.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), HTML::Entities

=cut

