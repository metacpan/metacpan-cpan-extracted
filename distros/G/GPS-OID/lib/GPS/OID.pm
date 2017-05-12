package GPS::OID;
use strict;
use warnings;

our $VERSION = '0.07';

=head1 NAME

GPS::OID - Package for GPS PRN - Object ID conversions.

=head1 SYNOPSIS

  use GPS::OID;
  my $obj = GPS::OID->new();
  print "PRN: ", $obj->prn_oid(22231), "\n";
  print "OID: ", $obj->oid_prn(1), "\n";

=head1 DESCRIPTION

This module maps GPS PRN number to Satellite OID and vice versa.

=head2 Object Identification Number (OID)

The catalog number assigned to the object by the US Air Force. The numbers are assigned sequentially as objects are cataloged. This is the most common way to search for TLE data on this site.

Object numbers less then 10000 are always aligned to the right, and padded with zeros or spaces to the left.

=head2 Pseudo Random Numbers (PRNs)

GPS satellites are identified by the receiver by means of PRN-numbers. Real GPS satellites are numbered from 1 - 32. WAAS/EGNOS satellites and other pseudolites are assigned higher numbers.  The PRN-numbers of the satellites appear on the satellite view screens of many GPS receivers.

=head1 CONVENTIONS

Function naming convention is "format of the return" underscore "format of the parameters."

=head1 CONSTRUCTOR

=head2 new

The new() constructor

  my $obj = GPS::OID->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
}

=head2 prn_oid 

PRN given Object ID.

  my $prn=prn_oid(22231);

=cut

sub prn_oid {
  my $self=shift();
  my $param=int(shift());
  my $data=$self->data;
  return $data->{$param};
}

=head2 oid_prn

Object ID given PRN.

  my $oid=oid_prn(1);

=cut

sub oid_prn {
  my $self=shift();
  my $param=int(shift());
  my $data=$self->data;
  $data={map {int($data->{$_}), $_} keys %$data};
  return $data->{$param};
}

=head2 listprn

List all known PRNs.

  my @prn=$obj->listprn;
  my $prn=$obj->listprn;

=cut

sub listprn {
  my $self=shift();
  my %list=$self->data;
  my @list=sort {$a <=> $b} values %list;
  return wantarray ? @list : \@list;
}

=head2 listoid

List all known OIDs.

  my @oid=$obj->listoid;
  my $oid=$obj->listoid;

=cut

sub listoid {
  my $self=shift();
  my %list=$self->data;
  my @list=sort {$a <=> $b} keys %list;
  return wantarray ? @list : \@list;
}

=head2 data

OID to PRN hash reference

  my $data=$self->data;

=cut

sub data {
  my $self=shift();
  unless (defined($self->{'data'})) {
    my %data=(
              22231 => q{01},
              28474 => q{02},
              23833 => q{03},
              22877 => q{04},
              22779 => q{05},
              23027 => q{06},
              22657 => q{07},
              25030 => q{08},
              22700 => q{09},
              23953 => q{10},
              25933 => q{11},
              29601 => q{12},
              24876 => q{13},
              26605 => q{14},
              20830 => q{15},
              27663 => q{16},
              28874 => q{17},
              26690 => q{18},
              28190 => q{19},
              26360 => q{20},
              27704 => q{21},
              28129 => q{22},
              28361 => q{23},
              21552 => q{24},
              21890 => q{25},
              22014 => q{26},
              22108 => q{27},
              26407 => q{28},
              22275 => q{29},
              24320 => q{30},
              29486 => q{31},
              24307 => q{120}, #EGNOS Inmarsat 3F2 AOR-E  15.5°W Garmin 33
              28899 => q{121}, #      Inmarsat 4F2 AOR-E  53.0°W Garmin 34
              24819 => q{122}, #WAAS  Inmarsat 3F4 AOR-W 142.0°W Garmin 35
              26863 => q{124}, #EGNOS ARTEMIS             21.5°E Garmin 37
             #23839 => q{126}, #      Inmarsat 3F1 IOR-W  64.0°E Garmin 39
              25153 => q{126}, #EGNOS Inmarsat 3F5 IOR-W  25.0°E Garmin 39
              28622 => q{129}, #MSAS  MTSAT-1            140.0°E Garmin 42
             #00000 => q{131}, #ESTB  Inmarsat-III IOR-E  65.5°E Garmin 44
              24674 => q{134}, #WAAS  Inmarsat 3F3 POR   178.0°E Garmin 47
              28884 => q{135}, #WAAS  Galaxy 15 (PanAm)  133.0°W Garmin 48
              28937 => q{137}, #MSAS  MTSAT-2                    Garmin 50
              28868 => q{138}, #WAAS  Anik F1R (Telsat)  107.3°W Garmin 51
             );
    $self->{'data'}=\%data;
  }
  return wantarray ? %{$self->{'data'}} : $self->{'data'};
}

=head2 overload

Adds or overloads new OID/PRN pairs.

  $obj->overload($oid=>$prn);

=cut

sub overload {
  my $self=shift();
  my $oid=shift();
  my $prn=shift();
  my $data=$self->data;
  my $return=q{added};
  if (exists($data->{$oid})) {
    $return='overloaded';
  }
  $data->{$oid}=$prn;
  return defined($data->{$oid}) ? $return : undef();
}

=head2 reset

Resets overloaded OID/PRN pairs to package defaults.

  $obj->reset;

=cut

sub reset {
  my $self=shift();
  undef($self->{'data'});
}

1;

__END__

=head1 TODO

=head1 BUGS

Please send issues to the gpsd-dev email list.

=head1 LIMITS

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO
