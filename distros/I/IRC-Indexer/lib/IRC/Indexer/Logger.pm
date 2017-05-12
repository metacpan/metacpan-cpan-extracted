package IRC::Indexer::Logger;

use 5.10.1;
use strict;
use warnings;
use Carp;

use Scalar::Util qw/blessed/;

use Log::Handler;

sub new {
  my $self = {};
  my $class = shift;
  bless $self, $class;
  ## Set up a Log::Handler for specified LogFile
  
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  if ($args{devnull}) {
    ## Sometimes it's useful to have a log object present,
    ## but not necessarily logging anywhere:
    $self->{DevNull} = 1;
  } else { 
    $self->{LogFile} = $args{logfile}
      || croak "No LogFile specified in new()";
  }  
  $self->{LogLevel} = $args{loglevel} || 'info' ;
  
  $self->logger( $self->_create_logger );
  
  return $self
}

sub _create_logger {
  my ($self) = @_;
  my $logger = Log::Handler->new();
  $logger->add(
    file => {
      maxlevel => $self->{LogLevel},
      timeformat => "%Y/%m/%d %H:%M:%S",
      message_layout => "[%T] %L %p %m",
      
      filename => $self->{LogFile},
      filelock => 1,
      fileopen => 1,
      reopen   => 1,
      utf8     => 1,
      autoflush => 1,
    },
  ) unless $self->{DevNull};
 
  return $logger
}

sub logger {
  my ($self, $logger) = @_;
  ## Return/set our Log::Handler
  return $self->{LogObj} = $logger if blessed $logger;
  return $self->{LogObj}
}

sub log_to {
  ## Adjust the log destination
  my ($self, $path) = @_;
  return unless $path;
  $self->{LogFile} = $path;
  $self->logger->flush;
  $self->logger( $self->_create_logger );
  return $self->logger
}

1;
__END__
=pod

=head1 NAME

IRC::Indexer::Logger - Simple interface to Log::Handler

=head1 SYNOPSIS

  my $handler = IRC::Indexer::Logger->new(
    ## Path to output file:
    LogFile  => $logfile_path,

    ## Typically 'debug', 'info', 'warn':
    LogLevel => 'info',
    
    ## Enable DevNull to set up loggers yourself later
    ## (Useful for only logging to STDOUT for example)
    DevNull => 0,
  );

  ## Switch to a different file:
  $handler->log_to($new_logfile);
  
  ## Access the actual logger:
  my $logger = $handler->logger;
  
  ## Log things:
  $logger->info("Something informative");
  $logger->warn("Something went wrong!");
  $logger->debug("Things are happening.");
  
=head1 DESCRIPTION

Simplified construction of Log::Handler instances for IRC::Indexer 
frontends.

See the SYNOPSIS for usage details and L<Log::Handler> for more 
about using the log object itself.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
