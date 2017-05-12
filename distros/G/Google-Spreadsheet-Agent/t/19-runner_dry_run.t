use IO::CaptureOutput qw/capture/;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $turn_on = { ready => 1, dryrun => undef };
my $turn_off = { ready => undef, dryrun => undef };

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 24 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $testing_dry_run_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'dryrun',
                  page_name => 'testing',
                  bind_key_fields => {'testentry' => 'testing.dryruntest'}
);

my $skip_page_dry_run_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'dryrun',
                  page_name => 'skip_page',
                  bind_key_fields => {'testentry' => 'skip_page.dryruntest'}
);

my $only_page_dry_run_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'dryrun',
                  page_name => 'only_page',
                  bind_key_fields => {'testentry' => 'only_page.dryruntest'}
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'dryrun'],
                               rows => [
                                         { testentry => 'testing.dryruntest' }
                                       ]
                             },
                  skip_page => {
                               header => ['testentry','ready', 'dryrun'],
                               rows => [
                                         { testentry => 'skip_page.dryruntest' }
                                       ]
                             },
                  only_page => {
                               header => ['testentry','ready', 'dryrun'],
                               rows => [
                                         { testentry => 'only_page.dryruntest' }
                                       ]
                             },
};

setup_pages($page_rows);

my $agent_script = $FindBin::Bin.'/../agent_bin/dryrun_agent.pl';
`chmod 700 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}

my $agent_runner = Google::Spreadsheet::Agent::Runner->new(
     dry_run => 1,
);

my ($prog_out, $prog_err);
capture { $agent_runner->run; } \$prog_out, \$prog_err;
ok(!$testing_dry_run_test_agent->get_entry()->content->{dryrun}, 'Not ready, dryrun_agent should not have run on testing');
ok(!$skip_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'Not ready, dryrun_agent should not have run on skip_page');
ok(!$only_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'Not ready, dryrun_agent should not have run on only_page');
unlike($prog_err, qr/$agent_script testing.dryrun/, 'Not ready, command for running dryrun_agent on testing should not be in program stderr');
unlike($prog_err, qr/$agent_script skip_page.dryrun/, 'Not ready, command for running dryrun_agent on skip_page should not be in program stderr');
unlike($prog_err, qr/$agent_script only_page.dryrun/, 'Not ready, command for running dryrun_agent on only_page should not be in program stderr');

$testing_dry_run_test_agent->get_entry()->param($turn_on);
$skip_page_dry_run_test_agent->get_entry()->param($turn_on);
$only_page_dry_run_test_agent->get_entry()->param($turn_on);

($prog_out, $prog_err) = undef;
capture { $agent_runner->run; } \$prog_out, \$prog_err;
ok(!$testing_dry_run_test_agent->get_entry()->content->{dryrun}, 'Ready, but dryrun_agent should still not have run');
ok(!$skip_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'Ready, but dryrun_agent should still not have run');
ok(!$only_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'Ready, but dryrun_agent should not have run');
like($prog_err, qr/$agent_script testing.dryrun/, 'Ready, command for running dryrun_agent on testing should be in proram std_err');
like($prog_err, qr/$agent_script skip_page.dryrun/, 'Ready, command for running dryrun_agent on skip_page should be in program stderr');
like($prog_err, qr/$agent_script only_page.dryrun/, 'Ready, command for running dryrun_agent on only_page should be in program stderr');

$testing_dry_run_test_agent->get_entry()->param($turn_on);
$skip_page_dry_run_test_agent->get_entry()->param($turn_on);
$only_page_dry_run_test_agent->get_entry()->param($turn_on);
($prog_out, $prog_err) = undef;

$agent_runner->only_pages(['testing']);

capture { $agent_runner->run; } \$prog_out, \$prog_err;
ok(!$testing_dry_run_test_agent->get_entry()->content->{dryrun}, 'dryrun_agent should never run on testing');
ok(!$skip_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'dryrun_agent should never run on skip_page');
ok(!$only_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'dryrun_agent should never run on only_page');
like($prog_err, qr/$agent_script testing.dryrun/, 'only_pages testing, command for running dryrun_agent on testing should be in program stderr');
unlike($prog_err, qr/$agent_script skip_page.dryrun/, 'only_pages testing, command for running dryrun_agent on skip_page should not be in program stderr');
unlike($prog_err, qr/$agent_script only_page.dryrun/, 'only_pages testing, command for running dryrun_agent on only_page should not be in program stderr');

$testing_dry_run_test_agent->get_entry()->param($turn_on);
$skip_page_dry_run_test_agent->get_entry()->param($turn_on);
$only_page_dry_run_test_agent->get_entry()->param($turn_on);
($prog_out, $prog_err) = undef;

$agent_runner->no_only_pages;
$agent_runner->skip_pages(['testing','only_page']);
capture { $agent_runner->run; } \$prog_out, \$prog_err;
ok(!$testing_dry_run_test_agent->get_entry()->content->{dryrun}, 'dryrun_agent should never run on testing');
ok(!$skip_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'dryrun_agent should never run on skip_page');
ok(!$only_page_dry_run_test_agent->get_entry()->content->{dryrun}, 'dryrun_agent should never run on only_page');
unlike($prog_err, qr/$agent_script testing.dryrun/, 'skip_pages testing, only_page; command for running dryrun_agent on testing should not be in program stderr');
like($prog_err, qr/$agent_script skip_page.dryrun/, 'skip_pages testing, only_page; command for running dryrun_agent on skip_page should be in program stderr');
unlike($prog_err, qr/$agent_script only_page.dryrun/, 'skip_pages testing, only_page; command for running dryrun_agent on only_page should not be in program stderr');

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
      my $page = $testing_dry_run_test_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $testing_dry_run_test_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $testing_dry_run_test_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $testing_dry_run_test_agent->google_db->add_worksheet({
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
