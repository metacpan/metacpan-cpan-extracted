###
###  Copyright (c) 2019 - 2024 Curtis Leach.  All rights reserved.
###
###  A crazy extension module for Fred::Fish::DBUG.
###
###  Module: Fred::Fish::DBUG::SignalKiller

=head1 NAME

Fred::Fish::DBUG::SignalKiller - A crazy extension module for Fred::Fish::DBUG.

=head1 SYNOPSIS

 use Fred::Fish::DBUG::SignalKiller;
   or 
 require Fred::Fish::DBUG::SignalKiller;

=head1 DESCRIPTION

All this module does is redirect Perl's core die method to a custom function.
So that whenever B<die> is called, it bypasses Perl's B<die> function in favor
of the one defined here by L<Fred::Fish::DBUG::SignalKiller>.

You only need to use this module if you wish to tell Perl to basically ignore
all calls to B<die>.  By running:

   DBUG_TRAP_SIGNAL ("__DIE__", DBUG_SIG_ACTION_LOG, @funcs);

After sourcing in this module, and making the above call to DBUG_TRAP_SIGNAL,
any calls to B<die> or B<croak> will log this request to B<fish>, call the
provided custom functions, and then return control to your program as if the
call to B<die> or B<croak> were just like any other function you called.
Basically causing your code to ignore B<eval> or B<try/catch> logic.  Breaking
a lot of logic in many, many modules that depend on it.

Needless to say this isn't really recomended.  But if you really, really want
to do this, just source in this module and then use the DBUG_SIG_ACTION_LOG
action for B<die> will work this way.  Otherwise if you don't source in this
module it will behave exactly the same as DBUG_SIG_ACTION_DIE instead.

I repeat again, you really, really don't want to use this module.  But if you
do, it's your funeral.

=head1 WHAT ABOUT THE OTHER ACTIONS FOR DIE?

All the other actions for B<die> work the same whether you source in this module
or not.  So why bother.

=head1 WHAT ABOUT THE OTHER SIGNALS?

All the other signals work the same whether you source in this module or not.
Except if you use DBUG_SIG_ACTION_DIE to trigger a call to B<die> and you've
told B<die> to use DBUG_SIG_ACTION_LOG.  In that case please reread the
DESCRIPTION for what's going to happen.  It's not pretty.

=cut


package Fred::Fish::DBUG::SignalKiller;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

# The module whose behaviour we want to modify
# so that we can sabotage everything else!
use Fred::Fish::DBUG::Signal 2.09;

$VERSION = "2.09";
@ISA = qw( Exporter );
@EXPORT = qw( );
@EXPORT_OK = qw( );


# ----------------------------------------------------------
# Redirectiong Perl's die/croak commands to this custom code.
# Needed so that we can implement:
#      DBUG_TRAP_SIGNAL ("__DIE__", DBUG_SIG_ACTION_LOG, @funcs);
# ----------------------------------------------------------

BEGIN
{
   *CORE::GLOBAL::die = \&_custom_fish_die;
   return;
}


# ----------------------------------------------------------
# The replacement to Perl's core die routine ...
# ----------------------------------------------------------
sub _custom_fish_die
{
   # Did someone request that die be trapped by Fred::Fish::DBUG::Signal?
   # It detects if someone reset $SIG{__DIE__} outside that module
   # and it will never return DBUG_SIG_ACTION_LOG in that case!

   my $action = DBUG_FIND_CURRENT_TRAPS ("__DIE__");

   # Let's get the DBUG function to call ...
   my $func;
   if ( $action == DBUG_SIG_ACTION_LOG ) {
      $func = $SIG{__DIE__} || "";
      if ( ref ( $func ) eq "CODE" ) {
         ;   # We have a good $func CODE value ...
      } elsif ( $func =~ m/^(.+)::([^:]+)$/ ) {
         $func = ${1}->can ($2);
         $action = 0  unless ( ref ( $func ) eq "CODE" );
      } else {
         $action = 0;  # Should never happen ...
      }
   }

   # We use "goto" so that any line numbers printed in fish will report
   # where it died instead of this custom function.
   if ( $action == DBUG_SIG_ACTION_LOG ) {
      # Tell the DBUG module this module has been sourced in!
      Fred::Fish::DBUG::Signal::_dbug_enable_signal_suicide ();

      my $msg = join ("", @_);
      @_ = ( $msg );
      goto &$func;     # Returns to the caller, not to this code !!!
   }

   # If we get here, we're back to using Perl's core die function ...
   goto &CORE::die;    # Will Auto-call $SIG{__DIE__}->(@_) if set ...

   return;             # Never gets here!
}


# -----------------------------------------------------------------------------
# End of Fred::Fish::DBUG::SignalKiller ...
# -----------------------------------------------------------------------------

=head1 SEE ALSO

L<Fred::Fish::DBUG> - The controlling module for this set of modules.  The one
you should be using.

L<Fred::Fish::DBUG::ON> - The live version of the B<fish> module.

L<Fred::Fish::DBUG::OFF> - The stub version of the B<fish> module.

L<Fred::Fish::DBUG::TIE> - Allows you to trap and log STDOUT/STDERR to B<fish>.

L<Fred::Fish::DBUG::Signal> - Handles the trapping and logging all signals to
B<fish>.

L<Fred::Fish::DBUG::Test> - A L<Test::More> wrapper to redirect test results to
B<fish>.

L<Fred::Fish::DBUG::Tutorial> - Sample code demonstrating using the B<fish>
module.

=head1 COPYRIGHT

Copyright (c) 2019 - 2024 Curtis Leach.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ==============================================================
#required if module is included w/ require command;
1;
