BEGIN { $| = 1; print "1..4\n"; }
END   { print "not ok 1\n" unless $loaded; }

use MIDI::Music;
use Fcntl;

$loaded = 1;
print "ok 1\n";

my $mm = new MIDI::Music;

print <<HERE;

Welcome to the MIDI::Music test. You should enable sound on your machine
before proceeding. If an external synth is your primary (or only) playback 
mechanism, you should have it turned on/plugged in as well.

HERE

print "Test event play? [y]/n : ";
if (<> =~ /^n/i) {

    print "skipping playevents() test. (ok 2)\n";

} else {

    print "testing playevents().... ";
    $mm->init('gminstr' => [19,],
              'mode'    => O_WRONLY,
              'timesig' => [3, 2, 24, 8],
              'tempo'   => 80,
              ) || die $mm->errstr . ' not ok 2';

    $mm->playevents([['patch_change', 0, 0, 19],

                     ['note_on', 0, 0, 57, 91], #
                     ['note_on', 0, 0, 45, 91], #  It is
                     ['note_on', 0, 0, 33, 91], #

                     ['note_off', 96, 0, 57, 91], #
                     ['note_off', 0, 0, 45, 91],  #
                     ['note_off', 0, 0, 33, 91],  # much easier
                     ['note_on', 0, 0, 61, 91],   #
                     ['note_on', 0, 0, 49, 91],   #
                     ['note_on', 0, 0, 37, 91],

                     ['note_off', 144, 0, 61, 91], #
                     ['note_off', 0, 0, 49, 91],   #
                     ['note_off', 0, 0, 37, 91],   # to do this
                     ['note_on', 0, 0, 64, 91],    #
                     ['note_on', 0, 0, 52, 91],    #
                     ['note_on', 0, 0, 40, 91],

                     ['note_off', 48, 0, 64, 91], #
                     ['note_off', 0, 0, 52, 91],  #
                     ['note_off', 0, 0, 40, 91],  # on a keyboard!
                     ['note_on', 0, 0, 62, 91],   #
                     ['note_on', 0, 0, 50, 91],   #
                     ['note_on', 0, 0, 38, 91],

                     ['note_off', 48, 0, 62, 91],
                     ['note_off', 0, 0, 50, 91],
                     ['note_off', 0, 0, 38, 91],
                     ['note_on', 0, 0, 61, 91],
                     ['note_on', 0, 0, 49, 91],
                     ['note_on', 0, 0, 37, 91],

                     ['note_off', 48, 0, 61, 91], # ( These are the first 
                     ['note_off', 0, 0, 49, 91],  #   few bars of Cesar
                     ['note_off', 0, 0, 37, 91],  #   Franck's "Fantasy in
                     ['note_on', 0, 0, 66, 91],   #   A Major" )
                     ['note_on', 0, 0, 54, 91],   #
                     ['note_on', 0, 0, 42, 91],   #

                     ['set_tempo', 0, (60000000 / 60)], # rit. -> 60 bpm

                     ['note_off', 144, 0, 66, 91],
                     ['note_off', 0, 0, 54, 91],
                     ['note_off', 0, 0, 32, 91],
                    ]) || die $mm->errstr . ' not ok 2';
    $mm->dumpbuf();
    $mm->close();
    print "ok 2\n";
}

print "Test MIDI file play (you must have MIDI-Perl installed)? [y]/n : ";
if (<> =~ /^n/i) {

    print "skipping playmidifile() test (ok 3)\n";

} else {

    print "testing playmidifile()... ";
    $mm->playmidifile('kandahar.mid') || die $mm->errstr . ' not ok 3';
    print "ok 3\n";
}


print "Test recording? y/[n] : ";
if (<> =~ /^y/) {

    print "Device number to use? [0] : ";
    my $devno = <> || 0;

    print <<HERE;

Play some notes on your keyboard (you should see a printout of the events 
being sent from it.)

This test will end automatically after a few seconds...

HERE

    $mm->init('device'   => $devno,
              'mode'     => O_RDONLY,
              #'realtime' => 1,
              ) || die $mm->errstr . ' not ok 4';

    # Read 1k buffers' worth of MIDI data, print events...
    for (0 .. 1024) {

        my $events_read = $mm->readevents();

        if (defined $events_read) {

            foreach my $ev (@$events_read) {
                print join(',', @$ev), "\n";
            }
        }
    }
    $mm->close;
    print "ok 4\n";

} else {

    print "skipping readevents() test (ok 4)\n";
}
