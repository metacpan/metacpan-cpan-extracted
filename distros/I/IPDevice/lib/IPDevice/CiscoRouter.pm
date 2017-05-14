#!/usr/bin/env perl
####
## This file provides a class for holding informations regarding a Cisco
## router.
####

package IPDevice::CiscoRouter;
use IPDevice::RouterBase;
use IPDevice::CiscoRouter::Accesslist;
use IPDevice::CiscoRouter::Card;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(IPDevice::RouterBase);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

IPDevice::CiscoRouter

=head1 SYNOPSIS

 use IPDevice::CiscoRouter;
 my $router = new IPDevice::CiscoRouter;
 $router->set_hostname('hostname');
 my $card = $router->card(0);
 my $acl  = $router->accesslist('DENYSTUPIDS');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a Cisco router.

=head1 CONSTRUCTOR AND METHODS

This module provides, in addition to all methods from
L<IPDevice::RouterBase|IPDevice::RouterBase>, the following methods.

=head2 new([%args])

Object constructor. Valid arguments:

I<hostname>: The initial router hostname.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  $self->set_vendor('cisco');
  return $self->_init(%args);
}


=head2 interfacename($interfacename)

Returns the L<IPDevice::RouterBase::Interface|IPDevice::RouterBase::Interface> with the given name.
Valid names have the format 'POS1/2/3', 'Loopback0', 'Serial1/0/0:0', or
just '1/2/3' etc.
If the interface does not yet exist, it will be created.

=cut
sub interfacename {
  my($self, $logintname) = @_;
  #print "IPDevice::CiscoRouter::interfacename(): $logintname\n";
  my $logintno =  $logintname;  # Logical interface number.
  my $intname  =  $logintname;  # Physical interface name.
  my $intno    =  $logintname;  # Interface name without the type.
  my $unit;                     # Unit number.
  $logintno    =~ s/^[^\d]*//;
  $intname     =~ s/[:\.].*$//;
  $intno       =~ s/^[^\d]*([^:\.]+).*/$1/;
  $unit        = $1 if $logintname =~ /[:\.](\d+)$/;
  
  # Extract the interface, module and card from the name.
  my($card, $mod);
  $card  = $1, $mod = $2 if $intno =~ /^(\d+)\/(\d+)\/\d+[:\.]?/;
  $card  = $1            if $intno =~ /^(\d+)\/\d+$/;
  #print "IPDevice::CiscoRouter::interfacename(): $logintname, $card/$mod/x:$unit\n";
  return $self->card($card)->module($mod)->interface($intname) if !defined $unit;
  return $self->card($card)->module($mod)->interface($intname)->unit($unit);
}


=head2 accesslist($name)

Returns the L<IPDevice::CiscoRouter::Accesslist|IPDevice::CiscoRouter::Accesslist> with the given
name. If the L<IPDevice::CiscoRouter::Accesslist|IPDevice::CiscoRouter::Accesslist> does not yet
exist, it will be created.

=cut
sub accesslist {
  my($self, $name) = @_;
  return $self->{accesslists}->{$name} if $self->{accesslists}->{$name};
  my $accesslist = new IPDevice::CiscoRouter::Accesslist(name => $name);
  return $self->{accesslists}->{$name} = $accesslist;
}


=head2 foreach_accesslist($func, %data)

Walks through all L<IPDevice::CiscoRouter::Accesslist|IPDevice::CiscoRouter::Accesslist>
calling the function $func. Args passed to $func are:

I<$acl>: The L<IPDevice::CiscoRouter::Accesslist|IPDevice::CiscoRouter::Accesslist>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_accesslist {
  my($self, $func, %data) = @_;
  #print "DEBUG: IPDevice::CiscoRouter::foreach_accesslist(): Called.\n";
  for my $aclname (keys %{$self->{accesslists}}) {
    my $acl = $self->{accesslists}->{$aclname};
    #print "DEBUG: IPDevice::CiscoRouter::foreach_accesslist(): ACL $aclname\n";
    return FALSE if !$func->($acl, %data);
  }
  return TRUE;
}


=head1 COPYRIGHT

Copyright (c) 2004 Samuel Abels.
All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Samuel Abels <spam debain org>

=cut

1;

__END__
