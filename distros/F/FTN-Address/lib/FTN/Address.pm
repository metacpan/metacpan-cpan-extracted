# FTN/Address.pm
#
# Copyright (c) 2005-2006 Serguei Trouchelle. All rights reserved.
# Copyright (c)      2013 Robert James Clay. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# History:
#  1.04  2013/05/09 Move 'Address.pm' file to a more standard location under lib/FTN directory.
#  1.03  2007/02/04 Quality update (Test::Pod, Test::Pod::Coverage), Data::Define used
#  1.02  2006/09/07 Added empty value processing
#  1.01  2005/02/16 Initial revision

=head1 NAME

FTN::Address - Process FTN addresses

=head1 SYNOPSIS

 my $addr = new FTN::Address('2:464/4077');

 my $address4D = $addr->get();     # 2:464/4077.0

 my $address5D = $addr->getfull(); # 2:464/4077.0@fidonet

 my $fqdn = $addr->fqdn();         # f4077.n464.z2.fidonet.net


 my $addr = empty FTN::Address();

 $addr->assign('2:464/4077');

 my $address4D = $addr->get();     # 2:464/4077.0

=head1 DESCRIPTION

FTN::Address

=head1 METHODS

=head2 new

This method creates FTN::Address object.
Takes FTN address as argument. Address can be feed in three addressing variants:

3D, ex.: new FTN::Address '2:464/0'
4D, ex.: new FTN::Address '2:464/4077.1'
5D, ex.: new FTN::Address '2:464/357.0@fidonet'

Default domain for 3D and 4D address is 'fidonet'

=head2 empty

This method creates empty FTN::Address object. 
You cannot use it before assigning a new value. 

Takes no parameters.

=head2 assign( $address )

This method assign new address to FTN::Address object. 

Takes FTN address as argument (like 'new' method).

=head2 get()

This method returns qualified 4D address.

Takes no parameters.

=head2 getfull()

This method returns qualified 5D address. 

Takes no parameters.

=head2 fqdn( [ $root_domain [, $level ] ] );

This method returns fully qualified domain name, as described in FSP-1026
Fidonet Technical Standards Comittee document. See this document for details.

Valid values for level are "0, 1, 2, 3, 4, DOM, DO1, DO2, DO3, DO4"
Parameters can be omitted, default values will be used.
Default root domain is 'net', default level is '0'.

Examples:

 my $addr = new FTN::Address('2:464/4077');
 
 print $addr->fqdn();                    # f4077.n464.z2.fidonet.net
 
 print $addr->fqdn('org');               # f4077.n464.z2.fidonet.org
 
 print $addr->fqdn('railways.dp.ua', 2); # f4077.n464.railways.dp.ua

=head1 AUTHORS

Serguei Trouchelle E<lt>F<stro@railways.dp.ua>E<gt>
Robert James Clay E<lt>F<jame@rocasa.us>E<gt>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Serguei Trouchelle. All rights reserved.
Copyright (c) 2013 Robert James Clay. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package FTN::Address;

require Exporter;
use Config;

use strict;
use warnings;

use Data::Define qw/brockets/;

our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ();
our @ISA = qw/Exporter/;

$FTN::Address::VERSION = "1.04";

our $DEFAULT_DOMAIN = 'fidonet';
our $DEFAULT_ROOT = 'net';

#
# Constructor
#

sub new {
  my $self = shift;
  my $addr = shift;
  if ($addr and $addr =~ m!^(\d+):(\d+)/(\d+)(\.(\d+))?(@(\w+))?$!) {
    $self = 
       {'z' => $1,
        'n' => $2,
        'f' => $3,
        'p' => $5 ? $5 : 0,
        'd' => $7 ? $7 : $DEFAULT_DOMAIN,
       };
    $self->{'__addr'} = $self->{'z'} . ':' . $self->{'n'} . '/' .
                        $self->{'f'} . '.' . $self->{'p'};
    $self->{'__addrd'} = $self->{'__addr'} . '@' . $self->{'d'};
  } else {
    $@ = join('', 'Invalid address: ', define($addr));
    return undef;
  }

  bless $self;
  return $self;
}

#
# Empty constructor
#

sub empty {
  my $self = shift;
  $self = {'__empty' => 1};
  bless $self;
  return $self;
}

#
# Assign new value
#

sub assign {
  my $self = shift;
  my $addr = shift;
  if ($addr and $addr =~ m!^(\d+):(\d+)/(\d+)(\.(\d+))?(@(\w+))?$!) {
    $self->{'z'} = $1;
    $self->{'n'} = $2;
    $self->{'f'} = $3;
    $self->{'p'} = $5 ? $5 : 0;
    $self->{'d'} = $7 ? $7 : $DEFAULT_DOMAIN;
    $self->{'__addr'} = $self->{'z'} . ':' . $self->{'n'} . '/' .
                        $self->{'f'} . '.' . $self->{'p'};
    $self->{'__addrd'} = $self->{'__addr'} . '@' . $self->{'d'};
    delete $self->{'__empty'};
  } else {
    $@ = join('', 'Invalid address: ', $addr);
    $self->{'__empty'} = 1;
    return undef;
  }
}

#
# get 4D address
#

sub get {
  my $self = shift;
  if ($self->{'__empty'}) {
    $@ = 'Cannot use empty FTN::Address object';
    return undef;
  }
  return $self->{'__addr'};
}

#
# get 5D address
#

sub getfull {
  my $self = shift;
  if ($self->{'__empty'}) {
    $@ = 'Cannot use empty FTN::Address object';
    return undef;
  }
  return $self->{'__addrd'};
}

#
# get FQDN
#

sub fqdn {
  my $self = shift;
  if ($self->{'__empty'}) {
    $@ = 'Cannot use empty FTN::Address object';
    return undef;
  }
  my $root = shift || $DEFAULT_ROOT;
  my $level = shift || 0;

  $level = $1 if $level =~ /^DO([M1234])$/;
  $level = 0 if $level eq 'M';

  if ($level eq '0') { # DOM - 5D ([pPP.]fFF.nNN.zZZ.fidonet.RD)
    return ($self->{'p'} ? 'p' . $self->{'p'}  . '.' : '') .
           'f' . $self->{'f'} . '.' .
           'n' . $self->{'n'} . '.' .
           'z' . $self->{'z'} . '.' .
           $self->{'d'} .  '.' . $root;
  } elsif ($level eq '1') { # DO1 - 1D (fFF.RD)
    return 'f' . $self->{'f'} . '.' .
           $root;
  } elsif ($level eq '2') { # DO2 - 2D (fFF.nNN.RD)
    return 'f' . $self->{'f'} . '.' .
           'n' . $self->{'n'} . '.' .
           $root;
  } elsif ($level eq '3') { # DO3 - 3D (fFF.nNN.zZZ.RD)
    return 'f' . $self->{'f'} . '.' .
           'n' . $self->{'n'} . '.' .
           'z' . $self->{'z'} . '.' .
           $root;
  } elsif ($level eq '4') { # DO4 - 4D ([pPP.]fFF.nNN.zZZ.RD)
    return ($self->{'p'} ? 'p' . $self->{'p'}  . '.' : '') .
           'f' . $self->{'f'} . '.' .
           'n' . $self->{'n'} . '.' .
           'z' . $self->{'z'} . '.' .
           $root;
  } else {
    $@ = 'Invalid level: ' . $level;
    return undef;
  }
}

1;
