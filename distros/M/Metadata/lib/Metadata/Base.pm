# Hey emacs, this is -*-perl-*- !
#
# $Id: Base.pm,v 1.10 2001/01/09 12:04:12 cmdjb Exp $
#
# Metadata::Base - base class for metadata
#
# Copyright (C) 1997-2001 Dave Beckett - http://purl.org/net/dajobe/
# All rights reserved.
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package Metadata::Base;

require 5.004;

use strict;
use vars qw($VERSION $Debug);

use Carp;

$VERSION = sprintf("%d.%02d", ('$Revision: 1.10 $ ' =~ /\$Revision:\s+(\d+)\.(\d+)/));


# Class debugging
$Debug = 0;

sub debug { 
  my $self=shift;
  # Object debug - have an object reference
  if (ref ($self)) {
    my $old=$self->{DEBUG};
    $self->{DEBUG}=@_ ? shift : 1;
    return $old;
  }

  # Class debug (self is debug level)
  return $Debug if !defined $self; # Careful, could be debug(0)

  my $old=$Debug;
  $Debug=$self;
  $old;
}

sub whowasi { (caller(1))[3] }


# Constructor
sub new ($%) {
  my ($type,$self)=@_;
  $self = {} unless defined $self;

  my $class = ref($type) || $type;
  bless $self, $class;

  $self->{DEBUG}=$Debug unless defined $self->{DEBUG};

  $self->{DEFAULT_OPTIONS}={ %$self };

  # Create empty order if needed
  $self->{ORDER}=[] if $self->{ORDERED};

  $self->{ELEMENTS}={};
  $self->{ELEMENTS_COUNT}=0;

  warn "@{[&whowasi]}\n" if $self->{DEBUG};

  $self;
}


# Clone
sub clone ($) {
  my $self=shift;

  my $copy=new ref($self);

  my(@order)=$self->{ORDERED} ? @{$self->{ORDER}} : keys %{$self->{ELEMENTS}};
  for my $element (@order) {
    my(@values)=$self->get($element);
    $copy->set($element, [ @values ]);
  }

  $copy->{DEBUG}=$self->{DEBUG};
  $copy->{DEFAULT_OPTIONS}={ %{$self->{DEFAULT_OPTIONS}} };

  $copy;
}


sub set ($$$;$) {
  my $self=shift;
  return $self->_set('set',@_);
}


sub add ($$$;$) {
  my $self=shift;
  return $self->_set('add',@_);
}


sub _set ($$$$;$) {
  my $self=shift;
  my $operation=shift;

  my($element,$value,$index)=$self->validate(@_);
  return if !defined $element;

  if (!defined $self->{ELEMENTS}->{$element}) {
    # Update order
    push(@{$self->{ORDER}}, $element) if $self->{ORDERED};
    $self->{ELEMENTS_COUNT}++;
    warn "@{[&whowasi]} Adding new element $element\n" if $self->{DEBUG};
  }

  if (ref($value)) {  # Assuming eq 'ARRAY'
    $self->{ELEMENTS}->{$element}=[ @$value ];
    warn "@{[&whowasi]} Set $element to values @$value\n" if $self->{DEBUG};
  } else {
    if (defined $index) {
      # Set new value at a particular index
      $self->{ELEMENTS}->{$element}->[$index]=$value;
    } else {
      if ($operation eq 'add') {
	# Append value to end of list
	push(@{$self->{ELEMENTS}->{$element}}, $value);
	$index=@{$self->{ELEMENTS}->{$element}} - 1;
      } else {
	$index='(all)';
	$self->{ELEMENTS}->{$element}=[ $value ];
      }
    }
    warn "@{[&whowasi]} Set $element subvalue $index to value $value\n" if $self->{DEBUG};
  }
}


sub get ($$;$) {
  my $self=shift;
  my($element,$index)=@_;
  warn "@{[&whowasi]} Get $element subvalue ", (defined $index) ? $index : "(undefined)","\n" if $self->{DEBUG};
  ($element,$index)=$self->validate_elements($element,$index);
  return if !defined $element;

  warn "@{[&whowasi]} After validate, element $element subvalue ", (defined $index) ? $index : "(undefined)", "\n" if $self->{DEBUG};

  my $value=$self->{ELEMENTS}->{$element};
  return if !defined $value;

  if (defined $index) {
    return $value->[$index];
  } else {
    return wantarray ? @$value : join(' ', grep (defined $_, @$value));
  }
}


