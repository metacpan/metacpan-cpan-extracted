package Enbugger::NYTProf;
$Enbugger::NYTProf::VERSION = '2.016';
# COPYRIGHT AND LICENCE
#
# Copyright (C) 2007,2009 WhitePages.com, Inc. with primary
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


=head1 NAME

Enbugger::NYTProf - subclass for Devel::NYTProf profiler

=cut


use strict;
use vars qw( @ISA @Symbols );
BEGIN { @ISA = 'Enbugger' }
require B::Utils;




=head1 OVERRIDEN METHODS

=over

=item CLASS-E<gt>_load_debugger

=cut

sub _load_debugger {
    my ( $class ) = @_;
    
    # Compile D::NYTProf w/o the debugger on.
    Enbugger->_compile_with_nextstate();
    require Devel::NYTProf;

    # Install the debugger. Protect $^P from Enbugger's own PL_perldb clobbering.
    {
        local $^P;
        $class->init_debugger;
    }

    $class->load_source;

    # Install D::NYTProf's hooks.
    # TODO: Detect whether INIT has already passed. If not, just install the proper
    # INIT{} and let it happen at the right time.
    DB::_INIT();

    return;
}


1 if $B::Utils::file;
sub instrument_runtime {
    # Fix-up all previously compiled code to use the slots assigned
    # into PL_ppaddr.
    #
    # TODO: Devel::NYTProf itself prefers to keep Time::HiRes uninstrumented 
    # so don't do it. Also, avoid instrumenting Devel::NYTProf.
    B::Utils::walkallops_simple( sub { return if
                                           'B::NULL' eq ref $_[0]
                                           || $B::Utils::file =~ m{
                                               (?:
                                                   Devel/NYTProf\.pm
                                                 | Devel/NYTProf/Core\.pm
                                                 | Time/HiRes\.pm
                                               )
                                               \z
                                             }x;
                                       Enbugger::NYTProf::instrument_op($_[0]);
                                   });

}




=back

=cut




# Load up a list of symbols known to be associated with this
# debugger. Enbugger, the base class will use this to guess at which
# debugger has been loaded if it was loaded prior to Enbugger being
# around.
1 if %Enbugger::RegisteredDebuggers;
$Enbugger::RegisteredDebuggers{NYTProf}{symbols} = [qw[
    DB
    DB_profiler
    _INIT
    __ANON__[/opt/perl-5.10.0/lib/site_perl/5.10.0/darwin-2level/Devel/NYTProf.pm:39]
    _finish
    args
    dbline
    disable_profile
    enable_profile
    finish_profile
    init_profiler
    postponed
    set_option
    signal
    single
    sub
    trace
]];

() = -.0

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
