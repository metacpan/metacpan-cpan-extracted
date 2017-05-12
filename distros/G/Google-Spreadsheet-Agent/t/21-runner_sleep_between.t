use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $run_agents = 1;
my $set_ready = 1;
my $turn_off = { ready => undef, sleepbetween => undef };
my $turn_on = { ready => 1 };

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 9 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $test_sleep_between_agent = Google::Spreadsheet::Agent->new(
               agent_name => 'sleepbetween',
               page_name => 'testing',
               bind_key_fields => { 'testentry' => 'test' }
);
my $sleepbetweentest_sleep_between_agent = Google::Spreadsheet::Agent->new(
               agent_name => 'sleepbetween',
               page_name => 'testing',
               bind_key_fields => { 'testentry' => 'sleepbetweentest' }
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'sleepbetween'],
                               rows => [
                                         { testentry => 'test' },
                                         { testentry => 'sleepbetweentest' }
                                       ]
                             }
};

setup_pages($page_rows);

my $default_diff = difference_between(5);
my $two_diff = difference_between(2);
my $eight_diff = difference_between(8);

is($default_diff, 0, 'default_diff should be 0 when nothing is ready');
is($two_diff, 0, 'two_diff should be 0 when nothing is ready');
is($eight_diff, 0, 'eight_diff should be 0 when nothing is ready');

$default_diff = difference_between(5, $set_ready);
$two_diff = difference_between(2, $set_ready);
$eight_diff = difference_between(8, $set_ready);

is($default_diff, 0, 'default_diff should be 0 when test entry is ready and no agent is run');

my $expected_two_diff = 2 - 5;
is($two_diff, $expected_two_diff, "two_diff should be ${expected_two_diff} when test entry is ready and no agent is run");

my $expected_eight_diff = 8 - 5;
is($eight_diff, $expected_eight_diff, "eight_diff should be ${expected_eight_diff} seconds when test entry is ready and no agent is run");

my $agent_script = $FindBin::Bin.'/../agent_bin/sleepbetween_agent.pl';
`chmod 700 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}

$default_diff = difference_between(5, $set_ready, $run_agents);
$two_diff = difference_between(2, $set_ready, $run_agents);
$eight_diff = difference_between(8, $set_ready, $run_agents);

# These three are susceptible to differences in timing due solely to
# timing involved in communicating with googledoc services.
# They may fail for this reason.
ok(is_within_range($default_diff, 0, 1), 'default_diff should be 0 when test entry is ready and agent is actually run');

# number of entries times (sleep_between_goal + sleep_between_entry)
$expected_two_diff = (2 + 2) - (5 + 5);
ok(is_within_range($two_diff, $expected_two_diff, 1), "two_diff should be ${expected_two_diff} when test entry is ready and agent is actually run");

$expected_eight_diff = (8 + 8) - (5 + 5);
ok(is_within_range($eight_diff, $expected_eight_diff, 1), "eight_diff should be ${expected_eight_diff} when test entry is ready and agent is actually run");

`chmod 600 ${agent_script}`;

cleanup_pages($page_rows);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $test_sleep_between_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $test_sleep_between_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $test_sleep_between_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $test_sleep_between_agent->google_db->add_worksheet({
           'title' => $page_name,
           'col_count' => scalar(@{ $page_rows{$page_name}->{header} }),
           'row_count' => scalar(@{ $page_rows{$page_name}->{rows} })
      });
    }

    my $colnum = 1;
    my @header_cells = ();
    foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
      push @header_cells, {col => $colnum++, row => 1, input_value => $header_val};
    }
    $page->batchupdate_cell(@header_cells);

    foreach my $row (@{ $page_rows{$page_name}->{rows} }) {
      $page->add_row($row);
    }
  }
}

sub difference_between {
  my ($sleep_between, $set_ready, $run_agent) = @_;

  my ($initial_time, $dtime_between, $ntime_between);
  my $drunner = get_new_runner();
  my $nrunner = get_new_runner();
  $nrunner->sleep_between($sleep_between);

  unless ($run_agent) {
    $drunner->process_entries_with( sub {
       my ($entry, $updateable_entry) = @_;

       if ($initial_time) {
         $dtime_between = time() - $initial_time;
       }
       else {
         $initial_time = time();
       }
    });

    $nrunner->process_entries_with( sub {
       my ($entry, $updateable_entry) = @_;

       if ($initial_time) {
         $ntime_between = time() - $initial_time;
       }
       else {
         $initial_time = time();
       }
    });
  }

  $test_sleep_between_agent->get_entry()->param($turn_on) if ($set_ready && !$run_agent);
  $sleepbetweentest_sleep_between_agent->get_entry()->param($turn_on) if ($set_ready);

  $initial_time = time() if ($run_agent);
  $drunner->run();
  $dtime_between = time() - $initial_time if ($run_agent);

  $test_sleep_between_agent->get_entry()->param($turn_off) if ($set_ready && !$run_agent);
  $sleepbetweentest_sleep_between_agent->get_entry()->param($turn_off) if ($set_ready);
  $test_sleep_between_agent->get_entry()->param($turn_on) if ($set_ready && !$run_agent);
  $sleepbetweentest_sleep_between_agent->get_entry()->param($turn_on) if ($set_ready);

  $initial_time = ($run_agent) ? time() : undef;
  $nrunner->run;
  $ntime_between = time() - $initial_time if ($run_agent);

  $test_sleep_between_agent->get_entry()->param($turn_off) if ($set_ready && !$run_agent);
  $sleepbetweentest_sleep_between_agent->get_entry()->param($turn_off) if ($set_ready);

  return $ntime_between - $dtime_between;
}

sub get_new_runner {
  return Google::Spreadsheet::Agent::Runner->new(
     only_pages => ['testing' ]
  );
}

sub is_within_range {
    my ($actual, $expected, $fudge) = @_;
    my @vals = sort {$a <=> $b} ($expected + $fudge, $expected - $fudge);

    return 1 if ( ($vals[0] <= $actual) && ($actual <= $vals[1]) );
    print STDERR "got ${actual} expected ${expected} +- ${fudge}\n";
    return;
}
