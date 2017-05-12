#! perl

# Csv.pm -- Reporter backend for CSV reports.
# Author          : Johan Vromans
# Created On      : Thu Jan  5 18:47:37 2006
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:39:24 2010
# Update Count    : 16
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Report::Reporter::Csv;

use strict;
use warnings;

use EB;

use base qw(EB::Report::Reporter);

################ API ################

sub start {
    my ($self, @args) = @_;
    $self->SUPER::start(@args);
}

sub finish {
    my ($self) = @_;
    $self->SUPER::finish();
    close($self->{fh});
}

my $sep;

sub add {
    my ($self, $data) = @_;

    my $style = delete($data->{_style});

    $self->SUPER::add($data);

    return unless %$data;

    $sep = $self->{_sep} ||= $cfg->val(qw(csv separator), ",");

    $self->_checkhdr;

    my $line;

    foreach my $col ( @{$self->{_fields}} ) {
	my $fname = $col->{name};
	my $value = defined($data->{$fname}) ? _csv($data->{$fname}) : "";
	$line .= $sep if defined($line);
	$line .= $value;
    }

    print {$self->{fh}} ($line, "\n");
}

################ Pseudo-Internal (used by Base class) ################

sub header {
    my ($self) = @_;
    if ( grep { $_->{title} =~ /\S/ } @{$self->{_fields}} ) {
	print {$self->{fh}} (join($sep,
				  map { _csv($_->{title}||"") }
				  @{$self->{_fields}}), "\n");
    }
}

################ Internal methods ################

sub _csv {
    my ($value) = @_;
    # Quotes must be doubled.
    $value =~ s/"/""/g;
    # Quote if anything non-simple.
    $value = '"' . $value . '"'
      if $value =~ /\s|\Q$sep\E|"/
	|| $value !~ /^[+-]?\d+([.,]\d+)?/;

    return $value;
}

1;
