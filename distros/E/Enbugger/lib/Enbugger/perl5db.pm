package Enbugger::perl5db;
$Enbugger::perl5db::VERSION = '2.016';
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


=head1 NAME

Enbugger::perl5db - subclass for the ordinary perl5db.pl debugger

=cut


use strict;
use vars qw( @ISA @Symbols );
BEGIN { @ISA = 'Enbugger' }




=head1 OVERRIDEN METHODS

=over

=item CLASS-E<gt>_load_debugger

=cut

sub _load_debugger {
    my ( $class ) = @_;
    
    $class->_compile_with_nextstate();
    require 'perl5db.pl';
    $class->_compile_with_dbstate();

    # FIXME: Why is this fix-up necessary? It's apparently something
    # funny about how I sometimes choose to set PERLDB_OPTS=noTTY.
    $DB::LINEINFO = $DB::OUT if ! defined $DB::LINEINFO;

    $class->init_debugger;
    
    return;
}





=item CLASS-E<gt>_stop

=cut

1 if $DB::signal;
sub _stop {

    # perl5db looks for this to stop.
    $DB::signal = 1;

    # Use at least the default debug flags.
    $^P |= 0x33f;

    return;
}





=item CLASS-E<gt>_write( TEXT )

=cut

1 if $DB::OUT;
sub _write {
    my $class = shift @_;

    print { $DB::OUT } @_;

    return;
}





=back

=cut




# Load up a list of symbols known to be associated with this
# debugger. Enbugger, the base class will use this to guess at which
# debugger has been loaded if it was loaded prior to Enbugger being
# around.
1 if %Enbugger::RegisteredDebuggers;
$Enbugger::RegisteredDebuggers{perl5db}{symbols} = [qw[
    ARGS
    BEGIN
    CommandSet
    CreateTTY
    CvGV_name
    CvGV_name_or_bust
    DB
    DBGR
    DollarCaretP
    DollarCaretP_flags
    DollarCaretP_flags_r
    END
    FD_TO_CLOSE
    IN
    I_m_init
    ImmediateStop
    LINEINFO
    LineInfo
    NonStop
    OUT
    ReadLine
    RememberOnROptions
    RemotePort
    SAVEIN
    SAVEOUT
    Snocheck
    Spatt
    Srev
    TTY
    VERSION
    XT
    a
    action
    after
    afterinit
    alias
    arg
    args
    arrow
    b
    balanced_brace_re
    break_on_filename_line
    break_on_filename_line_range
    break_on_line
    break_on_load
    break_subroutine
    breakable_line
    breakable_line_in_filename
    catch
    clean_ENV
    cmd
    cmd_A
    cmd_B
    cmd_E
    cmd_L
    cmd_M
    cmd_O
    cmd_W
    cmd_a
    cmd_b
    cmd_b_line
    cmd_b_load
    cmd_b_sub
    cmd_e
    cmd_h
    cmd_i
    cmd_l
    cmd_o
    cmd_pre580_D
    cmd_pre580_W
    cmd_pre580_a
    cmd_pre580_b
    cmd_pre580_h
    cmd_pre580_null
    cmd_pre590_prepost
    cmd_prepost
    cmd_stop
    cmd_v
    cmd_w
    cmd_wrapper
    cmdfhs
    cond
    console
    create_IN_OUT
    db_complete
    db_stop
    dbdie
    dbline
    dbwarn
    deep
    delete_action
    delete_breakpoint
    dieLevel
    diesignal
    doccmd
    doret
    dump_option
    dump_trace
    dumpit
    emacs
    end
    end_report
    eval
    evalarg
    expand_DollarCaretP_flags
    fake::
    fall_off_end
    file
    filename
    filename_error
    filename_ini
    find_sub
    finished
    fix_less
    fork_TTY
    frame
    get_fork_TTY
    get_list
    gets
    had_breakpoints
    header
    help
    hist
    histfile
    histsize
    i
    incr
    incr_pos
    infix
    inhibit_exit
    ini_INC
    ini_pids
    ini_warn
    inpat
    is_safe_file
    j
    l
    laststep
    level
    line
    lineinfo
    list_modules
    load_hist
    lock
    macosx_get_fork_TTY
    max
    maxtrace
    methods
    methods_via
    noTTY
    notty
    od
    old_watch
    onetimeDump
    onetimedumpDepth
    option
    optionAction
    optionRequire
    optionVars
    option_val
    options
    options2remember
    ornaments
    os2_get_fork_TTY
    osingle
    otrace
    package
    packname
    pager
    panic
    parse_DollarCaretP_flags
    parse_options
    pat
    pidprompt
    pids
    pieces
    piped
    position
    post
    postponed
    postponed_file
    postponed_sub
    prc
    pre
    pre580_help
    pre580_summary
    prefix
    pretype
    prevbus
    prevdie
    preview
    prevsegv
    prevwarn
    print_help
    print_lineinfo
    print_trace
    psh
    rc
    rcfile
    readline
    recallCommand
    remoteport
    report_break_on_load
    rerun
    res
    reset_IN_OUT
    resetterm
    restart
    rl
    rl_attribs
    runman
    runnonstop
    safe_do
    save
    save_hist
    saved
    savout
    second_time
    seen
    selected
    set_list
    sethelp
    setman
    setterm
    sh
    share
    shellBang
    signal
    signalLevel
    single
    skipCvGV
    slave_editor
    stack
    stack_depth
    start
    stop
    stuff
    sub
    subname
    subrange
    subroutine_filename_lines
    summary
    system
    term
    term_pid
    tkRunning
    to_watch
    trace
    truehist
    try
    tty
    typeahead
    unbalanced
    usercontext
    vars
    warn
    warnLevel
    watchfunction
    window
    xterm_get_fork_TTY
]];

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
