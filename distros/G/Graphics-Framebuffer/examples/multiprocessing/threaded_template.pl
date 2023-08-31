#!/usr/bin/env perl

use strict;
# use warnings; # Use just for development, otherwise leave warnings off
use constants {
    TRUE  => 1,
    FALSE => 0,
};

use threads;
use threads::shared;
use Sys::CPU;              # Finds the number of cores your CPU has
use Graphics::Framebuffer; # There are things to import, if you want, but they
                           # are usually not needed.

##############################################################################
## Initialize any global variables here ######################################

our $threads = Sys::CPU::cpu_count();

##############################################################################
# Initialize any shared variables here

our $RUNNING : shared  = TRUE;
our $OK_START : shared = FALSE;

##############################################################################
# Initialize your threads here, to prevent copying any unneeded large
# variables.
our @THREADS;
for (my $count=0;$count < $threads;$count++) {
    push(@THREADS,threads->create(\&thread_runner,[$parameter]));
}

##############################################################################

# It's good to have a framebuffer object open in the main thread.
# $FB is your framebuffer object.  See the documentation, if you want to pass
# any parameters when initializing the module, but no parameters should be
# just fine to get started.
my $FB = Graphics::Framebuffer->new();

$FB->cls('OFF'); # Turn off the console cursor

# You can optionally set graphics mode here, but remember to turn on text mode
# before exiting.

$FB->graphics_mode(); # Shuts off all text and cursors.

# Gathers information on the screen for you to use as global information
our $screen_info = $FB->screen_dimensions();

alarm 0;
$SIG{'ALRM'} = sub { # Hard exit if a thread is hung and won't play nice
    $FB->text_mode();
    foreach my $t (@THREADS) {
        $t->kill('KILL')->detach();
    }
    exec('reset');
};
foreach my $sig (qw(INT HUP TERM QUIT KILL)) {
    $SIG{$sig} = \&finish;
}
## Do your stuff in here #####################################################



##############################################################################

$RUNNING = FALSE;  # Tell threads to exit
$FB->text_mode();  # Turn text and cursor back on.  You MUST do this if
                   # graphics mode was set.
$FB->cls('ON');    # Turn the console cursor back on
exit(0);

sub finish {
    $RUNNING = FALSE;
    alarm 20;
    foreach my $t (@THREADS) {
        $t->join();
    }
    exec('reset');
}

# You want your thread to remain running and act as a job processor.  It is
# not good to call and exit threads a lot.  So set up shared variables to
# communicate between threads.
#
# If your thread is going to set a shared variable, then make sure to use
# locking to prevent another thread from stepping on its toes:
#
#    {
#        lock($variable);
#        $variable = "something";
#    }

sub thread_runner {
    my $parameters = shift;

    while($RUNNING && ! $OK_START) {
        threads->yield(); # wait until the main process says it's ok to proceed.
    }

    if ($RUNNING) { # Always make sure the thread has permission to do more
        my $fb = Graphics::Framebuffer->new('SPLASH' => FALSE);
        foreach my $sig (qw(INT HUP TERM QUIT KILL)) {
            local $SIG{$sig} = sub {$fb->text_mode(); threads->exit; };
        }

        while($RUNNING) {
            # do your stuff in here
        }
    }
}

__END__

=head1 NAME

Threaded template file for writing scripts that use Graphics::Framebuffer and
threads.

=head1 SYNOPIS

First, copy this file, and name the copy whatever you want (using "yourscript"
for this example):

 cp threaded_template.pl yourscript.pl

Now edit "yourscript.pl" from now on.  Please do not directly edit
"threaded_template.pl".

=head1 DESCRIPTION

Use this file as a starting point for writing your scripts.  Copy it so as to
not destroy the original template, then edit the copy.

=cut
