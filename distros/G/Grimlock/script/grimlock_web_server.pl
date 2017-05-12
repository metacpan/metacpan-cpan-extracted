#!/usr/bin/env perl

BEGIN {
    $ENV{CATALYST_SCRIPT_GEN} = 40;
}

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Grimlock::Web', 'Server');

1;

=head1 NAME

grimlock_web_server.pl - GRIMLOCK TEST SERVER

=head1 SYNOPSIS

grimlock_web_server.pl [options]

   -d --debug           SHOW ERROR MESSAGE WHEN MAKE DUMB MISTAKE
   -f --fork            MAKE NEW PROCESS FOR REQUEST
                        (DEFAULT NO TRUE)
   -? --help            SHOW HELP PAGE FOR DUMMY WHO NO CAN REMEMBER HOW GRIMLOCK WORK
   -h --host            NAME OF COMPUTER TO RUN GRIMLOCK BEAUTIFUL BLOG SOFTWARE
   -p --port            NUMBER OF THINGY TO MAKE CONNECTION TO GRIMLOCK BLOG
   -k --keepalive       SPARE CONNECTION PUNY LIFE
   -r --restart         RESTART WHEN GET FRUSTRATED AND SMASH FILES
                        (DEFAULT NO TRUE)
   -rd --restart_delay  SLOW RESTART BLOG WHEN SMASH FILES
                  
   -rr --restart_regex  RESTART WHEN THINGIES THAT MATCH ARE SMASHED
                        ('\.yml$|\.yaml$|\.conf|\.pm$' ARE THINGIES)
   --background         MAKE GRIMLOCK BLOG SHUT UP AND WORK QUIET IN BACKGROUND BEHIND SCENES
   --pidfile            NAME PROCESS FILE THINGY SO YOU CAN KILL GRIMLOCK BLOG LATER WHEN BORED

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

RUN GRIMLOCK BEAUTIFUL BLOG SOFTWARE IN DEVELOPER MODE

=head1 AUTHORS

ME, GRIMLOCK!

=head1 COPYRIGHT

ME GRIMLOCK WANT SHARE BEAUTIFUL SOFTWARE ME WRITE WITH WORLD.  ME GRIMLOCK SAY THIS SOFTWARE RELEASE UNDER ARTISTIC LICENSE.

SEE L<perlartistic>.

=cut