sub delete ($$;$) {
  my $self=shift;
  my($element,$index)=@_;
  warn "@{[&whowasi]} element $element subvalue ", (defined $index) ? $index : "(undefined)","\n" if $self->{DEBUG};
  ($element,$index)=$self->validate_elements($element,$index);
  return if !defined $element;

  warn "@{[&whowasi]} After validate, element $element subvalue ", (defined $index) ? $index : "(undefined)", "\n" if $self->{DEBUG};

  my $value=$self->{ELEMENTS}->{$element};
  return if !defined $value;

  my(@old)=@{$value};
  if (defined $index) {
    undef $value->[$index];
    # Are all element subvalues missing / undefined?  If so, then
    # allow code below to delete entire element.
    $index=undef if !grep (defined $_, @{$self->{ELEMENTS}->{$element}});
  }

  if (!defined $index) {
    undef @{$self->{ELEMENTS}->{$element}};
    delete $self->{ELEMENTS}->{$element};
    $self->{ELEMENTS_COUNT}--;
    if ($self->{ORDERED}) {
      @{$self->{ORDER}} = grep ($_ ne $element, @{$self->{ORDER}});
    }
  }
  return(@old);
}


sub exists ($$;$) {
  my $self=shift;
  my($element,$index)=$self->validate_elements(@_);

  return if !exists $self->{ELEMENTS}->{$element};
  return 1 if !defined $index;
  # Trying to find sub-element
  return $self->{ELEMENTS}->{$element}->[$index];
}


sub size ($;$) {
  my $self=shift;
  my $element=shift;

  return $self->{ELEMENTS_COUNT} if !defined $element;

  return if !exists $self->{ELEMENTS}->{$element};

  my $value=$self->{ELEMENTS}->{$element};
  return scalar(@$value);
}


sub elements ($) {
  my $self=shift;
  return @{$self->{ORDER}} if $self->{ORDERED};
  return keys %{$self->{ELEMENTS}};
}


# Old name
sub fields ($) {
  sub fields_warn { warn Carp::longmess @_; }
  fields_warn "Depreciated method called\n";
  return shift->elements;
}


sub order ($;@) {
  my $self=shift;
  return unless $self->{ORDERED};

  return @{$self->{ORDER}} if !@_;

  my(@old_order)=@{$self->{ORDER}} if defined wantarray;
  $self->{ORDER}=[@_];

  return @old_order if defined wantarray;
}


# Set the given element, value and index?
sub validate ($$$;$) {
  my $self=shift;
  # Not used here
  #my($self, $element, $value, $index)=@_;
  return @_;
}


# Check the legality of the given element and index
sub validate_elements ($$;$) {
  my $self=shift;
  # Not used here
  #my($self, $element, $value, $index)=@_;
  return @_;
}


# Return a native-formatted version of this metadata
sub format ($) {
  my $self=shift;
  my $string=$self->{ELEMENTS_COUNT}." elements\n";
  my(@order)=$self->{ORDERED} ? @{$self->{ORDER}} : keys %{$self->{ELEMENTS}};
  $string.="Order: @order\n" if $self->{ORDERED};
  for my $element (@order) {
    for my $value ($self->get($element)) {
      $string.="$element: $value\n";
    }
  }
  $string;
}


# Probably possible to do this using symbol table references
sub as_string ($) { shift->format; }


# Pack the metadata as small as possible - binary OK and preferred
sub pack ($) {
  my $self=shift;
  my(@order)=$self->{ORDERED} ? @{$self->{ORDER}} : keys %{$self->{ELEMENTS}};
  my $string='';
  for my $element (@order) {
    for my $value ($self->get($element)) {
      $value='' if !defined $value;
      $string.="$element\0$value\0";
    }
  }
  $string;
}


# Read the packed format and restore the same metadata state
sub unpack ($$) {
  my $self=shift;
  my $value=shift;

  return if !defined $value;

  $self->clear;
  my(@vals)=(split(/\0/,$value));
  while(@vals) {
    my($element,$value)=splice(@vals,0,2);
    $self->add($element,$value);
  }

  1;
}


