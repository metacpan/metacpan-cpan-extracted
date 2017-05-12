# ====================================================================
# Copyright (C) 1997,1998 Stephen Farrell <stephen@farrell.org>
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# ====================================================================
# File: Component.pm
# Author: Stephen Farrell
# Created: August, 1997
# Locations: http://www.palefire.org/~sfarrell/TableLayout/
# CVS $Id: Component.pm,v 1.17 1998/09/20 21:05:28 sfarrell Exp $
# ====================================================================


##
## This class is abstract
##
package HTML::TableLayout::Component;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::ISA=qw(HTML::TableLayout::TL_BASE);
use Carp;
use strict;

##
## Default init
##
sub tl_init {
  my $this = shift;
  ##
  ## QUIZ--how do i avoid this temporary variable?
  ##
  my %params = @_;
  $this->{TL_PARAMS} = \ %params;
  $this->SUPER::tl_init();
}

##
## tl_setContext(): Sets the context in the heirarchy when packing and
## displaying. This is done "late"
##
sub tl_setContext {
  my ($this, $container) = @_;
  my $window = $container->{TL_WINDOW};
  my $form = $container->{TL_FORM};
  
  
  ## ====================================================================
  ##
  ## DEBUGGING 
  ##
  
  confess "container is null" unless $container;
  confess "window is null" unless $window;
  
  ##
  ## it's ok for the form to be null, but if it is, we don't want to
  ## clobber an existing value for it.
  ##
  ## ====================================================================
  
  defined $container and $this->{TL_CONTAINER} = $container;
  defined $window and $this->{TL_WINDOW} = $window;
  defined $form and $this->{TL_FORM} = $form;
}

##
## tl_getContainer(),tl_getWindow(),tl_getForm(): Accessors for the
## above--notethat these might not be used much b/c we know the name
## of the data very well.
##
sub tl_getContainer { return shift->{TL_CONTAINER} }
sub tl_getWindow { return shift->{TL_WINDOW} }
sub tl_getForm { return shift->{TL_FORM} }


##
## tl_setup(): is called just before printing, and is meant to provide
## "late" packing and searching for requirements in containers (like
## looking for a Form).  Actually, it's called everywhere before
## anything prints, so if you want to play with values in your
## neighboring components, have fun.
##
## If you override this, you must call your super's version.  (like
## $this->SUPER::tl_setup()). ok ok I'm lying right now b/c as you can
## see, there is nothing here so obviously you don't HAVE to call it.
## but I might add something later.  Also, if your parent is a
## componentcontainer, then you MUST call it (or do equivalent and
## keep your fingers crossed for future versions).
##
sub tl_setup {  }


##
## tl_print(): uses i_print() and f_print() to display object.
##
sub tl_print {  }


##
## tl_breakAfter(): The component has a break "<BR>" after it.  This
## doesn't happen automatically--the component printing it needs to
## check if it is there and print it itself.
##

sub tl_breakAfter { return shift->{TL_BREAK_AFTER} }

sub tl_destroy {
  my ($this) = @_;
  undef $this->{TL_BREAK_AFTER};
  undef $this->{TL_CONTAINER};
  undef $this->{TL_WINDOW};
  undef $this->{TL_FORM};
  $this->SUPER::tl_destroy();
}

# ---------------------------------------------------------------------

package HTML::TableLayout::ComponentContainer;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::ComponentContainer::ISA=qw(HTML::TableLayout::Component);

sub tl_init {
  my $this = shift;
  $this->SUPER::tl_init(@_);
  $this->{TL_COMPONENTS} = [];
  $this->{TL_BREAKS} = [];
}

##
## insert(): add a component.  subclasses should always call this,
## like tl_setup()
##
sub insert { 
  my ($this, $obj, $br) = @_;

  if (! ref $obj) {
    $obj = HTML::TableLayout::Component::Text->new($obj);
  }

  if ($obj->isa("HTML::TableLayout::Form")) {
    $this->{TL_FORM} = $obj;
    $this->{form_is_mine} = $obj;
  }
  else {
    push @{ $this->{TL_COMPONENTS} }, $obj;
    push @{ $this->{TL_BREAKS} }, $br;
  }
  return $this;
}

