# Hey emacs, this is -*-perl-*- !
#
# $Id: SOIF.pm,v 1.10 2001/01/09 12:04:12 cmdjb Exp $
#
# Metadata::SOIF - Harvest Structured Objects Interchange Format class
#
# Copyright (C) 1997-2001 Dave Beckett - http://purl.org/net/dajobe/
# All rights reserved.
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package Metadata::SOIF;

require 5.004;

use strict;
use vars qw(@ISA $VERSION $Debug %Default_Options);

use Carp;

use Metadata::Base;

@ISA     = qw( Metadata::Base );
$VERSION = sprintf("%d.%02d", ('$Revision: 1.10 $ ' =~ /\$Revision:\s+(\d+)\.(\d+)/));

%Default_Options=(
  TEMPLATE_TYPE => 'FILE',
  URL => '',
  SPLIT => '0',
  DEBUG => '0',
);


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
  $copy->{URL}= $self->{URL};

  $copy;
}


sub template_type ($;$) {
  my $self=shift;
  return $self->{TEMPLATE_TYPE} if !@_;

  my $old=$self->{TEMPLATE_TYPE};
  $self->{TEMPLATE_TYPE}=shift;
  $old;
}


sub url ($;$) {
  my $self=shift;
  return $self->{URL} if !@_;

  my $old=$self->{URL};
  $self->{URL}=shift;
  $old;
}


sub read ($$;$) {
  my $self = shift;
  my $fh=shift;

  $self->clear;

  return undef if eof($fh);

  my $seen_url=0;
  $self->url(shift) and $seen_url=1 if @_;

  my $count=0;
  while(<$fh>) {
    warn "@{[&whowasi]}: Read line: '$_'\n" if $self->{DEBUG};
    if (/^\}/) {
      last;
    } elsif (my($template_type,$url)=/^\@\s*(\S+)\s*\{\s*(\S+)\s*$/o) {
      warn "@{[&whowasi]}: Read Template Type '$template_type' URL '$url'\n" if $self->{DEBUG};
      $self->template_type($template_type);
      $self->url($url) and $seen_url=1 unless $seen_url;
    } elsif (my($element,$rest_length,$value)=/^\s*([^{]+)\{(\d+)\}:\t(.*)$/so) {
      my $value_length=length($value)-1;  # -1 off for for NL, removed below
      $value_length=0 if $value_length<0; # however handle 0 length value
      $rest_length-= $value_length;
      if ($rest_length>0) {
	$value_length++; # Append after newline
        my $read_length=read($fh,$value,$rest_length, $value_length);
        croak "Cannot read $rest_length bytes (read $read_length) - $!\n"
	  if $read_length != $rest_length;
      }
      chomp $value; # extra newline removed here
      # Split values on newlines into sub-values, maybe
      my(@v);
      if ($self->{SPLIT} && ((@v)=split(/\n/, $value)) > 1) {
        $self->set($element, \@v);
      } else {
        $self->set($element, $value);
      }
      $count++;
    } else {
      warn "@{[&whowasi]}:$.: Do not understand line '$_'\n";
    }
  }
  
  warn "@{[&whowasi]}: Read $count elements\n" if $self->{DEBUG};
  return 1;
}


sub format ($;$) {
  my $self=shift;
  $self->url(shift) if @_;

  my $url=$self->url;
  my $string="\@$self->{TEMPLATE_TYPE} {";
  $string.= $url ? " $url\n" : "\n";
  for my $element ($self->order) {
    my $value=join("\n",grep (defined $_, $self->get($element) ));
    $string.="$element\{".length($value)."\}:\t".$value."\n";
  }
  return $string."}\n";
}


# Pack Template Type and URL too
sub pack ($) {
  my $self=shift;
  my $string=$self->SUPER::pack;

  # Use the knowledge that Metadata::Base uses 'thing\0' for fields
  return join("\001", $self->{TEMPLATE_TYPE}, $self->{URL}, $string);
}


sub unpack ($$) {
  my $self=shift;
  my($tt,$url,$string)=split(/\001/, shift);
  $self->SUPER::unpack($string);
  $self->{TEMPLATE_TYPE}=$tt;
  $self->{URL}=$url;
}


1;
__END__

=head1 NAME

Metadata::SOIF - SOIF object metadata class

=head1 SYNOPSIS

  use Metadata::SOIF
  ...
  $i=new Metadata::SOIF;
  $i->set('element1', [qw(v1 v2 v3)]);
  $i->set('element2', 'v2');

  my $val=$i->get('element2);
  for my $v ($i->get('element1') {
    ...
  }
  ...

=head1 DESCRIPTION

The Metadata::SOIF class supports SOIF objects metadata using the
L<Metadata::Base> class and customises it for SOIF objects where
element names have I<variants> to represent to sub-values.

SOIF was developed by the Harvest project -- the Structured Objects
Interchange Format -- to be used for distributed resource discovery.
See the Harvest Project home page at http://harvest.transarc.com/ for
more details.


=head1 CONSTRUCTOR

=over 4

=item new [OPTIONS]

An optional hash of options can be given to the constructor to set
various options.  There are currently two I<Metadata::SOIF>
options defined:

=over 6

=item I<DEBUG>

This class has a separate I<debug> class / object method that works
in the same fashion as the I<Metadata::Base> method B<debug>.
Setting it here also sets the debugging on the base I<Metadata::Base>
object too.

=item I<SPLIT>

In the B<read> method, split the SOIF values on newlines to give multiple
subvalues (default off).

=back

=head1 METHODS

The methods here describe the differences from the L<Metadata::Base> class
methods.

=over 4

=item template_type [TEMPLATE TYPE]

The template type of the metadata can be set by this method if an
I<TEMPLATE TYPE> is given.  The old value is returned when it is set or
returned when this method is called with no arguments.

=item url [URL]

The URL of the metadata can be set by this method if an I<URL> is given.
The old value is returned when it is set or returned
when this method is called with no arguments.

=item read HANDLE, [URL]

Implements reading a single SOIF object from the given I<HANDLE>.
Optionally allows the setting of the SOIF I<URL> for the object in
preference for the one read from the I<HANDLE>

=item format [URL]

Returns a formatted version of the SOIF object suitable for writing
to a file (and reading in with the B<read> method).  Optionally allows
the setting of the object I<URL> to use in formatting.

=back 4

=head1 SEE ALSO

L<Metadata::Base>

=head1 AUTHOR

By Dave Beckett E<lt>I<D.J.Beckett@ukc.ac.uk>E<gt>.

=head1 COPYRIGHT

Copyright 1997 Dave Beckett.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

