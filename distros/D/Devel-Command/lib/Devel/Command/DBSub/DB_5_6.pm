package Devel::Command::DBSub::DB_5_6;

sub import {
  if ($] =~ /^5.006/) {
    # This module will work.
    return \&DB::alt_56_DB;
  }
  else {
    # Not a 5.6 Perl.
    return undef;
  }
}

# The patched 5.6 debugger's DB() routine.
{
no strict;
no warnings;
package DB;

sub alt_56_DB {
    # _After_ the perl program is compiled, $single is set to 1:
    if ($single and not $second_time++) {
      if ($runnonstop) {	# Disable until signal
	for ($i=0; $i <= $stack_depth; ) {
	    $stack[$i++] &= ~1;
	}
	$single = 0;
	# return;			# Would not print trace!
      } elsif ($ImmediateStop) {
	$ImmediateStop = 0;
	$signal = 1;
      }
    }
    $runnonstop = 0 if $single or $signal; # Disable it if interactive.
    &save;
    ($package, $filename, $line) = caller;
    $filename_ini = $filename;
    $usercontext = '($@, $!, $^E, $,, $/, $\, $^W) = @saved;' .
      "package $package;";	# this won't let them modify, alas
    local(*dbline) = $main::{'_<' . $filename};
    $max = $#dbline;
    if (($stop,$action) = split(/\0/,$dbline{$line})) {
	if ($stop eq '1') {
	    $signal |= 1;
	} elsif ($stop) {
	    $evalarg = "\$DB::signal |= 1 if do {$stop}"; &eval;
	    $dbline{$line} =~ s/;9($|\0)/$1/;
	}
    }
    my $was_signal = $signal;
    if ($trace & 2) {
      for (my $n = 0; $n <= $#to_watch; $n++) {
	$evalarg = $to_watch[$n];
	local $onetimeDump;	# Do not output results
	my ($val) = &eval;	# Fix context (&eval is doing array)?
	$val = ( (defined $val) ? "'$val'" : 'undef' );
	if ($val ne $old_watch[$n]) {
	  $signal = 1;
	  print $OUT <<EOP;
Watchpoint $n:\t$to_watch[$n] changed:
    old value:\t$old_watch[$n]
    new value:\t$val
EOP
	  $old_watch[$n] = $val;
	}
      }
    }
    if ($trace & 4) {		# User-installed watch
      return if watchfunction($package, $filename, $line) 
	and not $single and not $was_signal and not ($trace & ~4);
    }
    $was_signal = $signal;
    $signal = 0;
    if ($single || ($trace & 1) || $was_signal) {
	if ($slave_editor) {
	    $position = "\032\032$filename:$line:0\n";
	    print $LINEINFO $position;
	} elsif ($package eq 'DB::fake') {
	  $term || &setterm;
	  print_help(<<EOP);
Debugged program terminated.  Use B<q> to quit or B<R> to restart,
  use B<O> I<inhibit_exit> to avoid stopping after program termination,
  B<h q>, B<h R> or B<h O> to get additional info.  
EOP
	  $package = 'main';
	  $usercontext = '($@, $!, $^E, $,, $/, $\, $^W) = @saved;' .
	    "package $package;";	# this won't let them modify, alas
	} else {
	    $sub =~ s/\'/::/;
	    $prefix = $sub =~ /::/ ? "" : "${'package'}::";
	    $prefix .= "$sub($filename:";
	    $after = ($dbline[$line] =~ /\n$/ ? '' : "\n");
	    if (length($prefix) > 30) {
	        $position = "$prefix$line):\n$line:\t$dbline[$line]$after";
		$prefix = "";
		$infix = ":\t";
	    } else {
		$infix = "):\t";
		$position = "$prefix$line$infix$dbline[$line]$after";
	    }
	    if ($frame) {
		print $LINEINFO ' ' x $stack_depth, "$line:\t$dbline[$line]$after";
	    } else {
		print $LINEINFO $position;
	    }
	    for ($i = $line + 1; $i <= $max && $dbline[$i] == 0; ++$i) { #{ vi
		last if $dbline[$i] =~ /^\s*[\;\}\#\n]/;
		last if $signal;
		$after = ($dbline[$i] =~ /\n$/ ? '' : "\n");
		$incr_pos = "$prefix$i$infix$dbline[$i]$after";
		$position .= $incr_pos;
		if ($frame) {
		    print $LINEINFO ' ' x $stack_depth, "$i:\t$dbline[$i]$after";
		} else {
		    print $LINEINFO $incr_pos;
		}
	    }
	}
    }
    $evalarg = $action, &eval if $action;
    if ($single || $was_signal) {
	local $level = $level + 1;
	foreach $evalarg (@$pre) {
	  &eval;
	}
	print $OUT $stack_depth . " levels deep in subroutine calls!\n"
	  if $single & 4;
	$start = $line;
	$incr = -1;		# for backward motion.
	@typeahead = (@$pretype, @typeahead);
      CMD:
	while (($term || &setterm),
	       ($term_pid == $$ or &resetterm),
	       defined ($cmd=&readline("  DB" . ('<' x $level) .
				       ($#hist+1) . ('>' x $level) .
				       " "))) 
        {
		$single = 0;
		$signal = 0;
		$cmd =~ s/\\$/\n/ && do {
		    $cmd .= &readline("  cont: ");
		    redo CMD;
		};
		$cmd =~ /^$/ && ($cmd = $laststep);
		push(@hist,$cmd) if length($cmd) > 1;
	      PIPE: {
		    $cmd =~ s/^\s+//s;   # trim annoying leading whitespace
		    $cmd =~ s/\s+$//s;   # trim annoying trailing whitespace
		    ($i) = split(/\s+/,$cmd);
		    if ($alias{$i}) { 
			# squelch the sigmangler
			local $SIG{__DIE__};
			local $SIG{__WARN__};
			eval "\$cmd =~ $alias{$i}";
			if ($@) {
			    print $OUT "Couldn't evaluate `$i' alias: $@";
			    next CMD;
			} 
		    }

### Extended commands

### Define your extended commands in C<%commands> at the top of the file.
### This section runs them.

                   foreach my $do (keys %DB::commands) {
                     next unless $cmd =~ /^$do\s*/;
                     $commands{$do}->($cmd) and next CMD;
                     #  ? next CMD : last CMD;
                   }

                   $cmd =~ /^q$/ && ($fall_off_end = 1) && exit $?;
		    $cmd =~ /^h$/ && do {
			print_help($help);
			next CMD; };
		    $cmd =~ /^h\s+h$/ && do {
			print_help($summary);
			next CMD; };
		    # support long commands; otherwise bogus errors
		    # happen when you ask for h on <CR> for example
		    $cmd =~ /^h\s+(\S.*)$/ && do {      
			my $asked = $1;			# for proper errmsg
			my $qasked = quotemeta($asked); # for searching
			# XXX: finds CR but not <CR>
			if ($help =~ /^<?(?:[IB]<)$qasked/m) {
			  while ($help =~ /^(<?(?:[IB]<)$qasked([\s\S]*?)\n)(?!\s)/mg) {
			    print_help($1);
			  }
			} else {
			    print_help("B<$asked> is not a debugger command.\n");
			}
			next CMD; };
		    $cmd =~ /^t$/ && do {
			$trace ^= 1;
			print $OUT "Trace = " .
			    (($trace & 1) ? "on" : "off" ) . "\n";
			next CMD; };
		    $cmd =~ /^S(\s+(!)?(.+))?$/ && do {
			$Srev = defined $2; $Spatt = $3; $Snocheck = ! defined $1;
			foreach $subname (sort(keys %sub)) {
			    if ($Snocheck or $Srev^($subname =~ /$Spatt/)) {
				print $OUT $subname,"\n";
			    }
			}
			next CMD; };
		    $cmd =~ /^v$/ && do {
			list_versions(); next CMD};
		    $cmd =~ s/^X\b/V $package/;
		    $cmd =~ /^V$/ && do {
			$cmd = "V $package"; };
		    $cmd =~ /^V\b\s*(\S+)\s*(.*)/ && do {
			local ($savout) = select($OUT);
			$packname = $1;
			@vars = split(' ',$2);
			do 'dumpvar.pl' unless defined &main::dumpvar;
			if (defined &main::dumpvar) {
			    local $frame = 0;
			    local $doret = -2;
			    # must detect sigpipe failures
			    eval { &main::dumpvar($packname,@vars) };
			    if ($@) {
				die unless $@ =~ /dumpvar print failed/;
			    } 
			} else {
			    print $OUT "dumpvar.pl not available.\n";
			}
			select ($savout);
			next CMD; };
		    $cmd =~ s/^x\b/ / && do { # So that will be evaled
			$onetimeDump = 'dump'; };
		    $cmd =~ s/^m\s+([\w:]+)\s*$/ / && do {
			methods($1); next CMD};
		    $cmd =~ s/^m\b/ / && do { # So this will be evaled
			$onetimeDump = 'methods'; };
		    $cmd =~ /^f\b\s*(.*)/ && do {
			$file = $1;
			$file =~ s/\s+$//;
			if (!$file) {
			    print $OUT "The old f command is now the r command.\n";
			    print $OUT "The new f command switches filenames.\n";
			    next CMD;
			}
			if (!defined $main::{'_<' . $file}) {
			    if (($try) = grep(m#^_<.*$file#, keys %main::)) {{
					      $try = substr($try,2);
					      print $OUT "Choosing $try matching `$file':\n";
					      $file = $try;
					  }}
			}
			if (!defined $main::{'_<' . $file}) {
			    print $OUT "No file matching `$file' is loaded.\n";
			    next CMD;
			} elsif ($file ne $filename) {
			    *dbline = $main::{'_<' . $file};
			    $max = $#dbline;
			    $filename = $file;
			    $start = 1;
			    $cmd = "l";
			  } else {
			    print $OUT "Already in $file.\n";
			    next CMD;
			  }
		      };
		    $cmd =~ s/^l\s+-\s*$/-/;
		    $cmd =~ /^([lb])\b\s*(\$.*)/s && do {
			$evalarg = $2;
			my ($s) = &eval;
			print($OUT "Error: $@\n"), next CMD if $@;
			$s = CvGV_name($s);
			print($OUT "Interpreted as: $1 $s\n");
			$cmd = "$1 $s";
		    };
		    $cmd =~ /^l\b\s*([\':A-Za-z_][\':\w]*(\[.*\])?)/s && do {
			$subname = $1;
			$subname =~ s/\'/::/;
			$subname = $package."::".$subname 
			  unless $subname =~ /::/;
			$subname = "main".$subname if substr($subname,0,2) eq "::";
			@pieces = split(/:/,find_sub($subname) || $sub{$subname});
			$subrange = pop @pieces;
			$file = join(':', @pieces);
			if ($file ne $filename) {
			    print $OUT "Switching to file '$file'.\n"
				unless $slave_editor;
			    *dbline = $main::{'_<' . $file};
			    $max = $#dbline;
			    $filename = $file;
			}
			if ($subrange) {
			    if (eval($subrange) < -$window) {
				$subrange =~ s/-.*/+/;
			    }
			    $cmd = "l $subrange";
			} else {
			    print $OUT "Subroutine $subname not found.\n";
			    next CMD;
			} };
		    $cmd =~ /^\.$/ && do {
			$incr = -1;		# for backward motion.
			$start = $line;
			$filename = $filename_ini;
			*dbline = $main::{'_<' . $filename};
			$max = $#dbline;
			print $LINEINFO $position;
			next CMD };
		    $cmd =~ /^w\b\s*(\d*)$/ && do {
			$incr = $window - 1;
			$start = $1 if $1;
			$start -= $preview;
			#print $OUT 'l ' . $start . '-' . ($start + $incr);
			$cmd = 'l ' . $start . '-' . ($start + $incr); };
		    $cmd =~ /^-$/ && do {
			$start -= $incr + $window + 1;
			$start = 1 if $start <= 0;
			$incr = $window - 1;
			$cmd = 'l ' . ($start) . '+'; };
		    $cmd =~ /^l$/ && do {
			$incr = $window - 1;
			$cmd = 'l ' . $start . '-' . ($start + $incr); };
		    $cmd =~ /^l\b\s*(\d*)\+(\d*)$/ && do {
			$start = $1 if $1;
			$incr = $2;
			$incr = $window - 1 unless $incr;
			$cmd = 'l ' . $start . '-' . ($start + $incr); };
		    $cmd =~ /^l\b\s*((-?[\d\$\.]+)([-,]([\d\$\.]+))?)?/ && do {
			$end = (!defined $2) ? $max : ($4 ? $4 : $2);
			$end = $max if $end > $max;
			$i = $2;
			$i = $line if $i eq '.';
			$i = 1 if $i < 1;
			$incr = $end - $i;
			if ($slave_editor) {
			    print $OUT "\032\032$filename:$i:0\n";
			    $i = $end;
			} else {
			    for (; $i <= $end; $i++) {
			        ($stop,$action) = split(/\0/, $dbline{$i});
			        $arrow = ($i==$line 
					  and $filename eq $filename_ini) 
				  ?  '==>' 
				    : ($dbline[$i]+0 ? ':' : ' ') ;
				$arrow .= 'b' if $stop;
				$arrow .= 'a' if $action;
				print $OUT "$i$arrow\t", $dbline[$i];
				$i++, last if $signal;
			    }
			    print $OUT "\n" unless $dbline[$i-1] =~ /\n$/;
			}
			$start = $i; # remember in case they want more
			$start = $max if $start > $max;
			next CMD; };
		    $cmd =~ /^D$/ && do {
		      print $OUT "Deleting all breakpoints...\n";
		      my $file;
		      for $file (keys %had_breakpoints) {
			local *dbline = $main::{'_<' . $file};
			my $max = $#dbline;
			my $was;
			
			for ($i = 1; $i <= $max ; $i++) {
			    if (defined $dbline{$i}) {
				$dbline{$i} =~ s/^[^\0]+//;
				if ($dbline{$i} =~ s/^\0?$//) {
				    delete $dbline{$i};
				}
			    }
			}
			
			if (not $had_breakpoints{$file} &= ~1) {
			    delete $had_breakpoints{$file};
			}
		      }
		      undef %postponed;
		      undef %postponed_file;
		      undef %break_on_load;
		      next CMD; };
		    $cmd =~ /^L$/ && do {
		      my $file;
		      for $file (keys %had_breakpoints) {
			local *dbline = $main::{'_<' . $file};
			my $max = $#dbline;
			my $was;
			
			for ($i = 1; $i <= $max; $i++) {
			    if (defined $dbline{$i}) {
			        print $OUT "$file:\n" unless $was++;
				print $OUT " $i:\t", $dbline[$i];
				($stop,$action) = split(/\0/, $dbline{$i});
				print $OUT "   break if (", $stop, ")\n"
				  if $stop;
				print $OUT "   action:  ", $action, "\n"
				  if $action;
				last if $signal;
			    }
			}
		      }
		      if (%postponed) {
			print $OUT "Postponed breakpoints in subroutines:\n";
			my $subname;
			for $subname (keys %postponed) {
			  print $OUT " $subname\t$postponed{$subname}\n";
			  last if $signal;
			}
		      }
		      my @have = map { # Combined keys
			keys %{$postponed_file{$_}}
		      } keys %postponed_file;
		      if (@have) {
			print $OUT "Postponed breakpoints in files:\n";
			my ($file, $line);
			for $file (keys %postponed_file) {
			  my $db = $postponed_file{$file};
			  print $OUT " $file:\n";
			  for $line (sort {$a <=> $b} keys %$db) {
				print $OUT "  $line:\n";
				my ($stop,$action) = split(/\0/, $$db{$line});
				print $OUT "    break if (", $stop, ")\n"
				  if $stop;
				print $OUT "    action:  ", $action, "\n"
				  if $action;
				last if $signal;
			  }
			  last if $signal;
			}
		      }
		      if (%break_on_load) {
			print $OUT "Breakpoints on load:\n";
			my $file;
			for $file (keys %break_on_load) {
			  print $OUT " $file\n";
			  last if $signal;
			}
		      }
		      if ($trace & 2) {
			print $OUT "Watch-expressions:\n";
			my $expr;
			for $expr (@to_watch) {
			  print $OUT " $expr\n";
			  last if $signal;
			}
		      }
		      next CMD; };
		    $cmd =~ /^b\b\s*load\b\s*(.*)/ && do {
			my $file = $1; $file =~ s/\s+$//;
			{
			  $break_on_load{$file} = 1;
			  $break_on_load{$::INC{$file}} = 1 if $::INC{$file};
			  $file .= '.pm', redo unless $file =~ /\./;
			}
			$had_breakpoints{$file} |= 1;
			print $OUT "Will stop on load of `@{[join '\', `', sort keys %break_on_load]}'.\n";
			next CMD; };
		    $cmd =~ /^b\b\s*(postpone|compile)\b\s*([':A-Za-z_][':\w]*)\s*(.*)/ && do {
			my $cond = length $3 ? $3 : '1';
			my ($subname, $break) = ($2, $1 eq 'postpone');
			$subname =~ s/\'/::/g;
			$subname = "${'package'}::" . $subname
			  unless $subname =~ /::/;
			$subname = "main".$subname if substr($subname,0,2) eq "::";
			$postponed{$subname} = $break 
			  ? "break +0 if $cond" : "compile";
			next CMD; };
		    $cmd =~ /^b\b\s*([':A-Za-z_][':\w]*(?:\[.*\])?)\s*(.*)/ && do {
			$subname = $1;
			$cond = length $2 ? $2 : '1';
			$subname =~ s/\'/::/g;
			$subname = "${'package'}::" . $subname
			  unless $subname =~ /::/;
			$subname = "main".$subname if substr($subname,0,2) eq "::";
			# Filename below can contain ':'
			($file,$i) = (find_sub($subname) =~ /^(.*):(.*)$/);
			$i += 0;
			if ($i) {
			    local $filename = $file;
			    local *dbline = $main::{'_<' . $filename};
			    $had_breakpoints{$filename} |= 1;
			    $max = $#dbline;
			    ++$i while $dbline[$i] == 0 && $i < $max;
			    $dbline{$i} =~ s/^[^\0]*/$cond/;
			} else {
			    print $OUT "Subroutine $subname not found.\n";
			}
			next CMD; };
		    $cmd =~ /^b\b\s*(\d*)\s*(.*)/ && do {
			$i = $1 || $line;
			$cond = length $2 ? $2 : '1';
			if ($dbline[$i] == 0) {
			    print $OUT "Line $i not breakable.\n";
			} else {
			    $had_breakpoints{$filename} |= 1;
			    $dbline{$i} =~ s/^[^\0]*/$cond/;
			}
			next CMD; };
		    $cmd =~ /^d\b\s*(\d*)/ && do {
			$i = $1 || $line;
                        if ($dbline[$i] == 0) {
                            print $OUT "Line $i not breakable.\n";
                        } else {
			    $dbline{$i} =~ s/^[^\0]*//;
			    delete $dbline{$i} if $dbline{$i} eq '';
                        }
			next CMD; };
		    $cmd =~ /^A$/ && do {
		      print $OUT "Deleting all actions...\n";
		      my $file;
		      for $file (keys %had_breakpoints) {
			local *dbline = $main::{'_<' . $file};
			my $max = $#dbline;
			my $was;
			
			for ($i = 1; $i <= $max ; $i++) {
			    if (defined $dbline{$i}) {
				$dbline{$i} =~ s/\0[^\0]*//;
				delete $dbline{$i} if $dbline{$i} eq '';
			    }
			}
			
			unless ($had_breakpoints{$file} &= ~2) {
			    delete $had_breakpoints{$file};
			}
		      }
		      next CMD; };
		    $cmd =~ /^O\s*$/ && do {
			for (@options) {
			    &dump_option($_);
			}
			next CMD; };
		    $cmd =~ /^O\s*(\S.*)/ && do {
			parse_options($1);
			next CMD; };
		    $cmd =~ /^\<\<\s*(.*)/ && do { # \<\< for CPerl sake: not HERE
			push @$pre, action($1);
			next CMD; };
		    $cmd =~ /^>>\s*(.*)/ && do {
			push @$post, action($1);
			next CMD; };
		    $cmd =~ /^<\s*(.*)/ && do {
			unless ($1) {
			    print $OUT "All < actions cleared.\n";
			    $pre = [];
			    next CMD;
			} 
			if ($1 eq '?') {
			    unless (@$pre) {
				print $OUT "No pre-prompt Perl actions.\n";
				next CMD;
			    } 
			    print $OUT "Perl commands run before each prompt:\n";
			    for my $action ( @$pre ) {
				print $OUT "\t< -- $action\n";
			    } 
			    next CMD;
			} 
			$pre = [action($1)];
			next CMD; };
		    $cmd =~ /^>\s*(.*)/ && do {
			unless ($1) {
			    print $OUT "All > actions cleared.\n";
			    $post = [];
			    next CMD;
			}
			if ($1 eq '?') {
			    unless (@$post) {
				print $OUT "No post-prompt Perl actions.\n";
				next CMD;
			    } 
			    print $OUT "Perl commands run after each prompt:\n";
			    for my $action ( @$post ) {
				print $OUT "\t> -- $action\n";
			    } 
			    next CMD;
			} 
			$post = [action($1)];
			next CMD; };
		    $cmd =~ /^\{\{\s*(.*)/ && do {
			if ($cmd =~ /^\{.*\}$/ && unbalanced(substr($cmd,2))) { 
			    print $OUT "{{ is now a debugger command\n",
				"use `;{{' if you mean Perl code\n";
			    $cmd = "h {{";
			    redo CMD;
			} 
			push @$pretype, $1;
			next CMD; };
		    $cmd =~ /^\{\s*(.*)/ && do {
			unless ($1) {
			    print $OUT "All { actions cleared.\n";
			    $pretype = [];
			    next CMD;
			}
			if ($1 eq '?') {
			    unless (@$pretype) {
				print $OUT "No pre-prompt debugger actions.\n";
				next CMD;
			    } 
			    print $OUT "Debugger commands run before each prompt:\n";
			    for my $action ( @$pretype ) {
				print $OUT "\t{ -- $action\n";
			    } 
			    next CMD;
			} 
			if ($cmd =~ /^\{.*\}$/ && unbalanced(substr($cmd,1))) { 
			    print $OUT "{ is now a debugger command\n",
				"use `;{' if you mean Perl code\n";
			    $cmd = "h {";
			    redo CMD;
			} 
			$pretype = [$1];
			next CMD; };
		    $cmd =~ /^a\b\s*(\d*)\s*(.*)/ && do {
			$i = $1 || $line; $j = $2;
			if (length $j) {
			    if ($dbline[$i] == 0) {
				print $OUT "Line $i may not have an action.\n";
			    } else {
				$had_breakpoints{$filename} |= 2;
				$dbline{$i} =~ s/\0[^\0]*//;
				$dbline{$i} .= "\0" . action($j);
			    }
			} else {
			    $dbline{$i} =~ s/\0[^\0]*//;
			    delete $dbline{$i} if $dbline{$i} eq '';
			}
			next CMD; };
		    $cmd =~ /^n$/ && do {
		        end_report(), next CMD if $finished and $level <= 1;
			$single = 2;
			$laststep = $cmd;
			last CMD; };
		    $cmd =~ /^s$/ && do {
		        end_report(), next CMD if $finished and $level <= 1;
			$single = 1;
			$laststep = $cmd;
			last CMD; };
		    $cmd =~ /^c\b\s*([\w:]*)\s*$/ && do {
		        end_report(), next CMD if $finished and $level <= 1;
			$subname = $i = $1;
			#  Probably not needed, since we finish an interactive
			#  sub-session anyway...
			# local $filename = $filename;
			# local *dbline = *dbline;	# XXX Would this work?!
			if ($i =~ /\D/) { # subroutine name
			    $subname = $package."::".$subname 
			        unless $subname =~ /::/;
			    ($file,$i) = (find_sub($subname) =~ /^(.*):(.*)$/);
			    $i += 0;
			    if ($i) {
			        $filename = $file;
				*dbline = $main::{'_<' . $filename};
				$had_breakpoints{$filename} |= 1;
				$max = $#dbline;
				++$i while $dbline[$i] == 0 && $i < $max;
			    } else {
				print $OUT "Subroutine $subname not found.\n";
				next CMD; 
			    }
			}
			if ($i) {
			    if ($dbline[$i] == 0) {
				print $OUT "Line $i not breakable.\n";
				next CMD;
			    }
			    $dbline{$i} =~ s/($|\0)/;9$1/; # add one-time-only b.p.
			}
			for ($i=0; $i <= $stack_depth; ) {
			    $stack[$i++] &= ~1;
			}
			last CMD; };
		    $cmd =~ /^r$/ && do {
		        end_report(), next CMD if $finished and $level <= 1;
			$stack[$stack_depth] |= 1;
			$doret = $option{PrintRet} ? $stack_depth - 1 : -2;
			last CMD; };
		    $cmd =~ /^R$/ && do {
		        print $OUT "Warning: some settings and command-line options may be lost!\n";
			my (@script, @flags, $cl);
			push @flags, '-w' if $ini_warn;
			# Put all the old includes at the start to get
			# the same debugger.
			for (@ini_INC) {
			  push @flags, '-I', $_;
			}
			# Arrange for setting the old INC:
			set_list("PERLDB_INC", @ini_INC);
			if ($0 eq '-e') {
			  for (1..$#{'::_<-e'}) { # The first line is PERL5DB
			        chomp ($cl =  ${'::_<-e'}[$_]);
			    push @script, '-e', $cl;
			  }
			} else {
			  @script = $0;
			}
			set_list("PERLDB_HIST", 
				 $term->Features->{getHistory} 
				 ? $term->GetHistory : @hist);
			my @had_breakpoints = keys %had_breakpoints;
			set_list("PERLDB_VISITED", @had_breakpoints);
			set_list("PERLDB_OPT", %option);
			set_list("PERLDB_ON_LOAD", %break_on_load);
			my @hard;
			for (0 .. $#had_breakpoints) {
			  my $file = $had_breakpoints[$_];
			  *dbline = $main::{'_<' . $file};
			  next unless %dbline or $postponed_file{$file};
			  (push @hard, $file), next 
			    if $file =~ /^\(eval \d+\)$/;
			  my @add;
			  @add = %{$postponed_file{$file}}
			    if $postponed_file{$file};
			  set_list("PERLDB_FILE_$_", %dbline, @add);
			}
			for (@hard) { # Yes, really-really...
			  # Find the subroutines in this eval
			  *dbline = $main::{'_<' . $_};
			  my ($quoted, $sub, %subs, $line) = quotemeta $_;
			  for $sub (keys %sub) {
			    next unless $sub{$sub} =~ /^$quoted:(\d+)-(\d+)$/;
			    $subs{$sub} = [$1, $2];
			  }
			  unless (%subs) {
			    print $OUT
			      "No subroutines in $_, ignoring breakpoints.\n";
			    next;
			  }
			LINES: for $line (keys %dbline) {
			    # One breakpoint per sub only:
			    my ($offset, $sub, $found);
			  SUBS: for $sub (keys %subs) {
			      if ($subs{$sub}->[1] >= $line # Not after the subroutine
				  and (not defined $offset # Not caught
				       or $offset < 0 )) { # or badly caught
				$found = $sub;
				$offset = $line - $subs{$sub}->[0];
				$offset = "+$offset", last SUBS if $offset >= 0;
			      }
			    }
			    if (defined $offset) {
			      $postponed{$found} =
				"break $offset if $dbline{$line}";
			    } else {
			      print $OUT "Breakpoint in $_:$line ignored: after all the subroutines.\n";
			    }
			  }
			}
			set_list("PERLDB_POSTPONE", %postponed);
			set_list("PERLDB_PRETYPE", @$pretype);
			set_list("PERLDB_PRE", @$pre);
			set_list("PERLDB_POST", @$post);
			set_list("PERLDB_TYPEAHEAD", @typeahead);
			$ENV{PERLDB_RESTART} = 1;
			#print "$^X, '-d', @flags, @script, ($slave_editor ? '-emacs' : ()), @ARGS";
			exec $^X, '-d', @flags, @script, ($slave_editor ? '-emacs' : ()), @ARGS;
			print $OUT "exec failed: $!\n";
			last CMD; };
		    $cmd =~ /^T$/ && do {
			print_trace($OUT, 1); # skip DB
			next CMD; };
		    $cmd =~ /^W\s*$/ && do {
			$trace &= ~2;
			@to_watch = @old_watch = ();
			next CMD; };
		    $cmd =~ /^W\b\s*(.*)/s && do {
			push @to_watch, $1;
			$evalarg = $1;
			my ($val) = &eval;
			$val = (defined $val) ? "'$val'" : 'undef' ;
			push @old_watch, $val;
			$trace |= 2;
			next CMD; };
		    $cmd =~ /^\/(.*)$/ && do {
			$inpat = $1;
			$inpat =~ s:([^\\])/$:$1:;
			if ($inpat ne "") {
			    # squelch the sigmangler
			    local $SIG{__DIE__};
			    local $SIG{__WARN__};
			    eval '$inpat =~ m'."\a$inpat\a";	
			    if ($@ ne "") {
				print $OUT "$@";
				next CMD;
			    }
			    $pat = $inpat;
			}
			$end = $start;
			$incr = -1;
			eval '
			    for (;;) {
				++$start;
				$start = 1 if ($start > $max);
				last if ($start == $end);
				if ($dbline[$start] =~ m' . "\a$pat\a" . 'i) {
				    if ($slave_editor) {
					print $OUT "\032\032$filename:$start:0\n";
				    } else {
					print $OUT "$start:\t", $dbline[$start], "\n";
				    }
				    last;
				}
			    } ';
			print $OUT "/$pat/: not found\n" if ($start == $end);
			next CMD; };
		    $cmd =~ /^\?(.*)$/ && do {
			$inpat = $1;
			$inpat =~ s:([^\\])\?$:$1:;
			if ($inpat ne "") {
			    # squelch the sigmangler
			    local $SIG{__DIE__};
			    local $SIG{__WARN__};
			    eval '$inpat =~ m'."\a$inpat\a";	
			    if ($@ ne "") {
				print $OUT $@;
				next CMD;
			    }
			    $pat = $inpat;
			}
			$end = $start;
			$incr = -1;
			eval '
			    for (;;) {
				--$start;
				$start = $max if ($start <= 0);
				last if ($start == $end);
				if ($dbline[$start] =~ m' . "\a$pat\a" . 'i) {
				    if ($slave_editor) {
					print $OUT "\032\032$filename:$start:0\n";
				    } else {
					print $OUT "$start:\t", $dbline[$start], "\n";
				    }
				    last;
				}
			    } ';
			print $OUT "?$pat?: not found\n" if ($start == $end);
			next CMD; };
		    $cmd =~ /^$rc+\s*(-)?(\d+)?$/ && do {
			pop(@hist) if length($cmd) > 1;
			$i = $1 ? ($#hist-($2||1)) : ($2||$#hist);
			$cmd = $hist[$i];
			print $OUT $cmd, "\n";
			redo CMD; };
		    $cmd =~ /^$sh$sh\s*([\x00-\xff]*)/ && do {
			&system($1);
			next CMD; };
		    $cmd =~ /^$rc([^$rc].*)$/ && do {
			$pat = "^$1";
			pop(@hist) if length($cmd) > 1;
			for ($i = $#hist; $i; --$i) {
			    last if $hist[$i] =~ /$pat/;
			}
			if (!$i) {
			    print $OUT "No such command!\n\n";
			    next CMD;
			}
			$cmd = $hist[$i];
			print $OUT $cmd, "\n";
			redo CMD; };
		    $cmd =~ /^$sh$/ && do {
			&system($ENV{SHELL}||"/bin/sh");
			next CMD; };
		    $cmd =~ /^$sh\s*([\x00-\xff]*)/ && do {
			# XXX: using csh or tcsh destroys sigint retvals!
			#&system($1);  # use this instead
			&system($ENV{SHELL}||"/bin/sh","-c",$1);
			next CMD; };
		    $cmd =~ /^H\b\s*(-(\d+))?/ && do {
			$end = $2 ? ($#hist-$2) : 0;
			$hist = 0 if $hist < 0;
			for ($i=$#hist; $i>$end; $i--) {
			    print $OUT "$i: ",$hist[$i],"\n"
			      unless $hist[$i] =~ /^.?$/;
			};
			next CMD; };
		    $cmd =~ /^(?:man|(?:perl)?doc)\b(?:\s+([^(]*))?$/ && do {
			runman($1);
			next CMD; };
		    $cmd =~ s/^p$/print {\$DB::OUT} \$_/;
		    $cmd =~ s/^p\b/print {\$DB::OUT} /;
		    $cmd =~ s/^=\s*// && do {
			my @keys;
			if (length $cmd == 0) {
			    @keys = sort keys %alias;
			} 
                        elsif (my($k,$v) = ($cmd =~ /^(\S+)\s+(\S.*)/)) {
			    # can't use $_ or kill //g state
			    for my $x ($k, $v) { $x =~ s/\a/\\a/g }
			    $alias{$k} = "s\a$k\a$v\a";
			    # squelch the sigmangler
			    local $SIG{__DIE__};
			    local $SIG{__WARN__};
			    unless (eval "sub { s\a$k\a$v\a }; 1") {
				print $OUT "Can't alias $k to $v: $@\n"; 
				delete $alias{$k};
				next CMD;
			    } 
			    @keys = ($k);
			} 
			else {
			    @keys = ($cmd);
			} 
			for my $k (@keys) {
			    if ((my $v = $alias{$k}) =~ ss\a$k\a(.*)\a$1) {
				print $OUT "$k\t= $1\n";
			    } 
			    elsif (defined $alias{$k}) {
				    print $OUT "$k\t$alias{$k}\n";
			    } 
			    else {
				print "No alias for $k\n";
			    } 
			}
			next CMD; };
		    $cmd =~ /^\|\|?\s*[^|]/ && do {
			if ($pager =~ /^\|/) {
			    open(SAVEOUT,">&STDOUT") || &warn("Can't save STDOUT");
			    open(STDOUT,">&OUT") || &warn("Can't redirect STDOUT");
			} else {
			    open(SAVEOUT,">&OUT") || &warn("Can't save DB::OUT");
			}
			fix_less();
			unless ($piped=open(OUT,$pager)) {
			    &warn("Can't pipe output to `$pager'");
			    if ($pager =~ /^\|/) {
				open(OUT,">&STDOUT") # XXX: lost message
				    || &warn("Can't restore DB::OUT");
				open(STDOUT,">&SAVEOUT")
				  || &warn("Can't restore STDOUT");
				close(SAVEOUT);
			    } else {
				open(OUT,">&STDOUT") # XXX: lost message
				    || &warn("Can't restore DB::OUT");
			    }
			    next CMD;
			}
			$SIG{PIPE}= \&DB::catch if $pager =~ /^\|/
			    && ("" eq $SIG{PIPE}  ||  "DEFAULT" eq $SIG{PIPE});
			$selected= select(OUT);
			$|= 1;
			select( $selected ), $selected= "" unless $cmd =~ /^\|\|/;
			$cmd =~ s/^\|+\s*//;
			redo PIPE; 
		    };
		    # XXX Local variants do not work!
		    $cmd =~ s/^t\s/\$DB::trace |= 1;\n/;
		    $cmd =~ s/^s\s/\$DB::single = 1;\n/ && do {$laststep = 's'};
		    $cmd =~ s/^n\s/\$DB::single = 2;\n/ && do {$laststep = 'n'};
		}		# PIPE:
	    $evalarg = "\$^D = \$^D | \$DB::db_stop;\n$cmd"; &eval;
	    if ($onetimeDump) {
		$onetimeDump = undef;
	    } elsif ($term_pid == $$) {
		print $OUT "\n";
	    }
	} continue {		# CMD:
	    if ($piped) {
		if ($pager =~ /^\|/) {
		    $? = 0;  
		    # we cannot warn here: the handle is missing --tchrist
		    close(OUT) || print SAVEOUT "\nCan't close DB::OUT\n";

		    # most of the $? crud was coping with broken cshisms
		    if ($?) {
			print SAVEOUT "Pager `$pager' failed: ";
			if ($? == -1) {
			    print SAVEOUT "shell returned -1\n";
			} elsif ($? >> 8) {
			    print SAVEOUT 
			      ( $? & 127 ) ? " (SIG#".($?&127).")" : "", 
			      ( $? & 128 ) ? " -- core dumped" : "", "\n";
			} else {
			    print SAVEOUT "status ", ($? >> 8), "\n";
			} 
		    } 

		    open(OUT,">&STDOUT") || &warn("Can't restore DB::OUT");
		    open(STDOUT,">&SAVEOUT") || &warn("Can't restore STDOUT");
		    $SIG{PIPE} = "DEFAULT" if $SIG{PIPE} eq \&DB::catch;
		    # Will stop ignoring SIGPIPE if done like nohup(1)
		    # does SIGINT but Perl doesn't give us a choice.
		} else {
		    open(OUT,">&SAVEOUT") || &warn("Can't restore DB::OUT");
		}
		close(SAVEOUT);
		select($selected), $selected= "" unless $selected eq "";
		$piped= "";
	    }
	}			# CMD:
       $fall_off_end = 1 unless defined $cmd; # Emulate `q' on EOF
	foreach $evalarg (@$post) {
	  &eval;
	}
    }				# if ($single || $signal)
    ($@, $!, $^E, $,, $/, $\, $^W) = @saved;
    ();
}

}

1;

__END__

=head1 NAME

Devel::Command::DBSub::DB_5_6.pm  - Perl 5.6 debugger patch

=head1 SYNOPSIS

  # in .perldb
  use Devel::Command; 

=head1 DESCRIPTION

C<Devel::Command::DBSub::DB_5_6> encapsulates the C<DB()> subroutine to be
used to patch the debugger when C<Devel::Command> is loaded. This module should
work for any sub-version of Perl 5.6.

The C<import> subroutine in this module determines whether or not the 
perl we're running under is perl 5.6.x or not.

=head2 alt_56_DB

This subroutine is essentially a copy of the 5.6 DB::DB function, with the code
necessary to pick up custom functions patched in.

=head1 SEE ALSO

C<perl5db.pl>, notably the documentation for the C<DB::DB> subroutine.

C<Devel::Command>, for details on the C<DBSub> plugins.

=head1 AUTHOR

Joe McMahon, E<lt>mcmahon@ibiblio.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Joe McMahon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut