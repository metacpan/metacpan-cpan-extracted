use IO::CaptureOutput qw/capture/;
use FindBin;
use Test::More;
use Google::Spreadsheet::Agent;
use Google::Spreadsheet::Agent::Runner;

my $conf_file = $FindBin::Bin.'/../config/agent.conf.yml';
if (-e $conf_file) {
  plan( tests => 6 );
}
else {
  plan( 
    skip_all => 'You must create a valid test Google Spreadsheet and a valid '
                .$conf_file
                .' configuration file pointing to it to run the tests. See README.txt file for more information on how to run the tests.'
      );
}

my $testing_agentbin_test_agent = Google::Spreadsheet::Agent->new(
                  agent_name => 'agentbinrun',
                  page_name => 'testing',
                  bind_key_fields => {'testentry' => 'agentbintest'}
);

my $page_rows = {
                  testing => {
                               header => ['testentry','ready', 'agentbinrun'],
                               rows => [
                                         { testentry => 'agentbintest', ready => 1 }
                                       ]
                             }
};

setup_pages($page_rows);

my $agent_script = $FindBin::Bin.'/agent_bin/agentbinrun_agent.pl';

my $agent_runner = Google::Spreadsheet::Agent::Runner->new(
     debug => 1
);

my ($stdout, $stderr);
capture { $agent_runner->run; } \$stdout, \$stderr;
ok(!$testing_agentbin_test_agent->get_entry()->content->{agentbinrun}, 'agentbinrun_agent should not have run with default agent_bin');
unlike($stderr, qr/$agent_script/, 'Command for running agent_script should not be in stderr');

sleep 5;

$agent_runner->agent_bin($FindBin::Bin.'/agent_bin');
capture { $agent_runner->run; } \$stdout, \$stderr;
ok(!$testing_agentbin_test_agent->get_entry()->content->{agentbinrun}, 'agentbinrun_agent should not have run with non executable agent script in set agent_bin');
unlike($stderr, qr/$agent_script/, 'Command for running agent_script should not be in stderr still');

sleep 5;
`chmod 700 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}

capture { $agent_runner->run; } \$stdout, \$stderr;
ok($testing_agentbin_test_agent->get_entry()->content->{agentbinrun}, 'agentbinrun_agent should have run');
like($stderr, qr/$agent_script/, 'Command for running agent_script should be in stderr');

`chmod 600 ${agent_script}`;
if ($?) {
    die "Could not chmod $agent_script $!\n";
}
cleanup_pages($page_rows);
exit;

sub cleanup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  my $colnum = 1;
  my @header_cells;
  foreach my $page_name (keys %page_rows) {
    if ($page_name eq 'testing') {
      my $page = $testing_agentbin_test_agent->google_db->worksheet({title => $page_name});
      foreach my $row ($page->rows) {
        $row->delete;
      }

      foreach my $header_val (@{ $page_rows{$page_name}->{header} }) {
        push @header_cells, {col => $colnum++, row => 1, input_value => ''};
      }
      $page->batchupdate_cell(@header_cells);
    }
    else {
      $testing_agentbin_test_agent->google_db->worksheet({title => $page_name})->delete;
    }
  }
}

sub setup_pages {
  my $page_def = shift;
  my %page_rows = %{$page_def};

  foreach my $page_name (keys %page_rows) {
    my $page;
    if ($page_name eq 'testing') {
      $page = $testing_agentbin_test_agent->google_db->worksheet({title=>$page_name});
      die "You must create a google spreadsheet with a testing page in it for these tests to work with.  See README.txt file for more information\n" unless($page);
    } 
    else { 
      $page = $testing_agentbin_test_agent->google_db->add_worksheet({
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
