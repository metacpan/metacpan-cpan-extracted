
#
# a little help to use gdb to debug the c code, running the perl world.
# start gdb on the perl executable (e.g. "gdb perl" in xemacs)
# then type "r" to execute this macro
#   that will put you at a perl debugger prompt.
# you can interupt it w/ a control-C (or two, if in emacs) which will put
# you at the gdb prompt, with all of the shared libs loaded.
# then, for instance, you can set a break in sim4_helper() and have at it.
#
define r
 run -I../../blib/arch -I../../blib/lib -d t/sim4.t
end 
define r2
 run -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.0/i386-linux \
     -I/usr/lib/perl5/5.6.0 -d /tmp/moose.t
end 
define r3
 run -I../../blib/arch -I../../blib/lib -d t/qtest.t
end 
