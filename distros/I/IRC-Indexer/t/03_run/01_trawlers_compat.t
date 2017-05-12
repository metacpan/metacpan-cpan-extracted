use strict; use warnings;
use Test::More tests => 22;
use POE;

## Tests Trawl::Bot/Forking
## These should be compatible.

my @compat;

BEGIN {
  @compat = qw/
    IRC::Indexer::Trawl::Bot
    IRC::Indexer::Trawl::Forking
  /;
  use_ok($_) for @compat;
}

my $sname = 'Nonexist'.int(rand 666);

for my $class (@compat) {
  diag("Testing $class");
  
  POE::Session->create(
    inline_states => {
      '_start' => sub {
        my $trawler = new_ok( $class => [
           Server   => $sname,
           Timeout  => 3,
           Postback => $_[SESSION]->postback('trawler_done'),
         ],
        );
        
        ok( $trawler->run, 'Trawler run()' );
        my $sid;
        ok( $sid = $trawler->ID(), 'Trawler ID()' );
      },
      
      'trawler_done' => sub {      
        pass( 'Received postback' );
        
        my $trawler = $_[ARG1]->[0];
        
        isa_ok( $trawler, $class );
        ok( $trawler->done, 'Trawler reports completion' );
        ok( $trawler->failed, 'Trawler reports failed' );
        is( $trawler->trawler_for, $sname, 'trawler_for() is correct');
        isa_ok( $trawler->report, 'IRC::Indexer::Report::Server' );
        is( $trawler->report->connectedto, $sname, 
          'connectedto() is correct'
        );
        $_[KERNEL]->post( $trawler->ID, 'shutdown' );
      },
    },
  );
  
  $poe_kernel->run;

}