##
## insertLn(): add a component w/ <BR> afterwards.  Generally I've
## handled this as a wrapper method that calls insert with a second
## argument of "1".
##
sub insertLn { return shift->insert(shift,1) }


##
## tl_setup(): if you choose to override this method, then you must do
## what is done here, or call $this->SUPER::tl_setup().  Of course, if
## you replicate this method's functionality, you should be aware that
## in the future this function might change, and you might need to
## update your equivalent functionality in the future....  (yes, I'm
## scrounging for hints on OO design!)
##
sub tl_setup {
  my ($this) = @_;

  $this->tl_setup_form();

  foreach my $cmp (@{ $this->{TL_COMPONENTS} }) {
    die("null comp.") unless $cmp;
    ##
    ## Maybe it is a form input, in which case it needs to be inserted
    ## into the appropriate form.
    ##
    if ($cmp->isa("HTML::TableLayout::FormComponent")) {
      my $f = $this->{TL_FORM};
      if ($f) {
	$f->insert($cmp);
	$cmp->tl_setContext($this);
      }
      else {
	die("No Form to insert this FormComponent [$cmp] into [$this]");
      }
    }
    $cmp->tl_setContext($this);
    $cmp->tl_setup();
  }
  $this->SUPER::tl_setup(); 
} 

sub tl_setup_form {
  my $this = shift;
  
  ##
  ## If we have a form, this is the time to set its context
  ##
  if ($this->{form_is_mine}) {
    if ($this->{form_is_mine} ne $this->{TL_FORM}) {
      die("Nested forms detected!");
    }
    else {
      $this->{TL_FORM}->tl_setContext($this);
      $this->{TL_WINDOW}->_incrementNumForms();
    }
  }
}


##
## this makes a ComponentContainer an implementable object--and a very
## useful one at that.  YOu can just stick stuff in it and it'll print
## the various things with no added overhead.  unfortunately,
## subclasses will need to reproduce any behavior here...
##
sub tl_print {
  my ($this) = @_;

  $this->{form_is_mine} and $this->{TL_FORM}->tl_print();
  foreach (0..$#{ $this->{TL_COMPONENTS} }) {
    $this->{TL_COMPONENTS}->[$_]->tl_print();
    $this->{TL_BREAKS}->[$_] and $this->{TL_WINDOW}->i_print("><BR");
  }
  $this->{form_is_mine} and $this->{TL_FORM}->_print_end();
}

sub tl_destroy {
  my ($this) = @_;
  foreach(@{ $this->{TL_COMPONENTS} }) {
    $_->tl_destroy();
  }
  undef $this->{TL_BREAKS};
  undef $this->{TL_COMPONENTS};
  $this->SUPER::tl_destroy();
}

sub getAllChildren {
  my ($this, $what) = @_;

  my @children;
  if (scalar(@{ $this->{TL_COMPONENTS} })) {
    foreach my $child (@{ $this->{TL_COMPONENTS} }) {
      push @children, $child if (! $what or $child->isa($what));
      push @children, $child->getAllChildren($what)
	if $child->isa("HTML::TableLayout::ComponentContainer");
    }
  }
  return @children;
}
    
  

# ---------------------------------------------------------------------
## clearly this is not what I meant... FIXME!
package HTML::TableLayout::ComponentCell;
@HTML::TableLayout::ComponentCell::ISA=qw(HTML::TableLayout::Cell);

# ---------------------------------------------------------------------

package HTML::TableLayout::ComponentTable;
@HTML::TableLayout::ComponentTable::ISA=qw(HTML::TableLayout::Table);


# ---------------------------------------------------------------------

package HTML::TableLayout::Component::Text;
use HTML::TableLayout::Symbols;
use Carp;
@HTML::TableLayout::Component::Text::ISA=qw(HTML::TableLayout::Component);

