# Hey emacs, this is -*-perl-*- !
#
# $Source: /home/cmdjb/develop/perl/Metadata/lib/Metadata/RCS/IAFA.pm,v $
#
# $Id: IAFA.pm,v 1.10 2001/01/09 12:07:26 cmdjb Exp $
#
# Metadata::IAFA - IAFA templates class
#
# Copyright (C) 1997-1998 Dave Beckett.  All rights reserved.
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package Metadata::IAFA;

require 5.004;

use strict;
use vars qw(@ISA $VERSION $Debug %Default_Options
	    $HEADER_TEMPLATE_TYPE $FOOTER_TEMPLATE_TYPE);

use Carp;

use Metadata::Base;

@ISA     = qw( Metadata::Base );
$VERSION = sprintf("%d.%02d", ('$Revision: 1.10 $ ' =~ /\$Revision:\s+(\d+)\.(\d+)/));

%Default_Options=(
  TEMPLATE_TYPE => 'DOCUMENT',
  STRICT => '0',
  DEBUG => '0',
  WRAP => '0',
);

$HEADER_TEMPLATE_TYPE = 'X-AFA-HEADER';
$FOOTER_TEMPLATE_TYPE = 'X-AFA-FOOTER';


# Class debugging
$Debug = 0;

sub debug { 
  my $self=shift;
  # Object debug - have an object reference
  if (ref ($self)) { 
    my $old=$self->{DEBUG};
    $self->{DEBUG}=@_ ? shift : 1;
    $self->SUPER::debug($self->{DEBUG});
    return $old;
  }

  # Class debug (self is debug level)
  return $Debug if !defined $self; # Careful, could be debug(0)

  my $old=$Debug;
  $Default_Options{DEBUG}=$Debug=$self;
  Metadata::Base::debug($Debug);
  $old;
}

sub whowasi { (caller(1))[3] }


# Constructor
sub new {
  my $proto =shift;
  my $class = ref($proto) || $proto;
  my $options= { @_ };
  $options->{ORDERED}=1;
  for (keys %Default_Options) {
    $options->{$_}=$Default_Options{$_} unless defined $options->{$_};
  }

  my $self = $class->SUPER::new($options);
  bless $self, $class;
  return $self;
}


# Clone
sub clone ($) {
  my $self=shift;

  my $copy = $self->SUPER::clone;

  $copy->{TEMPLATE_TYPE}= $self->{TEMPLATE_TYPE};

  $copy;
}


sub template_type ($;$) {
  my $self=shift;
  return $self->{TEMPLATE_TYPE} if !@_;

  my $old=$self->{TEMPLATE_TYPE};
  $self->{TEMPLATE_TYPE}=shift;
  $old;
}


# Set the given element, value and index?
sub validate ($$$;$) {
  my($self, $element, $value, $index)=@_;
  warn "@{[&whowasi]}: Field: $element Value: ", (defined $value) ? $value : "(undefined)", " Index:",(defined $index) ? $index : "(undefined)", "\n" if $self->{DEBUG};
  if ($element eq 'Template-Type') {
    $self->{TEMPLATE_TYPE}=$value;
    return;
  }
  $index=$1 if $element =~ s/-v(\d+)$//;
  return ($element, $value, $index);
}


# Check the legality of the given element and index
sub validate_elements ($$;$) {
  my($self, $element, $index)=@_;
  warn "@{[&whowasi]}: Field: $element Index:", (defined $index) ? $index : "(undefined)", "\n" if $self->{DEBUG};
  
  $index=$1 if $element =~ s/-v(\d+)$//;
  return ($element, $index);
}


