#!/usr/bin/env perl
####
## This module provides a base class, providing routines for storing
## informations regarding an IP router.
####

package RouterBase;
use RouterBase::Card;
use RouterBase::Prefixlist;
use RouterBase::StaticRoute;
use RouterBase::BGP;
use RouterBase::ISIS;
use RouterBase::IPHost;
use strict;
use vars qw($VERSION);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

RouterBase

=head1 SYNOPSIS

 use RouterBase;
 my $router = new RouterBase;
 $router->set_hostname('hostname');
 my $card = $router->card(0);
 $card->module(1);

=head1 DESCRIPTION

This module provides a base class, providing routines for storing informations
regarding an IP router.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<hostname>: The initial router hostname.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new router.
##
sub _init {
  my($self, %args) = @_;
  $self->{hostname} = $args{hostname} if $args{hostname};
  return $self;
}


=head2 set_hostname($hostname)

Set the hostname.

=cut
sub set_hostname {
  my($self, $hostname) = @_;
  $self->{hostname} = $hostname;
}


=head2 get_hostname()

Returns the hostname.

=cut
sub get_hostname {
  my $self = shift;
  return $self->{hostname};
}


=head2 set_vendor($vendor)

Defines the vendor.

=cut
sub set_vendor {
  my($self, $vendor) = @_;
  $self->{vendor} = $vendor;
}


=head2 get_vendor()

Returns the vendor.

=cut
sub get_vendor {
  my $self = shift;
  return $self->{vendor};
}


=head2 set_model($model)

Defines the model name.

=cut
sub set_model {
  my($self, $model) = @_;
  $self->{model} = $model;
}


=head2 get_model()

Returns the model name.

=cut
sub get_model {
  my $self = shift;
  return $self->{model};
}


=head2 set_os($os)

Defines the operating system name and version.

=cut
sub set_os {
  my($self, $os) = @_;
  $self->{os} = $os;
}


=head2 get_os()

Returns the operating system name and version.

=cut
sub get_os {
  my $self = shift;
  return $self->{os};
}


=head2 set_cfgversion($version)

Defines the configuration version.

=cut
sub set_cfgversion {
  my($self, $version) = @_;
  $self->{cfgversion} = $version;
}


=head2 get_cfgversion()

Returns the configuration version.

=cut
sub get_cfgversion {
  my $self = shift;
  return $self->{cfgversion};
}


=head2 card($cardnumber)

Returns the L<RouterBase::Card|RouterBase::Card> with the given number.
If it does not exist, it will be created.
If no card number is given, a virtual card will be returned anyway.
You can, for example, add modules/interfaces that do not have a pysical card
there.

=cut
sub card {
  my($self, $cardno) = @_;
  #print "DEBUG: RouterBase::card(): Called.\n";
  $cardno = -1 if !defined $cardno;
  return $self->{cards}->{$cardno} if $self->{cards}->{$cardno};
  #print "DEBUG: RouterBase::card(): New card $cardno.\n";
  my $card = new RouterBase::Card(name => $cardno);
  $card->set_number($cardno);
  return $self->{cards}->{$cardno} = $card;
}


=head2 isis()

Returns the L<RouterBase::ISIS|RouterBase::ISIS> instance.
If that ISIS instance does not yet exist, a new one will be created/returned.

=cut
sub isis {
  my $self = shift;
  return $self->{isis} if $self->{isis};
  $self->{isis} = new RouterBase::ISIS;
}


=head2 bgp($localas)

Returns the L<RouterBase::BGP|RouterBase::BGP> instance with the given local
as number.
If that BGP instance does not yet exist, a new one will be created/returned.

=cut
sub bgp {
  my($self, $localas) = @_;
  return $self->{bgp}->{$localas} if $self->{bgp}->{$localas};
  $self->{bgp}->{$localas} = new RouterBase::BGP(localas => $localas);
}


=head2 prefixlist($name)

Returns the L<RouterBase::Prefixlist|RouterBase::Prefixlist> with the given
name. If the L<RouterBase::Prefixlist|RouterBase::Prefixlist> does not exist
yet, it will be created and returned.

=cut
sub prefixlist {
  my($s, $name) = @_;
  return $s->{prefixlists}->{$name} if $s->{prefixlists}->{$name};
  return $s->{prefixlists}->{$name} = new RouterBase::Prefixlist(name => $name);
}


=head2 add_staticroute($ip, $mask, $destination)

Add a new static route to the router.
Returns the newly created L<RouterBase::StaticRoute|RouterBase::StaticRoute>.

=cut
sub add_staticroute {
  my($self, $ip, $mask, $dest) = @_;
  my $route = new RouterBase::StaticRoute;
  $route->set_network($ip, $mask);
  $route->set_destination($dest);
  return $self->{staticroutes}->{"$ip/$mask"} = $route;
}


=head2 get_staticroute($ip, $mask)

Returns the L<RouterBase::StaticRoute|RouterBase::StaticRoute> with the given
ip and mask.

=cut
sub get_staticroute {
  my($self, $ip, $mask) = @_;
  return $self->{staticroutes}->{"$ip/$mask"};
}


=head2 ip_host($name, $port)

Returns the L<RouterBase::IPHost|RouterBase::IPHost> with the given
hostname/port.
If it does not exist yet, a new one will be created.

=cut
sub ip_host {
  my($self, $name, $port) = @_;
  $port *= 1 if $port;
  return $self->{ip_hosts}->{"$name/$port"}
      if $self->{ip_hosts}->{"$name/$port"};
  $self->{ip_hosts}->{"$name/$port"} = new RouterBase::IPHost($name, $port);
  return $self->{ip_hosts}->{"$name/$port"};
}


