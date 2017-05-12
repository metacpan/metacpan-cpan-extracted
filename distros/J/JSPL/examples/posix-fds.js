#!./bin/jspl
require('POSIX', 'POSIX', -1);

// POSIX.read needs an override, can't pass $buf by reference, so:
POSIX.read = new PerlSub(
    'my $buf; my($fd, $len) = @_; POSIX::read($fd, $buf, $len); $buf'
);

if(Argv.length != 1) 
    throw new Error("Usage: "+PrgName+" <file>");

var file = Argv[0];
say(sprintf("Opening: '%s'", file));

var fd = POSIX.open(file, POSIX.O_RDONLY);
if(typeof fd == 'undefined') {
    var err = POSIX.errno();
    throw new Error(sprintf("%s (%d)", POSIX.strerror(err), err));
} else {
    POSIX.lseek(fd, -6, POSIX.SEEK_END)
    say("The last 5 chars reads: '", POSIX.read(fd, 5), "'");
}