sub read ($) {
  confess "Not implemented in base class\n";
}


sub write ($$) {
  my $self=shift;
  my $fd=shift;
  print $fd $self->format;  
}


sub reset ($) {
  my $self=shift;

  my $default_options=$self->{DEFAULT_OPTIONS};
  while(my($attr,$value)=each %$default_options) {
    $self->{$attr}=$value;
  }

  $self->clear;
}


sub clear ($) {
  my $self=shift;

  $self->{ELEMENTS}={};
  $self->{ELEMENTS_COUNT}=0;

  # Empty order if needed
  $self->{ORDER}=[] if $self->{ORDERED};
}


sub get_date_as_seconds ($$) {
  my $self=shift;
  iso8601_to_seconds($self->get(shift));
}


sub set_date_as_seconds ($$$) {
  my $self=shift;
  my($element,$value)=shift;
  $self->set($element, seconds_to_iso8601($value));
}


sub get_date_as_iso8601 ($$) {
  my $self=shift;
  $self->get(shift);
}


sub set_date_as_iso8601 ($$$) {
  my $self=shift;
  $self->set(@_);
}


sub seconds_to_iso8601 ($) {
  my($ss,$mm,$hh,$day,$month,$year)=gmtime(shift);
  sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
	  $year+1900, $month+1,$day,$hh,$mm,$ss);
}


sub iso8601_to_seconds ($) {
  my $value=shift;
  my($year,$month,$day,$hh,$mm,$ss,$tz)= ($value =~ m{
     ^
     (\d\d\d\d) (?:                          # year YYYY required
       - (\d\d) (?:                          # month -MM optional 
           - (\d\d) (?:                      # day -DD optional
               T (\d\d) : (\d\d) (?:         # time 'T'HH:MM optional
                 (?: : (\d\d (?: \.\d+)?) )? # :SS :SS.frac opt. followed by
                 (Z | (?: [+-]\d+:\d+))      # 'Z' | +/-HH:MM timezone
               )? # optional TZ/SS/SS+TZ
            )? # optional THH:MM ..
       )? # optional -DD...
     )? # optional -MM...
     $
  }x);

  return if !defined $year;

  # Round to start of year, month, etc. since it is too difficult to round
  # to the end (leap years).
  # Really it should return two values for the start & end of period
  # - maybe in V2.0
  $month ||=1; $day ||=1; $hh ||=0; $mm ||=0; $ss ||=0; $tz ||='Z';

  $tz='' if $tz eq 'Z';

  require 'Time/Local.pm';
  
  $value=Time::Local::timegm(int($ss),$mm,$hh,$day,$month-1,$year-1900);

  if ($tz =~ /^(.)(\d+):(\d+)$/) {
    my $s=(($2*60)+$3)*60;
    $value= ($1 eq '+') ? $value+$s : $value-$s;
  }
  if ($ss=~ /(\.\d+)$/) {
    $value.= $1; # Note string concatenation
  }
  $value;
}



1;

__END__

=head1 NAME

Metadata::Base - base class for metadata

=head1 SYNOPSIS

  package Metadata::FOO

  use vars(@ISA);
  ...
  @ISA=qw(Metadata::Base);
  ...

=head1 DESCRIPTION

Metadata:Base class - the core functionality for handling metadata.

=head1 CONSTRUCTOR

=over 4

=item new [OPTIONS]

Create a new Metadata object with an optional hash of options to describe
the metadata characteristics.  Currently only the following can be set:

=over 4

=item DEBUG

Set if debugging should be enabled from creation.  This can also be
set and read by the B<debug> method below.  If this is not defined,
it is set to the current class debugging state which can be read from
the class method L<debug> described below.

=item ORDERED

Set if the metadata elements are ordered

=back

=head1 COPY CONSTRUCTOR

=over 4

=item clone

Create a new identical Metadata object from this one.

=back

=head1 CLASS METHODS

=over 4

=item debug [VALUE]

If I<VALUE> is given, sets the debugging state of this class and
returns the old state.  Otherwise returns the current debugging
state.

=item seconds_to_iso8601 SECONDS

