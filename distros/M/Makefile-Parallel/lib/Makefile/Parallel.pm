package Makefile::Parallel;

use Makefile::Parallel::Grammar;
use Log::Log4perl;
use Proc::Simple;
use Clone qw(clone);
use Time::HiRes qw(gettimeofday tv_interval);
use Time::Interval;
use Time::Piece::ISO;
use GraphViz;
use Digest::MD5;
use Data::Dumper;

use warnings;
use strict;
our $VERSION = '0.09';

=encoding utf8

=head1 NAME

Makefile::Parallel - A distributed parallel makefile

=head1 SYNOPSIS

This module should not be called directly. Please see the perldoc of
the pmake program on the /examples directory of this distribution.

=cut

# Module Stuff
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( process_makefile );

my $logger;

my $queue;
my $running   = {}; # Holds the running ID's   (ID -> info)
my $finnished = {}; # Holds the finnished ID's (ID -> info)
my $scheduler;      # Holds the scheduler engine
my $counter   = 0;  # Holds the order of the executed processes
my $filename;       # Holds the filename of the makefile
my $debug;          # TRUE if we got debug enabled

# This stuff deals with the interruption (Ctrl + C)
$SIG{INT}  = \&process_interrupt;
my $interrupted       = 0;

=head1 process_makefile

Main function. Accepts a file to parse and a 
hash reference with options.

TODO: Document options

=cut

sub process_makefile {
    my ($file, $options) = @_;

    # Set sensible defaults
    $options              ||= {};
    $options->{scheduler} ||= 'LOCAL';
    $options->{local}     ||= '1'; # Default CPU's on local mode
    $options->{dump}      ||= 0;
    $options->{clean}     ||= 0;
    $options->{clock}     ||= 10;
    $options->{debug}     ||= 0;
    $options->{continue}  ||= 0;

    # TODO: Give more flexibility
    if($options->{scheduler} eq 'PBS') {
        use Makefile::Parallel::Scheduler::PBS;
        $scheduler = Makefile::Parallel::Scheduler::PBS->new();
        $scheduler->{mail} = $options->{mail} if $options->{mail};
    } else {
        use Makefile::Parallel::Scheduler::Local;
        $scheduler = Makefile::Parallel::Scheduler::Local->new({ max => $options->{local} });
    }

    # Debug settings
    if($options->{debug}) { 
        # Clean logs... ## FIXME - do not rely on OS.
        `rm -rf log/`; mkdir "log";

        my $conf = q(
            log4perl.category.PMake = DEBUG, Logfile, Screen

            log4perl.appender.Logfile = Log::Log4perl::Appender::File
            log4perl.appender.Logfile.filename = log/makefile.log
            log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Logfile.layout.ConversionPattern = [%d] [%p]	%F(%L) %m%n

            log4perl.appender.Screen = Log::Log4perl::Appender::Screen
            log4perl.appender.Screen.stderr = 0
            log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Screen.layout.ConversionPattern = [%d] %m%n
        );
        Log::Log4perl::init(\$conf);
        $debug = 1;
    }
    else {
        my $conf = q(
            log4perl.category.PMake = INFO, Screen

            log4perl.appender.Screen = Log::Log4perl::Appender::Screen
            log4perl.appender.Screen.stderr = 0
            log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Screen.layout.ConversionPattern = [%d] %m%n
        );
        Log::Log4perl::init(\$conf);
        $debug = 0;
    }
    $logger = Log::Log4perl::get_logger("PMake");

    # Parse the file
    $logger->info("Trying to parse \"$file\"");
    $queue = Makefile::Parallel::Grammar->parseFile($file);

    if($queue) { $logger->info("Parse ok.. proceeding to plan the scheduling"); }
    else {       $logger->error("Parse failed, aborting..."); return }
    $filename = $file;

    # Copy perl routines to perl actions
    if(defined $queue->[-1]{perl}) {
	for my $job (@{$queue}) {
		if(defined $job->{action}[0]{perl}) {
			$job->{perl} = $queue->[-1]{perl};
		}
	}
	delete $queue->[-1];
    }

    # Dump if the user want it
    die Dumper $queue if($options->{dump});

    # Clean the temporary files if we are PBS
    clean() if($options->{clean});

    # Recover the journal if the user wants to continue
    journal_recover() if ($options->{continue});

    # Enter the loop
    while(1) {
        # $logger->debug("New loop starting");
        loop();
        # $logger->debug("Loop processed, sleeping");
        sleep $options->{clock};
    }
}

