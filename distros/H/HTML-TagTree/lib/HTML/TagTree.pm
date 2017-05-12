###############################################################################
##                                                                           ##
##    Copyright (c) 2007 - 2013 by Dan DeBrito.                              ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################


package HTML::TagTree;
our $AUTOLOAD;


use strict;
use version;

my $DOUBLE_QUOTE = '"';
my $SINGLE_QUOTE = "'";
our $VERSION = qv('1.03');

my %preprocess_tag;
my %empty_tags = (
   # Tags that should not contain content or children tags
   br => 1,
   input => 1,
);

my %tag_open_substitutions = (
   ifie => '!--[if IE]',

);
my %tag_close_substitutions = (
   ifie => '![endif]--',
);
my %tags_no_autowhitespace = (
   # Don't allow autofilling of whitespace for these tags and any children
   'a' => 1,
   'code' => 1,
   'pre' => 1,
   'samp' => 1,
   'span' => 1,
   'textarea' => 1,
);

my %valid_empty_tags_for_shortening = (
   # These tags don't need a full close tag but can use abbreviated notation when empty.
   # eg:
   #  <br />  instead of <br></br>

   area => 1,
   base => 1,
   br => 1,
   canvas => 1,    # HTML5
   col => 1,
   frame => 1,
   hr => 1,
   input => 1,
   img => 1,
   link => 1,
   meta => 1,
   option => 1,
   param => 1,

);
my %valid_tags = (
   'a' => 'Defines an anchor 3.0 3.0 STF ',
   'abbr' => 'Defines an abbreviation 6.2   STF ',
   'acronym' => 'Defines an acronym 6.2 4.0 STF ',
   'address' => 'Defines an address element 4.0 4.0 STF ',
   'applet' => 'Deprecated. Defines an applet 2.0 3.0 TF ',
   'area' => 'Defines an area inside an image map 3.0 3.0 STF ',
   'b' => 'Defines bold text 3.0 3.0 STF ',
   'base' => 'Defines a base URL for all the links in a page 3.0 3.0 STF ',
   'basefont' => 'Deprecated. Defines a base font 3.0 3.0 TF ',
   'bdo' => 'Defines the direction of text display 6.2 5.0 STF ',
   'big' => 'Defines big text 3.0 3.0 STF ',
   'blockquote' => 'Defines a long quotation 3.0 3.0 STF ',
   'body' => 'Defines the body element 3.0 3.0 STF ',
   'br' => 'Inserts a single line break 3.0 3.0 STF ',
   'button' => 'Defines a push button 6.2 4.0 STF ',
   'canvas' => 'HTML5',
   'caption' => 'Defines a table caption 3.0 3.0 STF ',
   'center' => 'Deprecated. Defines centered text 3.0 3.0 TF ',
   'cite' => 'Defines a citation 3.0 3.0 STF ',
   'code' => 'Defines computer code text 3.0 3.0 STF ',
   'col' => 'Defines attributes for table columns    3.0 STF ',
   'colgroup' => 'Defines groups of table columns   3.0 STF ',
   'dd' => 'Defines a definition description 3.0 3.0 STF ',
   'del' => 'Defines deleted text 6.2 4.0 STF ',
   'dir' => 'Deprecated. Defines a directory list 3.0 3.0 TF ',
   'div' => 'Defines a section in a document 3.0 3.0 STF ',
   'dfn' => 'Defines a definition term   3.0 STF ',
   'dl' => 'Defines a definition list 3.0 3.0 STF ',
   'dt' => 'Defines a definition term 3.0 3.0 STF ',
   'em' => 'Defines emphasized text  3.0 3.0 STF ',
   'fieldset' => 'Defines a fieldset 6.2 4.0 STF ',
   'font' => 'Deprecated. Defines text font, size, and color 3.0 3.0 TF ',
   'form' => 'Defines a form  3.0 3.0 STF ',
   'frame' => 'Defines a sub window (a frame) 3.0 3.0 F ',
   'frameset' => 'Defines a set of frames 3.0 3.0 F ',
   'h1' => 'Defines header 1 to header 6 3.0 3.0 STF ',
   'h2' => 'Defines header 1 to header 6 3.0 3.0 STF ',
   'h3' => 'Defines header 1 to header 6 3.0 3.0 STF ',
   'h4' => 'Defines header 1 to header 6 3.0 3.0 STF ',
   'h5' => 'Defines header 1 to header 6 3.0 3.0 STF ',
   'h6' => 'Defines header 1 to header 6 3.0 3.0 STF ',
   'head' => 'Defines information about the document 3.0 3.0 STF ',
   'hr' => 'Defines a horizontal rule 3.0 3.0 STF ',
   'html' => 'Defines an html document 3.0 3.0 STF ',
   'i' => 'Defines italic text 3.0 3.0 STF ',
   'ifie' => 'unigue Tag used to define Internet Explorer specific HTML ',
   'iframe' => 'Defines an inline sub window (frame) 6.0 4.0 TF ',
   'img' => 'Defines an image 3.0 3.0 STF ',
   'input' => 'Defines an input field 3.0 3.0 STF ',
   'ins' => 'Defines inserted text 6.2 4.0 STF ',
   'isindex' => 'Deprecated. Defines a single-line input field 3.0 3.0 TF ',
   'kbd' => 'Defines keyboard text 3.0 3.0 STF ',
   'label' => 'Defines a label for a form control 6.2 4.0 STF ',
   'legend' => 'Defines a title in a fieldset 6.2 4.0 STF ',
   'li' => 'Defines a list item 3.0 3.0 STF ',
   'link' => 'Defines a resource reference  4.0 3.0 STF ',
   'map' => 'Defines an image map  3.0 3.0 STF ',
   'menu' => 'Deprecated. Defines a menu list 3.0 3.0 TF ',
   'meta' => 'Defines meta information 3.0 3.0 STF ',
   'noframes' => 'Defines a noframe section 3.0 3.0 TF ',
   'noscript' => 'Defines a noscript section 3.0 3.0 STF ',
   'object' => 'Defines an embedded object   3.0 STF ',
   'ol' => 'Defines an ordered list 3.0 3.0 STF ',
   'optgroup' => 'Defines an option group 6.0 6.0 STF ',
   'option' => 'Defines an option in a drop-down list 3.0 3.0 STF ',
   'p' => 'Defines a paragraph 3.0 3.0 STF ',
   'param' => 'Defines a parameter for an object 3.0 3.0 STF ',
   'pre' => 'Defines preformatted text 3.0 3.0 STF ',
   'q' => 'Defines a short quotation 6.2   STF ',
   's' => 'Deprecated. Defines strikethrough text 3.0 3.0 TF ',
   'samp' => 'Defines sample computer code 3.0 3.0 STF ',
   'script' => 'Defines a script 3.0 3.0 STF ',
   'select' => 'Defines a selectable list 3.0 3.0 STF ',
   'small' => 'Defines small text 3.0 3.0 STF ',
   'span' => 'Defines a section in a document 4.0 3.0 STF ',
   'strike' => 'Deprecated. Defines strikethrough text 3.0 3.0 TF ',
   'strong' => 'Defines strong text 3.0 3.0 STF ',
   'style' => 'Defines a style definition 4.0 3.0 STF ',
   'sub' => 'Defines subscripted text 3.0 3.0 STF ',
   'sup' => 'Defines superscripted text 3.0 3.0 STF ',
   'table' => 'Defines a table 3.0 3.0 STF ',
   'tbody' => 'Defines a table body   4.0 STF ',
   'td' => 'Defines a table cell 3.0 3.0 STF ',
   'textarea' => 'Defines a text area 3.0 3.0 STF ',
   'tfoot' => 'Defines a table footer   4.0 STF ',
   'th' => 'Defines a table header 3.0 3.0 STF ',
   'thead' => 'Defines a table header   4.0 STF ',
   'title' => 'Defines the document title 3.0 3.0 STF ',
   'tr' => 'Defines a table row 3.0 3.0 STF ',
   'tt' => 'Defines teletype text 3.0 3.0 STF ',
   'u' => 'Deprecated. Defines underlined text 3.0 3.0 TF ',
   'ul' => 'Defines an unordered list 3.0 3.0 STF ',
   'var' => 'Defines a variable 3.0 3.0 STF ',
   'xmp' => 'Deprecated. Defines preformatted text 3.0 3.0   ',
);