=head2 foreach_ip_host($func, %data)

Walks through all hostname <-> IP mappings calling the function $func.
Args passed to $func are:

I<$card>: The L<RouterBase::IPHost|RouterBase::IPHost>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the hostname <-> IP mapping list evaluation will be
stopped.

=cut
sub foreach_ip_host {
  my($self, $func, %data) = @_;
  for my $host (sort {$a <=> $b} keys %{$self->{ip_hosts}}) {
    my $iphost = $self->{ip_hosts}->{$host};
    #print "DEBUG: RouterBase::foreach_ip_host(): IP mapping $host\n";
    return FALSE if !$func->($iphost, %data);
  }
  return TRUE;
}


=head2 foreach_bgp($func, %data)

Walks through all BGP instances calling the function $func.
Args passed to $func are:

I<$card>: The L<RouterBase::BGP|RouterBase::BGP>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the BGP instance list evaluation will be stopped.

=cut
sub foreach_bgp {
  my($self, $func, %data) = @_;
  #print "DEBUG: RouterBase::foreach_bgp(): Called.\n";
  for my $as (sort {$a <=> $b} keys %{$self->{bgp}}) {
    my $bgp = $self->{bgp}->{$as};
    #print "DEBUG: RouterBase::foreach_bgp(): BGP instance $as\n";
    return FALSE if !$func->($bgp, %data);
  }
  return TRUE;
}


=head2 foreach_prefixlist($func, %data)

Walks through all prefixlists calling the function $func.
Args passed to $func are:

I<$pfxlist>: The L<RouterBase::Prefixlist|RouterBase::Prefixlist>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the list evaluation will be stopped.

=cut
sub foreach_prefixlist {
  my($self, $func, %data) = @_;
  #print "DEBUG: RouterBase::foreach_prefixlist(): Called.\n";
  for my $name (keys %{$self->{prefixlists}}) {
    my $pfxlist = $self->{prefixlists}->{$name};
    #print "DEBUG: RouterBase::foreach_prefixlist(): Prefixlist $name\n";
    return FALSE if !$func->($pfxlist, %data);
  }
  return TRUE;
}


=head2 foreach_card($func, %data)

Walks through all cards calling the function $func.
Args passed to $func are:

I<$card>: The L<RouterBase::Card|RouterBase::Card>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the card list evaluation will be stopped.

=cut
sub foreach_card {
  my($self, $func, %data) = @_;
  #print "DEBUG: RouterBase::foreach_card(): Called.\n";
  for my $cardno (sort {$a <=> $b} keys %{$self->{cards}}) {
    my $card = $self->{cards}->{$cardno};
    #print "DEBUG: RouterBase::foreach_card(): Card number $cardno\n";
    return FALSE if !$func->($card, %data);
  }
  return TRUE;
}


=head2 foreach_module($func, %data)

Walks through all modules calling the function $func.
Args passed to $func are:

I<$module>: The L<RouterBase::Module|RouterBase::Module>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the module list evaluation will be stopped.

=cut
sub foreach_module {
  my($self, $func, %data) = @_;
  #print "DEBUG: RouterBase::foreach_module(): Called.\n";
  for my $cardno (sort {$a <=> $b} keys %{$self->{cards}}) {
    my $card = $self->{cards}->{$cardno};
    #print "DEBUG: RouterBase::foreach_module(): Card number $cardno\n";
    return FALSE if !$card->foreach_module($func, %data);
  }
  return TRUE;
}


=head2 foreach_interface($func, %data)

Walks through all interfaces calling the function $func.
Args passed to $func are:

I<$interface>: The L<RouterBase::Interface|RouterBase::Interface>.
I<%data>: The given data, just piped through.

If $func returns FALSE, the interface list evaluation will be stopped.

=cut
sub foreach_interface {
  my($self, $func, %data) = @_;
  #print "DEBUG: RouterBase::foreach_interface(): Called.\n";
  for my $cardno (sort {$a <=> $b} keys %{$self->{cards}}) {
    my $card = $self->{cards}->{$cardno};
    #print "DEBUG: RouterBase::foreach_interface(): Card number $cardno\n";
    return FALSE if !$card->foreach_interface($func, %data);
  }
  return TRUE;
}


=head2 foreach_unit($func, %data)

Walks through all L<RouterBase::LogicalInterface|RouterBase::LogicalInterface>
calling the function $func. Args passed to $func are:

I<$interface>: The L<RouterBase::LogicalInterface|RouterBase::LogicalInterface>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_unit {
  my($self, $func, %data) = @_;
  #print "DEBUG: RouterBase::foreach_unit(): Called.\n";
  for my $cardno (sort {$a <=> $b} keys %{$self->{cards}}) {
    my $card = $self->{cards}->{$cardno};
    #print "DEBUG: RouterBase::foreach_unit(): Card number $cardno\n";
    return FALSE if !$card->foreach_unit($func, %data);
  }
  return TRUE;
}


=head2 print_data()

Prints all data regarding the router to STDOUT (e.g. for debugging).

=cut
sub print_data {
  my $self = shift;
  print "Router Hostname:   ", $self->get_hostname,   "\n";
  print "Router Vendor:     ", $self->get_vendor,     "\n";
  print "Router Model:      ", $self->get_model,      "\n";
  print "Router OS:         ", $self->get_os,         "\n";
  print "Router Cfgversion: ", $self->get_cfgversion, "\n";
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
