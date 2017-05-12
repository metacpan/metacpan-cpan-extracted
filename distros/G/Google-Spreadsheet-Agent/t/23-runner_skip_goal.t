use strict;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 8 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $turn_off = { ready => undef, goalnotskipped => undef, sleepbetween => undef };
my $turn_on = { ready => 1, goalnotskipped => undef, sleepbetween => undef };

my $agent_runner = Google::Spreadsheet::Agent::Runner->new(
   only_pages => ['testing' ],
   sleep_between => 10
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'goalnotskipped', 'sleepbetween'],
                               rows => [
                                   { testentry => 'test' },
                                   { testentry => 'skipgoaltest' }
                               ]
                             }
};

setup_pages($page_rows, $agent_runner->google_db);

my $goalnotskipped_script = join('/', $agent_runner->agent_bin, 'goalnotskipped_agent.pl');
my $sleepbetween_script = join('/', $agent_runner->agent_bin, 'sleepbetween_agent.pl');

`chmod 700 ${goalnotskipped_script}`;
if ($?) {
    die "Could not chmod $goalnotskipped_script $!\n";
}

`chmod 700 ${sleepbetween_script}`;
if ($?) {
    die "Could not chmod $sleepbetween_script $!\n";
}

my $test_agent = Google::Spreadsheet::Agent->new(
               agent_name => 'goalnotskipped',
               page_name => 'testing',
               bind_key_fields => { 'testentry' => 'test' }
);

my $skipgoaltest_agent = Google::Spreadsheet::Agent->new(
               agent_name => 'goalnotskipped',
               page_name => 'testing',
               bind_key_fields => { 'testentry' => 'skipgoaltest' }
);


$skipgoaltest_agent->get_entry()->param($turn_on);
$agent_runner->run;
sleep 15;

my $skipgoaltest_agent_entry = $skipgoaltest_agent->get_entry();
is($skipgoaltest_agent_entry->content->{goalnotskipped}, 1, 'goalnotskipped should be 1 with no skip_goal set');
is($skipgoaltest_agent_entry->content->{sleepbetween}, 1, 'sleepbetween should be 1 with no skip_goal set');

$skipgoaltest_agent->get_entry()->param($turn_on);
$agent_runner->skip_goal(sub {
  my ($entry, $goal) = @_;

  # the default skip_goal skips goals whose agent_bin script is not executable, which should be emulated
  # if you know that this might be the case for some goals in the spreadsheet
  return 1 unless (-x join('/', $agent_runner->agent_bin, $goal.'_agent.pl'));
  return ($goal eq 'goalnotskipped');
});

$agent_runner->run;
sleep 10;

$skipgoaltest_agent_entry = $skipgoaltest_agent->get_entry();
is($skipgoaltest_agent_entry->content->{goalnotskipped}, '', 'goalnotskipped should be undef with skip_goal set');
is($skipgoaltest_agent_entry->content->{sleepbetween}, 1, 'sleepbetween should still be 1 with skip_goal set');

$skipgoaltest_agent->get_entry()->param($turn_on);
$agent_runner->skip_goal(
    sub {
          my ($entry, $goal) = @_;

          return 1 unless (-x join('/', $agent_runner->agent_bin, $goal.'_agent.pl'));
          return ($goal ne 'goalnotskipped') 
        }
);

$agent_runner->run;
sleep 10;

$skipgoaltest_agent_entry = $skipgoaltest_agent->get_entry();
is($skipgoaltest_agent_entry->content->{goalnotskipped}, 1, 'goalnotskipped should be 1 with skip_goal set to skip all other goals');
is($skipgoaltest_agent_entry->content->{sleepbetween}, '', 'sleepbetween should still be 1 with skip_goal set to skip all other goals');

`chmod 600 ${sleepbetween_script}`;
if ($?) {
    die "Could not chmod $sleepbetween_script $!\n";
}

$test_agent->get_entry()->param($turn_on);
$skipgoaltest_agent->get_entry()->param($turn_on);
$agent_runner->skip_goal(
    sub {
          my ($entry, $goal) = @_;
          return 1 unless (-x join('/', $agent_runner->agent_bin, $goal.'_agent.pl'));
          return if ($entry->{testentry} eq 'skipgoaltest' && $goal eq 'goalnotskipped');
          return 1; # skip all the rest
        }
);
# note, above could be accomplished with a skip_entry filter with a skip_goal filter but its useful to
# demonstrate that the entry is there to check for other attributes on it to determine whether a goal should
# run or not

$agent_runner->run;
sleep 10;

my $test_agent_entry = $test_agent->get_entry();
$skipgoaltest_agent_entry = $skipgoaltest_agent->get_entry();
is($test_agent_entry->content->{goalnotskipped}, '', 'testing.goalnotskipped should be undef for skipgoaltest for this skip_goal');
is($skipgoaltest_agent_entry->content->{goalnotskipped}, 1, 'skipgoaltest.goalnotskipped should be 1 for skipgoaltest for this skip_goal');

`chmod 600 ${goalnotskipped_script}`;
if ($?) {
    die "Could not chmod $goalnotskipped_script $!\n";
}

cleanup_pages($page_rows, $agent_runner->google_db);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my $google_db = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my $google_db = shift;

  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $google_db->add_worksheet({
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