my %element_types = (
   header => 'Valid header elements: <link> <style> <title> <meta> and <script> belong in <head> ',
   structural_block => 'Reflect hierarchy and relationship. Block elements belong in structured blocks:
                        <ol> <ul> <dl> <table> and <div> (which can be structural or terminal)',
   terminal_block => ' <h1> <h2> <h3> <h4> <h5> <h6> 
                       <p>
                       <blockquote>
                       <dt>
                       <address>
                       caption>
                     ',
   multi_purpose_block => 'Can eithor extend or terminate structure.
                           <div> <li> <dd> <td> <th> <form> <noscript>
                          ',
   inline => ' <em> ',
);


sub new {
	my $class = shift;
   my $tag = shift;
   my $content = shift;
   my $tag_attributes = shift;

   my %hash;
   # build class data structure
   my $self = \%hash;
	
	if ( (ref $class) eq 'HTML::TagTree') {
      my $parent_obj = $class;
      $hash{parent} = $parent_obj;
      $class = 'HTML::TagTree';
      push @{$parent_obj->{children_objs}}, $self;
   }
   if (defined $tag_attributes && ($tag_attributes ne '')) {
      $self->{attributes} = $tag_attributes;
   }
   &process_tag($self,$tag);
   if (defined $content && ($content ne '')) {
      &_process_content($self,$content);
   }
	
   bless $self, $class;
	return $self;
}


sub release {
   my $self = shift;;

   # This method is required to release memory if HTML is used in a persistant Perl program (eg like a server).

  if (exists $self->{parent}) {
     delete $self->{parent};      # remove ref to parent object
  }
  $self->DESTROY();
}

sub add_attribute {
   my $self = shift;
   my $attribute = shift;
   if (exists $self->{attributes}) {
      # pad the attributes with a space
      $self->{attributes} .= ' ';
   }
   $self->{attributes} .= $attribute;
}   

