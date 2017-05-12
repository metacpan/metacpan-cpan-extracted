#!/usr/bin/perl -w

use strict;
use warnings 'all';
use forks;
use Email::Blaster::Throttled;

my $blaster = Email::Blaster::Throttled->new( );

$blaster->handle_event( type => 'server_startup' );

my @workers = ( );

foreach my $throttled ( $blaster->config->throttled )
{
  push @workers, threads->create(sub {
    my ($throttled) = @{$_[0]};
    
    warn "Throttled Server for @{[ $throttled->domain ]} (@{[ $throttled->hourly_limit ]}/hour) starting up...\n";
    
    local $SIG{INT} = $SIG{TERM} = sub {
      # Quitting:
      warn "Throttled Server for @{[ $throttled->domain ]} (@{[ $throttled->hourly_limit ]}/hour) shutting down...\n";
      $blaster->handle_event( type => 'server_shutdown' );
      exit;
    };
    use Email::Blaster::Transmission;
    use My::TransmissionInitHandler;
    use My::Contact;
    
    $blaster->run( $throttled->domain, $throttled->hourly_limit );
  }, [ $throttled ]);
}# end foreach()

map { $_->join() } @workers;




