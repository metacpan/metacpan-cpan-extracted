print "Starting outer\n";
use inner1;
use inner2;

#debug> Debug is ON.

inner1::run();

inner2::run();

print "Done.\n";
