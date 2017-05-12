package Google::Spreadsheet::Agent::Runner;

use FindBin;
use Moose;
use Carp;

our $VERSION = '0.02';

extends ('Google::Spreadsheet::Agent::DB');

has 'dry_run' => (
                  is => 'rw',
                  isa => 'Bool',
                  predicate => 'is_dry_run',
                  clearer => 'no_dry_run'
                  );

has 'run_in_serial' => (
                        is => 'rw',
                        isa => 'Bool',
                        default => 0,
                        predicate => 'is_run_in_serial'
                        );

has 'debug' => (
                is => 'rw',
                isa => 'Bool',
                lazy => 1, # depends on dry_run if not set explicitly
                builder => '_build_debug',
                predicate => 'is_debug',
                clearer => 'no_debug'
                );

has 'query_fields' => (
                       is => 'ro',
                       isa => 'ArrayRef',
                       lazy => 1, # depends on config
                       builder => '_build_query_fields',
                       init_arg => undef # query_fields cannot be overridden
                       );

has 'sleep_between' => (
                        is => 'rw',
                        isa => 'Int',
                        default => 5
                        );

has 'agent_bin' => (
                    is => 'rw',
                    isa => 'Str',
                    default => sub { $FindBin::Bin.'/../agent_bin' },
                    );

has 'skip_pages' => (
                     is => 'rw',
                     isa => 'ArrayRef',
                     predicate => 'has_skip_pages',
                     clearer => 'no_skip_pages'
                     );

has 'skip_pages_if' => (
                     is => 'rw',
                     isa => 'CodeRef',
                     predicate => 'has_skip_pages_if',
                     clearer => 'no_skip_pages_if'
                     );

has 'only_pages' => (
                     is => 'rw',
                     isa => 'ArrayRef',
                     predicate => 'has_only_pages',
                     clearer => 'no_only_pages'
                     );

has 'only_pages_if' => (
                     is => 'rw',
                     isa => 'CodeRef',
                     predicate => 'has_only_pages_if',
                     clearer => 'no_only_pages_if'
                     );

has 'skip_entry' => (
                     is => 'rw',
                     isa => 'CodeRef',
                     builder => '_build_skip_entry'
);

has 'skip_goal' => (
                    is => 'rw',
                    isa => 'CodeRef',
                    lazy => 1, # depends on agent_bin
                    builder => '_build_skip_goal'
);

has 'process_entries_with' => (
                               is => 'rw',
                               isa => 'CodeRef',
                               lazy => 1,
                               builder => '_build_process_entries_with'
                               );

# BUILDERS

sub BUILD {
    my $self = shift;

    die ("You cannot construct a runner with both only_pages and skip_pages\n") if ($self->only_pages && $self->skip_pages);
}

sub _build_debug {
    my $self = shift;
    return $self->dry_run;
}

sub _build_query_fields {
    my $self = shift;

    return [
            sort {
                $self->config->{key_fields}->{$a}->{rank} <=> $self->config->{key_fields}->{$b}->{rank} 
            } keys %{$self->config->{key_fields}}
            ];
}

sub _build_skip_entry {
    return (
            sub {
                my $entry = shift;
                return 1 unless ($entry->content->{ready});
                return 1 if ($entry->content->{complete});
                return; 
            }
            );
}

sub _build_skip_goal {
    my $self = shift;
    return (
            sub {
                my ($entry, $goal) = @_;
                print "Checking ${goal}\n" if ($self->debug);

                return 1 if ($entry->{$goal}); # r, 1, F cause it to be skipped
                my $goal_script = join('/', $self->agent_bin, $goal.'_agent.pl');
                return 1 unless (-x $goal_script);
                return;
            }
            );
}

sub _build_process_entries_with {
    my $self = shift;

    return (
                  sub {
                      my $runnable_entry = shift;
                      my $title = join(' ', map { $runnable_entry->{$_} } @{$self->query_fields});
                      print STDERR "Checking goals for ${title}\n" if ($self->debug);

                      foreach my $goal ( grep { !$self->skip_goal->($runnable_entry, $_) } keys %{$runnable_entry} ) {
                          $self->run_entry_goal($runnable_entry, $goal);
                          sleep $self->sleep_between;
                      }
                  }
            );
}

# METHODS

