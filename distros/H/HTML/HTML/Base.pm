#!/usr/local/bin/perl

require 5.001;

my $Revision = '$Revision: 0.6 $';
my $Version = $Revision; $Version =~ s/.*(\d+\.\d+).*/$1/;

use strict qw(vars refs subs);

# HTML Module for Perl 5

# Author: Greg Anderson 

# Contact info:

# email: greg@acoates.com

# snail: 2504 Fairglen Dr, San Jose, CA  95125
# phone: (408) 267-3306

# Extensive and excellent assistance from:

#	Joel Rosi-Schwartz
#	Etish Associates
#	12 Waverley Way, Finchampstead, Wokingham, Berkshire RG40 4YD, UK
#	joel@etish.co.uk
#	+44 1734 730260 (phone)
#	+44 1734 730272 (fax)

#	Randy Terbush (randy@zyzzyva.com)

# This code is Copyright (C) Greg Anderson, of Anderson-Coates 1995. 
# All rights reserved.  This program is free software; you can redistribute it 
# and/or modify it under the same terms as Perl itself.

# Release:

# This release is pre-Alpha 1, presented for the evaluation and
# discussion of the Perl community.  

# Plug:

# Anderson-Coates is a consulting firm specializing in professional Internet
# software and services.  For more info call (408) 267-3306 or visit our
# Web site at http://www.acoates.com/

# Documentation:

# There is a POD format file available describing how to use this module, but 
# you could probably figure it out by reading the comments.