my %MARKUP = (bold =>	"B",
	      italic => "I",
	      big =>	"BIG",
	      small =>	"SMALL");


sub tl_init {
  my $this = shift;
  $this->{text} = shift;
  $this->SUPER::tl_init(@_);
}


sub tl_getParameters {
  my ($this) = @_;
  
  confess("WAS DESTROYED") if $this->{WAS_DESTROYED};
  confess("TL_PARAMS undef [$this]") unless $this->{TL_PARAMS};
  confess("TL_WINDOW undef [$this]") unless $this->{TL_WINDOW};

  my %params = ($this->{TL_WINDOW}->{PARAMETERS}->get($this),
		    %{ $this->{TL_PARAMS} });
  foreach("italic","bold", "big", "small") {
    if (exists $params{$_}) {
      delete $params{$_};
      push @{ $this->{markup} }, $MARKUP{$_};
    }
  }
  return (%params);
}

sub tl_print {
  my ($this) = @_;
  my $w = $this->{TL_WINDOW};
  my %p = $this->tl_getParameters();
  $w->i_print();
  my $m;
  foreach $m (@{ $this->{markup} }) {
    $w->f_print("><$m");
  }
  
  $w->f_print("><FONT".params(%p).">");
  if ($this->{tl_do_not_pad}) {
    $w->f_print($this->{"text"});
  }
  else {
    $w->f_print(" " . $this->{"text"} . " "); 
  }
  $w->f_print("</FONT");
  
  foreach $m (reverse @{ $this->{markup} }) {
    $w->f_print("></$m");
  }
}

##
## Yuck.  Padding of text is a messy issue after moving to the ><
## style tagging... the problem is that if we don't pad, the text is
## glued together unexpectedly.  if i do pad, then links look bad.
## This function is here so a link can tell it's text components not
## to pad.
##
sub tl_do_not_pad { shift->{tl_do_not_pad} = 1 }

# ---------------------------------------------------------------------

package HTML::TableLayout::Component::Image;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::Image::ISA=qw(HTML::TableLayout::Component);

sub tl_init {
  my ($this, $url, %params) = @_;
  $this->SUPER::tl_init(%params);
  $this->{url} = $url;
}

sub tl_print {
  my ($this, %ops) = @_;
  my $w = $this->{TL_WINDOW};
  my $p = params($this->tl_getParameters()) || "";
  $w->i_print(qq{><IMG SRC="$this->{url}" $p});
}

# ---------------------------------------------------------------------

package HTML::TableLayout::Component::Link;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::Link::ISA
  =qw(HTML::TableLayout::ComponentContainer);

sub tl_init {
  my $this	   = shift;
  $this->{href}	   = shift;
  $this->{anchor}  = shift;
  $this->SUPER::tl_init(@_);
  
  if (ref $this->{anchor}) {
    $this->{TL_COMPONENTS}->[0] = $this->{anchor};
  }
  else {
    $this->{TL_COMPONENTS}->[0]
      = HTML::TableLayout::Component::Text->new($this->{anchor});
  }
  if ($this->{TL_COMPONENTS}->[0]->isa("HTML::TableLayout::Component::Text")) {
    ##
    ## see comment for tl_do_not_pad() method of Text
    ##
    $this->{TL_COMPONENTS}->[0]->tl_do_not_pad();
  }
}

sub passCGI {
  my ($this, $cgi, @pass) = @_;
  if (! (ref $cgi eq "HASH")) { die("malformed passcgi") }
  $this->{href} .= "?";
  my @p = scalar(@pass) ? @pass : keys %$cgi;

  my ($k, $v);
  foreach (@p) {
    if (/^([^=]+)=(.*)$/) {
      ($k, $v) = ($1, $2);
    }
    else {
      ($k, $v) = ($_, $cgi->{$_});
    }

    $this->{href} .= $k . "=" . escape_url($v) . "&";
  }
  return $this;
}

