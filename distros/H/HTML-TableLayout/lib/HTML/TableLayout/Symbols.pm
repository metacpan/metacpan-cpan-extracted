# ====================================================================
# Copyright (C) 1997,1998 Stephen Farrell <stephen@farrell.org>
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# ====================================================================
# File: Symbols.pm
# Author: Stephen Farrell
# Created: August 1997
# Locations: http://www.palefire.org/~sfarrell/TableLayout/
# CVS $Id: Symbols.pm,v 1.16 1998/09/20 21:07:40 sfarrell Exp $
# ====================================================================

package HTML::TableLayout::Symbols;
use Carp;
use Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
	   
	   parameters
	   window
	   win_header
	   table
	   cell
	   cell_header
	   text
	   image
	   link
	   list
	   pre
	   comment
	   script
	   hrule
	   container
	   font
	   
	   _anchor
	   _row
	   _scell
	   
	   form
	   form_base
	   choice
	   button
	   checkbox
	   textarea
	   hidden
	   faux
	   input_text
	   password
	   submit
	   radio
	   
	   $NOTER
	   $OOPSER
	   
	   sum
	   max
	   min
	   params
	   
	  );


##
## magic constructors
##


# :DEFAULT
sub parameters { return HTML::TableLayout::Parameters->new(@_) }
sub window { return HTML::TableLayout::Window->new(@_) }
sub table { return HTML::TableLayout::Table->new(@_) }
sub cell { return HTML::TableLayout::Cell->new(@_) }
sub cell_header { return HTML::TableLayout::CellHeader->new(@_) }
sub win_header { return HTML::TableLayout::WindowHeader->new(@_) }
sub script { return HTML::TableLayout::Script->new(@_) }
sub text { return HTML::TableLayout::Component::Text->new(@_) }
sub image { return HTML::TableLayout::Component::Image->new(@_) }
sub link { return HTML::TableLayout::Component::Link->new(@_) }
sub list { return HTML::TableLayout::Component::List->new(@_) }
sub pre { return HTML::TableLayout::Component::Preformat->new(@_) }
sub comment { return HTML::TableLayout::Component::Comment->new(@_) }
sub hrule { return HTML::TableLayout::Component::HorizontalRule->new(@_) }
sub container { return HTML::TableLayout::ComponentContainer->new(@_) }
sub font { return HTML::TableLayout::Component::Font->new(@_) }

# :FORM
sub form { return HTML::TableLayout::Form->new(@_) }
sub radio { return HTML::TableLayout::FormComponent::Radio->new(@_) }
sub checkbox { return HTML::TableLayout::FormComponent::Checkbox->new(@_) }
sub textarea { return HTML::TableLayout::FormComponent::Textarea->new(@_) }
sub choice { return HTML::TableLayout::FormComponent::Choice->new(@_) }
sub button { return HTML::TableLayout::FormComponent::Button->new(@_) }
sub hidden { return HTML::TableLayout::FormComponent::Hidden->new(@_) }
sub faux { return HTML::TableLayout::FormComponent::Faux->new(@_) }
sub input_text { return HTML::TableLayout::FormComponent::InputText->new(@_) }
sub password { return HTML::TableLayout::FormComponent::Password->new(@_) }
sub submit { return HTML::TableLayout::FormComponent::Submit->new(@_) }


##
## These are callbacks for debugging.  Currently, most calls to the
## NOTER() are removed.  However, the OOPSER() is very much alive.
## The OOPSER can be pretty much any code reference that takes, as
## its first argument, a string explaining what the "oops" was about.
## By default this is warn(full_trace()); croak(@_);, but you may wish
## to override this behavior for your application.  I have a
## database-app that needs to do stuff like rollback the transaction
## if an error occurs, so I have an exception handler mechanism (aka
## "goto") which I use to override this behavior.  Just do
## HTML::TableLayout::Symbols::OOPSER = sub { do_whatever_then_die(@_) };
##
$NOTER = sub { carp(@_,"\n")  };
$OOPSER = sub { warn(full_trace()); croak(@_) };



##
## max();min();sum(): Some package-wide utility functions.
##
sub max { my ($a, $b) = @_; ($a > $b) ? $a : $b };
sub min { my ($a, $b) = @_; ($a < $b) ? $a : $b };
sub sum { my $s=0; foreach (@_) { $s += $_ }; return $s };

##
## params(): Internally I represent HTML parameters as a hash; this
## function transforms that hash into a string as appropriate for HTML
##
sub params {
  my (%params) = @_;
  my ($r, $p);
  foreach $p (keys %params) {
    if ($p =~ /^Anchor/) {	# capitalized=>only compare 1 letter (I hope!)
      $r .= params(HTML::TableLayout::_Anchor->new($params{$p})->value());
    }
    elsif (defined $params{$p}) {
      unless (($p eq "colspan" or $p eq "rowspan") and $params{$p} == 1) {
	$r .= " $p=\"$params{$p}\"";
      }
    }
    else {
      $r .= " $p";
    }
  }
  return $r;
}



##
## full_trace(): This is ripped out of Carp.pm--in fact, it is very
## much like longmess()--I don't just call Carp::longmess (presently)
## b/c it seems to be "private"-ish, so it would seem to be a mistake
## to rely upon its existence.
##
sub full_trace { 
  my $CarpLevel = 0;		# How many extra package levels to skip on carp.
  my $MaxEvalLen = 0;		# How much eval '...text...' to show. 0 = all.
  my $error = shift;
  my $mess = "";
  my $i = 1 + $CarpLevel;
  my ($pack,$file,$line,$sub,$eval,$require);
  while (($pack,$file,$line,$sub,undef,undef,$eval,$require) = caller($i++)) {
    if ($error =~ m/\n$/) {
      $mess .= $error;
    } else {
      if (defined $eval) {
	if ($require) {
	  $sub = "require $eval";
	} else {
	  $eval =~ s/([\\\'])/\\$1/g;
	  if ($MaxEvalLen && length($eval) > $MaxEvalLen) {
	    substr($eval,$MaxEvalLen) = '...';
	  }
	  $sub = "eval '$eval'";
	}
      } elsif ($sub eq '(eval)') {
	$sub = 'eval {...}';
      }
      $mess .= "\t$sub " if $error eq "called";
      $mess .= "$error at $file line $line\n";
    }
    $error = "called";
  }
  $mess || $error;
}


1;
