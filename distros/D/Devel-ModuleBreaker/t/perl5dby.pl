# trivial replacement for  perl5db.pl
# the output should match /^b+a+$/ in programs that set sub breakpoints
#                     and /^a+$/    in programs that don't
# (interspersed with whatever output the program writes to stdout)

package DB;
sub DB { print "a" }
sub cmd_b_sub { print "b" }

1;