sub process_tag {
   my $self = shift;
   my $tag = shift;

   my $attributes = '';
   if ($tag =~ m/^\s*(\w+)\s+(.*)/) {
      $tag = $1;
      $attributes = $2;
   }
   
   $self->{tag} = $tag;
   # Need to make sure all attribute set values are quoted (eg width="100%")
   # Using .= since attributes can be passed in several ways.
   if (exists $self->{attributes}) {
      # pad the attributes with a space
      $self->{attributes} .= ' ';
   }
   $self->{attributes} .= $attributes;
}

sub _process_content {
   my $self = shift;
   my $content = shift;

	if ( (ref $content) eq 'HTML::TagTree') {
      my $child_obj = $content;
      push @{$self->{children_objs}}, $child_obj;
      # need to fix child_obj tree indent levels;
      
      $child_obj->{parent} = $self;
   }
   else {
      push @{$self->{content}}, $content;
   }
}

sub print_html {
   # Print the resulting HTML to STDOUT
   my $self = shift;
   my $indent_level = shift;
   my $no_whitespace_flag = shift;

   $self->get_html_text($indent_level,$no_whitespace_flag, 1);
}

sub get_html_text {
   my $self = shift;
   my $indent_level = shift;
   my $no_whitespace_flag = shift;
   my $print = shift;     # Cause to print to STDOUT immediately

   my $old_no_whitespace_flag;
   my $old_nl;
   my $old_tab;
   
   my $content_flag = 0;
   if (! $indent_level) {
      $indent_level = 0;
   }
   $indent_level++;
   my $nl = "\n";
   my $tab = '   ' x $indent_level;
   my $tab1 = $tab . '   ';      # Tab is 3 spaces a Zuul intendend it to be.
   if ($no_whitespace_flag) {
      $tab = '';
      $tab1 = '';
      $nl = '';
   }
   my $tag_open = $self->{tag};
   if (exists $tag_open_substitutions{$tag_open}) {
      $tag_open = $tag_open_substitutions{$tag_open};
   }
   
   my $html_text = $tab . "<$tag_open";
   if ($print) {
      print $html_text;
   }
   if ( (exists $self->{attributes}) && ($self->{attributes} ne '') ) {
      if ((ref $self->{attributes}) eq 'ARRAY') {
         # Check to see if any of the attributes in the array is a callback
         # Use this callback mechanism to for doing things like minifying of 
         # javascript and css on the fly.
         my $attribute_text;
         foreach my $attribute (@{$self->{attributes}}) {
            if ((ref $attribute) eq 'CODE') {
               my $text = &$attribute();
               $attribute_text .= " " . $text;
            }
            if ((ref $attribute) eq 'SCALAR') {
               my $text = $$attribute;
               $attribute_text .= " " . $text;
            }
            else {
               $attribute_text .= " " . $attribute;
            }
         }
         # change the $self->{attributes} from an ARRAY ref to SCALAR
         $self->{attributes} = $attribute_text;
      }
      elsif ((ref $self->{attributes}) eq 'HASH') {
         foreach my $attribute (@{$self->{attributes}}) {
            my $att_value = $self->{attributes}{$attribute};
         }
         
      }
      elsif ((ref $self->{attributes}) eq 'CODE') {
         $self->{attributes} = &{$self->{attributes}}();
      }
      elsif ((ref $self->{attributes}) eq 'SCALAR') {
         $self->{attributes} = ${$self->{attributes}};
      }
      $self->{attributes} = &_quote_attribute_params($self->{attributes});
      if ($print) {
         print " $self->{attributes}";
      }
      else{
         $html_text .= " $self->{attributes}";
      }
   }
   if (exists $tags_no_autowhitespace{$self->{tag}}) {
      $old_tab = $tab;
      $tab = '';
      $tab1 = '';
      $old_nl = $nl; 
      $nl = '';
      $old_no_whitespace_flag = $no_whitespace_flag;
      $no_whitespace_flag = 1; 
   }
   if (  (!exists $self->{content})
         && (!exists $self->{children_objs})
         &&  (exists $valid_empty_tags_for_shortening{$tag_open})
#         && 0     # disable this logic
      ) {
      if ($print) {
         print " />$nl";
      }
      else{
         $html_text .= " />$nl";
      }
   }
   else{
      if ($print) {
         print ">$nl";
      }
      else{
         $html_text .= ">$nl";
      }
   }
   if (exists $self->{content}){
      $content_flag = 1;
      foreach my $content (@{$self->{content}}) {
         if ((ref $content) eq 'CODE') {
            # Get whats returned from the reference to a subroutine.
            $content = &{$content}();
         }
         elsif ((ref $content) eq 'SCALAR') {
            my $content = $$content;
         }
         if ($print) {
            print $tab1 . "$content$nl";
         }
         else{
            $html_text .= $tab1 . "$content$nl";
         }
      }
   }
   if (exists $self->{children_objs}) {
      foreach my $child (@{$self->{children_objs}}) {
         if ($print) {
            $child->get_html_text($indent_level,$no_whitespace_flag,$print);
         }
         else{
            $html_text .= $child->get_html_text($indent_level,$no_whitespace_flag);
         }
      }
   }

   # Close the tag
   my $tag_close = $self->{tag};
   if (exists $tag_close_substitutions{$tag_close}) {
      $tag_close = $tag_close_substitutions{$tag_close};
      if (exists $tags_no_autowhitespace{$self->{tag}}) {
         # Restore whitespace and tabs
         $no_whitespace_flag = $old_no_whitespace_flag;
         $nl = $old_nl;
         $tab = $old_tab;
      }
      if ($print) {
         print "$tab<$tag_close>$nl";
      }
      else{
         $html_text .= "$tab<$tag_close>$nl";  # No /   Only print end tag if content or children
      }
   }
   else{
      if (  (!exists $self->{content})
            && (!exists $self->{children_objs})
            &&  (exists $valid_empty_tags_for_shortening{$tag_open})
         ) {
          # Do do any thing tag closed earlier via <tag />
      }
      else{
         if ($print) {
            print "$tab</$tag_close>$nl";    # Only print end tag if content or children
         }
         else{
            $html_text .= "$tab</$tag_close>$nl";  # Only print end tag if content or children
         }
      }
   }
   return $html_text;
}


