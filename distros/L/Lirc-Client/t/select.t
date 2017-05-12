use strict;
use warnings;

use Test::More tests => 3;
use IO::Handle;

use IO::Select;
use Lirc::Client;

my $lirc = Lirc::Client->new( {
        prog   => "lirc-client-test",
        rcfile => "samples/lircrc.3",
        debug  => 0,
        fake   => 1,
} );
ok( $lirc, "created a lirc object" );

pipe my $read, my $write or die $!;
$write->autoflush(1);
$read->autoflush(1);
$lirc->{sock} = $read;
print $write "0 0 play test-remote\n";
$write->flush;
print $write "0 0 pause test-remote\n";
$write->flush;

#close $write;  # should not need to close

my @codes = qw/PLAY PAUSE/;
my $count = 0;

my $select = IO::Select->new();
$select->add( $lirc->sock );
while (1) {

    # do your own stuff, if you want
    if ( my @ready = $select->can_read(0) ) {

        # an IR event has been received
        # may not be a full line from lirc, but I have never seen one
        my @codes = $lirc->next_codes;    # should not block
        for my $code (@codes) {
            process($code);
        }
    }
}

sub process {
    my $code = shift;

    is( $code, shift @codes, "recognized command " . ++$count );
    exit if $count > 1;
}