=head1 journal_recover

Tries to recover the journal of the last makefile run.

=cut

sub journal_recover {
    my $journal = do "$filename.journal" or die "Can't open $filename.journal: $!";

    my $md5 = calc_makefile_md5();
    if($journal->{md5} ne $md5) {
        $logger->warn("MD5 Check Failed... The original Makefile was changed!! CONTINUE AT YOUR OWN RISK!");
    }

    # Restore the finnished list
    $finnished = $journal->{finnished};
    $counter   = $journal->{counter};

    # Ignore jobs already concluded
    # 1a passagem - cálculo das variáveis
    for my $job (@{$queue}) {
      next unless $job;
      if(is_finnished($job->{rule}{id})) {
        # If we got asShell to run, run it!
        find_and_run_asShell($job->{rule}{id});
        # If we got asPerl to run, run it!
        find_and_run_asPerl($job->{rule}{id});
      }
    }

    # 2a passagem - remoção dos já executados
    my $new_queue = [];
    for my $job (@{$queue}) {
      next unless $job;
      push @{$new_queue}, $job unless is_finnished($job->{rule}{id});
    }
    $queue = $new_queue;

    $logger->warn("Journal recovered.. Cross your fingers now..."); 
}

=head1 clean

This function is responsible to clean all the temporary files
created by the PBS system. It should be used only on the PBS scheduler
method.

=cut

sub clean {
    $scheduler->clean($queue);    

    $logger->info("Temporary files cleaned");
    exit(0);
}

=head1 loop

Loop it baby :D

=cut

sub loop {
    reap_dead_bodies();
    dispatch();
    write_journal();
}

=head1 reap_dead_bodies

This function is responsible of reaping the jobs that are
finnished. If the job needs to run something at the end
(example, find i <- grep | awk...) it is executed and the job
queue is expanded.

=cut