sub run_entry_goal {
    my ($self, $entry, $goal) = @_;
    print STDERR "Running goal ${goal}\n" if ($self->debug);

    my $goal_agent = join('/', $self->agent_bin, $goal.'_agent.pl');
    my @cmd = ($goal_agent);

    foreach my $query_field ( @{$self->query_fields} ) {
        next unless ($entry->{$query_field});
        push @cmd, $entry->{$query_field};
    }

    my $command = join(' ', @cmd);
    $command .= '&' unless ($self->run_in_serial);
    print STDERR "${command}\n" if ($self->debug);

    if (-x $goal_agent) {
        unless ($self->dry_run) {
            system($command);
        }
    }
    else {
        print STDERR "AGENT RUNNER DOES NOT EXIST!\n";
    }
}

sub get_pages_to_process {
    my $self = shift;

    my %skip_page = ();
    if ($self->only_pages) {
        %skip_page = map { $_->title => 1 } $self->google_db->worksheets;
        map { undef $skip_page{$_} } @{$self->only_pages};
    }
    elsif ($self->only_pages_if) {
        return grep { $self->only_pages_if->($_) } $self->google_db->worksheets;
    }
    elsif ($self->skip_pages) {
        %skip_page = map { $_ => 1 } @{$self->skip_pages};
    }
    elsif ($self->skip_pages_if) {
        return grep { !$self->skip_pages_if->($_) } $self->google_db->worksheets;
    }
    else {
        return $self->google_db->worksheets;
    }

    return grep { !($skip_page{$_->title}) } $self->google_db->worksheets;
}

sub get_runnable_entries {
    my $self = shift;
    my @runnable_entries = ();

    foreach my $page ($self->get_pages_to_process) {
        print STDERR "Processing page ".$page->title."\n" if ($self->debug);
        push @runnable_entries, grep { !($self->skip_entry->($_)) } $page->rows;
    }

    return @runnable_entries;
}

sub run {
    my $self = shift;

    foreach my $runnable_entry ($self->get_runnable_entries) {
        $self->process_entries_with->($runnable_entry->content, $runnable_entry);
        sleep $self->sleep_between;
    }
}

1;
__END__

=head1 NAME

Google::Spreadsheet::Agent - A Distributed Agent System using Google Spreadsheets

=head1 VERSION

Version 0.02

=head1 SYNOPSIS
  use Google::Spreadsheet::Agent::Runner;

  # iterate over all pages in the spreadsheet, running agents for each goal of
  # each entry that remains to be attempted, using the default skip_entry and
  # skip_goal filters (see below).

  my $agent_runner = Google::Spreadsheet::Agent::Runner->new();
  $agent_runner->run();


  # many parameters can be passed either to the constructor, or to an existing
  # Google::Spreadsheet::Agent::Runner object using the following parameters or
  # methods.
  
  # Instead of using the default entry processor (see below), override it with a
  # coderef that iterates over each entry on each page in the spreadsheet to do some
  # more appropriate work.  This coderef recieves the entry hashref, and the
  # updateable_entry Net::Google::Spreadsheet::Row object (see below) as arguments.
  my $agent_runner = Google::Spreadsheet::Agent::Runner->new();
  $agent_runner->process_entries_with(\&coderef);

  sub coderef = {
      my ($entry_content, $updateable_entry) = @_;
      # use the $entry_content hash of field key => value entries to get needed informaation
      ...
      # if applicable update the entry in the spreadsheet with a hashref of field key => value entries
      $hashref->{somefield} = $somenewvalue;
      $updateable_entry->param($hashref); # this updates the 'somefield' value for that entry
  }

  # You can modify the runner to skip specific pages
  my $agent_runner = Google::Spreadsheet::Agent::Runner->new(skip_pages => ['page1','page2']);

  # or
  $agent_runner->skip_pages(['page1','page2'];

  # or only run on a specific list of pages
  my $agent_runner = Google::Spreadsheet::Agent::Runner->new(only_pages => ['page1','page2']);

  # or
  $agent_runner->only_pages(['page1','page2']);

  # override the default entry filter. (Can be used in conjunction with skip_pages or only_pages
  # and with skip_goal).  The entry filter coderef is passed the entry hashref as argument
  my $agent_runner = Google::Spreadsheet::Agent::Runner->new(skip_entry => \&coderef);

  # or
  $agent_runner->skip_entry(\&coderef);

  sub coderef { my $entry = shift; # return 1 to skip, undef to accept }

  # override the default goal filter. (Can be used in conjunction with skip_pages or only pages,
  # and in conjunction with skip_entry). The goal filter coderef is passed the entry hashref
  # and goal string as argument.
  my $agent_runner = Google::Spreadsheet::Agent::Runner->new(skip_goal => \&coderef);

  # or
  $agent_runner->skip_goal(\&coderef);

  sub coderef { my $entry = shift; my $goal = shift; # return 1 to skip, undef to accept }

  # override the default agent_bin where the executable agents are located
  my $agent_runner = Google::Spreadsheet::Agent::Runner->new(agent_bin => $path);

  # or
  $agent_runner->agent_bin($path);

  # Once you have a constructed agent_runner, and you have set all the overrides that you
  # want to set, run the runner with
  $agent_runner->run();

  # Note, once you have run the runner, you can then override some of the parameters and run
  # it again, as needed.
    
=head1 DESCRIPTION

  This object is designed to automate the process of running
  Google::Spreadsheet::Agent scripts, or in general, iterating over entries in
  the Google::Spreadsheet::Agent::DB and doing useful work on them.  Agent runners
  can be run manually, or within a scheduling system, such as cron, at specified
  intervals.

=head1 CONFIGURATION

See L<Google::Spreadsheet::Agent::DB> for information about how to configure your Agent. 

=head1 METHODS

=head2 new

  This method constructs a new instance of a Google::Spreadsheet::Agent::Runner.  It
  requires no arguments, but there are several optional arguments which can be passed
  in to override its functionality.  Note, any of these parameters can also be called as
  setter methods on the object after it is constructed, with the same values as arguments
  to the method.

  debug => Bool
    If this is true, information about pages, entries, and goals that are checked
    and filtered is printed to STDERR.  This defaults to false.

  dry_run => Bool
    If this is true, then run will generate the commands that it would run for all
    runnable entry-goals, print them to STDERR, but not actually run the commands.
    This automatically sets debug to 1.  This defaults to false.  A runner can
    be tested to see if it is in dry_run mode using the is_dry_run method, and
    dry_run mode can be turned off using the no_dry_run method.  Note, if the
    process_entries_with coderef is overridden, this is ignored.

  run_in_serial => Bool
   If this is set to true, then the default process_entries_with subroutine runs
   each command in the foreground, rather than in the background, and thus
   runs them in serial.  The default for this is false, and all the commands
   are run in parallel, in the background.  This is not used when process_entries_with
   is set to a different CODEREF.

  sleep_between => INT
    This overrides the default amount of time, in seconds, that the runners will
    sleep between each entry that is run. The default is to sleep for 5 seconds.

  agent_bin => STR
    This overrides the default agent_bin location, $Findbin::Bin.'/../agent_bin'

  skip_pages => ARRAYREF
    This does not attempt any entries on the specified pages.
    It should not be passed with only_pages, or an exception is thrown.
    If the setter method is used to set a skip_pages ARRAYREF on a runner
    that already has an only_pages ARRAYREF, only_pages will take precidence
    over skip_pages.  You should always use the no_only_pages, no_skip_pages_if,
    or no_only_pages_if method before setting the skip_pages using the setter
    method on an already constructed runner object.

  skip_pages_if => CODEREF
    If set, this CODEREF is passed each Net::Google::Spreadsheet::Worksheet
    object as argument.  If it returns true for a given Worksheet
    the page will be skipped.  You should always use the no_skip_pages,
    no_only_pages, or no_only_pages_if method before setting the skip_pages_if
    attribute using the setter method on an already constructed runner
    object.

  only_pages => ARRAYREF
    This attempts entries only on the specified pages.  It should
    not be passed with skip_pages, or an exception is thrown.
    It is recommended that no_skip_pages, no_skip_pages_if,
    or no_only_pages_if be called before setting
    only_pages on an already constructed runner object.

  only_pages_if => CODEREF
    If set, the CODEREF is fed each Net::Google::Spreadsheet::Worksheet
    object as argument.  If this CODEREF returns false for a given Worksheet,
    it will be skipped.  It is recommended that no_skip_pages, no_skip_pages_if,
    or no_only_pages be called before setting only_pages on an already constructed
    runner object.

  skip_entry => CODEREF
    This coderef overrides the default entry filter, which filters an entry if
    it is not ready, or is complete.  Returning 1 from the coderef causes the
    entry to be skipped, and not processed by the runner, meaning it will not
    be passed to the process_entries_with coderef.

  skip_goal => CODEREF
    This is best used in conjuction with the default process_entries_with
    coderef.  This overrides the default goal filter, which skips each goal that is
    not tied to an executable ${goal}_agent.pl script in the agent_bin, or that is
    running or has already run (success or fail). This can be used alone, or in
    conjunction with only_pages or skip_pages, and also in conjunction with skip_entries.
    It is passed the $entry hashref, and $goal string as arguments.  Returning 1 from the
    coderef causes the goal to be skipped for an entry, and not processed by the default 
    process_entries_with coderef.  If you want it to be used in a supplied process_entries_with
    coderef, you will need to use it explicitly, using something like:

    unless ($runner->skip_goal->($entry->content, $goal)) {
      # do something with this entry and goal
    }

  process_entries_with => CODEREF
    This coderef overrides the default agent_runner.  The default agent_runner iterates through
    each entry not skipped by the entry_filter, and each goal not skipped by the goal_filter, and passes
    that entry and goal to the run_entry_goal method.  If a coderef is passed to override this
    default, it will have $entry_content HASHREF of each entry that is not skipped by the skip_entry filter,
    along with the $updateable_entry Net::Google::Spreadsheet::Row object as its argument.  If overridden,
    it does not iterate over individual goals on the entry, nor does it use the skip_goal filter.  
    You will need to write your own goal iterator and filter into the coderef, if you want to run, or skip over
    specific goals.  The $updateable_entry object can be used to fill in, or modify
    values for entry fields in the spreadsheet by passing a hashref with field key - values that
    you want to update to the param method of the $updateable_entry object.  Also, unless
    you make use of $self->dry_run in your coderef, this will also be ignored when the default
    coderef is overridden.

=head2 has_skip_pages

  This method allows you to determine if the object already has a defined skip_pages ARRAYREF.

=head2 no_skip_pages

  This method allows you to unset the skip_pages, so that the runner will not skip any pages.

=head2 has_skip_pages_if

  This method allows you to determine if the object has a skip_pages_if attribute set.

=head2 no_skip_pages_if

  This method allows you to unset the skip_pages_if attribute, so that the runner will not skip
  any pages.

=head2 has_only_pages

  This method allows you to determine if the object already has a defined only_pages ARRAYREF.

=head2 no_only_pages

  This method allows you to unset the only_pages, so that the runner will run all pages, or 
  skip pages.  It must be called before calling skip_pages on an already constructed object
  that has_only_pages.

=head2 no_only_pages_if

  This method allows you to clear the only_pages_if, so that the runner will run all pages, or
  use one of the other page filtering methods.

=head2 has_only_pages_if

  This method allows you to determine if the only_pages_if attribute is set.
 
=head2 is_dry_run

  This method returns true if the object is set to dry_run mode.

=head2 no_dry_run

  This method turns off dry_run mode (though it will not turn off debug mode).

=head2 is_debug

  This method returns true if the object is in debug mode (true if in dry_run, as well)

=head2 no_debug

  This method turns off debug mode (though it will not turn off dry_run mode).

=head2 run_entry_goal

  This method takes an entry HashRef, and a goal.  By default, It finds the goal_agent for the goal in agent_bin, and constructs
  a commandline to run the goal_agent for the entry.  Unless dry_run is true, it will then execute the command in the background
  and sleep sleep_between seconds.  If the goal_agent does not exist, or is not executable in the agent_bin directory, this method
  skips attempting to run it.  If debug or dry_run is true, each command is printed to STDERR before attempting to determine if the
  goal_agents exists and is executable in agent_bin, and sleep_between is ignored.

=head2 get_pages_to_process

  This method returns an array of all Net::Google::Spreadsheets::Worksheet objects from the Google::Spreadsheet::Agent::DB
  that pass the skip_pages, skip_pages_if, only_pages, or only_pages_if test.  If these are null, this returns every
  Net::Google::Spreadsheets::Worksheet object.

=head2 get_runnable_entries

  This method iterates over each Net::Google::Spreadsheets::Worksheet object returned by get_pages_to_process, and
  pushes each Net::Google::Spreadsheet::Row object that passes through the skip_entry filter onto an array, and returns
  this array.

=head2 run

  This method runs the process_entries_with coderef on each entry not skipped by the entry_filter.  It passes the
  entry HASHREF and updateable_entry Net::Google::Spreadsheet::Row object as arguments to the coderef.

=head1 AUTHOR

Darin London, C<< <darin.london at duke.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-google-spreadsheet-agent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Google-Spreadsheet-Agent>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Google::Spreadsheet::Agent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-Spreadsheet-Agent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Google-Spreadsheet-Agent>

=back

=head1 SEE ALSO

L<Google::Spreadsheet::Agent::DB>
L<Google::Spreadsheet::Agent>
L<Net::Google::Spreadsheets>
L<Moose>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Darin London.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