package HTML::Base;
{
  use Carp;

  # HTML global variables

  # Debug is a flag (0 or 1).  If 1, HTML spits out a lot of debugging rubbish 
  # to STDERR.

  my $Debug = +0;              

  # CurrentObject is a reference to the object which is to be the parent 
  # of the next object created.  The reference is updated whenever a new object
  # is created, or one is ended.

  my $CurrentObject;           

  # TopObject is the parent of all other objects in the object tree.
  # It is initialized to a new "blank" HTML object, just to have a common
  # ancester for everyone.

  my $TopObject = new HTML::Base::HTMLObject;

  # $FileHandle is a file handle "counter" that the Page object can use to
  # generate unique output file handles (simply by incrementing it).

  my $FileHandle = "FH000000";

  # %ObjectCache is a hash of frequently used HTMLObjects.
  # HTMLObjects can be placed into the cache with
  #
  #		HTML::Base::cache_object('object_name', $objref)
  #
  # and can be used in the current Page by calling:
  #
  #		$objref = HTML::Base::use_object('name');
  
  my(%ObjectCache) = ();

##############################################################################

  # HTML public global functions

  # HTML::Base::get_current() returns a reference to the current object;

  sub HTML::Base::get_current { $CurrentObject; }

  # HTML::Base::version is a convenience routine for displaying the version.

  sub HTML::Base::version { return $Version; }

  # HTML::Base::copy_object takes a reference to an existing HTML object
  # and makes a copy of it, including all of its attributes and children.
  # The copy will have no parent, and will not be linked to the CurrentObject.
  # A reference to the copy is returned.

  sub HTML::Base::copy_object {
    HTML::Base::_show_sub_entry (@_);
    my $self = shift;
    my $copy;
    if ($self) {

      if ($Debug) { 
	print STDERR "\nHTML::Base::copy_object copying $self\n";
	$self->showme;
      }

      # Get the type of the object we want to copy
      my $type = HTML::Base::object_type ($self);
      $type = "HTML::Base::" . $type;

      # Build the "new" subroutine name for this type of object, and get a
      # reference to the correct sub.

      my $newsubref = \&{$type . '::new'};

      # Call the "new" sub, and get a reference to the new object.  Pass
      # the attribute "NoParent" so that this new object will not be linked
      # to the CurrentObject

      $copy = &{$newsubref} ($type, 'Copy', '1', 'NoParent', '1');

      # Copy the HTML tag from the source to the copy.  This is just in case
      # the tag was dependant upon any parameters passed to the original 
      # constructor (such as in the case of the Header object).

      $copy->{'tag'} = $self->{'tag'};

      # Copy the source object's Attributes hash to the new object
      HTML::Base::_copy_attributes ($self, $copy);

      # Create an array for the copy's potential children objects.

      $copy->{'Children'} = [];

      # Iterate through all of the children of the source object, and copy
      # each.

      my $child;
      my $childcopy;
      foreach $child (@{$self->{'Children'}}) {

	# Make of copy of this child and get a reference to the copy
	$childcopy = HTML::Base::copy_object ($child);

	# Link the new child copy to the new parent copy
	undef $childcopy->{Attributes}->{NoParent};
	HTML::Base::link_to_parent ($childcopy, $copy);

      }

      # Return reference to new copy of object
      $copy;
    }
  }

  # HTML::Base::cache_object pushes a copy of an HTMLObject onto %ObjectCache

  sub HTML::Base::cache_object {
    HTML::Base::_show_sub_entry (@_);
    my($name, $objref) = @_;
    if ($name, $objref) {
      # Make a copy of the given object
      $ObjectCache{$name} = HTML::Base::copy_object($objref);
    }
  }

  # HTML::Base::use_object copies an HTMLObject from %ObjectCache into the
  # current object tree.

  sub HTML::Base::use_object {
    HTML::Base::_show_sub_entry (@_);
    my $name = shift;
    my $self = HTML::Base::copy_object($ObjectCache{$name});
    if ($self) {
      if ($CurrentObject) {
        $self->{'Parent'} = $CurrentObject;
        push @{$CurrentObject->{'Children'}} , $self;
      }
      $CurrentObject = $self;
    }
  }

  # HTML::Base::html_debug is a convenience routine for setting 
  #   $HTML::Base::Debug to 1.

  sub HTML::Base::html_debug { $Debug = +1; }

  # HTML::Base::end_object "closes" an object simply by pointing the 
  # $CurrentObject to the parent of the given object (or the parent of 
  # $CurrentObject if no object was specified).

  sub HTML::Base::end_object {
    HTML::Base::_show_sub_entry (@_);
    my $self = shift; 
    if ($self) {
      if ($Debug) {
        print (STDERR "\nHTML::Base::endobject : self = $self,\n  My parent = $self->{Parent}\n");
        print (STDERR "  HTML::Base::CurrentObject = $CurrentObject,\n");
      }
      if ($self->{Parent}) { $CurrentObject = $self->{Parent} }
    }
    else {
      $CurrentObject = $CurrentObject->{'Parent'};
    }
    if ($Debug) {print (STDERR "  New HTML::Base::CurrentObject = $CurrentObject,\n");}
  } # end sub endobject

  # HTML::Base::end_all_objects "closes" all open objects, simply by changing 
  # the $CurrentObject reference to that of the upper-most object.  This is
  # a convenient way to get out of a deeply nested set of HTML commands
  # quickly and start fresh.

  sub HTML::Base::end_all_objects {
    HTML::Base::_show_sub_entry (@_);
    $CurrentObject = $TopObject;
  } # end sub end_all_objects

  # realize is the method which makes an HTML object tree output itself.

  sub HTML::Base::realize {
    HTML::Base::execute();
  }

  # execute is the method which makes an HTML object tree output itself.
  # HTML::Base::execute is simply a convenient wrapper around the 
  # HTMLObject class's execute method.  In this way, a client application may 
  # use the HTML::Base::execute function without any arguments to mean 
  # "execute the entire object tree from the top down".

  sub HTML::Base::execute {
    HTML::Base::_show_sub_entry (@_);
    my $top = HTML::Base::HTMLObject::find_top_object ($CurrentObject);
    if ($top) {$top->execute}
  }

  # HTML::Base::link_to_parent takes a reference to two HTMLObjects (see
  # package HTMLObject below for a description of the object) and makes the
  # first the child of the second.  Returns a reference to the first (for
  # lack of any better return).

  sub HTML::Base::link_to_parent {
    HTML::Base::_show_sub_entry (@_);
    my ($self, $parent) = @_;
    if ($self && $parent) {
      if ($Debug) {
	print STDERR "\nHTML::Base::link_to_parent linking\n  $self to\n  $parent\n";
      }
      $self->{'Parent'} = $parent;
      push @{$parent->{'Children'}} , $self;
    }
    $self;
  }

  # HTML::Base::object_type returns the name of the HTML object whose reference
  # is passed in.

  sub HTML::Base::object_type {
      my $self = shift;
      my @list;
      (@list) = split /=/, $self;
      (@list) = split /::/, $list[0];
      $list[2];
  }

  # Given an HTML object reference and a type of an HTML object, 
  # HTML::Base::contained_by returns 1 if the given object is contained
  # (at any higher level) by another object of the given type, or returns
  # 0 otherwise.

  sub HTML::Base::contained_by {
    my ($self, $type) = @_;
    if ($self && $type) {
      while ($self) {
        if (HTML::Base::object_type($self) eq $type) { return (1) }
        $self = $self->{Parent};
      }
    }
    return (0);
  }

##############################################################################

  # HTML::Base private functions
  	
  # HTML::Base::_set_if_not_set() simply checks if the caller requested that
  # an Attribute be set a desired value, else it sets it to the
  # supplied default value.
  # NB - It would be useful if we had a list of acceptable values
  # for those Attributes that limit the values and did error checking
  # against them.
 
  sub HTML::Base::_set_if_not_set {
    my($self, $attribute, $default) = @_;
    unless (defined $self->{Attributes}->{$attribute}) {
      $self->{Attributes}->{$attribute} = $default;
    }
  }

  # HTML::Base::_copy_attributes copies the Attributes hash from the source
  # object into the destination object.

  sub HTML::Base::_copy_attributes {
    HTML::Base::_show_sub_entry (@_);
    my($source, $destination) = @_;
    my ($key, $value);
    if ($source->{Attributes}) {
      while (($key,$value) = each %{$source->{Attributes}}) {
        $destination->{Attributes}->{$key} = $value;
      }
    }
  }

  # HTML::Base::_output_html is a simple output filter which translates all of 
  # the HTML
  # reserved characters (like "<" and ">") to their HTML escape equivalents,
  # then outputs the resulting string.

  sub HTML::Base::_output_html {
    HTML::Base::_show_sub_entry (@_);
    my $string = shift;
    $string =~ s/\&/\&amp;/g;
    $string =~ s/\</\&lt;/g;
    $string =~ s/\>/\&gt;/g;
    $string =~ s/\"/\&quot;/g;
    print $string;
  }

  # HTML::Base::_conditional_newline outputs a newline character if the 
  # object passed to it is not contained within an HTML object which doesn't
  # want newlines printed.  This is indicated by the object's having a
  # NoNewLine hash key specified.

  sub HTML::Base::_conditional_newline {
    HTML::Base::_show_sub_entry (@_);
    my $self = shift;
    while ($self) {
      if ($self->{NoNewLine}) { return (0) }
      $self = $self->{Parent};
    }
    print "\n";
  }

  # HTML::Base::_comment_divider simply draws a nice divider to separate
  # comments in Debug mode

  sub HTML::Base::_comment_divider {
    if ($Debug) {print STDERR ("#" x 79 . "\n");}
  }

  # HTML::Base::_show_sub_entry prints debug information about the entry
  # of the subroutine who called this one.  To use, make this the first
  # line of a subroutine:
  #	HTML::Base::_show_sub_entry (@_);

  sub HTML::Base::_show_sub_entry {
    if ($Debug) {
      my @calldata = caller(1);
      print STDERR "\n$calldata[3]: \@_ = \n  @_\n";
    }
  }

  # HTML::Base::_show_new_object prints debug information about the object
  # we just created, and ends the object's comment section with a divider.
  # To use, make this call after the object has been blessed:
  #	HTML::Base::_show_new_object ($self);

  sub HTML::Base::_show_new_object {
    if ($Debug) {
      my $self = shift;
      if ($self) { $self->showme; }
      HTML::Base::_comment_divider();
    }
  }

##############################################################################

  # HTML::Base::HTMLObject definition

  # All objects that can be output to an HTML stream are derived classes of
  # HTML::Base::HTMLObject.  Each HTMLObject contains:

         # An annonymous hash (itself)

         # Another annonymous hash,  known as {Attributes}.  This is a private
         # namespace for HTMLObject-specific variables.  For example, the
         # HTML Image tag requires a "SRC" attribute.  Other HTML objects
         # (such as <BR>) require no attributes.  This namespace may also be
         # used to store non-HTML attributes about the object, so long as the
         # chosen attribute names (keys) do not interfere with the HTML
         # standard ones.  For ease of reading, the HTML attributes are
         # specified in all capitals (ie, "HREF").

         # (Optionally) Yet another annonymous hash, known as 
         # {Displayed_Attributes}.  This is a list of Attribute key names which
         # are to be used in building the HTML tags.  For example, the
         # Preformatted object has one attribute in its Displayed_Attributes
         # list, "WIDTH".  If a Preformatted object is created with an
         # {Attributes} hash = {'WIDTH','80','NAME','Bob'}, only the WIDTH
         # attribute will actually be output.  The result would look like this:
         # <PRE WIDTH="80"> ... </PRE>

         # A reference to the object's parent, if known. {Parent}

         # A list of references to all of the object's children, if any. 
         # {Children}

         # A method for creating output to an HTML stream, called "display".

  package HTML::Base::HTMLObject;
  {

    # HTMLObject constructor.  This routine takes a list of arguments, the
    # first of which is assumed to be the object type (HTMLObject, of course!).
    # Anything after the type is assumed to be a list of key/value pairs.
    # These are set into the Attributes hash.  Note that no checking is done
    # to see if these are "legal" attributes.  You can, therefore, set any
    # attributes you want simply by passing them as the final parameters to
    # the constructor of any HTML object.

    # One special attribute is possible for all HTMLObjects: NoParent.  If
    # set to something (anything!), then the object created will not be linked
    # to the CurrentObject.  This allows the creation of "prototype" HTML
    # objects which can be cached until ready to use in the "real" object tree.

    sub new {                  
      HTML::Base::_show_sub_entry (@_);
      my $self = {};        
      my $type = shift;        
      $self->{Attributes} = {};        
      my ($key, $value);
      while (@_) {
        $key = shift;
        $value = shift;
        if ($Debug) { print (STDERR "HTML::Base::HTMLObject::new setting attribute $key = $value\n")}
        $self->{Attributes}->{$key} = $value;        
      }
      bless $self;
      if (! $self->{Attributes}->{'NoParent'}) {
        if ($Debug) {print STDERR "HTML::Base::HTMLObject::new: linking\n  $self to CurrentObject as child.\n"}
	link_to_current $self;
      }
      $self;
    } # end sub new

    # link_to_current is called by the HTMLObject constructor.  It points the
    # {Parent} ref of the new HTMLObject to the CurrentObject, creates an
    # empty {Children} array for the new object, then makes the new object
    # the CurrentObject.

    sub link_to_current {
      HTML::Base::_show_sub_entry (@_);
      my $self = shift; 
      if ($Debug) { 
        print (STDERR "\nHTML::Base::HTMLObject::link_to_current:\n  self = $self,\n  CurrentObject = $CurrentObject\n");
      }
      if ($CurrentObject) {
        $self->{'Children'} = [];
        HTML::Base::link_to_parent ($self, $CurrentObject);
      }
      $CurrentObject = $self;
    }

    # make_current takes a reference to any HTML object and then makes that
    # object the $CurrentObject.  This is useful for remembering a point in an
    # HTML hierarchy that you wish to return to quickly.  Simply stash a
    # reference to the desired object in a scalar variable.  Then, when you
    # want that object to be current again, call $objref->make-current.

    sub make_current {
      HTML::Base::_show_sub_entry (@_);
      my $self = shift;
      if ($self) { $CurrentObject = $self; }
    } # end sub end_all_objects

    # end_object is identical to HTML::Base::end_object.  We just include 
    # it here so that an object can end itself via the $objref->end_object 
    # syntax.

    sub end_object {
      HTML::Base::_show_sub_entry (@_);
      HTML::Base::end_object (@_);
    }

    # realize is just another name for execute.

    sub realize {
      execute(@_);
    }

    # execute is the method to call when you want a tree of HTML objects to
    # display themselves.  The object passed to execute is "executed", along
    # with all of its children (but not its ancesters).  Display is done
    # in two passes for each object.  First, the object's display method is
    # called with the parameter "open".  This tells the object to "open"
    # whatever HTML tag it uses.  When, later, the object's display method is
    # called again with the "close" parameter, it will output whatever is
    # needed to complete the HTML tag.  For example, the Bold object outputs
    # "<B>" on open, and "</B>" on close.

    # The algorithm for execute is simple: Display my self with "open", then
    # call execute recursively once for each of my children, then display 
    # myself with "close".

    sub execute {
      HTML::Base::_show_sub_entry (@_);
      my $self = shift; 
      my $child;
      if ($Debug) {print STDERR "\nHTML::Base::HTMLObject::execute: self = $self"}
      if (! $self) {$self = find_top_object ($CurrentObject)}
      if ($self) {
        $self->display("open");
        foreach $child (@{$self->{'Children'}}) {
          $child->execute;
        }
        $self->display("close");
      }
    }

    # Given a reference to an HTML Object, find_top_object returns a reference
    # to the object which is the given object's most distant relative (up-wise,
    # that is).

    sub find_top_object {
      HTML::Base::_show_sub_entry (@_);
      my $self = shift; 
      while ($self->{'Parent'}) { $self = $self->{'Parent'} }
      $self;
    }

    # object_type returns the single-word type of the HTML object passed.

    sub object_type {
      HTML::Base::object_type(shift);
    }

    # copy_object copies the given object and returns a reference to the copy

    sub copy_object {
      HTML::Base::copy_object(shift);
    }

    # link_to_parent makes the referenced HTML object a child of the
    # specified parent.

    sub link_to_parent {
      my ($self, $parent) = @_;
      if ($self && $parent) { HTML::Base::link_to_parent($self, $parent)}
    }

    # showme is a little debugging routine.  Calling $objref->showme causes
    # the object to print out some stats about itself to STDERR.

    sub showme {
      my $self = shift; 
      my $child;
      printf (STDERR "\nHTMLObject: I am %s\n",$self);
      if ($self->{Parent}) {printf (STDERR "  My parent is %s\n",$self->{Parent}) }
      else { print (STDERR "  I have no parent ;-( \n");}
      if ($self->{Children}) {
        printf (STDERR "  I have %d children.\n", $#{$self->{Children}}+1);
        foreach $child (@{$self->{Children}}) {
          print (STDERR "   child: $child\n");
        }
      }
      if (%{$self->{Attributes}}) {
        print (STDERR "  These are my attributes:\n");
        my ($key, $value);
        while (($key,$value) = each (%{$self->{Attributes}})) { 
          print (STDERR "    $key = $value\n") 
        }
      }
    } # end sub showme

    # Given an HTML object reference and a type of an HTML object, 
    # contained_by returns 1 if the given object is contained
    # (at any higher level) by another object of the given type, or returns
    # 0 otherwise.

    sub contained_by {
      my ($self, $type) = @_;
      if ($self && $type) {
	HTML::Base::contained_by ($self, $type);
      }
    }

    # This display method is a dummy or "virtual" method for the HTMLObject
    # superclass.  Only classes derived from HTMLObject really know how to
    # display themselves.

    sub display { # dummy virtual method for superclass
    }

    # Given an HTMLObject ref and a list of attribute names,
    # display_attributes will check to see if the given object contains the
    # named attributes, and if it does it will output them in the form:

    #          ATTRIBUTE=VALUE

    # Note that if an attribute is defined in {Attributes}, but has no value,
    # we assume that it should appear, but with no value, like that:

    #          ATTRIBUTE

    # This supports the ISMAP attribute of the IMG tag, which can be specified
    # in the IMG tag, but which carries no value!

# A special Attribute, 'Eval' is recognised.  In this case it is the
# users responsibity to make certain that the output strings are legal
# and complete HTML syntax since no sanitizing is is performed.
#
#   'Eval' => 1
#  ------------
#	If set then the text is first processed with a
#	perl eval().  This permits the enclusion of objects on the
#	tree that are evaluated at the time of actual usage.  This
#	enables the embedding of Perl variables whose values are either
#	not known at the time of construction or which change dymanically.
#	It is especially useful for constructs such as
#
#		  new Text('${\main::pure_magic()}', Eval => 1);
#
#	which will delay the call to pure_magic() until the moment the
#	the Page is being output and insert the output from the call
#	into the byte stream of the Page. See the perlref manual page
#	if you want to understand how this works. Note that the the 
#	argument must be in single quotes (') for this to work. Also
#	be aware that the evaluation takes place in package Eval, but
#	that all variables are automatically forced back into main
#	before the evaluation. This does the `right' thing even if
#	the variable is in another package, e.g.
#
#		  $MY::var => $main::MY:var
#		  $main::var => $main::main::var  - which happens to be okay :)

    sub display_attributes {
      HTML::Base::_show_sub_entry (@_);
      my $self = shift;
      my $attribute = shift;
      local $::value;

      while ($attribute) {
	if (defined ($self->{Attributes}->{$attribute})) { 
	  print " $attribute";

	  if ($self->{Attributes}->{$attribute}) { 
	    $::value = $self->{Attributes}->{$attribute};
	    print "=\"";

	    if (defined $self->{Attributes}->{Eval}) {
	      $::value =~ s/\$(\w)/\$main::$1/gm;
	      eval "\$::value = qq($::value)";

	      # JIS - need better diagnostics
	      print STDERR "\neval failed: $@\n" if $@;
	      print "$::value";
	    }
	    else {
	      HTML::Base::_output_html $::value;
            }

	    print "\"";
	  }
	}

	$attribute = shift;

      } # end while

    } # end sub display_attributes

  } # end package HTMLObject

##############################################################################

  # The next packages are classes derived from HTMLObject

  # HTML::Base::BinaryTag class.  This class is itself a superclass from 
  # which derives
  # all HTML objects whose syntax is merely <x> on open and </x> on close,
  # where "x" = some single string with no spaces.  (Example: <I>Hi</I>)

  # BinaryTag will also handle HTML attributes.  If the HTMLObject has an
  # array named Displayed_Attributes, the BinaryTag::display will add the
  # values of any of those attributes in that list that have values to the
  # opening tag.  For example, if an Anchor object has an attribute named
  # "HREF", then HTML::Base::BinaryTag::display will output "<A HREF=(value)>"

  package HTML::Base::BinaryTag;
  {
    @HTML::Base::BinaryTag::ISA = qw( HTML::Base::HTMLObject );

    # The BinaryTag constructor builds an HTMLObject, then adds the 
    # HTML tag (ie, "H1") as an attribute to the object.

    sub new {
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $tag = shift; 
      my $self = new HTML::Base::HTMLObject @_;
      $self->{'tag'} = $tag;
      bless $self;
    } # end sub new

    # BinaryTag objects simply display their opening tags on "open" and their
    # closing tags on "close". (Ie. "<H1>" on open, and "</H1>" on close.)
    # A newline char is also added for readability, so long as we aren't in
    # a block of preformatted text.

    sub display {
      my $self = shift;
      my $mode = shift;
      if ($Debug) {$self->showme}
      if ($mode eq "open") {
        print ("<$self->{'tag'}");
        if ($self->{Displayed_Attributes}) {
          $self->display_attributes (@{$self->{Displayed_Attributes}});
        }
        print (">");
        HTML::Base::_conditional_newline ($self);
      }
      elsif ($mode eq "close") {
        print ("<\/$self->{'tag'}>");
        HTML::Base::_conditional_newline ($self);
      }
    } # end sub display

  } # end package BinaryTag

##############################################################################

  # HTML::Base::UnaryTag class.  This class is also a superclass from which 
  # derives all HTML objects whose syntax is just <x> on open where "x" = some 
  # single string with no spaces.  (Example: <BR>)  HTML attributes are
  # also supported (see the comments with the BinaryTag class).

  package HTML::Base::UnaryTag;
  {
    @HTML::Base::UnaryTag::ISA = qw( HTML::Base::HTMLObject );

    # The UnaryTag constructor builds an HTMLObject, then adds the 
    # HTML tag (ie, "BR") as an attribute to the object.

    sub new {
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $tag = shift; 
      my $self = new HTML::Base::HTMLObject @_;
      $self->{'tag'} = $tag;
      bless $self;
    } # end sub new

    # UnaryTag objects only output on "open" display calls.

    sub display {
      my $self = shift;
      my $mode = shift;
      if ($Debug) {$self->showme}
      if ($mode eq "open") {
        print ("<$self->{'tag'}");
        if ($self->{Displayed_Attributes}) {
          $self->display_attributes (@{$self->{Displayed_Attributes}});
        }
        print (">");
        HTML::Base::_conditional_newline ($self);
      }
    } # end sub display

  } # end package UnaryTag

##############################################################################

# HTML objects:  The next packages are the HTML object classes themselves.

##############################################################################

  package HTML::Base::Address; # Implements the <ADDRESS></ADDRESS> HTML tags
  {
    @HTML::Base::Address::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("ADDRESS",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Address

##############################################################################
  package HTML::Base::Anchor;              # Implements the <A></A> HTML tags
  {
    @HTML::Base::Anchor::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("A",@_);
      $self->{Displayed_Attributes} = ['HREF','NAME','REL','REV','URN',
                                       'METHODS'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Anchor

##############################################################################
  package HTML::Base::Base;   # Implements the <BASE></BASE> HTML tags
  {
    @HTML::Base::Base::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("BASE",@_);
      $self->{Displayed_Attributes} = ['HREF'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Base

##############################################################################
  package HTML::Base::BlockQuote;
			   # Implements the <BLOCKQUOTE></BLOCKQUOTE> HTML tags
  {
    @HTML::Base::BlockQuote::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("BLOCKQUOTE",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::BlockQuote

##############################################################################
  package HTML::Base::Body;    # Implements the <BODY></BODY> HTML tags
  {
    @HTML::Base::Body::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("BODY",@_);
      $self->{Displayed_Attributes} = 
	  ['BACKGROUND','BGCOLOR','TEXT','LINK','VLINK'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Body

##############################################################################
  package HTML::Base::Bold;   # Implements the <B></B> HTML tags
  {
    @HTML::Base::Bold::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("B",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Bold

##############################################################################
  package HTML::Base::Break;               # Implements the <BR> HTML tag
  {
    @HTML::Base::Break::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("BR",@_);
      $self->{Displayed_Attributes} = ['CLEAR'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Break

##############################################################################
  package HTML::Base::Center;   # Implements the <CENTER></CENTER> HTML tags
  {
    @HTML::Base::Center::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("CENTER",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Center

##############################################################################
  package HTML::Base::Cite;   # Implements the <CITE></CITE> HTML tags
  {
    @HTML::Base::Cite::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("CITE",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Cite

##############################################################################
  package HTML::Base::Code;  # Implements the <CODE></CODE> HTML tags
  {
    @HTML::Base::Code::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("CODE",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Code

##############################################################################
  package HTML::Base::Comment;   # Implements the <!-- ...  --> HTML tags
  {
    @HTML::Base::Comment::ISA = qw( HTML::Base::HTMLObject );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::HTMLObject @_;
      $self->{NoNewLine} = 'TRUE';
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    } # end sub new

    sub display {
      my $self = shift;
      my $mode = shift;
      if ($Debug) {$self->showme}
      if ($mode eq "open") {
        print ("<!--");
      } # end if
      elsif ($mode eq "close") {
        print ("-->");
        HTML::Base::_conditional_newline ($self);
      } # end elsif
    } # end sub display
  }  # end package HTML::Base::Comment

##############################################################################
  package HTML::Base::Definition;    # Implements the <DD> HTML tag
  {
    @HTML::Base::Definition::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("DD",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Definition

##############################################################################
  package HTML::Base::DefinitionList;   # Implements the <DL></DL> HTML tags
  {
    @HTML::Base::DefinitionList::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("DL",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::DefinitionList

##############################################################################
  package HTML::Base::DefinitionTerm;  # Implements the <DT> HTML tag
  {
    @HTML::Base::DefinitionTerm::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("DT",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::DefinitionTerm

##############################################################################
  package HTML::Base::Directory;   # Implements the <DIR></DIR> HTML tags
  {
    @HTML::Base::Directory::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("DIR",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Directory

##############################################################################
  package HTML::Base::Emphasis;       # Implements the <EM></EM> HTML tags
  {
    @HTML::Base::Emphasis::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("EM",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Emphasis

##############################################################################
  package HTML::Base::Form;     # Implements the <FORM> HTML tag
  {
    @HTML::Base::Form::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("FORM",@_);
      $self->{Displayed_Attributes} = [qw( METHOD ACTION ENCTYPE )];
      HTML::Base::_set_if_not_set($self, METHOD => 'POST');
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Form

##############################################################################
  package HTML::Base::Head;           # Implements the <HEAD></HEAD> HTML tags
  {
    @HTML::Base::Head::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("HEAD",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Head

##############################################################################
  package HTML::Base::Header;   # Implements the <Hx></Hx> HTML tags, where
  {                             # "x" is an integer in the range of 1-6.
    @HTML::Base::Header::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $level = shift; 
      my $self;
      if ($level ne 'Copy') {
        if ($level eq 'Level') {
          $level = shift;
        }
        $level = substr($level,0,1);
        if ($level =~ "[1-6]") { 
          $self = new HTML::Base::BinaryTag (("H" . $level),@_);
        }
        else {
          return 0
        }
      }
      else {
        unshift @_,$level;
        $self = new HTML::Base::BinaryTag (("H"),@_);
      }
      $self->{Displayed_Attributes} = ['ALIGN'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Header

##############################################################################
  package HTML::Base::HorizontalRule;   # Implements the <HR> HTML tag
  {
    @HTML::Base::HorizontalRule::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("HR",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::HorizontalRule

##############################################################################
  package HTML::Base::Image;         # Implements the <IMG> HTML tag
  {
    @HTML::Base::Image::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("IMG",@_);
      $self->{Displayed_Attributes} = ['SRC','ALIGN','ALT','BORDER','ISMAP'];
      $self->{NoNewLine} = 'TRUE';
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Image

##############################################################################
  package HTML::Base::Input;               # Implements the <INPUT> HTML tag
  {
    @HTML::Base::Input::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("INPUT",@_);
      $self->{Displayed_Attributes} =
        [qw( ALIGN CHECKED MAXLENGTH NAME SIZE SRC TYPE VALUE )];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }

    # display is called here so that we have any opportunity
    # to reset the form elements to be consistent with the
    # last call of the form.
    #
    # NB -
    #	I am relying on $R:: having been sent, which is good enough
    #	for now, but it should be made more robust.  Pass in the
    #	CGI object during creation?
    # Joel

    sub display {
      my $self = shift;
      my $mode = shift;

      no strict qw(refs);

      if ($mode eq "open") {
        my $name = $self->{Attributes}->{NAME};
        my $type = $self->{Attributes}->{TYPE};
        my $value = $self->{Attributes}->{VALUE};

        if ( $HTML::Base::Page::Request && 
	     defined $HTML::Base::Page::Request->param($name) ) {
          if ( lc($self->{Attributes}->{TYPE}) eq 'radio' ) {
	    if ( $HTML::Base::Page::Request->param($name) eq 
		 $self->{Attributes}->{VALUE} ) {
	      $self->{Attributes}->{CHECKED} = '';
	    } 
	    else {
	      undef $self->{Attributes}->{CHECKED};
            }
	  }
	  else {
	    $self->{Attributes}->{VALUE} = 
	      $HTML::Base::Page::Request->param($name);
          }
	}
		
	HTML::Base::UnaryTag::display($self, $mode, @_);
      }
      elsif ($mode eq "close") {
	HTML::Base::UnaryTag::display($self, $mode, @_);
      }
    } # end sub HTML::Base::Input::display
  }  # end package HTML::Base::Input

##############################################################################
  package HTML::Base::IsIndex;    # Implements the <ISINDEX> HTML tag
  {
    @HTML::Base::IsIndex::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("ISINDEX",@_);
      $self->{Displayed_Attributes} = ['ACTION'];   # ?? IN WHAT STANDARD???
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::IsIndex

##############################################################################
  package HTML::Base::Italic;           # Implements the <I></I> HTML tags
  {
    @HTML::Base::Italic::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("I",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Italic

##############################################################################
  package HTML::Base::Keyboard; # Implements the <KEYBOARD></KEYBOARD> HTML tags
  {
    @HTML::Base::Keyboard::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("KEYBOARD",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Keyboard

##############################################################################
  package HTML::Base::Link;              # Implements the <LINK> HTML tag
  {
    @HTML::Base::Link::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("LINK",@_);
      $self->{Displayed_Attributes} = ['HREF','NAME','REL','REV','URN',
                                       'METHODS'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Link

##############################################################################
  package HTML::Base::ListItem;              # Implements the <LI> HTML tag
  {
    @HTML::Base::ListItem::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("LI",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::ListItem

##############################################################################
  package HTML::Base::Menu;    # Implements the <MENU></MENU> HTML tags
  {
    @HTML::Base::Menu::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("MENU",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Menu

##############################################################################
  package HTML::Base::Meta;              # Implements the <META> HTML tag
  {
    @HTML::Base::Meta::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("META",@_);
      $self->{Displayed_Attributes} = ['NAME','CONTENT','HTTP-EQUIV'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Meta

##############################################################################
  package HTML::Base::NextId;              # Implements the <NEXTID> HTML tag
  {
    @HTML::Base::NextId::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("NEXTID",@_);
      $self->{Displayed_Attributes} = ['N'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::NextId

##############################################################################
  package HTML::Base::Option;      # Implements the <OPTION> HTML tag
  {
    @HTML::Base::Option::ISA = qw( HTML::Base::UnaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::UnaryTag ("OPTION",@_);
      $self->{Displayed_Attributes} = [qw( SELECTED VALUE)];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }

    # display is defined here so that we have any opportunity
    # to reset the form elements to be consistent with the
    # last call of the form. This only works if a valid
    # Request module has been reqistered for this Page via
    # $page->save_request($req)

    sub display {
      my $self = shift;
      my $mode = shift;

      no strict qw(refs);
      if ($mode eq "open") {
        my $value = $self->{Children}[0]->{Attributes}->{Text};
        if ($HTML::Base::Page::Request) {
          if (defined $self->{Parent}->{Attributes}->{MULTIPLE}) {
            undef $self->{Attributes}->{SELECTED};
            foreach 
	      ($HTML::Base::Page::Request->param($HTML::Base::Option::name)) {
              if ($_ eq $value) {
                $self->{Attributes}->{SELECTED} = '';
                last;
	      }
            }
          }
          elsif ($HTML::Base::Page::Request->param($HTML::Base::Option::name) 
		 eq $value ) {
            $self->{Attributes}->{SELECTED} = '';
          }
          else {
            undef $self->{Attributes}->{SELECTED};
          }
        }
		
	HTML::Base::UnaryTag::display($self, $mode, @_);
      }
      elsif ($mode eq "close") {
	HTML::Base::UnaryTag::display($self, $mode, @_);
      }
    } # end sub HTML::Base::Option::display
  }  # end package HTML::Base::Option

##############################################################################
  package HTML::Base::OrderedList;    # Implements the <OL></OL> HTML tags
  {
    @HTML::Base::OrderedList::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("OL",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::OrderedList

##############################################################################
  # Page is a special kind of HTMLObject.  Not only does it output the
  # <HTML></HTML> tags, it also controls the filehandle to which output
  # for a particular page of HTML will be sent.

  # The Page object recognizes the attribute "OUTPUTFILE", which will specify
  # the name of the file to write HTML into for this page.  The attribute
  # OUTPUTMODE defines whether or not we want to trash any existing content
  # of the file (OUTPUTMODE = OVERWRITE, which is the default), or append
  # the current HTML to an existing file (OUTPUTMODE = APPEND).
  # If no filename is given, standard output is assumed.

  # Page has another attribute called LASTFILEHANDLE, which holds the handle
  # of the file which was last the default output file.  This is set when
  # Page->display is called in "open" mode, using the select function.
  # When Page->display is called in "close" mode, the LASTFILEHANDLE is
  # retrieved and used to point the default output stream to wherever it was
  # before we changed it.

  package HTML::Base::Page;    # Implements the <HTML></HTML> HTML tags
                               # and controls output to files.
  {
    use Carp;
    @HTML::Base::Page::ISA = qw( HTML::Base::BinaryTag );

    my $Request = undef;

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("HTML",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
     
    sub save_request {
      my($self, $request) = @_;
      $self->{Request} = $request;
    }

    # The method HTML::Base::Page::display outputs the <HTML></HTML> tags, 
    # and also
    # controls the filehandle for output that all HTMLObjects who are 
    # decendants of this Page object will use.

    sub display {
      no strict 'refs';
      my $self = shift;
      my $mode = shift;
      my $OutputFile;
      if ($Debug) {$self->showme}
      if ($mode eq "open") {

	$HTML::Base::Page::Request = $self->{Request};

        # We are starting a new page.  Get the output file name, if given:

        if ($OutputFile = $self->{Attributes}->{OUTPUTFILE}) {

          # If the output file begins with the redirection char ">", we'll
          # assume that the user knows what he's doing and has formatted the
          # filename accordingly.  If not, then we'll preface the file name
          # with either ">", for file overwrite mode, or ">>" for append mode.

          if (substr($OutputFile,0,1) ne '>') { 
            if ($self->{Attributes}->{OUTPUTMODE} eq 'APPEND') {
              $OutputFile = '>>' . $OutputFile; 
            }
            else { 
              $OutputFile = '>' . $OutputFile; 
              $self->{Attributes}->{OUTPUTMODE} = 'OVERWRITE';
            }
          }

          # Make a new unique file handle (just by incrementing the last one)

          $self->{Attributes}->{FILEHANDLE} = ++$HTML::Base::FileHandle;
          if ($Debug) {
            print (STDERR "\nHTML::Base::Page::display: OutputFile = $OutputFile Handle = $self->{Attributes}->{FILEHANDLE}");
          }

          # Try to open the new output file, using the new file handle

            open ($self->{Attributes}->{FILEHANDLE},$OutputFile) || 
              carp ("HTML::Base: Can't open $OutputFile for output, mode = $self->{Attributes}->{OUTPUTMODE}");

          # Make the new file handle the default handle for output, and 
          # remember the old default file handle for later.

          $self->{Attributes}->{LASTFILEHANDLE} =
                  select ($self->{Attributes}->{FILEHANDLE});
        }

        # We call the usual BinaryTag->display method to actually print out 
        # the <HTML> and </HTML> tags

        $self->HTML::Base::BinaryTag::display($mode);

      } # end if

      elsif ($mode eq "close") {

        $Page::Request = undef;

        # Print out the </HTML> tag

        $self->HTML::Base::BinaryTag::display($mode);

        # We have finished one page of HTML.  Close the output file.

        if ($self->{Attributes}->{FILEHANDLE}) {
          close ($self->{Attributes}->{FILEHANDLE}) || 
              carp ("HTML::Base: Error closing $self->{Attributes}->{OUTPUTFILE}");
	}

        # Restore the previous default output file handle

        if ($self->{Attributes}->{FILEHANDLE}) {
          select ($self->{Attributes}->{LASTFILEHANDLE});
        }
      } # end elsif

    } # end sub HTML::Base::Page::display

  } # end package HTML::Base::Page

##############################################################################
  package HTML::Base::Paragraph;           # Implements the <P></P> HTML tags
  {
    @HTML::Base::Paragraph::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("P",@_);
      $self->{Displayed_Attributes} = ['ALIGN'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Paragraph

##############################################################################
  package HTML::Base::Preformatted; # Implements the <PRE></PRE> HTML tags
  {
    @HTML::Base::Preformatted::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("PRE",@_);
      $self->{Displayed_Attributes} = ['WIDTH'];
      $self->{NoNewLine} = 'TRUE';
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package Preformatted

##############################################################################
  package HTML::Base::Sample;   # Implements the <SAMPLE></SAMPLE> HTML tags
  {
    @HTML::Base::Sample::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("SAMPLE",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Sample

##############################################################################
  package HTML::Base::Select;               # Implements the <SELECT> HTML tag
  {
    @HTML::Base::Select::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("SELECT",@_);
      $self->{Displayed_Attributes} = [qw( NAME MULTIPLE SIZE ALIGN )];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }

    # display is defined here only to set up $HTML::Base::Option::name which
    # will be needed by subsequent calls to HTML::Base::Option::display so it
    # knows which Request module variable(s) to access via
    # $req->param($HTML::Base::Option::name)

    sub display {
      my $self = shift;
      my $mode = shift;

      no strict qw(refs);
      if ($mode eq "open") {
        $HTML::Base::Option::name = $self->{Attributes}->{NAME};
        HTML::Base::BinaryTag::display($self, $mode, @_);
      }
      elsif ($mode eq "close") {
        undef $HTML::Base::Option::name;
        HTML::Base::BinaryTag::display($self, $mode, @_);
      }
    } # end sub display

    # multiple is a convenience routine to create a Select MULTIPLE
    #
    #	$self is an object returned by new Select
    #
    #	$items is an array reference to the OPTION text
    #
    #	$selected is a (optional) array reference which should contain
    #	a binary map of which elements in @{$items} are pre selected.
    #	For each element in @{$items} the corresponding element in
    #	@{$selected} is checked and if it is set the OPTION	is marked
    #	SELECTED.

    sub multiple {
      my($self, $items, $selected) = @_;
      my($item, $option);
      my $nl = HTML::Base::contained_by($self, 'Preformatted') ? "\n" : '';
      $self->make_current;
      $self->{Attributes}->{MULTIPLE} = '';
      foreach $item (@{$items}) {
        if (defined $selected && shift @{$selected} ) {
          $option = new HTML::Base::Option SELECTED => '';
        } else {
          $option = new HTML::Base::Option;
        }

        new HTML::Base::Text $item . $nl;
        $option->end_object;
        $self->make_current;
      }
    }

    # pulldown is a convenience routine to create a pulldown list
    #
    #	$self is an object returned by new Select
    #
    #	$items is an array reference to the OPTION text
    #
    #	$selected is a (optional) scalar string which is compared to
    #	each item in @{$items} and if a match is found that OPTION
    #	is marked SELECTED. Otherwise the first element of @{$items}
    #	is marked SELECTED.

    sub pulldown {
      my($self, $items, $selected) = @_;
      my($item, $option);
      my $nl = HTML::Base::contained_by($self, 'Preformatted') ? "\n" : '';
      $self->make_current;
      undef $self->{Attributes}->{MULTIPLE};
      undef $self->{Attributes}->{SIZE};
      defined $selected or $selected = @{$items}[0];
      foreach $item (@{$items}) {
        if ($item eq $selected ) {
          $option = new HTML::Base::Option SELECTED => '';
        } 
	else {
          $option = new HTML::Base::Option;
        }

        new HTML::Base::Text $item . $nl;
        $option->end_object;
        $self->make_current;
      }
    }

    # scrolled is a convenience routine to create a scrolled list
    #
    #	$self is an object returned by new Select
    #
    #	$items is an array reference to the OPTION text
    #
    #	$selected is a (optional) scalar string which is compared to
    #	each item in @{$items} and if a match is found that OPTION
    #	is marked SELECTED

    sub scrolled {
      my($self, $items, $selected) = @_;
      my($item, $option);

      my $nl = HTML::Base::contained_by($self, 'Preformatted') ? "\n" : '';
      $self->make_current;
      undef $self->{Attributes}->{MULTIPLE};
      defined $self->{Attributes}->{SIZE} or $self->{Attributes}->{SIZE} = 6;
      foreach $item (@{$items}) {
        if ($item eq $selected ) {
          $option = new HTML::Base::Option SELECTED => '';
        } 
        else {
          $option = new HTML::Base::Option;
        }

        new HTML::Base::Text $item . $nl;
        $option->end_object;
        $self->make_current;
      }
    }

  }  # end package HTML::Base::Select

##############################################################################
  package HTML::Base::Strong;    # Implements the <STRONG></STRONG> HTML tags
  {
    @HTML::Base::Strong::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("STRONG",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Strong

##############################################################################
  package HTML::Base::Table;  #Implements the <TABLE></TABLE> tags
  {
    @HTML::Base::Table::ISA = qw( BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift;
      my $self = new BinaryTag ("TABLE",@_);
      $self->{Displayed_Attributes} = 
	 ['BORDER','CELLPADDING','CELLSPACING','WIDTH'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  } # end package HTML::Base::Table
 
##############################################################################
  package HTML::Base::TableCaption; #Implements the <CAPTION></CAPTION> tags
  {
    @HTML::Base::TableCaption::ISA = qw( BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift;
      my $self = new BinaryTag ("CAPTION",@_);
      $self->{Displayed_Attributes} = ['ALIGN','VALIGN'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  } # end package HTML::Base::TableCaption

##############################################################################
  package HTML::Base::TableData; #Implements the <TD></TD> tags
  {
    @HTML::Base::TableData::ISA = qw( BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift;
      my $self = new BinaryTag ("TD",@_);
      $self->{Displayed_Attributes} = 
	 ['ALIGN','VALIGN','NOWRAP','COLSPAN','ROWSPAN','WIDTH'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  } # end package HTML::Base::TableData

##############################################################################
  package HTML::Base::TableHeader; #Implements the <TH></TH> tags
  {
    @HTML::Base::TableHeader::ISA = qw( BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift;
      my $self = new BinaryTag ("TH",@_);
      $self->{Displayed_Attributes} = 
	['ALIGN','VALIGN','NOWRAP','COLSPAN','ROWSPAN','WIDTH'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  } # end package HTML::Base::TableHeader

##############################################################################
  package HTML::Base::TableRow; #Implements the <TR></TR> tags
  {
    @HTML::Base::TableRow::ISA = qw( BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift;
      my $self = new BinaryTag ("TR",@_);
      $self->{Displayed_Attributes} = ['ALIGN','VALIGN'];
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  } # end package HTML::Base::TableRow

##############################################################################
# Text is a special-purpose HTML object which has no HTML tag associated
# with it.  Instead, it is meant to contain the text that makes up the
# actual content of the HTML document.  A Text object which is a child of
# an HTML object will output its text within the scope of the HTML tags
# of its owner.
#
# The actual text is stored in an attribute of Text called {Text} (confused
# yet?)  When being passed to the new method of Text, the text to be
# displayed must be the first parameter, preceding any attributes to be
# set.  Examples:
#
#          new Text "This is my text";
#          new Text ("This is my text","Attribute1","Wowzo");
#
# Before being output, the text is sanitized for HTML use by translating
# all of the forbidden HTML chars (like "<") into their HTML escape
# equivalences.
#
# Two special Attributes, 'Eval' and 'Verb' are recognised.  In both
# cases it is the user's responsibity to make certain that the output
# strings are legal and complete HTML syntax since no sanitizing is
# is performed.
#
#   'Eval' => 1
#  ------------
#	If set then the text is first processed with a
#	perl eval().  This permits the enclusion of objects on the
#	tree that are evaluated at the time of actual usage.  This
#	enables the embedding of Perl variables whose values are either
#	not known at the time of construction or which change dymanically.
#	It is especially useful for constructs such as
#
#	  new Text('${\main::pure_magic()}', Eval => 1);
#
#	which will delay the call to pure_magic() until the moment the
#	the Page is being output and insert the output from the call
#	into the byte stream of the Page. See the perlref manual page
#	if you want to understand how this works. Note that the the 
#	argument must be in single quotes (') for this to work. Also
#	be aware that the evaluation takes place in package Eval, but
#	that all variables are automatically forced back into main
#	before the evaluation. This does the `right' thing even if
#	the variable is in another package, e.g.
#
#		$MY::var => $main::MY:var
#		$main::var => $main::main::var	- which happens to be okay :)
#
#  'Verb' => 1
#  ------------
#	Supresses the quoting of HTML special characters. This allows the
#	inclusion of chunks of real HTML in the current page. e.g.
# 
#			new Text("<B>I want this in Bold</B>", Verb => 1);
#
#	This is useful for include substantial pieces of pre-formatted
#	HTML in the output stream.
#
#  NOTE: For both 'Eval' and 'Verb' Text: no newline is printed, unless you
#        have newline(s) in your text!

  package HTML::Base::Text;
  {
    @HTML::Base::Text::ISA = qw( HTML::Base::HTMLObject );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $text = shift; 
      my $self;
      if ($text ne 'Copy') {
        if ($text eq 'Text') {$text = shift;}
        $self = new HTML::Base::HTMLObject @_;
        $self->{Attributes}->{Text} = $text;
        if ($self->{Parent}) {$self->{Parent}->make_current;}
      }
      else {
        unshift @_,$text;
        $self = new HTML::Base::HTMLObject @_;
      }
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }

    sub display {
      my $self = shift;
      my $mode = shift;

      if ($Debug) {$self->showme}

      if ($mode eq "open") {
	    my $text = $self->{Attributes}->{Text};

        if ( defined $self->{Attributes}->{Eval} ) {
	  $text =~ s/\$(\w)/\$main::$1/gm;
	  eval "\$text = qq($text)";
	  # JIS - need better diagnostics
	  print STDERR "\neval failed: $@\n" if $@;
          print "$text";
        }
        elsif ( defined $self->{Attributes}->{Verb} ) {
          print "$text";
        }
        else {
          HTML::Base::_output_html $self->{Attributes}->{Text};
          HTML::Base::_conditional_newline ($self);
	}
      }
    } # end sub HTML::Base::Text::display

  }  # end package HTML::Base::Text

##############################################################################
  package HTML::Base::TextArea;    # Implements the <TEXTAREA> HTML tag
  {
    @HTML::Base::TextArea::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("TEXTAREA",@_);
      $self->{Displayed_Attributes} = [qw( NAME ROWS COLS )];
      $self->{NoNewLine} = 'TRUE';
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }

    # display is defined here only to set up $HTML::Base::Text::name which
    # will be needed by subsequent calls to HTML::Base::Text::display so it
    # knows which Request module variable(s) to access via
    # $req->param($HTML::Base::Option::name)

    sub display {
      my $self = shift;
      my $mode = shift;

      no strict qw(refs);
      if ($mode eq "open") {
        if ($HTML::Base::Page::Request ) {
          $self->{Children}[0]->{Attributes}->{Text} =
          $HTML::Base::Page::Request->param($self->{Attributes}->{NAME});
        }
        HTML::Base::BinaryTag::display($self, $mode, @_);
      }

      elsif ($mode eq "close") {
        undef $HTML::Base::Text::name;
        HTML::Base::BinaryTag::display($self, $mode, @_);
      }
    } # end sub display

  }  # end package HTML::Base::TextArea

##############################################################################
  package HTML::Base::Title;  # Implements the <TITLE></TITLE> HTML tags
  {
    @HTML::Base::Title::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("TITLE",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Title

##############################################################################
  package HTML::Base::Tty;           # Implements the <TTY></TTY> HTML tags
  {
    @HTML::Base::Tty::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("TTY",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Tty

##############################################################################
  package HTML::Base::UnorderedList; # Implements the <UL></UL> HTML tags
  {
    @HTML::Base::UnorderedList::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("UL",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::UnorderedList

##############################################################################
  package HTML::Base::Var;           # Implements the <VAR></VAR> HTML tags
  {
    @HTML::Base::Var::ISA = qw( HTML::Base::BinaryTag );

    sub new {
      HTML::Base::_comment_divider();
      HTML::Base::_show_sub_entry (@_);
      my $type = shift; 
      my $self = new HTML::Base::BinaryTag ("VAR",@_);
      bless $self;
      HTML::Base::_show_new_object($self);
      $self;
    }
  }  # end package HTML::Base::Var

##############################################################################
}  # end package HTML
1;
__END__;


