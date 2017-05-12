package Devel::Command::DBSub::DB_5_10;

sub import {
  if (my($sub_version) = 
        # 5.9.5's debugger is based on the 5.10 release.
        # 5.11 is (so far) based on 5.10 as well.
        ($] =~ /^5.010(.*)/ or
         $] =~ /^5.011(.*)/ or 
         $] =~ /^5.009005/)
     ) {
      return \&DB::alt_510_DB;
    }
    else {
      # Not 5.10 or 5.9.5.
      return undef;
  }
}

{
no strict;
no warnings;

package DB;

sub alt_510_DB {

    # lock the debugger and get the thread id for the prompt
	lock($DBGR);
	my $tid;
	if ($ENV{PERL5DB_THREADED}) {
		$tid = eval { "[".threads->tid."]" };
	}

    # Check for whether we should be running continuously or not.
    # _After_ the perl program is compiled, $single is set to 1:
    if ( $single and not $second_time++ ) {

        # Options say run non-stop. Run until we get an interrupt.
        if ($runnonstop) {    # Disable until signal
                # If there's any call stack in place, turn off single
                # stepping into subs throughout the stack.
            for ( $i = 0 ; $i <= $stack_depth ; ) {
                $stack[ $i++ ] &= ~1;
            }

            # And we are now no longer in single-step mode.
            $single = 0;

            # If we simply returned at this point, we wouldn't get
            # the trace info. Fall on through.
            # return;
        } ## end if ($runnonstop)

        elsif ($ImmediateStop) {

            # We are supposed to stop here; XXX probably a break.
            $ImmediateStop = 0;    # We've processed it; turn it off
            $signal        = 1;    # Simulate an interrupt to force
                                   # us into the command loop
        }
    } ## end if ($single and not $second_time...

    # If we're in single-step mode, or an interrupt (real or fake)
    # has occurred, turn off non-stop mode.
    $runnonstop = 0 if $single or $signal;

    # Preserve current values of $@, $!, $^E, $,, $/, $\, $^W.
    # The code being debugged may have altered them.
    &save;

    # Since DB::DB gets called after every line, we can use caller() to
    # figure out where we last were executing. Sneaky, eh? This works because
    # caller is returning all the extra information when called from the
    # debugger.
    local ( $package, $filename, $line ) = caller;
    local $filename_ini = $filename;

    # set up the context for DB::eval, so it can properly execute
    # code on behalf of the user. We add the package in so that the
    # code is eval'ed in the proper package (not in the debugger!).
    local $usercontext =
      '($@, $!, $^E, $,, $/, $\, $^W) = @saved;' . "package $package;";

    # Create an alias to the active file magical array to simplify
    # the code here.
    local (*dbline) = $main::{ '_<' . $filename };

    # we need to check for pseudofiles on Mac OS (these are files
    # not attached to a filename, but instead stored in Dev:Pseudo)
    if ( $^O eq 'MacOS' && $#dbline < 0 ) {
        $filename_ini = $filename = 'Dev:Pseudo';
        *dbline = $main::{ '_<' . $filename };
    }

    # Last line in the program.
    local $max = $#dbline;

    # if we have something here, see if we should break.
    if ( $dbline{$line}
        && ( ( $stop, $action ) = split( /\0/, $dbline{$line} ) ) )
    {

        # Stop if the stop criterion says to just stop.
        if ( $stop eq '1' ) {
            $signal |= 1;
        }

        # It's a conditional stop; eval it in the user's context and
        # see if we should stop. If so, remove the one-time sigil.
        elsif ($stop) {
            $evalarg = "\$DB::signal |= 1 if do {$stop}";
            &eval;
            $dbline{$line} =~ s/;9($|\0)/$1/;
        }
    } ## end if ($dbline{$line} && ...

    # Preserve the current stop-or-not, and see if any of the W
    # (watch expressions) has changed.
    my $was_signal = $signal;

    # If we have any watch expressions ...
    if ( $trace & 2 ) {
        for ( my $n = 0 ; $n <= $#to_watch ; $n++ ) {
            $evalarg = $to_watch[$n];
            local $onetimeDump;    # Tell DB::eval() to not output results

            # Fix context DB::eval() wants to return an array, but
            # we need a scalar here.
            my ($val) = join( "', '", &eval );
            $val = ( ( defined $val ) ? "'$val'" : 'undef' );

            # Did it change?
            if ( $val ne $old_watch[$n] ) {

                # Yep! Show the difference, and fake an interrupt.
                $signal = 1;
                print $OUT <<EOP;
Watchpoint $n:\t$to_watch[$n] changed:
    old value:\t$old_watch[$n]
    new value:\t$val
EOP
                $old_watch[$n] = $val;
            } ## end if ($val ne $old_watch...
        } ## end for (my $n = 0 ; $n <= ...
    } ## end if ($trace & 2)

    # If there's a user-defined DB::watchfunction, call it with the
    # current package, filename, and line. The function executes in
    # the DB:: package.
    if ( $trace & 4 ) {    # User-installed watch
        return
          if watchfunction( $package, $filename, $line )
          and not $single
          and not $was_signal
          and not( $trace & ~4 );
    } ## end if ($trace & 4)

    # Pick up any alteration to $signal in the watchfunction, and
    # turn off the signal now.
    $was_signal = $signal;
    $signal     = 0;

    # Check to see if we should grab control ($single true,
    # trace set appropriately, or we got a signal).
    if ( $single || ( $trace & 1 ) || $was_signal ) {

        # Yes, grab control.
        if ($slave_editor) {

            # Tell the editor to update its position.
            $position = "\032\032$filename:$line:0\n";
            print_lineinfo($position);
        }

        elsif ( $package eq 'DB::fake' ) {

            # Fallen off the end already.
            $term || &setterm;
            print_help(<<EOP);
Debugged program terminated.  Use B<q> to quit or B<R> to restart,
  use B<o> I<inhibit_exit> to avoid stopping after program termination,
  B<h q>, B<h R> or B<h o> to get additional info.  
EOP

            # Set the DB::eval context appropriately.
            $package     = 'main';
            $usercontext =
                '($@, $!, $^E, $,, $/, $\, $^W) = @saved;'
              . "package $package;";    # this won't let them modify, alas
        } ## end elsif ($package eq 'DB::fake')

        else {

            # Still somewhere in the midst of execution. Set up the
            #  debugger prompt.
            $sub =~ s/\'/::/;    # Swap Perl 4 package separators (') to
                                 # Perl 5 ones (sorry, we don't print Klingon
                                 #module names)

            $prefix = $sub =~ /::/ ? "" : "${'package'}::";
            $prefix .= "$sub($filename:";
            $after = ( $dbline[$line] =~ /\n$/ ? '' : "\n" );

            # Break up the prompt if it's really long.
            if ( length($prefix) > 30 ) {
                $position = "$prefix$line):\n$line:\t$dbline[$line]$after";
                $prefix   = "";
                $infix    = ":\t";
            }
            else {
                $infix    = "):\t";
                $position = "$prefix$line$infix$dbline[$line]$after";
            }

            # Print current line info, indenting if necessary.
            if ($frame) {
                print_lineinfo( ' ' x $stack_depth,
                    "$line:\t$dbline[$line]$after" );
            }
            else {
                print_lineinfo($position);
            }

            # Scan forward, stopping at either the end or the next
            # unbreakable line.
            for ( $i = $line + 1 ; $i <= $max && $dbline[$i] == 0 ; ++$i )
            {    #{ vi

                # Drop out on null statements, block closers, and comments.
                last if $dbline[$i] =~ /^\s*[\;\}\#\n]/;

                # Drop out if the user interrupted us.
                last if $signal;

                # Append a newline if the line doesn't have one. Can happen
                # in eval'ed text, for instance.
                $after = ( $dbline[$i] =~ /\n$/ ? '' : "\n" );

                # Next executable line.
                $incr_pos = "$prefix$i$infix$dbline[$i]$after";
                $position .= $incr_pos;
                if ($frame) {

                    # Print it indented if tracing is on.
                    print_lineinfo( ' ' x $stack_depth,
                        "$i:\t$dbline[$i]$after" );
                }
                else {
                    print_lineinfo($incr_pos);
                }
            } ## end for ($i = $line + 1 ; $i...
        } ## end else [ if ($slave_editor)
    } ## end if ($single || ($trace...

    # If there's an action, do it now.
    $evalarg = $action, &eval if $action;

    # Are we nested another level (e.g., did we evaluate a function
    # that had a breakpoint in it at the debugger prompt)?
    if ( $single || $was_signal ) {

        # Yes, go down a level.
        local $level = $level + 1;

        # Do any pre-prompt actions.
        foreach $evalarg (@$pre) {
            &eval;
        }

        # Complain about too much recursion if we passed the limit.
        print $OUT $stack_depth . " levels deep in subroutine calls!\n"
          if $single & 4;

        # The line we're currently on. Set $incr to -1 to stay here
        # until we get a command that tells us to advance.
        $start = $line;
        $incr  = -1;      # for backward motion.

        # Tack preprompt debugger actions ahead of any actual input.
        @typeahead = ( @$pretype, @typeahead );

        # The big command dispatch loop. It keeps running until the
        # user yields up control again.
        #
        # If we have a terminal for input, and we get something back
        # from readline(), keep on processing.
      CMD:
        while (

            # We have a terminal, or can get one ...
            ( $term || &setterm ),

            # ... and it belogs to this PID or we get one for this PID ...
            ( $term_pid == $$ or resetterm(1) ),

            # ... and we got a line of command input ...
            defined(
                $cmd = &readline(
                        "$pidprompt $tid DB"
                      . ( '<' x $level )
                      . ( $#hist + 1 )
                      . ( '>' x $level ) . " "
                )
            )
          )
        {

			share($cmd);
            # ... try to execute the input as debugger commands.

            # Don't stop running.
            $single = 0;

            # No signal is active.
            $signal = 0;

            # Handle continued commands (ending with \):
            $cmd =~ s/\\$/\n/ && do {
                $cmd .= &readline("  cont: ");
                redo CMD;
            };

            # Empty input means repeat the last command.
            $cmd =~ /^$/ && ( $cmd = $laststep );
            chomp($cmd);    # get rid of the annoying extra newline
            push( @hist, $cmd ) if length($cmd) > 1;
            push( @truehist, $cmd );
			share(@hist);
			share(@truehist);

            # This is a restart point for commands that didn't arrive
            # via direct user input. It allows us to 'redo PIPE' to
            # re-execute command processing without reading a new command.
          PIPE: {
                $cmd =~ s/^\s+//s;    # trim annoying leading whitespace
                $cmd =~ s/\s+$//s;    # trim annoying trailing whitespace
                ($i) = split( /\s+/, $cmd );

                # See if there's an alias for the command, and set it up if so.
                if ( $alias{$i} ) {

                    # Squelch signal handling; we want to keep control here
                    # if something goes loco during the alias eval.
                    local $SIG{__DIE__};
                    local $SIG{__WARN__};

                    # This is a command, so we eval it in the DEBUGGER's
                    # scope! Otherwise, we can't see the special debugger
                    # variables, or get to the debugger's subs. (Well, we
                    # _could_, but why make it even more complicated?)
                    eval "\$cmd =~ $alias{$i}";
                    if ($@) {
                        local $\ = '';
                        print $OUT "Couldn't evaluate `$i' alias: $@";
                        next CMD;
                    }
                } ## end if ($alias{$i})

                ### Extended commands

                ### Define your extended commands in C<%commands> at the top of the file.
                ### This section runs them.

                foreach my $do (keys %DB::commands) {
                 next unless $cmd =~ /^$do\s*/;
                 $commands{$do}->($cmd) and next CMD;
                 #  ? next CMD : last CMD;
                }

                $cmd =~ /^q$/ && do {
                    $fall_off_end = 1;
                    clean_ENV();
                    exit $?;
                };

                $cmd =~ /^t$/ && do {
                    $trace ^= 1;
                    local $\ = '';
                    print $OUT "Trace = "
                      . ( ( $trace & 1 ) ? "on" : "off" ) . "\n";
                    next CMD;
                };

                $cmd =~ /^S(\s+(!)?(.+))?$/ && do {

                    $Srev     = defined $2;     # Reverse scan?
                    $Spatt    = $3;             # The pattern (if any) to use.
                    $Snocheck = !defined $1;    # No args - print all subs.

                    # Need to make these sane here.
                    local $\ = '';
                    local $, = '';

                    # Search through the debugger's magical hash of subs.
                    # If $nocheck is true, just print the sub name.
                    # Otherwise, check it against the pattern. We then use
                    # the XOR trick to reverse the condition as required.
                    foreach $subname ( sort( keys %sub ) ) {
                        if ( $Snocheck or $Srev ^ ( $subname =~ /$Spatt/ ) ) {
                            print $OUT $subname, "\n";
                        }
                    }
                    next CMD;
                };

                $cmd =~ s/^X\b/V $package/;

                # Bare V commands get the currently-being-debugged package
                # added.
                $cmd =~ /^V$/ && do {
                    $cmd = "V $package";
                };

                # V - show variables in package.
                $cmd =~ /^V\b\s*(\S+)\s*(.*)/ && do {

                    # Save the currently selected filehandle and
                    # force output to debugger's filehandle (dumpvar
                    # just does "print" for output).
                    local ($savout) = select($OUT);

                    # Grab package name and variables to dump.
                    $packname = $1;
                    @vars     = split( ' ', $2 );

                    # If main::dumpvar isn't here, get it.
                    do 'dumpvar.pl' || die $@ unless defined &main::dumpvar;
                    if ( defined &main::dumpvar ) {

                        # We got it. Turn off subroutine entry/exit messages
                        # for the moment, along with return values.
                        local $frame = 0;
                        local $doret = -2;

                        # must detect sigpipe failures  - not catching
                        # then will cause the debugger to die.
                        eval {
                            &main::dumpvar(
                                $packname,
                                defined $option{dumpDepth}
                                ? $option{dumpDepth}
                                : -1,    # assume -1 unless specified
                                @vars
                            );
                        };

                        # The die doesn't need to include the $@, because
                        # it will automatically get propagated for us.
                        if ($@) {
                            die unless $@ =~ /dumpvar print failed/;
                        }
                    } ## end if (defined &main::dumpvar)
                    else {

                        # Couldn't load dumpvar.
                        print $OUT "dumpvar.pl not available.\n";
                    }

                    # Restore the output filehandle, and go round again.
                    select($savout);
                    next CMD;
                };

                $cmd =~ s/^x\b/ / && do {    # Remainder gets done by DB::eval()
                    $onetimeDump = 'dump';    # main::dumpvar shows the output

                    # handle special  "x 3 blah" syntax XXX propagate
                    # doc back to special variables.
                    if ( $cmd =~ s/^\s*(\d+)(?=\s)/ / ) {
                        $onetimedumpDepth = $1;
                    }
                };

                $cmd =~ s/^m\s+([\w:]+)\s*$/ / && do {
                    methods($1);
                    next CMD;
                };

                # m expr - set up DB::eval to do the work
                $cmd =~ s/^m\b/ / && do {    # Rest gets done by DB::eval()
                    $onetimeDump = 'methods';   #  method output gets used there
                };

                $cmd =~ /^f\b\s*(.*)/ && do {
                    $file = $1;
                    $file =~ s/\s+$//;

                    # help for no arguments (old-style was return from sub).
                    if ( !$file ) {
                        print $OUT
                          "The old f command is now the r command.\n";    # hint
                        print $OUT "The new f command switches filenames.\n";
                        next CMD;
                    } ## end if (!$file)

                    # if not in magic file list, try a close match.
                    if ( !defined $main::{ '_<' . $file } ) {
                        if ( ($try) = grep( m#^_<.*$file#, keys %main:: ) ) {
                            {
                                $try = substr( $try, 2 );
                                print $OUT "Choosing $try matching `$file':\n";
                                $file = $try;
                            }
                        } ## end if (($try) = grep(m#^_<.*$file#...
                    } ## end if (!defined $main::{ ...

                    # If not successfully switched now, we failed.
                    if ( !defined $main::{ '_<' . $file } ) {
                        print $OUT "No file matching `$file' is loaded.\n";
                        next CMD;
                    }

                    # We switched, so switch the debugger internals around.
                    elsif ( $file ne $filename ) {
                        *dbline   = $main::{ '_<' . $file };
                        $max      = $#dbline;
                        $filename = $file;
                        $start    = 1;
                        $cmd      = "l";
                    } ## end elsif ($file ne $filename)

                    # We didn't switch; say we didn't.
                    else {
                        print $OUT "Already in $file.\n";
                        next CMD;
                    }
                };

                # . command.
                $cmd =~ /^\.$/ && do {
                    $incr = -1;    # stay at current line

                    # Reset everything to the old location.
                    $start    = $line;
                    $filename = $filename_ini;
                    *dbline   = $main::{ '_<' . $filename };
                    $max      = $#dbline;

                    # Now where are we?
                    print_lineinfo($position);
                    next CMD;
                };

                # - - back a window.
                $cmd =~ /^-$/ && do {

                    # back up by a window; go to 1 if back too far.
                    $start -= $incr + $window + 1;
                    $start = 1 if $start <= 0;
                    $incr  = $window - 1;

                    # Generate and execute a "l +" command (handled below).
                    $cmd = 'l ' . ($start) . '+';
                };

                # All of these commands were remapped in perl 5.8.0;
                # we send them off to the secondary dispatcher (see below).
                $cmd =~ /^([aAbBeEhilLMoOPvwW]\b|[<>\{]{1,2})\s*(.*)/so && do {
                    &cmd_wrapper( $1, $2, $line );
                    next CMD;
                };

                $cmd =~ /^y(?:\s+(\d*)\s*(.*))?$/ && do {

                    # See if we've got the necessary support.
                    eval { require PadWalker; PadWalker->VERSION(0.08) }
                      or &warn(
                        $@ =~ /locate/
                        ? "PadWalker module not found - please install\n"
                        : $@
                      )
                      and next CMD;

                    # Load up dumpvar if we don't have it. If we can, that is.
                    do 'dumpvar.pl' || die $@ unless defined &main::dumpvar;
                    defined &main::dumpvar
                      or print $OUT "dumpvar.pl not available.\n"
                      and next CMD;

                    # Got all the modules we need. Find them and print them.
                    my @vars = split( ' ', $2 || '' );

                    # Find the pad.
                    my $h = eval { PadWalker::peek_my( ( $1 || 0 ) + 1 ) };

                    # Oops. Can't find it.
                    $@ and $@ =~ s/ at .*//, &warn($@), next CMD;

                    # Show the desired vars with dumplex().
                    my $savout = select($OUT);

                    # Have dumplex dump the lexicals.
                    dumpvar::dumplex( $_, $h->{$_},
                        defined $option{dumpDepth} ? $option{dumpDepth} : -1,
                        @vars )
                      for sort keys %$h;
                    select($savout);
                    next CMD;
                };

                # n - next
                $cmd =~ /^n$/ && do {
                    end_report(), next CMD if $finished and $level <= 1;

                    # Single step, but don't enter subs.
                    $single = 2;

                    # Save for empty command (repeat last).
                    $laststep = $cmd;
                    last CMD;
                };

                # s - single step.
                $cmd =~ /^s$/ && do {

                    # Get out and restart the command loop if program
                    # has finished.
                    end_report(), next CMD if $finished and $level <= 1;

                    # Single step should enter subs.
                    $single = 1;

                    # Save for empty command (repeat last).
                    $laststep = $cmd;
                    last CMD;
                };


                # c - start continuous execution.
                $cmd =~ /^c\b\s*([\w:]*)\s*$/ && do {

                    # Hey, show's over. The debugged program finished
                    # executing already.
                    end_report(), next CMD if $finished and $level <= 1;

                    # Capture the place to put a one-time break.
                    $subname = $i = $1;

                    #  Probably not needed, since we finish an interactive
                    #  sub-session anyway...
                    # local $filename = $filename;
                    # local *dbline = *dbline; # XXX Would this work?!
                    #
                    # The above question wonders if localizing the alias
                    # to the magic array works or not. Since it's commented
                    # out, we'll just leave that to speculation for now.

                    # If the "subname" isn't all digits, we'll assume it
                    # is a subroutine name, and try to find it.
                    if ( $subname =~ /\D/ ) {    # subroutine name
                            # Qualify it to the current package unless it's
                            # already qualified.
                        $subname = $package . "::" . $subname
                          unless $subname =~ /::/;

                        # find_sub will return "file:line_number" corresponding
                        # to where the subroutine is defined; we call find_sub,
                        # break up the return value, and assign it in one
                        # operation.
                        ( $file, $i ) = ( find_sub($subname) =~ /^(.*):(.*)$/ );

                        # Force the line number to be numeric.
                        $i += 0;

                        # If we got a line number, we found the sub.
                        if ($i) {

                            # Switch all the debugger's internals around so
                            # we're actually working with that file.
                            $filename = $file;
                            *dbline   = $main::{ '_<' . $filename };

                            # Mark that there's a breakpoint in this file.
                            $had_breakpoints{$filename} |= 1;

                            # Scan forward to the first executable line
                            # after the 'sub whatever' line.
                            $max = $#dbline;
                            ++$i while $dbline[$i] == 0 && $i < $max;
                        } ## end if ($i)

                        # We didn't find a sub by that name.
                        else {
                            print $OUT "Subroutine $subname not found.\n";
                            next CMD;
                        }
                    } ## end if ($subname =~ /\D/)

                    # At this point, either the subname was all digits (an
                    # absolute line-break request) or we've scanned through
                    # the code following the definition of the sub, looking
                    # for an executable, which we may or may not have found.
                    #
                    # If $i (which we set $subname from) is non-zero, we
                    # got a request to break at some line somewhere. On
                    # one hand, if there wasn't any real subroutine name
                    # involved, this will be a request to break in the current
                    # file at the specified line, so we have to check to make
                    # sure that the line specified really is breakable.
                    #
                    # On the other hand, if there was a subname supplied, the
                    # preceding block has moved us to the proper file and
                    # location within that file, and then scanned forward
                    # looking for the next executable line. We have to make
                    # sure that one was found.
                    #
                    # On the gripping hand, we can't do anything unless the
                    # current value of $i points to a valid breakable line.
                    # Check that.
                    if ($i) {

                        # Breakable?
                        if ( $dbline[$i] == 0 ) {
                            print $OUT "Line $i not breakable.\n";
                            next CMD;
                        }

                        # Yes. Set up the one-time-break sigil.
                        $dbline{$i} =~ s/($|\0)/;9$1/;  # add one-time-only b.p.
                    } ## end if ($i)

                    # Turn off stack tracing from here up.
                    for ( $i = 0 ; $i <= $stack_depth ; ) {
                        $stack[ $i++ ] &= ~1;
                    }
                    last CMD;
                };

                # r - return from the current subroutine.
                $cmd =~ /^r$/ && do {

                    # Can't do anythign if the program's over.
                    end_report(), next CMD if $finished and $level <= 1;

                    # Turn on stack trace.
                    $stack[$stack_depth] |= 1;

                    # Print return value unless the stack is empty.
                    $doret = $option{PrintRet} ? $stack_depth - 1 : -2;
                    last CMD;
                };

                $cmd =~ /^T$/ && do {
                    print_trace( $OUT, 1 );    # skip DB
                    next CMD;
                };

                $cmd =~ /^w\b\s*(.*)/s && do { &cmd_w( 'w', $1 ); next CMD; };

                $cmd =~ /^W\b\s*(.*)/s && do { &cmd_W( 'W', $1 ); next CMD; };

                $cmd =~ /^\/(.*)$/ && do {

                    # The pattern as a string.
                    $inpat = $1;

                    # Remove the final slash.
                    $inpat =~ s:([^\\])/$:$1:;

                    # If the pattern isn't null ...
                    if ( $inpat ne "" ) {

                        # Turn of warn and die procesing for a bit.
                        local $SIG{__DIE__};
                        local $SIG{__WARN__};

                        # Create the pattern.
                        eval '$inpat =~ m' . "\a$inpat\a";
                        if ( $@ ne "" ) {

                            # Oops. Bad pattern. No biscuit.
                            # Print the eval error and go back for more
                            # commands.
                            print $OUT "$@";
                            next CMD;
                        }
                        $pat = $inpat;
                    } ## end if ($inpat ne "")

                    # Set up to stop on wrap-around.
                    $end = $start;

                    # Don't move off the current line.
                    $incr = -1;

                    # Done in eval so nothing breaks if the pattern
                    # does something weird.
                    eval '
                        for (;;) {
                            # Move ahead one line.
                            ++$start;

                            # Wrap if we pass the last line.
                            $start = 1 if ($start > $max);

                            # Stop if we have gotten back to this line again,
                            last if ($start == $end);

                            # A hit! (Note, though, that we are doing
                            # case-insensitive matching. Maybe a qr//
                            # expression would be better, so the user could
                            # do case-sensitive matching if desired.
                            if ($dbline[$start] =~ m' . "\a$pat\a" . 'i) {
                                if ($slave_editor) {
                                    # Handle proper escaping in the slave.
                                    print $OUT "\032\032$filename:$start:0\n";
                                } 
                                else {
                                    # Just print the line normally.
                                    print $OUT "$start:\t",$dbline[$start],"\n";
                                }
                                # And quit since we found something.
                                last;
                            }
                         } ';

                    # If we wrapped, there never was a match.
                    print $OUT "/$pat/: not found\n" if ( $start == $end );
                    next CMD;
                };

                # ? - backward pattern search.
                $cmd =~ /^\?(.*)$/ && do {

                    # Get the pattern, remove trailing question mark.
                    $inpat = $1;
                    $inpat =~ s:([^\\])\?$:$1:;

                    # If we've got one ...
                    if ( $inpat ne "" ) {

                        # Turn off die & warn handlers.
                        local $SIG{__DIE__};
                        local $SIG{__WARN__};
                        eval '$inpat =~ m' . "\a$inpat\a";

                        if ( $@ ne "" ) {

                            # Ouch. Not good. Print the error.
                            print $OUT $@;
                            next CMD;
                        }
                        $pat = $inpat;
                    } ## end if ($inpat ne "")

                    # Where we are now is where to stop after wraparound.
                    $end = $start;

                    # Don't move away from this line.
                    $incr = -1;

                    # Search inside the eval to prevent pattern badness
                    # from killing us.
                    eval '
                        for (;;) {
                            # Back up a line.
                            --$start;

                            # Wrap if we pass the first line.

                            $start = $max if ($start <= 0);

                            # Quit if we get back where we started,
                            last if ($start == $end);

                            # Match?
                            if ($dbline[$start] =~ m' . "\a$pat\a" . 'i) {
                                if ($slave_editor) {
                                    # Yep, follow slave editor requirements.
                                    print $OUT "\032\032$filename:$start:0\n";
                                } 
                                else {
                                    # Yep, just print normally.
                                    print $OUT "$start:\t",$dbline[$start],"\n";
                                }

                                # Found, so done.
                                last;
                            }
                        } ';

                    # Say we failed if the loop never found anything,
                    print $OUT "?$pat?: not found\n" if ( $start == $end );
                    next CMD;
                };

                # $rc - recall command.
                $cmd =~ /^$rc+\s*(-)?(\d+)?$/ && do {

                    # No arguments, take one thing off history.
                    pop(@hist) if length($cmd) > 1;

                    # Relative (- found)?
                    #  Y - index back from most recent (by 1 if bare minus)
                    #  N - go to that particular command slot or the last
                    #      thing if nothing following.
                    $i = $1 ? ( $#hist - ( $2 || 1 ) ) : ( $2 || $#hist );

                    # Pick out the command desired.
                    $cmd = $hist[$i];

                    # Print the command to be executed and restart the loop
                    # with that command in the buffer.
                    print $OUT $cmd, "\n";
                    redo CMD;
                };

                # $sh$sh - run a shell command (if it's all ASCII).
                # Can't run shell commands with Unicode in the debugger, hmm.
                $cmd =~ /^$sh$sh\s*([\x00-\xff]*)/ && do {

                    # System it.
                    &system($1);
                    next CMD;
                };

                # $rc pattern $rc - find a command in the history.
                $cmd =~ /^$rc([^$rc].*)$/ && do {

                    # Create the pattern to use.
                    $pat = "^$1";

                    # Toss off last entry if length is >1 (and it always is).
                    pop(@hist) if length($cmd) > 1;

                    # Look backward through the history.
                    for ( $i = $#hist ; $i ; --$i ) {

                        # Stop if we find it.
                        last if $hist[$i] =~ /$pat/;
                    }

                    if ( !$i ) {

                        # Never found it.
                        print $OUT "No such command!\n\n";
                        next CMD;
                    }

                    # Found it. Put it in the buffer, print it, and process it.
                    $cmd = $hist[$i];
                    print $OUT $cmd, "\n";
                    redo CMD;
                };

                # $sh - start a shell.
                $cmd =~ /^$sh$/ && do {

                    # Run the user's shell. If none defined, run Bourne.
                    # We resume execution when the shell terminates.
                    &system( $ENV{SHELL} || "/bin/sh" );
                    next CMD;
                };

                # $sh command - start a shell and run a command in it.
                $cmd =~ /^$sh\s*([\x00-\xff]*)/ && do {

                    # XXX: using csh or tcsh destroys sigint retvals!
                    #&system($1);  # use this instead

                    # use the user's shell, or Bourne if none defined.
                    &system( $ENV{SHELL} || "/bin/sh", "-c", $1 );
                    next CMD;
                };

                $cmd =~ /^H\b\s*\*/ && do {
                    @hist = @truehist = ();
                    print $OUT "History cleansed\n";
                    next CMD;
                };

                $cmd =~ /^H\b\s*(-(\d+))?/ && do {

                    # Anything other than negative numbers is ignored by
                    # the (incorrect) pattern, so this test does nothing.
                    $end = $2 ? ( $#hist - $2 ) : 0;

                    # Set to the minimum if less than zero.
                    $hist = 0 if $hist < 0;

                    # Start at the end of the array.
                    # Stay in while we're still above the ending value.
                    # Tick back by one each time around the loop.
                    for ( $i = $#hist ; $i > $end ; $i-- ) {

                        # Print the command  unless it has no arguments.
                        print $OUT "$i: ", $hist[$i], "\n"
                          unless $hist[$i] =~ /^.?$/;
                    }
                    next CMD;
                };

                # man, perldoc, doc - show manual pages.
                $cmd =~ /^(?:man|(?:perl)?doc)\b(?:\s+([^(]*))?$/ && do {
                    runman($1);
                    next CMD;
                };

                # p - print (no args): print $_.
                $cmd =~ s/^p$/print {\$DB::OUT} \$_/;

                # p - print the given expression.
                $cmd =~ s/^p\b/print {\$DB::OUT} /;

                # = - set up a command alias.
                $cmd =~ s/^=\s*// && do {
                    my @keys;
                    if ( length $cmd == 0 ) {

                        # No args, get current aliases.
                        @keys = sort keys %alias;
                    }
                    elsif ( my ( $k, $v ) = ( $cmd =~ /^(\S+)\s+(\S.*)/ ) ) {

                        # Creating a new alias. $k is alias name, $v is
                        # alias value.

                        # can't use $_ or kill //g state
                        for my $x ( $k, $v ) {

                            # Escape "alarm" characters.
                            $x =~ s/\a/\\a/g;
                        }

                        # Substitute key for value, using alarm chars
                        # as separators (which is why we escaped them in
                        # the command).
                        $alias{$k} = "s\a$k\a$v\a";

                        # Turn off standard warn and die behavior.
                        local $SIG{__DIE__};
                        local $SIG{__WARN__};

                        # Is it valid Perl?
                        unless ( eval "sub { s\a$k\a$v\a }; 1" ) {

                            # Nope. Bad alias. Say so and get out.
                            print $OUT "Can't alias $k to $v: $@\n";
                            delete $alias{$k};
                            next CMD;
                        }

                        # We'll only list the new one.
                        @keys = ($k);
                    } ## end elsif (my ($k, $v) = ($cmd...

                    # The argument is the alias to list.
                    else {
                        @keys = ($cmd);
                    }

                    # List aliases.
                    for my $k (@keys) {

                        # Messy metaquoting: Trim the substiution code off.
                        # We use control-G as the delimiter because it's not
                        # likely to appear in the alias.
                        if ( ( my $v = $alias{$k} ) =~ ss\a$k\a(.*)\a$1 ) {

                            # Print the alias.
                            print $OUT "$k\t= $1\n";
                        }
                        elsif ( defined $alias{$k} ) {

                            # Couldn't trim it off; just print the alias code.
                            print $OUT "$k\t$alias{$k}\n";
                        }
                        else {

                            # No such, dude.
                            print "No alias for $k\n";
                        }
                    } ## end for my $k (@keys)
                    next CMD;
                };

                # source - read commands from a file (or pipe!) and execute.
                $cmd =~ /^source\s+(.*\S)/ && do {
                    if ( open my $fh, $1 ) {

                        # Opened OK; stick it in the list of file handles.
                        push @cmdfhs, $fh;
                    }
                    else {

                        # Couldn't open it.
                        &warn("Can't execute `$1': $!\n");
                    }
                    next CMD;
                };

                # save source - write commands to a file for later use
                $cmd =~ /^save\s*(.*)$/ && do {
                    my $file = $1 || '.perl5dbrc';    # default?
                    if ( open my $fh, "> $file" ) {

                       # chomp to remove extraneous newlines from source'd files
                        chomp( my @truelist =
                              map { m/^\s*(save|source)/ ? "#$_" : $_ }
                              @truehist );
                        print $fh join( "\n", @truelist );
                        print "commands saved in $file\n";
                    }
                    else {
                        &warn("Can't save debugger commands in '$1': $!\n");
                    }
                    next CMD;
                };

                # R - restart execution.
                # rerun - controlled restart execution.
                $cmd =~ /^(R|rerun\s*(.*))$/ && do {
                    my @args = ($1 eq 'R' ? restart() : rerun($2));

                    # Close all non-system fds for a clean restart.  A more
                    # correct method would be to close all fds that were not
                    # open when the process started, but this seems to be
                    # hard.  See "debugger 'R'estart and open database
                    # connections" on p5p.

                    my $max_fd = 1024; # default if POSIX can't be loaded
                    if (eval { require POSIX }) {
                        $max_fd = POSIX::sysconf(POSIX::_SC_OPEN_MAX());
                    }

                    if (defined $max_fd) {
                        foreach ($^F+1 .. $max_fd-1) {
                            next unless open FD_TO_CLOSE, "<&=$_";
                            close(FD_TO_CLOSE);
                        }
                    }

                    # And run Perl again.  We use exec() to keep the
                    # PID stable (and that way $ini_pids is still valid).
                    exec(@args) || print $OUT "exec failed: $!\n";

                    last CMD;
                };

                # || - run command in the pager, with output to DB::OUT.
                $cmd =~ /^\|\|?\s*[^|]/ && do {
                    if ( $pager =~ /^\|/ ) {

                        # Default pager is into a pipe. Redirect I/O.
                        open( SAVEOUT, ">&STDOUT" )
                          || &warn("Can't save STDOUT");
                        open( STDOUT, ">&OUT" )
                          || &warn("Can't redirect STDOUT");
                    } ## end if ($pager =~ /^\|/)
                    else {

                        # Not into a pipe. STDOUT is safe.
                        open( SAVEOUT, ">&OUT" ) || &warn("Can't save DB::OUT");
                    }

                    # Fix up environment to record we have less if so.
                    fix_less();

                    unless ( $piped = open( OUT, $pager ) ) {

                        # Couldn't open pipe to pager.
                        &warn("Can't pipe output to `$pager'");
                        if ( $pager =~ /^\|/ ) {

                            # Redirect I/O back again.
                            open( OUT, ">&STDOUT" )    # XXX: lost message
                              || &warn("Can't restore DB::OUT");
                            open( STDOUT, ">&SAVEOUT" )
                              || &warn("Can't restore STDOUT");
                            close(SAVEOUT);
                        } ## end if ($pager =~ /^\|/)
                        else {

                            # Redirect I/O. STDOUT already safe.
                            open( OUT, ">&STDOUT" )    # XXX: lost message
                              || &warn("Can't restore DB::OUT");
                        }
                        next CMD;
                    } ## end unless ($piped = open(OUT,...

                    # Set up broken-pipe handler if necessary.
                    $SIG{PIPE} = \&DB::catch
                      if $pager =~ /^\|/
                      && ( "" eq $SIG{PIPE} || "DEFAULT" eq $SIG{PIPE} );

                    # Save current filehandle, unbuffer out, and put it back.
                    $selected = select(OUT);
                    $|        = 1;

                    # Don't put it back if pager was a pipe.
                    select($selected), $selected = "" unless $cmd =~ /^\|\|/;

                    # Trim off the pipe symbols and run the command now.
                    $cmd =~ s/^\|+\s*//;
                    redo PIPE;
                };

                # t - turn trace on.
                $cmd =~ s/^t\s/\$DB::trace |= 1;\n/;

                # s - single-step. Remember the last command was 's'.
                $cmd =~ s/^s\s/\$DB::single = 1;\n/ && do { $laststep = 's' };

                # n - single-step, but not into subs. Remember last command
                # was 'n'.
                $cmd =~ s/^n\s/\$DB::single = 2;\n/ && do { $laststep = 'n' };

            }    # PIPE:

            # Make sure the flag that says "the debugger's running" is
            # still on, to make sure we get control again.
            $evalarg = "\$^D = \$^D | \$DB::db_stop;\n$cmd";

            # Run *our* eval that executes in the caller's context.
            &eval;

            # Turn off the one-time-dump stuff now.
            if ($onetimeDump) {
                $onetimeDump      = undef;
                $onetimedumpDepth = undef;
            }
            elsif ( $term_pid == $$ ) {
		eval {		# May run under miniperl, when not available...
                    STDOUT->flush();
                    STDERR->flush();
		};

                # XXX If this is the master pid, print a newline.
                print $OUT "\n";
            }
        } ## end while (($term || &setterm...

        continue {    # CMD:

            # At the end of every command:
            if ($piped) {

                # Unhook the pipe mechanism now.
                if ( $pager =~ /^\|/ ) {

                    # No error from the child.
                    $? = 0;

                    # we cannot warn here: the handle is missing --tchrist
                    close(OUT) || print SAVEOUT "\nCan't close DB::OUT\n";

                    # most of the $? crud was coping with broken cshisms
                    # $? is explicitly set to 0, so this never runs.
                    if ($?) {
                        print SAVEOUT "Pager `$pager' failed: ";
                        if ( $? == -1 ) {
                            print SAVEOUT "shell returned -1\n";
                        }
                        elsif ( $? >> 8 ) {
                            print SAVEOUT ( $? & 127 )
                              ? " (SIG#" . ( $? & 127 ) . ")"
                              : "", ( $? & 128 ) ? " -- core dumped" : "", "\n";
                        }
                        else {
                            print SAVEOUT "status ", ( $? >> 8 ), "\n";
                        }
                    } ## end if ($?)

                    # Reopen filehandle for our output (if we can) and
                    # restore STDOUT (if we can).
                    open( OUT, ">&STDOUT" ) || &warn("Can't restore DB::OUT");
                    open( STDOUT, ">&SAVEOUT" )
                      || &warn("Can't restore STDOUT");

                    # Turn off pipe exception handler if necessary.
                    $SIG{PIPE} = "DEFAULT" if $SIG{PIPE} eq \&DB::catch;

                    # Will stop ignoring SIGPIPE if done like nohup(1)
                    # does SIGINT but Perl doesn't give us a choice.
                } ## end if ($pager =~ /^\|/)
                else {

                    # Non-piped "pager". Just restore STDOUT.
                    open( OUT, ">&SAVEOUT" ) || &warn("Can't restore DB::OUT");
                }

                # Close filehandle pager was using, restore the normal one
                # if necessary,
                close(SAVEOUT);
                select($selected), $selected = "" unless $selected eq "";

                # No pipes now.
                $piped = "";
            } ## end if ($piped)
        }    # CMD:

        # No more commands? Quit.
        $fall_off_end = 1 unless defined $cmd;    # Emulate `q' on EOF

        # Evaluate post-prompt commands.
        foreach $evalarg (@$post) {
            &eval;
        }
    }    # if ($single || $signal)

    # Put the user's globals back where you found them.
    ( $@, $!, $^E, $,, $/, $\, $^W ) = @saved;
    ();
} ## end sub DB

}

1;
__END__

=head1 NAME

Devel::Command::DBSub::DB_5_10 - Devel::Command debugger patch for 5.10

=head1 SYNOPSIS

  # in .perldb:
  use Devel::Command;

=head1 DESCRIPTION

C<Devel::Command::DBSub::DB_5_10> loads a patched version of the debugger's
C<DB()> routine that will work with Perl 5.10.

=head2 alt_510_DB

This subroutine is essentially a copy of the 5.10 DB::DB function, with the code
necessary to pick up custom functions patched in.

=head1 NOTE

The POD documentation was removed from this subroutine to prevent this 
documentation becoming confusing. If you want real docs on how the debugger
works, see C<perldoc perl5db.pl>.

=head1 SEE ALSO

C<perl5db.pl>, notably the documentation for the C<DB::DB> subroutine.

C<Devel::Command> for a description of the debugger patching plugins.

=head1 AUTHOR

Joe McMahon, E<lt>mcmahon@ibiblio.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Joe McMahon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
