#!/usr/bin/env perl

use strict;
# use warnings; # Use just for development, otherwise leave warnings off

use Graphics::Framebuffer; # There are things to import, if you want, but they
                           # are usually not needed.

## Initialize any global variables here ######################################
# $FB is your framebuffer object.  See the documentation, if you want to pass
# any parameters when initializing the module, but no parameters should be
# just fine to get started.
our $FB = Graphics::Framebuffer->new();


##############################################################################

$FB->cls('OFF'); # Turn off the console cursor

# You can optionally set graphics mode here, but remember to turn on text mode
# before exiting.

$FB->graphics_mode(); # Shuts off all text and cursors.

# Gathers information on the screen for you to use as global information
our $screen_info = $FB->screen_dimensions();

## Do your stuff in here #####################################################



##############################################################################

$FB->text_mode();  # Turn text and cursor back on.  You MUST do this if
                   # graphics mode was set.
$FB->cls('ON');    # Turn the console cursor back on
exit(0);

__END__

=head1 NAME

Template file for writing scripts that use Graphics::Framebuffer

=head1 SYNOPIS

First, copy this file, and name the copy whatever you want (using "yourscript"
for this example):

 cp template.pl yourscript.pl

Now edit "yourscript.pl" from now on.  Please do not directly edit "template.pl".

=head1 DESCRIPTION

Use this file as a starting point for writing your scripts.  Copy it so as to
not destroy the original template, then edit the copy.

=cut