sub reap_dead_bodies {
    # Search all running procs for someone who died
    for my $runid (keys %{$running}) {
        if($scheduler->poll($running->{$runid}, $logger)) {
            # Still running
        } else {
            # No running anymore, remove from running and save

            # Save time stats
            my $t1 = [gettimeofday];
            my $elapsed = tv_interval($running->{$runid}->{starttime}, $t1);

            $running->{$runid}->{stoptime} = $t1;

            $elapsed = parseInterval(seconds => int($elapsed), Small => 1);
            $running->{$runid}->{elapsed}  = $elapsed;

            # Give user some feedback
            $logger->info("Process " . $scheduler->get_id($running->{$runid})
                        . " (" . $running->{$runid}->{rule}->{id} 
                        . ") has terminated [$elapsed]");
            $finnished->{$runid} = $running->{$runid};
            delete $running->{$runid};

            # Don't do nothing more if it was interrupted
            next if($finnished->{$runid}{interrupted});

            # Verify the exit status
            $scheduler->get_dead_job_info($finnished->{$runid});
            if($finnished->{$runid}{exitstatus} && !$finnished->{$runid}{interrupted}) {
                # Pumm!! Cancelar tudo!
                $logger->fatal("Process " . $scheduler->get_id($finnished->{$runid}) . " exited
                                with exit status " . $finnished->{$runid}{exitstatus} . "! Aborting
                                all queue...");
                process_interrupt(1);          # Forced;
                $finnished->{$runid}{fatal} = 1; # To graphviz later...
            }

            # If we got asShell to run, run it!
            find_and_run_asShell($runid);
            # If we got asPerl to run, run it!
            find_and_run_asPerl($runid);
        }
    }
}

=head1 find_and_run_asShell

This function goes through the finnished job
and tries to find asShell commands to run, doing
all the expands necessary

=cut

sub find_and_run_asShell {
    my ($runid) = @_;

    for my $action (@{$finnished->{$runid}->{action}}) {
        if($action->{asShell} && !(defined $finnished->{__var__}->{$action->{def}})) {
            $logger->info("Running shell action $action->{asShell}");
            $finnished->{__var__}->{$action->{def}} = [];

            open P, "$action->{asShell} |"; 
            while(<P>) {
                chomp;
                $logger->warn("Return value from the shell action is not a integer") unless /^\d+$/;
                push @{$finnished->{__var__}->{$action->{def}}}, $_;
            }
            close P;

            # Now expand the queue
            expand_forks($action->{def});
        }
    }
}

=head1 find_and_run_asPerl

This function goes through the finnished job
and tries to find asPerl commands to run, doing
all the expands necessary

=cut

sub find_and_run_asPerl {
    my ($runid) = @_;

    for my $action (@{$finnished->{$runid}->{action}}) {
        if($action->{asPerl} && !(defined $finnished->{__var__}->{$action->{def}})) {
            $logger->info("Running perl action $action->{asPerl}");
            $finnished->{__var__}->{$action->{def}} = [];
            $finnished->{__var__}{$action->{def}} = paction_list($action->{asPerl});

            # Now expand the queue
            expand_forks($action->{def});
        }
    }
}

=head1 paction_list

this function evaluates a perl action and retruns a list of strings.
the action can: 

 .return a ARRAY reference, 
 .print a list of lines to STDOUT (to be splited end chomped)
 .or return a string (to be splited and chomped)

=cut

sub paction_list{
  my $act=shift;
  my $var="";
  my $final=[];
  open(A,'>', \$var);
  my $old= select A;
  my $res = eval( "package main; no strict; " . $act );
  die $@ if $@;
  close A;
  select $old;

  if   (ref($res) eq "ARRAY"){ 
      $final = $res; }
  elsif($var =~ /\S/) {
      for(split("\n",$var)){ push (@$final, $_) if /\S/; } }
  else{
      for(split("\n",$res)){ push (@$final, $_) if /\S/; } }

  $final;
}

=head1 expand_forks

This function is responsible of expanding all the jobs
when a variable is evaluated. It expands both forks and 
joins.

=cut

sub expand_forks {
    my ($var)  = @_;
    my $values = $finnished->{__var__}->{$var};

    # For all queue items that has a $var, expand
    my $index = -1;
    for my $job (@{$queue}) {
		$index++;
		next unless $job;

        if($job->{rule}{vars} && (grep { $_ eq "\$$var" } @{$job->{rule}{vars}} )) {
            $logger->info("Found a fork on $job->{rule}->{id}. Expanding...");

            # Expand, expand, expand
			$job->{rule}{vars} = [ grep { $_ ne "\$$var" } @{$job->{rule}{vars} }];	
			delete $job->{rule}{vars} unless scalar @{$job->{rule}{vars}};
			
			delete $queue->[$index];

            my $count = 0;
			my @added_jobs = ();
            for my $index (@{$values}) {
               my $newjob = clone($job);
               $count++;

               # Actualiazr o id
               $newjob->{rule}{id} .= $index;

               # Actualizar a linha a executar
               for my $act (@{$newjob->{action}}) {
                   if($act->{shell}){
                     $act->{shell} =~ s/\$$var\b/$index/g;
                   }
                   elsif($act->{perl}){
                     $act->{perl} =~ s/\$$var\b/$index/g;
                   }
               }

               # Expand pipelines
               for my $dep (@{$newjob->{depend_on}}) {
                   if ($dep->{vars} && (grep { $_ eq "\$$var"} @{$dep->{vars}} )) {
                      # Expand the dependencie
					  $dep->{vars} = [ grep { $_ ne "\$$var" } @{$dep->{vars}} ];
					  delete $dep->{vars} unless scalar @{$dep->{vars}};
                      $dep->{id} .= $index;
                   }
               }
               push @{$queue}, $newjob;
			   push @added_jobs, $newjob->{rule}{id};
            } 
            $logger->info("Expanded.. Created new $count jobs: @added_jobs");
        }

        # Find joiners
        my $pos = 0;
        for my $dep (@{$job->{depend_on}}) {
            if ($dep->{vars} && (grep { $_ eq "\$$var" } @{$dep->{vars}} )) {
	
			   $dep->{vars} = [ grep { $_ ne "\$$var" } @{$dep->{vars}}];
	
               # Expand the dependencies
               delete $job->{depend_on}->[$pos];
               for my $index (@{$values}) {
				    my @vars = (scalar @{$dep->{vars}})?(vars => $dep->{vars}):();
                    push @{$job->{depend_on}}, { @vars, 
                                                 id => $dep->{id} . $index }; 
               }
            }
            $pos++;
        }
    }

    # Now find constructors like @var
    for my $job (@{$queue}) {
        next unless $job;

        # Search on actions
        for my $action (@{$job->{action}}) {
            if($action->{shell} && $action->{shell} =~ /\@$var\b/) {
                my $string = '';
                map { $string .= "$_ " } @{$values};
                $action->{shell} =~ s/\@$var\b/$string/g;
                $logger->info("The job $job->{rule}->{id} has been action expanded with $string");
            }
            elsif($action->{perl} && $action->{perl} =~ /\@$var\b/) {
                my $string = join(",", map { "q{$_}" } @{$values});
                $action->{perl} =~ s/\@$var\b/($string)/g;
                $logger->info("The job $job->{rule}->{id} has been action expanded with ($string)");
            }
        }

        # Search on asShell
        for my $action (@{$job->{action}}) {
            if($action->{asShell} && $action->{asShell} =~ /\@$var\b/) {
                my $string = '';
                map { $string .= "$_ " } @{$values};
                $action->{asShell} =~ s/\@$var\b/$string/g;
                $logger->info("The job $job->{rule}->{id} has been shell expanded with $string");
            }
        }

        # Search on asPerl
        for my $action (@{$job->{action}}) {
            if($action->{asPerl} && $action->{asPerl} =~ /\@$var\b/) {
                my $string = 'qw/';
                map { $string .= "$_ " } @{$values};
                $string .= "/";

                $action->{asPerl} =~ s/\@$var\b/$string/g;
                $logger->info("The job $job->{rule}->{id} has been Perl expanded with $string");
            }
        }
    }
}

=head1 report

Print a pretty report bla bla bla

=cut

sub report {

    $logger->info("Creating HTML report");
    open REPORT, ">$filename.html" or die "Can't create $filename.html";

    print REPORT "<table>\n";
    print REPORT "<tr><td>ID</td><td>Start Time</td><td>End Time</td><td>Elapsed</td></tr>\n";

    my ($id,$start,$stop,$interval);
    for my $job (sort sortcallback keys %{$finnished}) {
       next unless $finnished->{$job}{rule};

       $id       = $finnished->{$job}{rule}{id};
       $start    = (localtime($finnished->{$job}{starttime}[0]))->iso;
       $stop     = (localtime($finnished->{$job}{stoptime}[0]))->iso;
       $interval = $finnished->{$job}{realtime} || $finnished->{$job}{elapsed};
       print REPORT "<tr><td>$id</td><td>$start</td><td>$stop</td><td>$interval</td></tr>\n";
    }

    print REPORT "</table>\n";
    close REPORT;
}

sub sortcallback {
    my $foo = $finnished->{$a};
    my $bar = $finnished->{$b};

    return  0 if(!$foo->{order} && !$bar->{order});
    return -1 unless $foo->{order};
    return  1 unless $bar->{order};

    return $foo->{order} <=> $bar->{order};
}

=head1 dispatch

This function is responsible for dispatching the jobs that can run.

=cut

sub dispatch {
    my $new_queue = [];

    # If we aren't running nothing and ($interrupted || $queue empty) exit
    if((scalar keys %{$running}) == 0 && ($interrupted || (scalar @{$queue} == 0))) {
        $logger->info("Terminating the pipeline");
        at_exit();
    }

    # We don't wanna dispatch NOTHING if we have interrupted
    return if $interrupted;

    for my $job (@{$queue}) {
        next unless $job;

        # Find if the job dependencies are finnished
        if(can_run_job($job->{rule}->{id}, $job->{depend_on})) {

            $logger->info(Dumper($job)) unless $job->{rule}{id};

            $logger->info("The job \"" . $job->{rule}->{id} . "\" is ready to run. Launching");
            launch($job);
            $job->{starttime} = [gettimeofday];

            # Jump to the next job in queue
            next;
        } 

        # This job can't run yet.. add it to the new queue
        push @{$new_queue}, $job;
    } 

    # Return the new queue, the jobs that can't be dispatched yet
    $queue = $new_queue;
}

=head1 is_finnished

This function checks if the specified job is already done in
the finnished list.

=cut

sub is_finnished {
  my ($jobid) = @_;
  for my $job (keys %{$finnished}) {
    next unless $finnished->{$job}{rule};
    return 1 if($finnished->{$job}{rule}{id} eq $jobid);
  }
  return 0;
}

=head1 at_exit

This sub is called at the program exit

=cut

sub at_exit {
    graphviz();
    report();
    write_journal();

    exit(0);
}

=head1 write_journal

Saves the scheduler state to disk.

=cut

sub write_journal {
    my $journal = {};
    $journal->{md5} = calc_makefile_md5();

    # Pass all interrupted and failled processes back to queue
    my $acabados = clone($finnished);
    for my $job (keys %{$acabados}) {
        next unless $acabados->{$job}{rule};

        if($acabados->{$job}{fatal} || $acabados->{$job}{interrupted}) {
            delete $acabados->{$job};
        }
    }
    delete $acabados->{__var__};

    $journal->{finnished} = $acabados;
    $journal->{counter}   = $counter;

    open F, ">$filename.journal";
    print F (Dumper $journal);
    close F;
}

=head1 calc_makefile_md5

Calculates the MD5 of the current makefile

=cut

sub calc_makefile_md5 {
    open F, "<$filename";
    my $ctx = Digest::MD5->new;
    $ctx->addfile(*F);
    close F;

    return $ctx->b64digest;
}

=head1 can_run_jub

This one finds out if a job can run (all the dependencies are met).

=cut

sub can_run_job {
    my ($id, $deps) = @_;

    return 0 unless $scheduler->can_run();

    for my $dep (@{$deps}) {
        next unless $dep;
        next unless $dep->{id};
        return 0 unless defined $finnished->{$dep->{id}}
    }

    return 1;
}

=head1 launch

Launch a process (really??)

=cut

sub launch {
    my ($job) = @_;

    # Launch the process
    $scheduler->launch($job, $debug);
    $job->{order} = $counter++;

    # Save in the running list
    $running->{$job->{rule}->{id}} = $job;
    $logger->info("Launched \"" . $job->{rule}->{id} . "\" (" . $scheduler->get_id($job) . ")");
}

=head1 graphviz

Builds a preety graphviz file after the execution of the makefile

=cut

sub graphviz {
    my $time_for = {}; # Holds the walltime for the job id

    my $g = GraphViz->new(rankdir => 1);

    $logger->info("Creating GraphViz nodes");
    # Create all nodes
    for my $job (keys %{$finnished}) {
        next unless $finnished->{$job}{rule};

        my $id = $finnished->{$job}{rule}{id};
        $time_for->{$id} = $finnished->{$job}{realtime} || $finnished->{$job}{elapsed};

        my $color = 'black';
        $color = 'red' if $finnished->{$job}{fatal};
        $color = 'yellow' if $finnished->{$job}{interrupted};

        $g->add_node($id, label => "$id\n$time_for->{$id}"
                        , shape => 'box', color => $color);
    }

    $logger->info("Creating GraphViz edges");
    # Create edges
    for my $job (keys %{$finnished}) {
        next unless $finnished->{$job}{rule};

        for my $dep (@{$finnished->{$job}{depend_on}}) {
            next unless $dep;

            $g->add_edge($dep->{id}, $finnished->{$job}{rule}{id});
        }
    }

    open F, ">$filename.ps";
    print F $g->as_ps;
    close F;

    open F, ">$filename.dot";
    print F $g->as_text;
    close F;

    $logger->info("GraphViz file created on $filename.ps");
}

=head1 process_interrupt

This function is called everytime the user send a SIGINT to this process. 
The objective is to kill all the running processes and wait for them to die.

=cut

sub process_interrupt {
    my $forced = shift;
    $forced = 0 if $forced eq "INT"; # Hack O:-)

    if(!$interrupted || $forced) {
        if(!$forced) {
            $logger->warn("Interrupt pressed, enter QUIT to quit, other thing to continue");
            my $linha = <STDIN>;
            chomp($linha);

            if($linha ne 'QUIT') {
                $logger->info("Interrupt canceled... Keeping the loop");
                return;
            }
        }

        $interrupted = 1;
        $logger->info("Interrupt pressed, cleaning all the running processes");

        for my $runid (keys %{$running}) {
            $logger->info("Terminating job " . $scheduler->get_id($running->{$runid}));
            $running->{$runid}{interrupted} = 1;
            $scheduler->interrupt($running->{$runid});
        }
   } else {
      $logger->warn("Interrupt already called, please wait while cleaning");
   }
}


=head1 AUTHOR

Ruben Fonseca, C<< <root@cpan.org> >>

Alberto Simões C<< <ambs@cpan.org> >>

José João Almeida C<< <jj@di.uminho.pt> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-makefile-parallel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Makefile-Parallel>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2011 Ruben Fonseca, et al, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Makefile::Parallel