sub _quote_attribute_params {
   my $attributes_string = shift;
   
   my $attr_key;
   my $attr_value;
   my $autoquote_quote_type;
   my $autoquoting_value = '';
   my $char = '';
   my $prev_char = '';
   my $processed_string;
   my $return_attributes_string = '';
   #  <a href="http://pnwpest.org/cgi-bin/forecast/wxfc?station="KCVO""  style="text-decoration:underline; color:blue">
   #   $self->{attributes} =~ s/=([^\"\'])(\S+)/="$1$2"/gsx;   # quote the arguments
   my $starting_quote_type;
   my $state = 'looking_for_equal_sign';

   # State Machine:
   #    Note the 'looking_for_start_of_whitespace_while_autoquoting_value' state.
   #    This state is complicated because we don't know if the value contains single or double quotes.
   #    (Hopefully not both!). We'll surround the value with the proper quote type depending on content.
   #    For example:
   #        key=1"plywood
   #    converts to:
   #        key='1"plywood'
   #    The opposite occurs for input"
   #        key=8'long_stud
   #    converts to:
   #        key="8'long_stud"
   #    Default is double quoting. eg:
   #        key=value
   #    converts to:
   #        key="value"

   CHAR:
   while ($attributes_string =~ m/(.)/sg ){
      $prev_char = $char;
      $processed_string .= $prev_char;
      $char = $1;
      
      
      if ($state eq 'looking_for_equal_sign') {
         if ($char eq '=' ) {
            $state = 'getting_char_after_equal_sign';
         }
         elsif ($char =~ m/\s/) {
            # Ignore whitespace
            next CHAR;
         }
         else{
            $attr_key .= $char;    #Save individual attribute keys 
         }
         $return_attributes_string .= $char;
      }
      elsif ($state eq 'getting_char_after_equal_sign'){
         if ($char eq $SINGLE_QUOTE) {
            $state = 'looking_for_end_single_quote';
            $return_attributes_string .= $char;      
         }
         elsif ($char eq $DOUBLE_QUOTE) {
            $state = 'looking_for_end_double_quote';
            $return_attributes_string .= $char;
         }
         elsif ($char =~ m/\s/) {
            $return_attributes_string .= $DOUBLE_QUOTE . $DOUBLE_QUOTE . ' ';    # Add two double quotes and space.
            $state = 'looking_for_start_of_whitespace_to_quote_before';
         }
         else {                                    # Text directly after equal sign
            $state = 'looking_for_start_of_whitespace_while_autoquoting_value';
            $autoquoting_value = $char;
            $autoquote_quote_type = '';
         }
      }
      elsif ($state eq 'looking_for_end_single_quote') {
         $return_attributes_string .= $char;
         if ($char eq $SINGLE_QUOTE) {                          
            $state = 'looking_for_start_of_whitespace';
         }
      }
      elsif ($state eq 'looking_for_end_double_quote') {
         $return_attributes_string .= $char;    
         if ($char eq $DOUBLE_QUOTE) {                         
            $state = 'looking_for_start_of_whitespace';
         }
      }
      elsif ($state eq 'looking_for_end_quote') {
         if ($char =~ m/$starting_quote_type/ ) {
            $state = 'looking_for_start_of_whitespace';
         }
         $return_attributes_string .= $char;
      }
      elsif ($state eq 'looking_for_start_of_whitespace') {
         if ($char =~ m/\s/) {
            $state = 'looking_for_end_of_white_space';
         }
         else {
            &error_quoting($state,$char);
         }
         $return_attributes_string .= $char;
      }
      elsif ($state eq 'looking_for_start_of_whitespace_to_quote_before') {
         if ($char =~ m/\s/) {
            $state = 'looking_for_end_of_white_space';
            $return_attributes_string .= $DOUBLE_QUOTE . $char;
            next CHAR;
         }
         else{
            $return_attributes_string .= $char;
            next CHAR;
         }
      }
      elsif ($state eq 'looking_for_end_of_white_space') {
         if ($char =~ m/\S/) {
            $state = 'looking_for_equal_sign';
         }
         $return_attributes_string .= $char;
         next CHAR;
      }
      elsif ($state eq 'looking_for_start_of_whitespace_while_autoquoting_value') {
         if ($char =~ m/\s/) {
            if ( !$autoquote_quote_type ) {
               $autoquote_quote_type = $DOUBLE_QUOTE;    # Default to double quote.
            }
            $return_attributes_string .= $autoquote_quote_type 
                                         . $autoquoting_value 
                                         . $autoquote_quote_type
                                         . $char;
            $state = 'looking_for_equal_sign';
         }
         else{                              # Non-whitespace character
            $autoquoting_value .= $char;
            if ($char eq $DOUBLE_QUOTE) {                   
               if (!$autoquote_quote_type) {
                  $autoquote_quote_type = $SINGLE_QUOTE;    
               }
               elsif ($autoquote_quote_type eq $DOUBLE_QUOTE){
                  &error_quoting($state,$char,'Trying to quote a value with both single and double quote');
               }
            }
            elsif ($char eq $SINGLE_QUOTE) {
               if (!$autoquote_quote_type) {
                  $autoquote_quote_type = $DOUBLE_QUOTE;
               }
            }
         }
      }
      else {
         # Error, should never get here!
         &error_quoting($state, $char, "Undefined State at '$processed_string'");
      }


   }        # end of CHAR scope

   # At end of string. Clean up now. 
   if ($state eq 'looking_for_start_of_whitespace_to_quote_before') {
      $return_attributes_string .= '"';
   }
   elsif ($state eq 'getting_char_after_equal_sign') {
      $return_attributes_string .= '""';
   }
   elsif ($state eq 'looking_for_end_double_quote') {
      &error_quoting($state, $char, "Missing double quote at end of parameter string \n      '$processed_string'\n   Fixing by adding double quote automatically to end.");
      $return_attributes_string .= $DOUBLE_QUOTE;        #Force addition of missing end quote
   }
   elsif ($state eq 'looking_for_end_single_quote') {
      &error_quoting($state, $char, "Missing single quote at end of parameter string '$processed_string'");
      $return_attributes_string .= $SINGLE_QUOTE;        #Force addition of missing end quote
   }
   elsif ($state eq 'looking_for_start_of_whitespace_while_autoquoting_value') {
      # Add before and after quotes.
      if ( !$autoquote_quote_type ) {
         $autoquote_quote_type = $DOUBLE_QUOTE;    # Default to double quote.
      }
      $return_attributes_string .= $autoquote_quote_type 
                                   . $autoquoting_value 
                                   . $autoquote_quote_type;
   }

   return $return_attributes_string;
}


