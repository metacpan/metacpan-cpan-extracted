# Copyright 2009, 2011 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.


use 5.005;
use strict;
use File::Spec;
use ExtUtils::Manifest;

package MyPodParser;
use strict;
use Carp;
use FindBin;
use base 'Pod::Parser';

use constant DEBUG => 0;

# return arrayref of field or symbol names found in the pod
sub fields_found {
  my ($self) = @_;
  return $self->{'fields'} || croak "No fields found";
}
sub symbols_found {
  my ($self) = @_;
  return $self->{'symbols'} || croak "No symbols found";
}

sub command {
  my ($self, $command, $text, $line_num, $pod_para) = @_;
  if (DEBUG) { print "$command -- $text"; }

  if ($command eq 'for' && $text =~ /^\s*Finance_Quote_Grab\s+(.*)/) {
    (my @args = split /\s+/, $1)
      or die "Oops, expected thing after $text";
    my $thing = shift @args;
    if (@args) {
      my $method = "command_$thing";
      $self->$method (@args);
    } else {
      $self->{'next_thing'} = $thing;
    }
  }
}
sub command_fields {
  my ($self, $format, @symbols) = @_;
  $self->{'next_thing'} = 'fields';
  $self->{'fields_format'} = $format;
}
sub command_symbols {
  my ($self, @symbols) = @_;
  push @{$self->{'symbols'}}, @symbols;
}

sub verbatim {
  my ($self, $text, $line_num, $pod_para) = @_;
  if (my $thing = delete $self->{'next_thing'}) {
    my $flavour = $self->{'next_flavour'} || '';
    my $method = "verbatim_$thing" . ($flavour && "_$flavour");
    if (DEBUG) { print "verbatim() $thing $flavour -- $method -- $text\n"; }
    $self->$method ($text);
  }
}
sub verbatim_fields {
  my ($self, $text) = @_;
  my @fields;
  if ($self->{'fields_format'} eq 'flowed') {
    $text =~ s/^\s+//;
    @fields = split /\s+/, $text;
  } else {
    $text =~ s{^\s*(\w+)}{push @fields, $1}mge;
  }
  @fields or die "Oops, no fields recognised -- $text";
  push @{$self->{'fields'}}, @fields;
}
sub verbatim_symbols {
  my ($self, $text) = @_;
  (my @symbols = map {_trim_whitespace($_)} split /\n/, $text)
    or die "Oops, no symbols recognised -- $text";
  push @{$self->{'symbols'}}, @symbols;
}

sub textblock {
  my ($self) = @_;
  if (my $thing = delete $self->{'next_thing'}) {
    croak "Oops, expected verbatim paragraph after =for Finance_Quote_Grab";
  }
}

sub _trim_whitespace {
  my ($str) = @_;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

1;
__END__