sub read ($$) {
  my $self = shift;
  my $fh=shift;

  $self->clear;

  return undef if eof($fh);

  my $element='';
  my $value='';
  my $count=0;
  while(<$fh>) {
    chomp;
    if (/^([-#\w]+):\s*(.*)$/) {
      my($new_attr,$new_value)=($1,$2);
      $self->set($element, $value) and $count++ if $element;
      $count++;
      $element=$new_attr; $value=$new_value;
    } elsif (/^\s+(.*)$/) { # Allow leading whitespace to continue line
      my $bit=$1;

      # Strictly...
      last if $self->{STRICT} && !$bit; # end on a blank line too

      # A continuation line, so what about that white space?
      if ($value) {
	if ($self->{STRICT}) {
	  # strict - remove in URI elements, otherwise collapse to ' '
	  if ($element !~ /URI$/) {
	    $value .= ' ';
	  }
	} else {
	  # lax - preserve the newline, who cares?
	  $value.="\n";
	}
      }

      $value.=$bit;
    } elsif (!$_) {
      last;
    } else {
      warn "IAFA::read:$.: Do not understand line '$_'\n";
    }
  }
  
  $self->set($element, $value) and $count++ if $element;
  warn "@{[&whowasi]}: Read $count elements\n" if $self->{DEBUG};
  return 1;
}


sub format ($) {
  require 'Text/Wrap.pm';

  my $self=shift;
  my $string="Template-Type: $self->{TEMPLATE_TYPE}\n";
  for my $element ($self->order) {
    my $variants=$self->size($element);
    my $variant=0;
    for my $value ($self->get($element)) {
      next unless defined $value;
      chomp $value;
      if ($self->{STRICT}) {
        $value =~ s/\s+/ /g;
      } else {
        $value =~ s/\n/\n\t/g;
      }
      my $bit=($variants>1) ? "$element-v$variant: $value\n" : "$element: $value\n";
      if ($self->{STRICT} || $self->{WRAP}) {
	$bit=Text::Wrap::wrap("\t", "\t", $bit);
      }

      $string.=$bit;
    } continue {
      $variant++;
    }
  }
  $string;
}


sub pack ($) {
  my $self=shift;
  my $string=$self->SUPER::pack;

  # Use the knowledge that a field called Template-Type automagically becomes
  # a Template Type, not a regular field (via validate method).
  # Also depend on Metadata::Base using 'thing\0'  too.
  $string="Template-Type\0$self->{TEMPLATE_TYPE}\0".$string;

  $string;
}

# Base version is fine
# sub unpack


sub get_date_as_seconds ($$) {
  my($self,$element)=@_;

  my $value=$self->get($element);

  unless ($self->{STRICT}) {
    return $value if $value =~ /^\d+$/;

    if (my($year,$month,$day)=($value=~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/)) {
      require 'Time/Local.pm';

      return Time::Local::timegm(0,0,0,$day,$month-1,$year-1900);
    }
  }

  require 'Date/Parse.pm';

  return Date::Parse::str2time($value);
}


sub set_date_as_seconds ($$$) {
  my($self,$element,$value)=@_;

  if ($self->{STRICT}) {
    require 'Date/Format.pm';

    # RFC           Dow, day month year HH:MM TZ
    $value=Date::Format::time2str("%a, %d %b %Y %T %z", $value);
  }

  $self->set($element, $value);
}


sub decode_uri_element ($) {
  my($uri)=@_;

  return (undef,undef,undef) if !defined($uri);

  my($path,$remotepath);
  if ($uri =~ /^(.+)\s+->\s+(.+)$/) {
    ($path,$remotepath)=($1,$2);
  } else {
    $path=$uri; $remotepath='';
  }
  my($basepath)='';
  # URL: <word>://host/...
  if ($path=~ m%^\w+://.+%) {
    $basepath=$path; $remotepath=$path; $path=''; 
  # Relative URL: /path/file
  } elsif ($path=~ m%/([^/]+)$%) {
    $basepath=$1;
  # File: file
  } elsif ($path !~ m%/%) {
    $basepath=$path;
  }

  return ($basepath, $path, $remotepath);
}


sub encode_uri_element ($;$) {
  my($path, $remotepath)=@_;

  return $remotepath ? "$path -> $remotepath" : $path;
}


sub order_template_type ($) {
  my($type)=@_;
  
  return 0 if $type eq $HEADER_TEMPLATE_TYPE;
  return 2 if $type eq $FOOTER_TEMPLATE_TYPE;

  return 1;

}



1;
__END__

=head1 NAME

Metadata::IAFA - IAFA Template metadata class

=head1 SYNOPSIS

  use Metadata::IAFA
  ...
  $i=new Metadata::IAFA;
  $i->set('element1', [qw(v1 v2 v3)]);
  $i->set('element2', 'v2');

  my $val=$i->get('element2);
  for my $v ($i->get('element1') {
    ...
  }
  ...

=head1 DESCRIPTION

The Metadata::IAFA class supports IAFA Templates metadata using the
L<Metadata::Base> class and customises it for IAFA Templates where
element names have I<variants> to represent to sub-values.

=head1 CONSTRUCTOR

=over 4

=item new [OPTIONS]

An optional hash of options can be given to the constructor to set
various options.  There are currently three I<Metadata::IAFA>
options defined:

=over 6

=item I<STRICT>

This is defined to turn on strict interpretation of
the draft IAFA Templates standard.  See the B<read> method for what
this implies.

=item I<TEMPLATE_TYPE>

Set the template type for this IAFA Template (default is DOCUMENT).
The alternate ways to set this are via the B<template_type> or B<set>
methods.

=item I<DEBUG>

This class has a separate B<debug> class / object method that works
in the same fashion as the I<Metadata::Base> method B<debug>.
Setting it here also sets the debugging on the base I<Metadata::Base>
object too.

=item I<WRAP>

When formatting the metadata for output, word wrap the results so that
they fit into 80-columns.  This is done using the I<Text::Wrap> class.

=back

=head1 METHODS

The methods here describe the differences from the L<Metadata::Base> class
methods.

=over 4

=item set ELEMENT, VALUE, [INDEX]

=item get ELEMENT, [INDEX]

=item exists ELEMENT, [INDEX]

These methods work in the same way as the B<Metadata::Base::set> methods
except that I<ELEMENT> can contain the I<variant> if it is of the form:
I<ELEMENT>-I<INDEX> where I<INDEX> is a decimal number.

=item template_type [TEMPLATE-TYPE]

The Template-Type of the metadata can be set by the B<set> method but it
is stored separately from the regular elements and can only be retrieved
from using this method when it is called with no arguments.

=item read HANDLE

Implements reading a single IAFA Template from the given I<HANDLE>.
This is done in a generous style (different from the draft standard),
rather than ending the template on a blank line, uses empty lines and
thus allows element values to contain multiple paragraphs separated by
entirely white space lines.

=item format

Returns a formatted version of the IAFA Template suitable for writing
to a file (and reading in with the B<read> method).

=item get_date_as_seconds ELEMENT

This handles the strict IAFA format as well as a format of YYYY-MM-DD
and a raw decimal number-of-seconds.

=item decode_uri_element VALUE

Return a list of three elements from decoding the I<VALUE> as a URI
element: the base file name, the full path and the destination path (if
a symlink).  If the URI is just a plain URI, the full path will be
empty.

=item encode_uri_element URI
=item encode_uri_element FILE, PATH

Return an encoding for either a I<URI> or a local I<FILE> and its
remote I<PATH> (symlink).

=item order_template_type TEMPLATE-TYPE

Return an ordering of the I<TEMPLATE-TYPE> suitable for B<sort>.

=back 4

=head1 SEE ALSO

L<Metadata::Base>, L<Text::Wrap>

=head1 AUTHOR

By Dave Beckett - http://purl.org/net/dajobe/

=head1 COPYRIGHT

Copyright (C) 1997-2001 Dave Beckett - http://purl.org/net/dajobe/
All rights reserved.

=cut