sub error_quoting {
   my $state = shift;
   my $char = shift;
   my $msg = shift;

   my $total_msg =  "HTML::TagTree.pm Error in quoting attribute params -- state:'$state' char:'$char'\n";
   $total_msg .= "$msg\n";
   Carp::cluck($total_msg);
   if ($msg) {
      print STDERR "   $msg\n";
   }
   print STDERR "HTML::TagTree.pm Error in quoting attribute params -- state:'$state' char:'$char'\n";
   if ($msg) {
      print STDERR "   $msg\n";
   }
}

sub Error {
   my $self = shift;
   my $msg = shift;

   my $program_name = $0;
   if (exists $self->{log_routine}) {
      my $log_routine = $self->{log_routine};
      no strict;
      &log_routine($msg);
   }
   else {
      if ($msg =! m/\n$/) {
         $msg .= "\n";
      }
      print STDERR $msg;
   }
}


sub AUTOLOAD {
   my $self = shift;    # point to the new parent

   # This a autoload method catches any called method 
   # that is not defined.
   my $content = shift;
   my $tag_attributes = shift;

   my $tag = $AUTOLOAD;
   if ($tag =~ m/HTML::TagTree::(.+)/) {
      $tag = $1;
      if ($tag eq 'add_content') {
         $self->_process_content($content);
         # *{$AUTOLOAD} = sub { $_[0]->_process_content($_[1]) };   
         return;
      }
      elsif (! &is_valid_html_tag($tag)) {
         &Error("Not valid tag '$tag' attempted to be used!");
         die "Not valid tag '$tag' attempted to be used!";
      }
      my %child = ();
      my $child = \%child;
      bless $child, 'HTML::TagTree';
      $child->{tag} = $tag;
      if ( (defined $tag_attributes) && ($tag_attributes ne '') ) {
         if ( (ref $tag_attributes) eq 'HASH') {
            # passing in some parameters
            # The parameters are for use my this module.
            # These parameter should not be confused with html tag attributes
            $child->{parameters} = $content;
         }
         else {
            $child->{attributes} = $tag_attributes;
         }
      }
      if ( (defined $content) && ($content ne '') ) {
         if ( (ref $content) eq 'HTML::TagTree') {
            my $grand_child_obj = $content;
            push @{$child->{children_objs}}, $grand_child_obj;
            # need to fix child_obj tree indent levels;
            
            $grand_child_obj->{parent} = $child;
         }
         else {
            if (lc $tag eq 'select') {
               $child->process_select_tag($content);
            }
            else{
               push @{$child->{content}}, $content;
            }
         }
      }
      $child{parent} = $self;
      push @{$self->{children_objs}}, $child;
      return $child;
   }

   return;
}


sub get_array_of_hash_keys {
   my $hash_ref = shift;

   my @array;
   my %hash;
   if ( (ref $hash_ref) eq 'HASH') {
      %hash = %$hash_ref;
   }
   foreach my $key (keys %hash) {
      push @array, $key;
   }
   if (wantarray) {
      return @array;
   }
   else {
      return \@array;
   }
}