Convert the I<SECONDS> value to (subset of) ISO-8601 format
YYYY-MM-DDThh:mm:SSZ representing the GMT/UTC value.

=item iso8601_to_seconds VALUE

Convert 6 ISO-8601 subset formats to a seconds value.  The 6 formats
are those proposed for the Dublin Core date use:

   YYYY
   YYYY-MM
   YYYY-MM-DD
   YYYY-MM-DDThh:mm
   YYYY-MM-DDThh:mm:ssTZ
   YYYY-MM-DDThh:mm:ss.ssTZ

where TZ can be 'Z', +hh:mm or -hh:mm

B<NOTE>: This method rounds towards the start of the period (it
should really return two values for start and end).

=back

=head1 METHODS

=over 4

=item debug [VALUE]

If I<VALUE> is given, sets the debugging state of this object and
returns the old state.  Otherwise returns the current debugging
state.  The default debugging state is determined by the class debug
state.

=item set ELEMENT, VALUE, [INDEX]

Set element I<ELEMENT> to I<VALUE>.  If I<VALUE> is an array
reference, the existing array is used to as all the existing
sub-values.  Otherwise if I<INDEX> is given, sets the particular
sub-value of I<ELEMENT>, otherwise appends to the end of the existing
list of sub-values for I<ELEMENT>.

=item get ELEMENT, [INDEX]

Return the contents of the given I<ELEMENT>.  In an array context
returns the sub-values as an array, in a scalar context they are all
returned separated by spaces. If I<INDEX> is given, returns the value
of the given sub-value.

=item delete ELEMENT, [INDEX}

Delete the given I<ELEMENT>.  If an I<INDEX> is given, remove just
that sub-value.

=item exists ELEMENT, [INDEX]

Returns a defined value if the given I<ELEMENT> and/or sub-value
I<INDEX> exists.

=item size [ELEMENT]

Returns number of elements with no argument or the number of subvalues
for the given I<ELEMENT> or undef if I<ELEMENT> does not exist.

=item elements

Return a list of the elements (in the correct order if there is one).

=item order [ORDER]

If I<ORDER> is given, sets that as the order of the elements and returns
the old order list.  Otherwise, returns the current order of the
elements.  If the elements are not ordered, returns undef.

=item validate ELEMENT, VALUE, [INDEX]

This method is intended to be overriden by subclasses.  It is called
when a element value is being set.  The method should return either a
list of I<ELEMENT>, I<VALUE> and I<INDEX> values to use or an undefined value
in which case no element will be set.

=item validate_elements ELEMENT, [INDEX]

This method is intended to be overriden by subclasses.  It is called
when a element and/or index is being read.  The method should return
a list of I<ELEMENT> and I<INDEX> values to use.

=item as_string
=item format

Returns a string representing the metadata, suitable for storing (in
a text file).  This is different from the B<pack> method because this
value is meant to be the native encoding format of the metadata,
usually human readable, wheras B<pack> uses the minimum space.

=item pack

Return a packed string representing the metadata format.  This can be
used with B<unpack> to restore the values.

=item unpack VALUE

Initialise the metadata from the packed I<VALUE> which must be the
value made by the B<pack> method.

=item read HANDLE

Reads from the given file handle and initialises the metadata elements.
Returns undef if end of file is seen.

=item write HANDLE

Write to the given file handle a formatted version of this metadata
format.  Likely to use B<format> in most implementations.

=item reset

Reset the metadata object to the default ones (including any passed
with the constructor) and then do a I<clear>.

=item clear

Remove any stored elements in this metadata object.  This can be used
in conjuction with I<read> to prevent the overhead of many I<new>
operations when reading metadata objects from files.

=item get_date_as_seconds ELEMENT

Assuming I<ELEMENT> is stored in a date format, returns the number of
seconds since 1st January 1970.

=item set_date_as_seconds ELEMENT, VALUE

Set I<ELEMENT> encoded as a date corresponding to I<VALUE> which is the
number of seconds since 1st January 1970.

=back

=head1 AUTHOR

By Dave Beckett - http://purl.org/net/dajobe/

=head1 COPYRIGHT

Copyright (C) 1997-2001 Dave Beckett - http://purl.org/net/dajobe/
All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
