package IO::Socket::PortState;

use strict;
use warnings;
use IO::Socket::INET;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(check_ports);

our $VERSION = '0.03';

sub check_ports {
   my ($ip,$to,$pmhr,$proc) = @_;
   my $hr = defined wantarray ? {} : $pmhr;
   for my $prot (keys %{ $pmhr }) {
      for(keys %{ $pmhr->{$prot} }) {
         $hr->{$prot}->{$_}->{name} = $pmhr->{$prot}->{$_}->{name};
         if(ref $proc eq 'CODE') {
            $proc->($hr->{$prot}->{$_},$ip,$_,$prot,$to);
         } else {
            my $sock = IO::Socket::INET->new(
               PeerAddr => $ip,
               PeerPort => $_,
               Proto => $prot,
               Timeout => $to
            );
            $hr->{$prot}->{$_}->{open} = !defined $sock ? 0 : 1;
            $hr->{$prot}->{$_}->{note} = 'builtin()';
         }
      }
   }
   return $hr;
}

1;

__END__

=head1 NAME

IO::Socket::PortState - Perl extension for checking the open or closed status of a port.

=head1 SYNOPSIS

   use strict;
   use warnings;
   use IO::Socket::PortState qw(check_ports);

   my %porthash = ( ... );

   check_ports($host,$timeout,\%porthash);

   for my $proto (keys %porthash) {
      for(keys %{ $porthash{$proto} }) {
         print "$proto $_ is not open ($porthash{$proto}->{$_}->{name}) if !$porthash{$proto}->{$_}->{open};
      }
   }

=head1 DESCRIPTION

You can use it to check if a port is open or closed for a given host and protocol.

=head2 EXPORT

None by default. But you can export check_ports();

=head1 check_ports()

This function tests your \%porthash and sets a protocol/port's open and note keys (see \%porthash below for details).

By default it determines if "open" is 1 or 0 if the IO::Socket::INET object is defined or not. 
For protocols  not supported by IO::Socket::INET or for custom tests (IE open just to specific hosts, closed because activley blocked, service is down, etc)
use \&handler (see \&handler below)

  check_ports($host,$timeout,\%porthash,\&handler); 

Called in void contect it modifies the hashref given. Otherwise it returns a new hash ref 
which is usefull for looping through the same \%porthash for multiple hosts:

  my %porthash = ( ... );
  for(@hosts) {
     my $host_hr = check_ports($_,$timeout,\%porthash);
     print "Report for $_\n";
     # do something with $host_hr
  }

vs void context:

  my %porthash = ( ... );
  check_ports($host,$timeout,\%porthash);
  # now %porthash has been directly changed

=head2 \%porthash

This hash is a bit complex by necessity. (but its not so bad ;p)

The keys are the protocol (tcp, udp, ...) as can be used by IO::Socket::INET->new()'s "Proto" option (or whatever is valid for your custom \&handler

The values are a hashref. In this hashref the keys are the numeric ports and the valuse are a hashref.

This hashref has only one key "name" whose value can be an arbitrary label for your use and once run it sets "open" to 1 or 0 and "note" to "builtin()" so you knwo how "open" was figured.

   my %check = (
      tcp => {
         80 => {
            name => 'Apache', 
         },
         443 => {
            name => 'SSL Apache',
         },
      }, 
      udp => {
         53 => {
            name => 'DNS'
         },
         465 => {
            name => 'smtp tls/ssl'
         },
      },
   );

=head2 \&handler

Here is an example handler function you can use as a road map:

    sub handler {
       my($ent_hr,$host,$port,$proto,$timeout) = @_;

       # use $host, $port, $protocol, and $timeout to determine what you want however you like here

       # at a minimum do these two:
       $ent_hr->{open} = ???; # do what you like to set its open status to 1 or 0
       $ent_hr->{note} = 'my handler()'; 

       # set any other info you wanted here also...
       if(!$ent_hr->{open}) {
          $ent_hr->{closed_reason} = ???; # do what you like to set details about why its not open (blocked, not running, etc)
       }
    }

=head1 HOW TO EXPAND ON IO::Socket::PortState

This module's life came around as a result of wanting to monitor specific ports on several servers, specifically servers running cPanel (L<http://cpanel.net/>).
To make it easier to do that and provide a model to make it easier for anyone to create a module that is "server specific" I've created L<IO::Socket::PortState::cPanel>

If you want to do the same thing please use it as a guide, all you would need to do is change the hashrefs and package specific info and voila its all set :)

If you do use L<IO::Socket::PortState::cPanel> as a model (and I hope you do so that using any IO::Socket::PortState::* module will have a specific consistent use) please reference it in the POD of your module as outlined in the POD of L<IO::Socket::PortState::cPanel>.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
