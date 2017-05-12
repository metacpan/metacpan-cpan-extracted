package IRC::Indexer::Process::Trawler;

## Handled by Trawl::Forking
## Should be a proper session, really.

use strict;
use warnings;

use POE;

require IRC::Indexer::Trawl::Bot;

use Storable qw/nfreeze thaw/;

use bytes;

sub worker {
  $0 = "ircindexer TRAWL" unless $^O eq 'MSWin32';
  ## In case we're running as a forked coderef:
  POE::Kernel->stop;

  binmode STDOUT;
  binmode STDIN;
  
  STDOUT->autoflush(1);
  
  my $buf = '';
  my $read_bytes;
  
  while (1) {
    if (defined $read_bytes) {
      if (length $buf >= $read_bytes) {
        my $inputref = thaw( substr($buf, 0, $read_bytes, "") );
        $read_bytes = undef;

        ## Note: $server here is the "target server" (ConnectedTo)
        ## Not necessarily "Reported server name" (ServerName)
        ## Same for reply to master.
        my ($server, $conf) = @$inputref;
        die "Process::Trawler passed invalid configuration"
          unless ref $conf eq 'HASH';
        
        $0 = "ircindexer TRAWL $server" unless $^O eq 'MSWin32';
        
        my $trawler = IRC::Indexer::Trawl::Bot->new(%$conf);
        $trawler->run();
        
        POE::Kernel->run();
        
        my $report;
        if ($trawler->failed) {
          $report = {
            NetName     => $server,
            ServerName  => $server,
            ConnectedTo => $server,
            FinishedAt  => time,
            Status => 'FAIL', 
            Failure => $trawler->failed,
          };
        } else {
          $report = $trawler->report->netinfo();
        };
        
        my $frozen = nfreeze([ $server, $report ]);
        my $stream = length($frozen) . chr(0) . $frozen ;
        my $written = syswrite(STDOUT, $stream);
        die $! unless $written == length $stream;
        exit 0
      }
    } elsif ($buf =~ s/^(\d+)\0//) {
      $read_bytes = $1;
      next
    }
  
    my $readb = sysread(STDIN, $buf, 4096, length $buf);
    last unless $readb;
  }
  
  exit 0
}

1;
__END__

=pod

=head1 NAME

IRC::Indexer::Process::Trawler - Forkable Trawl::Bot session

=head1 SYNOPSIS

See L<IRC::Indexer::Trawl::Forking> and L<IRC::Indexer::Trawl::Bot>

=head1 DESCRIPTION

A forkable process managing a L<IRC::Indexer::Trawl::Bot> instance; 
this is the worker used by L<IRC::Indexer::Trawl::Forking> via 
L<POE::Wheel::Run> and L<POE::Filter::Reference>.

Given an array containing a server tag and a trawler configuration to 
pass through to L<IRC::Indexer::Trawl::Bot>, runs a single trawler until 
it is complete and returns a server information hash.

See L<IRC::Indexer::Trawl::Bot> for details on the non-forking 
asynchronous interface.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