##
## stolen from cgi.pm
##
sub escape_url {
    my $s = shift; $s eq undef and return undef;
    $s=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $s
}


sub tl_print {
  my ($this, %ops) = @_;
  
  my $w = $this->{TL_WINDOW};
  my $p = params($this->tl_getParameters()) || "";
  $w->i_print(qq{><A HREF="$this->{href}" $p});
  $this->{TL_COMPONENTS}->[0]->tl_print();
  $w->f_print("></A");
}

# ---------------------------------------------------------------------

package HTML::TableLayout::Component::Preformat;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::Preformat::ISA=
  qw(HTML::TableLayout::Component);

sub tl_init {
  my $this = shift;
  $this->{pre} = shift;
  $this->SUPER::tl_init(@_);
}

sub tl_print {
  my ($this) = @_;
  my $w = $this->{TL_WINDOW};
  $w->i_print("><PRE>");
  $w->f_print($this->{"pre"}."");
  $w->i_print("</PRE");
}
# ---------------------------------------------------------------------

package HTML::TableLayout::Component::Comment;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::Comment::ISA=
  qw(HTML::TableLayout::Component);

sub tl_init {
  my $this = shift;
  $this->{comment} = shift;
  $this->SUPER::tl_init(@_);
}

sub tl_print {
  my ($this) = @_;
  ##
  ## This is a pretty ugly hack--note fake tag "<x>"
  ##
  $this->{TL_WINDOW}->i_print("><!-- " . $this->{"comment"} . " --><x");
}

# ---------------------------------------------------------------------

package HTML::TableLayout::Component::HorizontalRule;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::HorizontalRule::ISA=
  qw(HTML::TableLayout::Component);

sub tl_print {
  my ($this) = @_;
  $this->{TL_WINDOW}->i_print("><HR".params($this->tl_getParameters())."");
} 

# ---------------------------------------------------------------------
package HTML::TableLayout::Component::Font;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::Font::ISA=
  qw(HTML::TableLayout::ComponentContainer);


sub tl_print {
  my $this = shift;

  my %p = $this->tl_getParameters();
  $this->{TL_WINDOW}->i_print("><FONT".params(%p)."");
  foreach (@{ $this->{TL_COMPONENTS} }) {
    $this->{TL_WINDOW}->_indentIncrement();
    $_->tl_print();
    $this->{TL_WINDOW}->_indentDecrement();
  }
  $this->{TL_WINDOW}->i_print("></FONT>");
}
    

# ---------------------------------------------------------------------
package HTML::TableLayout::Component::List;
use HTML::TableLayout::Symbols;
@HTML::TableLayout::Component::List::ISA=
  qw(HTML::TableLayout::ComponentContainer);

sub tl_init {
  my $this = shift;
  $this->{numbered} = shift;
  $this->{delimited} = shift;
  $this->SUPER::tl_init(@_);
}

sub insert {
  my ($this, $component, $br) = @_;
  if (! ref $component) {
    $component = HTML::TableLayout::Component::Text->new($component);
  }

  push @{ $this->{TL_BREAKS} }, $br;

  $this->SUPER::insert($component);
}



sub tl_print {
  my ($this) = @_;
  
  my $w = $this->{TL_WINDOW};
  my $list_denoter;
  if ($this->{numbered}) {
    $list_denoter = "OL";
  }
  else {
    $list_denoter = "UL";
  }
  $w->i_print("><$list_denoter");
  my $i;
  foreach $i (0..$#{ $this->{TL_COMPONENTS} }) {
    my $c = $this->{TL_COMPONENTS}->[$i];

    if ($this->{delimited} and
	! $c->isa("HTML::TableLayout::Component::List")) {
      $w->f_print("><LI");
    }

    $w->_indentIncrement();
    $c->tl_print();
    $w->_indentDecrement();

    ## do this if the component is a list??
    $this->{TL_BREAKS}->[$i] and $w->f_print("><BR");
  }
  $w->i_print("></$list_denoter");
}



1;