sub add_child {
   my $self = shift;
   my $content = shift;
   my $tag_attributes = shift;
	
   if ( (ref $content) eq 'HTML::TagTree') {
      my $child_obj = $content;
      push @{$self->{children_objs}}, $child_obj;
      # need to fix child_obj tree indent levels;
      
      $child_obj->{parent} = $self;
   }
}


sub DESTROY {
   my $self = shift;
   
   # Need to following to prevent silly error messages like:
   #    DESTROY created new reference to dead object 'HTML::TagTree' during global destruction.
   #
   if (exists $self->{parent}) {
      delete $self->{parent};      # remove ref to parent object
   }
   if (exists $self->{children_objs}) {
      foreach my $child (@{$self->{children_objs}}) {
         $child->DESTROY();
      }
      delete $self->{children_objs};     # remove refs to children objects
   }
}

sub is_valid_html_tag {
   my $tag = shift;
   
   my $lc_tag = lc $tag;
   if (exists $valid_tags{$lc_tag}) {
      return 1;
   }
   print STDERR "Invalid tag '$tag' supplied\n";
   return 0;
}


sub get_array_ref_for_table{
   my $self = shift;
   # Turns an HTML table into a 2 dimensional array of data from the table

   if ( (lc $self->{tag}) ne 'table') {
      return;
   }
   my @children = @{$self->{children_objs}};
   my @rows=();
   my @row_objs;
   # First collect the rows
   foreach my $child_obj (@children) {
      if ( (lc $child_obj->{tag}) eq 'tr') {
         push @row_objs,$child_obj;
      }
      elsif ( ($child_obj->{tag} eq 'thead')
              || ($child_obj->{tag} eq 'tbody')
            ) {
         my @headbody_children = @{$child_obj->{children_objs}};
         foreach my $child_obj (@headbody_children) {
            if ( (lc $child_obj->{tag}) eq 'tr') {
               push @row_objs,$child_obj;
            }
         }
      }
   }
   # Process the rows
   foreach my $child_obj (@row_objs) {
      next if (! exists $child_obj->{children_objs});
      my @possible_tds = @{$child_obj->{children_objs}};
      my @row=();
      foreach my $possible_td (@possible_tds) {
         next if ( ((lc $possible_td->{tag}) ne 'td')
                   && ((lc $possible_td->{tag}) ne 'th')
                 );
         if (! exists $possible_td->{content}) {
            push @row, undef;
            next;
         }
         my $value = $possible_td->{content};
         if ( (ref $value) ne 'ARRAY') {
            push @row, undef;
            next;
         }
         push @row, $value->[0];
         my $attributes = $possible_td->{attributes};
         if ($attributes =~ m/colspan=['"]?(\d+)/i) {
            my $colspan = $1;
            for (my $i=1; $i<$colspan; $i++) {
               # fill in blanks to match colspan
               push @row, undef;
            }
         }
      }
      push @rows, \@row;
   }
   
   return \@rows;
}

sub header{

   # This subroutine returns the standard HTML header

   my $header = '<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
   return $header;
}
          

sub process_select_tag{
   my $self = shift;
   my $hash = shift;

   return undef if ((ref $hash) ne 'HASH');
   if (exists $hash->{tag_attributes}) {
      $self->process_tag($hash->{tag_attributes});
   }
   if (exists $hash->{options}) {
      if ( (ref $hash->{options}) eq 'HASH') {
         my $sort_sub = sub {lc $a cmp lc $b};    # Default sort is alphabetical ingoring case
         if (exists $hash->{sort_sub}) {
            $sort_sub = $hash->{sort_sub};
         }
         if (exists $hash->{sort_numeric}) {
            $sort_sub = sub {$a <=> $b};
         }
         if (exists $hash->{sort_reverse_numeric}) {
            $sort_sub = sub {$b <=> $a};
         }
         if (exists $hash->{sort_numeric_by_value}) {
            $sort_sub = sub {$hash->{options}{$a} <=> $hash->{options}{$b}};
         }
         if (exists $hash->{sort_string_by_value}) {
            $sort_sub = sub {$hash->{options}{$a} cmp $hash->{options}{$b}};
         }
         foreach my $option (sort $sort_sub keys %{$hash->{options}}) {
            my $content = "<option ";
            if ($hash->{options}{$option} eq $hash->{selected}) {    # is the option value selected?
               $content .= 'selected="selected" ';
            }
            my $value = $option;
            if (not ref ($hash->{options}{$option})) {
               $value = $hash->{options}{$option};
            }
            $content .= "value=\"$value\">$option</option>";
            push @{$self->{content}}, $content;
         }
      }
      elsif ( (ref $hash->{options}) eq 'ARRAY') {
         foreach my $option ( @{$hash->{options}}) {
            my $content = "<option";
            if ($option eq $hash->{selected}) {
               $content .= ' selected="selected" ';
            }
            $content .= ">$option</option>";
            push @{$self->{content}}, $content;
         }
      }
   }
}


sub create_radio_table{
   my $self = shift;
   my $name = shift;
   my $values_ref = shift;
   my $labels_ref = shift;
   my $checked = shift;
   my $tag_attributes = shift;

   my %checked;
   if ( (ref $checked) eq 'HASH') {
      %checked = %$checked;
   }
   elsif ( (ref $checked) eq 'ARRAY') {
      foreach my $check (@$checked) {
         $checked{$check} = 1;
      }
   }
   elsif ( (ref $checked) eq 'SCALAR') {
      $checked{$$checked} = 1;
   }
   else {
      $checked{$checked} = 1;
   }
   my @values;
   if ( (ref $values_ref) eq 'ARRAY') {
      @values = @{$values_ref};
   }
   elsif ( (ref $values_ref) eq 'HASH') {
      @values = @{&get_array_of_hash_keys($values_ref)};
   }

   my $table;
   if ($self) {
      $table = $self->table();  
   }
   else {
      $table = HTML::TagTree->new('table');
   }
   foreach my $value (@values) {
      my $tr = $table->tr();
      my $td = $tr->td();
      my $label = $value;
      if (exists $labels_ref->{$value}) {
         $label = $labels_ref->{$value};
      }
      my $checked_string = '';
      if (exists $checked{$value}) {
         $checked_string='checked=checked';
      }
      $td->input($label,"type=radio name=$name id=$name value=$value $checked_string $tag_attributes");
   }
   
   return $table;

}

sub create_checkbox_table{
   my $self = shift;
   my $name = shift;
   my $inputs = shift;
   my $labels = shift;
   my $checked = shift;
   my $tag_attributes = shift;
   
   my %checked;
   if ( (ref $checked) eq 'HASH') {
      %checked = %$checked;
   }
   elsif ( (ref $checked) eq 'ARRAY') {
      foreach my $check (@$checked) {
         $checked{$check} = 1;
      }
   }
   elsif ( (ref $checked) eq 'SCALAR') {
      $checked{$checked} = 1;
   }
   my @inputs;   
   if ( (ref $inputs) eq 'ARRAY') {
      @inputs = @$inputs;
   }
   elsif ( (ref $inputs) eq 'HASH') {
      foreach my $input (sort {lc $a cmp lc $b} keys %$inputs) {
         push @inputs, $input;
      }
   }
   my $table;
   if ($self) {
      $table = $self->table();  
   }
   else {
      $table = HTML->new('table');
   }
   foreach my $input (@inputs) {
      my $tr = $table->tr();
      my $td = $tr->td();
      my $label = $input;
      if (exists $labels->{$input}) {
         $label = $labels->{$input};
      }
      my $checked_string = '';
      if (exists $checked{$input}) {
         $checked_string='checked=checked';
      }
      # $td->input($label,"type=checkbox name=$name id=$name value=$input $checked_string $tag_attributes");
      $td->input($label,"type=checkbox name=$name  value=$input $checked_string $tag_attributes");
   }
   
   return $table;
}

sub make_attribute_key_values{
   my $self = shift;

   my $attr_string = $self->{attributes};


}


sub add_valid_tags{
   my $self = shift;
   my $tags = shift;

   if ((ref $tags) eq 'ARRAY') {
      foreach my $tag (@$tags) {
         $valid_tags{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'HASH') {
      foreach my $tag (keys %$tags) {
         $valid_tags{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'SCALAR') {
      $valid_tags{$$tags} = 1;
   }
   elsif ((ref $tags) eq '') {
      $valid_tags{$tags} = 1;
   }
}
sub set_tags_no_autowhitespace{
   my $self = shift;
   my $tags = shift;
   
   # Define which tags should not include auto-whitespace when printed.
   %tags_no_autowhitespace = ();
   if ((ref $tags) eq 'ARRAY') {
      foreach my $tag (@$tags) {
         $tags_no_autowhitespace{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'HASH') {
      foreach my $tag (keys %$tags) {
         $tags_no_autowhitespace{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'SCALAR') {
      $tags_no_autowhitespace{$$tags} = 1;
   }
   elsif ((ref $tags) eq '') {
      $tags_no_autowhitespace{$tags} = 1;
   }
}

sub set_valid_empty_tags_for_shortening{
   my $self = shift;
   my $tags = shift;
   
   %valid_empty_tags_for_shortening = ();
   if ((ref $tags) eq 'ARRAY') {
      foreach my $tag (@$tags) {
         $valid_empty_tags_for_shortening{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'HASH') {
      foreach my $tag (keys %$tags) {
         $valid_empty_tags_for_shortening{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'SCALAR') {
      $valid_empty_tags_for_shortening{$$tags} = 1;
   }
   elsif ((ref $tags) eq '') {
      $valid_empty_tags_for_shortening{$tags} = 1;
   }
}

sub set_valid_tags{
   my $self = shift;
   my $tags = shift;
   
   %valid_tags = ();
   if ((ref $tags) eq 'ARRAY') {
      foreach my $tag (@$tags) {
         $valid_tags{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'HASH') {
      foreach my $tag (keys %$tags) {
         $valid_tags{$tag} = 1;
      }
   }
   elsif ((ref $tags) eq 'SCALAR') {
      $valid_tags{$$tags} = 1;
   }
   elsif ((ref $tags) eq '') {
      $valid_tags{$tags} = 1;
   }
}


%preprocess_tag = (
   'html' => sub {
      my $self = shift;
      my $tag = shift;

      my $tag_parameters = $self->{parameters};
      if ($tag_parameters !~ m/lang=/) {
         $self->{parameters} .= ' lang=en-US';
      }
   }
);

sub get_default_head_meta_attributes{
   my $attributes = 'http-equiv="content-type" content="text/html; charset=UTF-8"';

   return $attributes;
}

sub get_http_header {
   my $return = "Content-type: text/html\n";
   $return .= "Status: 200  OK\n\n";
}


sub get_doctype {
   my $return = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"';
   $return .= ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
   $return .= "\n\n";

   return $return;
}

sub version {
   return $VERSION;
}

return 1;


__END__

=head1 NAME

   HTML::TagTree - An HTML generator via a tree of 'tag' objects.


=head1 SYNOPSIS
  
   use HTML::TagTree;

   my $html = HTML::TagTree->new('html');   # Define the top of the tree of objects.
   my $head = $html->head();                # Put a 'head' branch on the tree.
   my $body = $html->body();                # Put a 'body' branch on the tree
   $head->title("This is the Title of Gary's Page, the opening title...");
   $head->meta('', 'name=author CONTENT="Dan DeBrito"');
   $body->div->h1('Hello Dolly');           # Example of method chaining to create
                                            # a long branch.
   my $table = $body->table('', 'width=100% border=1');
   my $row1 = $table->tr();
   $row1->td('cell a');
   $row1->td('cell b');
   $table->tr->td('This is a new row with new cell');  
   $table->tr->td('This is a another new row with new data');

   # Print to STDOUT the actual HTML representation of the tree
   $html->print_html();
   
   # Put HTML into a scalar variable
   my $html_source = $html->get_html_text();

   # Force destruction of object tree
   $html->release();

=head1 DESCRIPTION

      HTLM::TagTrees allows easy building of a tree objects where
      each object represents: 1) a tag 2) its value and 3) any
      tag attributes. Valid HTML is build of the tree via a method call.


=head1 FEATURES

   Smart quoting of tag parameters:
   Doing something like this:
      $body->div('','id=nav onclick="alert(\"Hello World\"');
   the HTML module will render HTML that looks like:
      <div id="nav" onclick='alert("Hello World")' \>

   Reduce whitespace in your HTML rendering by turning
   on the no_whitespace_flag.
   my $no_whitespace_html_text = $html->get_html_text('',1);
   
   # Or..
   my $indent_level = 0;
   my $no_whitespace_flag = 1;
   print $html_obj->get_html_text($indent_level, $no_whitespace_flag); 

=head1 INITIALIZATION
      
      HTML::TagTree->new(tag_name,[value],[attributes])
         Returns a TagTree object

=head1 METHODS

      Every HTML tag type is an object method.
      $obj->tag_name(content,attributes);
         Returns:
            object for valid creation
            undef if tag_name is not a valid name;
         Arguments:
            content:
               Untagged data that goes in between open and close tag. eg
                  <b>content</b>
               Content my be a Perl scalar, a ref to a scalar, 
               or ref to a subroutine. Dereferencing occurs at the
               time of HTML rendering (via print_html()
               or get_html_text() methods).
            attributes:
               Attributes of this HTML tag.
               Attributes argument may be a Perl scalar, a ref to a scalar,
               or a ref to a subroutine. Dereferencing occurs at the
               time of HTML rendering.
               Example of attributes:
                  'id=first_name name=fn class=str_cl'
      get_html_text(indent_level, no_whitespace_flag)
         Returns valid HTML representation of tag tree starting at the object.
         Arguments:
            indent_level:
               Starting amount of indentation. Typically leave undef or 0.
            no_whitespace_flag:
               Set to '1' to prevent insertion of linefeeds and whitespace padding
               for legibility.
      print_html()
         Prints the valid HTML to STDOUT
      release()
         Destroys all children objects so no objects reference
         this object (and it can be destroyed when it goes out of scope).
      set_valid_tags( tag_names )
         Clears and sets what the valid tag names are for which
         objects can be created.

=head1 FUNCTIONS

      HTML::TagTree::get_http_header();
         Returns the generic HTTP header:
            "Content-type: text/html\nStatus: 200  OK\n\n";


=head1 ABSTRACT
      
      The philosophy of HTML::TagTree is to let you create
      one region of code with lots of business logic 
      for rendering many possible resulting HTML files/output.
      This differs from the approach of using business logic code
      to decide which HTML template (of many) to render.
      So rather than maintaining many HTML templates, you
      maintain a Perl file that does all possible customizations
      of HTML generation.

      This module strives to minimize typing. Object treeing is
      just a simple method call, eg:
         $body->h1->b->i('This is a bold, italic heading');

      HTML::TagTree removes the worries of making simple HTML syntax
      errors such as no matching closing tag for an open tag.

=head1 VERSION

HTML::TagTree version 1.03.

=head1 PREREQUISITES

No prerequisites.

=head1 AUTHOR

Dan DeBrito (<ddebrito@gmail.com>)


=head1 COPYRIGHT

Copyright (c) 2007 - 2011 by Dan DeBrito. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt", "GNU_GPL.txt" and
"GNU_LGPL.txt" in this distribution for details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.


