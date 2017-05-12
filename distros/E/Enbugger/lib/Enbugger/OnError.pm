package Enbugger::OnError;
$Enbugger::OnError::VERSION = '2.016';
# COPYRIGHT AND LICENCE
#
# Copyright (C) 2007,2008 WhitePages.com, Inc. with primary
# development by Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.

use strict;
use warnings;
use Carp();

use constant {
    'DEFAULT_SIGNALS' => [qw[ __DIE__ USR1 ]],
    'DEFAULT_HOOK'    => \&ExceptionHandler,
};

sub import {
    my ( $class, @signals ) = @_;
    
    my $hook = $class->DEFAULT_HOOK;
    my $signals =
      @signals
        ? \ @signals
          : $class->DEFAULT_SIGNALS;

    $class->hook_signals( $signals, $hook );
    
    return;
}

sub hook_signals {
    my ( $self, $signals, $hook ) = @_;
    
    @SIG{@$signals} = ($hook) x @$signals;
    
    return;
}

sub ExceptionHandler {

    # Find the list of things in %SIG that are trapped by this function.
    my ( @self_hooked_sigs, %self_hooked_sigs_lu );
    keys %SIG;
    while ( my ( $name, $handler ) = each %SIG ) {
        if ( ref $handler
             and $handler == \ &ExceptionHandler ) {
            push @self_hooked_sigs, $name;
            $self_hooked_sigs_lu{$name} = undef;
        }
    }

    # When we are in a __DIE__ handler, do not accept when there is an
    # outer eval scope. Perhaps this should be configurable policy.
    if ( ( $_[0] eq '__DIE__'
           or ( not exists $self_hooked_sigs_lu{$_[0]} ) )
         and exists $self_hooked_sigs_lu{__DIE__} ) {
        for (
             my $cx = 1;
             my ( undef, undef, undef, $function ) = caller $cx;
             ++ $cx
            ) {
            
            
            if ($function =~ /^\(eval *\d*\)\z/ ) {
                return 1;
            }
        }
    }
    
    
    # Do not re-enter this handler while in it. In theory I could work
    # on this to make it safe for being reentrant but that's just not
    # work I'm doing today. Feel free to do this and send patches.
    local @SIG{ @self_hooked_sigs } = ('IGNORE') x @self_hooked_sigs;
    
    

    # Enable the debugger even if it wasn't used at compilation
    # time. ->debugger points to whatever the locally preferred
    # debugger is.
    require Enbugger;
    Enbugger->load_debugger;
    
    # Log the current exception.
    Enbugger->write( Carp::longmess("Received signal $_[0]") );
    
    
    # Trigger the debugger. I did some trial and error to get
    # this. perl5db.pl pays attention to $DB::signal. $^P gets set (if
    # it wasn't already) to statement level debugging and then enter
    # the DB() function. I originally tried this as goto &DB::DB but
    # found that I'd get popped out of the debugger. Whoops.
    Enbugger->stop;

    $@ = $_[0];
    DB::DB();
}


=begin emacs

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:

=end emacs

=cut

() = -.0
