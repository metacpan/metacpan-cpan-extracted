##################################################
package Log::Log4perl::Appender::Redis;
##################################################
our @ISA = qw(Log::Log4perl::Appender);
our $VERSION = '0.01';

use warnings;
use strict;
use FindBin;

use Redis;
use Sys::Hostname;

##################################################
sub new {
##################################################
  my($class, @options) = @_;

  my $self = {
              name            => "unknown name",
              silent_recovery => 0,
              no_warning      => 0,
              PeerAddr        => "localhost",
              PeerPort        => 6379,
              Proto           => 'tcp',
              Timeout         => 5,
              channel         => q{log},
              separator       => q{;},
	      encoding        => undef,
	      reconnect       => 2,
	      every           => 100,
	      defer_connection => 0,
	      @options,
             };

  bless $self, $class;

  #
  # connect to Redis server
  #
  return $self
    if( $self->{defer_connection} );

  return $self
    if( $self->connect() );

  #
  # failed connection
  #

  die( qq{Connect to Redis $self->{PeerAddr}:$self->{PeerPort} failed: $!} )
    if( ! $self->{silent_recovery} );


  if( ! $self->{no_warning} ) {
    warn "Connect to Redis $self->{PeerAddr}:$self->{PeerPort} failed: $!";
  } else {
    return $self;
  }

  return $self;
}

##################################################
sub connect {
##################################################
  my($self) = @_;

  eval {
    $self->{Redis}
      = Redis->new( server => $self->{PeerAddr}.q{:}.$self->{PeerPort},
		    reconnect => $self->{reconnect},
		    every => $self->{every},
		    encoding => $self->{encoding},
		  );
  };

  return $self->{Redis};
}

##################################################
sub log {
##################################################
  my($self, %params) = @_;

  #
  # try to connect
  #
  if( ($self->{silent_recovery}
       or $self->{defer_connection})
      and ! defined $self->{Redis}) {
    if(! $self->connect() ) {
      return;
    }
  }

  chomp( $params{message} );
  eval {
    $self->{Redis}->publish(
			    join( $self->{separator},
				  $self->{channel},
				  hostname(),
				  $FindBin::Script,
				  $params{ 'log4p_level' },
				),
			    $params{message}
			   );
  };

  # no error => return
  return
    if( ! $@ );

  if($@) {
    # only retry once
    return
      if( defined($params{log_retry}) );

    warn "Send to " . ref($self) . " failed ($@), retrying once...";
    $self->log( %params, log_retry => 1 );
  }

  return;
}

##################################################
sub DESTROY {
##################################################
  my($self) = @_;

  undef $self->{Redis};
}

1;

__END__

=head1 NAME

Log::Log4perl::Appender::Redis - Log to a Redis channel

Based on the Log::Log4perl::Appender::Socket by Mike Schilli <m@perlmeister.com> and Kevin Goess <cpan@goess.org>.

=head1 SYNOPSIS

    use Log::Log4perl::Appender::Redis;

    my $appender = Log::Log4perl::Appender::Redis->new(
      PeerAddr => "localhost",
      PeerPort => 1234,
    );

    $appender->log(message => "Log me\n");

=head1 DESCRIPTION

=head1 EXAMPLE

Start it and then run the following script as a client:

    use Log::Log4perl qw(:easy);

    my $conf = <<EOC;
    log4perl.category = TRACE, Redis
    log4perl.appender.Redis = Log::Log4perl::Appender::Redis
    log4perl.appender.Redis.min_level = debug
    log4perl.appender.Redis.PeerAddr = localhost
    log4perl.appender.Redis.PeerPort = 6379
    log4perl.appender.Redis.channel = mylog
    log4perl.appender.Redis.separator = ;;
    log4perl.appender.Redis.layout = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Redis.layout.ConversionPattern = %d [%H:%P] %m
    log4perl.appender.Redis.defer_connection = 1
    EOC

    Log::Log4perl->init(\$conf);
    TRACE("The");
    DEBUG("duck");
    INFO("came");
    WARN("singing");
    ERROR("cheerfully");
    FATAL("Quack!");

=head2 OUTPUT

    echo "PSUBSCRIBE *" | redis-cli
    Reading messages... (press Ctrl-C to quit)
    1) "psubscribe"
    2) "*"
    3) (integer) 1
    1) "pmessage"
    2) "*"
    3) "mylog;;gamma.localdomain;;r.pl;;TRACE"
    4) "2014/01/24 12:55:41 [gamma.localdomain:1323] The"
    1) "pmessage"
    2) "*"
    3) "mylog;;gamma.localdomain;;r.pl;;DEBUG"
    4) "2014/01/24 12:55:41 [gamma.localdomain:1323] duck"
    1) "pmessage"
    2) "*"
    3) "mylog;;gamma.localdomain;;r.pl;;INFO"
    4) "2014/01/24 12:55:41 [gamma.localdomain:1323] came"
    1) "pmessage"
    2) "*"
    3) "mylog;;gamma.localdomain;;r.pl;;WARN"
    4) "2014/01/24 12:55:41 [gamma.localdomain:1323] singing"
    1) "pmessage"
    2) "*"
    3) "mylog;;gamma.localdomain;;r.pl;;ERROR"
    4) "2014/01/24 12:55:41 [gamma.localdomain:1323] cheerfully"
    1) "pmessage"
    2) "*"
    3) "mylog;;gamma.localdomain;;r.pl;;FATAL"
    4) "2014/01/24 12:55:41 [gamma.localdomain:1323] Quack!"

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by pedro.frazao

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
